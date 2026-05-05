import Foundation
import WebKit

protocol AllohaParserDelegate: AnyObject {
    func onHlsLinksReceived(json: String, extraHeaders: [String: String])
    func onConfigUpdate(edgeHash: String, ttlSeconds: Int, extraHeaders: [String: String])
    func onM3u8Refreshed(url: String, extraHeaders: [String: String])
    func onStreamHeadersUpdated(extraHeaders: [String: String])
    func onError(error: String)
}

class AllohaParser: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    private var webView: WKWebView!
    weak var delegate: AllohaParserDelegate?
    private var isParsed = false
    
    private let userAgents = [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36",
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36"
    ]
    
    override init() {
        super.init()
        setupWebView()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: "AndroidBridge")
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.customUserAgent = userAgents.randomElement()
        webView.isHidden = true // We run it invisibly
        
        // Add to key window to ensure it processes timers and JS execution correctly
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.addSubview(self.webView)
                self.webView.frame = CGRect(x: 0, y: 0, width: 320, height: 240)
            }
        }
    }
    
    func parse(iframeUrl: String) {
        isParsed = false
        var secureUrl = iframeUrl
        if iframeUrl.hasPrefix("http://") {
            secureUrl = iframeUrl.replacingOccurrences(of: "http://", with: "https://")
        }
        
        let wrapperHtml = buildWrapperHtml(iframeUrl: secureUrl)
        if let parsedUrl = URL(string: secureUrl), let host = parsedUrl.host {
            let baseUrl = URL(string: "\(parsedUrl.scheme ?? "https")://\(host)/")
            webView.loadHTMLString(wrapperHtml, baseURL: baseUrl)
        }
    }
    
    func release() {
        DispatchQueue.main.async {
            self.webView.removeFromSuperview()
            self.webView.configuration.userContentController.removeScriptMessageHandler(forName: "AndroidBridge")
        }
    }

    private func syncCookiesToSharedStorage(completion: @escaping () -> Void) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { cookies in
            let sharedStorage = HTTPCookieStorage.shared
            for cookie in cookies {
                sharedStorage.setCookie(cookie)
            }
            completion()
        }
    }
    
    // MARK: - WKNavigationDelegate (Ignore SSL Errors)
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }
        
        switch action {
        case "onReady":
            if isParsed { return }
            isParsed = true
            let json = body["jsonResponse"] as? String ?? ""
            let headers = body["headers"] as? [String: String] ?? [:]
            syncCookiesToSharedStorage { [weak self] in
                self?.delegate?.onHlsLinksReceived(json: json, extraHeaders: headers)
            }
            
        case "onConfigUpdate":
            if !isParsed { return }
            let edgeHash = body["edgeHash"] as? String ?? ""
            let ttl = body["ttl"] as? Int ?? 120
            let headers = body["headers"] as? [String: String] ?? [:]
            syncCookiesToSharedStorage { [weak self] in
                self?.delegate?.onConfigUpdate(edgeHash: edgeHash, ttlSeconds: ttl, extraHeaders: headers)
            }
            
        case "onM3u8Refreshed":
            if !isParsed { return }
            let url = body["url"] as? String ?? ""
            let headers = body["headers"] as? [String: String] ?? [:]
            syncCookiesToSharedStorage { [weak self] in
                self?.delegate?.onM3u8Refreshed(url: url, extraHeaders: headers)
            }
            
        case "onStreamHeaders":
            if !isParsed { return }
            let headers = body["headers"] as? [String: String] ?? [:]
            syncCookiesToSharedStorage { [weak self] in
                self?.delegate?.onStreamHeadersUpdated(extraHeaders: headers)
            }
            
        case "onLog":
            let msg = body["msg"] as? String ?? ""
            print("AllohaParserJS: \(msg)")
            
        default:
            break
        }
    }
    
    private func buildWrapperHtml(iframeUrl: String) -> String {
        return """
        <html>
        <body style="margin:0;padding:0;background:black;">
            <iframe id="alloha_iframe" src="\(iframeUrl)" width="100%" height="100%" frameborder="0" allowfullscreen></iframe>
            <script>
                var AndroidBridge = {
                    onReady: function(jsonResponse, headersJson) {
                        window.webkit.messageHandlers.AndroidBridge.postMessage({action: 'onReady', jsonResponse: jsonResponse, headers: JSON.parse(headersJson)});
                    },
                    onConfigUpdate: function(edgeHash, ttl, headersJson) {
                        window.webkit.messageHandlers.AndroidBridge.postMessage({action: 'onConfigUpdate', edgeHash: edgeHash, ttl: ttl, headers: JSON.parse(headersJson)});
                    },
                    onM3u8Refreshed: function(url, headersJson) {
                        window.webkit.messageHandlers.AndroidBridge.postMessage({action: 'onM3u8Refreshed', url: url, headers: JSON.parse(headersJson)});
                    },
                    onStreamHeaders: function(headersJson) {
                        window.webkit.messageHandlers.AndroidBridge.postMessage({action: 'onStreamHeaders', headers: JSON.parse(headersJson)});
                    },
                    onLog: function(msg) {
                        window.webkit.messageHandlers.AndroidBridge.postMessage({action: 'onLog', msg: msg});
                    }
                };

                try {
                    Object.defineProperty(document, 'visibilityState', { get: () => 'visible' });
                    Object.defineProperty(document, 'hidden', { get: () => false });
                } catch(e) {}

                var iframe = document.getElementById('alloha_iframe');
                iframe.onload = function() {
                    try {
                        var iframeWin = iframe.contentWindow;

                        try {
                            Object.defineProperty(iframeWin.document, 'visibilityState', { get: () => 'visible' });
                            Object.defineProperty(iframeWin.document, 'hidden', { get: () => false });
                        } catch(e) {}

                        var bnsiData = null;
                        var capturedHeaders = {};
                        var isDone = false;
                        var lastM3u8Url = null;

                        var _pushHdrTimer = null;
                        function schedulePushStreamHeaders() {
                            if (!isDone) return;
                            if (_pushHdrTimer) clearTimeout(_pushHdrTimer);
                            _pushHdrTimer = setTimeout(function() {
                                _pushHdrTimer = null;
                                try { AndroidBridge.onStreamHeaders(JSON.stringify(capturedHeaders)); } catch(e) {}
                            }, 40);
                        }

                        function putHeader(name, value) {
                            if (!name || !value) return;
                            capturedHeaders[String(name).toLowerCase()] = String(value);
                            schedulePushStreamHeaders();
                        }

                        function checkDone() {
                            if (isDone) return;
                            var hasAuth = false, hasAccept = false;
                            for (var k in capturedHeaders) {
                                if (k === 'authorizations') hasAuth = true;
                                if (k === 'accepts-controls') hasAccept = true;
                            }
                            if (bnsiData && hasAuth && hasAccept) {
                                isDone = true;
                                AndroidBridge.onReady(bnsiData, JSON.stringify(capturedHeaders));
                            }
                        }

                        putHeader('origin', iframeWin.location.origin);
                        putHeader('referer', iframeWin.location.origin + '/');
                        putHeader('user-agent', iframeWin.navigator.userAgent);
                        putHeader('accept', '*/*');
                        putHeader('sec-fetch-dest', 'empty');
                        putHeader('sec-fetch-mode', 'cors');
                        putHeader('sec-fetch-site', 'cross-site');

                        var originalOpen = iframeWin.XMLHttpRequest.prototype.open;
                        iframeWin.XMLHttpRequest.prototype.open = function(method, url) {
                            this._allohaUrl = url;
                            this.addEventListener('load', function() {
                                var rUrl = this.responseURL || '';
                                if (rUrl.indexOf('/bnsi/') !== -1 && !isDone) {
                                    bnsiData = this.responseText;
                                    checkDone();
                                }
                                if (isDone && rUrl.indexOf('master.m3u8') !== -1 && rUrl !== lastM3u8Url) {
                                    lastM3u8Url = rUrl;
                                    try { AndroidBridge.onM3u8Refreshed(rUrl, JSON.stringify(capturedHeaders)); } catch(e) {}
                                }
                            });
                            originalOpen.apply(this, arguments);
                        };

                        var originalSetHeader = iframeWin.XMLHttpRequest.prototype.setRequestHeader;
                        iframeWin.XMLHttpRequest.prototype.setRequestHeader = function(name, value) {
                            putHeader(name, value);
                            var url = this._allohaUrl || '';
                            if (url.indexOf('.m3u8') !== -1 || url.indexOf('.ts') !== -1) { checkDone(); }
                            return originalSetHeader.apply(this, arguments);
                        };

                        var _fallbackHost = null;
                        var _primaryHost = null;
                        var _fallbackMasterUrl = null;
                        function extractFallbackHost() {
                            if (_fallbackHost || !bnsiData) return;
                            try {
                                var d = JSON.parse(bnsiData);
                                var src = d.hlsSource;
                                if (src && src[0] && src[0].quality) {
                                    var q = src[0].quality;
                                    var key = Object.keys(q)[0];
                                    var urls = q[key].split(' or ');
                                    if (urls.length > 1) {
                                        var m = urls[0].match(/https?:\\/\\/([^\\/]+)/);
                                        if (m) _primaryHost = m[1];
                                        var fb = urls[1].trim();
                                        var m2 = fb.match(/https?:\\/\\/([^\\/]+)/);
                                        if (m2) { _fallbackHost = m2[1]; _fallbackMasterUrl = fb; }
                                    }
                                }
                            } catch(e) {}
                        }

                        var originalFetch = iframeWin.fetch;
                        iframeWin.fetch = function(input, init) {
                            try {
                                var url = (typeof input === 'string') ? input : (input && input.url ? input.url : '');
                                if (init && init.headers) {
                                    if (typeof init.headers.forEach === 'function') {
                                        init.headers.forEach(function(v, k) { putHeader(k, v); });
                                    } else {
                                        for (var hk in init.headers) { putHeader(hk, init.headers[hk]); }
                                    }
                                }
                                if (url && (url.indexOf('.m3u8') !== -1 || url.indexOf('.ts') !== -1)) {
                                    checkDone();
                                    extractFallbackHost();
                                    if (_primaryHost && _fallbackHost && url.indexOf(_primaryHost) !== -1) {
                                        var self = this;
                                        var fallbackUrl = (url.indexOf('master.m3u8') !== -1 && _fallbackMasterUrl)
                                            ? _fallbackMasterUrl : url.replace(_primaryHost, _fallbackHost);
                                        return originalFetch.apply(self, [input, init]).then(function(resp) {
                                            if (resp.status === 500 || resp.status === 503 || resp.status === 403) {
                                                return originalFetch.apply(iframeWin, [fallbackUrl, init]);
                                            }
                                            return resp;
                                        });
                                    }
                                }
                            } catch(e) {}
                            return originalFetch.apply(this, arguments);
                        };

                        var _origSend = iframeWin.WebSocket.prototype.send;
                        var _allohaWs = null;
                        var _heartbeatTimer = null;
                        var _sessionStart = Date.now();
                        var _lastEdgeHash = null;

                        function startHeartbeat(ws) {
                            if (_heartbeatTimer) clearInterval(_heartbeatTimer);
                            _heartbeatTimer = setInterval(function() {
                                if (!isDone) return;
                                if (!ws || ws.readyState !== 1) return;
                                var t = Math.floor((Date.now() - _sessionStart) / 1000);
                                try {
                                    _origSend.call(ws, JSON.stringify({
                                        type: 'playing', current_time: t, resolution: '1080',
                                        track_id: '1', speed: 1, subtitle: 0, ts: Date.now()
                                    }));
                                } catch(e) {}
                            }, 25000);
                        }

                        iframeWin.WebSocket.prototype.send = function(data) {
                            if (!this.__alloha_hooked) {
                                this.__alloha_hooked = true;
                                var ws = this;
                                _allohaWs = ws;
                                _sessionStart = Date.now();
                                ws.addEventListener('message', function(event) {
                                    try {
                                        var msg = JSON.parse(event.data);
                                        if (msg && msg.type === 'config_update' && msg.edge_hash) {
                                            if (msg.edge_hash !== _lastEdgeHash) {
                                                _lastEdgeHash = msg.edge_hash;
                                                var ttl = msg.ttl || 120;
                                                capturedHeaders['accepts-controls'] = msg.edge_hash;
                                                AndroidBridge.onConfigUpdate(msg.edge_hash, ttl, JSON.stringify(capturedHeaders));
                                            }
                                        }
                                    } catch(e) {}
                                });
                                ws.addEventListener('close', function(e) {
                                    if (_allohaWs === ws) { _allohaWs = null; if (_heartbeatTimer) clearInterval(_heartbeatTimer); }
                                });
                                startHeartbeat(ws);
                            }
                            return _origSend.call(this, data);
                        };

                        var OrigWS = iframeWin.WebSocket;
                        iframeWin.WebSocket = function(url, protocols) {
                            return protocols ? new OrigWS(url, protocols) : new OrigWS(url);
                        };
                        iframeWin.WebSocket.prototype = OrigWS.prototype;
                        iframeWin.WebSocket.CONNECTING = OrigWS.CONNECTING;
                        iframeWin.WebSocket.OPEN = OrigWS.OPEN;
                        iframeWin.WebSocket.CLOSING = OrigWS.CLOSING;
                        iframeWin.WebSocket.CLOSED = OrigWS.CLOSED;

                        setInterval(function() {
                            if (!isDone) {
                                var playBtn = iframeWin.document.querySelector('.allplay__play-btn');
                                if (playBtn) playBtn.click();
                                var video = iframeWin.document.querySelector('video');
                                if (video) { video.muted = true; if (video.paused) video.play().catch(function(){}); }
                            }
                        }, 1500);

                    } catch(e) { AndroidBridge.onLog('JS Error: ' + e); }
                };
            </script>
        </body>
        </html>
        """
    }
}
