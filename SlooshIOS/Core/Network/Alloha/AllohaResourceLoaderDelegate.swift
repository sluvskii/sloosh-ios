import Foundation
import AVFoundation

class AllohaResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    private var headers: [String: String]
    private var session: URLSession!
    private var pendingRequests = [AVAssetResourceLoadingRequest: URLSessionDataTask]()
    
    init(headers: [String: String]) {
        self.headers = headers
        super.init()
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func updateHeaders(_ newHeaders: [String: String]) {
        self.headers.merge(newHeaders) { _, new in new }
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else { return false }
        
        // Convert custom scheme back to https/http
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if components?.scheme == "alloha-https" {
            components?.scheme = "https"
        } else if components?.scheme == "alloha-http" {
            components?.scheme = "http"
        }
        
        guard let actualURL = components?.url else { return false }
        
        var request = URLRequest(url: actualURL)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let cookies = HTTPCookieStorage.shared.cookies(for: actualURL), !cookies.isEmpty {
            let cookieHeaders = HTTPCookie.requestHeaderFields(with: cookies)
            for (key, value) in cookieHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Also set Range header if needed
        if let dataRequest = loadingRequest.dataRequest {
            if dataRequest.requestedOffset > 0 || dataRequest.requestedLength > 0 {
                let rangeHeader = "bytes=\(dataRequest.requestedOffset)-\(dataRequest.requestedOffset + Int64(dataRequest.requestedLength) - 1)"
                request.setValue(rangeHeader, forHTTPHeaderField: "Range")
            }
        }
        
        let task = session.dataTask(with: request)
        pendingRequests[loadingRequest] = task
        task.resume()
        
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        pendingRequests[loadingRequest]?.cancel()
        pendingRequests.removeValue(forKey: loadingRequest)
    }
    
    // MARK: - URLSessionDataDelegate & URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let request = pendingRequests.first(where: { $0.value == dataTask })?.key {
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                request.finishLoading(with: URLError(.badServerResponse))
                pendingRequests.removeValue(forKey: request)
                completionHandler(.cancel)
                return
            }

            if let contentInfoRequest = request.contentInformationRequest {
                let mimeType = response.mimeType ?? ""
                if mimeType.contains("mpegurl") || mimeType.contains("m3u8") || request.request.url?.pathExtension == "m3u8" {
                    contentInfoRequest.contentType = "com.apple.hls.playlist"
                } else if mimeType.contains("video/mp2t") || request.request.url?.pathExtension == "ts" {
                    contentInfoRequest.contentType = "public.mpeg-2-transport-stream"
                } else {
                    contentInfoRequest.contentType = mimeType
                }
                contentInfoRequest.contentLength = response.expectedContentLength
                contentInfoRequest.isByteRangeAccessSupported = true
            }
        }
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let request = pendingRequests.first(where: { $0.value == dataTask })?.key {
            // If it's a playlist (.m3u8), we need to modify the URIs inside it to use our custom scheme
            // so that subsequent requests for .ts segments or variants also go through our resource loader.
            if let url = dataTask.originalRequest?.url, url.pathExtension == "m3u8",
               let string = String(data: data, encoding: .utf8) {
                let modifiedString = modifyM3u8(string, baseURL: url)
                if let modifiedData = modifiedString.data(using: .utf8) {
                    request.dataRequest?.respond(with: modifiedData)
                } else {
                    request.dataRequest?.respond(with: data)
                }
            } else {
                request.dataRequest?.respond(with: data)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let request = pendingRequests.first(where: { $0.value == task })?.key {
            if let error = error {
                request.finishLoading(with: error)
            } else {
                request.finishLoading()
            }
            pendingRequests.removeValue(forKey: request)
        }
    }
    
    private func modifyM3u8(_ content: String, baseURL: URL) -> String {
        let lines = content.components(separatedBy: .newlines)
        var newLines = [String]()
        
        for line in lines {
            if line.isEmpty {
                newLines.append(line)
            } else if line.hasPrefix("#") {
                newLines.append(rewriteTaggedURIs(in: line, baseURL: baseURL))
            } else {
                newLines.append(rewriteURLString(line, baseURL: baseURL) ?? line)
            }
        }
        
        return newLines.joined(separator: "\n")
    }

    private func rewriteTaggedURIs(in line: String, baseURL: URL) -> String {
        let pattern = #"URI="([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return line
        }

        let nsLine = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        guard !matches.isEmpty else { return line }

        var rewrittenLine = line
        for match in matches.reversed() {
            guard match.numberOfRanges > 1 else { continue }
            let uri = nsLine.substring(with: match.range(at: 1))
            guard let rewrittenURL = rewriteURLString(uri, baseURL: baseURL) else { continue }
            let fullRange = match.range(at: 0)
            guard let swiftRange = Range(fullRange, in: rewrittenLine) else { continue }
            rewrittenLine.replaceSubrange(swiftRange, with: #"URI="\#(rewrittenURL)""#)
        }

        return rewrittenLine
    }

    private func rewriteURLString(_ urlString: String, baseURL: URL) -> String? {
        guard let uriURL = URL(string: urlString, relativeTo: baseURL)?.absoluteURL else {
            return nil
        }

        var components = URLComponents(url: uriURL, resolvingAgainstBaseURL: true)
        if components?.scheme == "https" {
            components?.scheme = "alloha-https"
        } else if components?.scheme == "http" {
            components?.scheme = "alloha-http"
        }

        return components?.url?.absoluteString
    }
}
