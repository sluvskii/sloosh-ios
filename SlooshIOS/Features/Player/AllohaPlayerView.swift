import SwiftUI
import AVKit

struct AllohaPlayerView: View {
    let movie: Movie

    @StateObject private var viewModel = AllohaPlayerViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showControls = true
    @State private var isPlaying = false
    @State private var controlsTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        isPlaying = true
                        scheduleHideControls()
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showControls.toggle()
                        }
                        if showControls {
                            scheduleHideControls()
                        } else {
                            controlsTask?.cancel()
                        }
                    }
            } else if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(.white)
                    Text("Подготавливаем поток...")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                    Text("Не удалось запустить видео")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Button("Повторить") {
                        Task {
                            await loadVideo()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if showControls {
                controlsOverlay
            }
        }
        .statusBarHidden()
        .task {
            await loadVideo()
        }
        .onDisappear {
            controlsTask?.cancel()
            viewModel.cleanup()
        }
    }

    private var controlsOverlay: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.black.opacity(0.5), in: Circle())
                }

                Spacer()

                Text(movie.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                Circle()
                    .fill(.clear)
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()

            HStack(spacing: 40) {
                Button {
                    guard let player = viewModel.player else { return }
                    let newTime = max(0, player.currentTime().seconds - 10)
                    player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }

                Button {
                    guard let player = viewModel.player else { return }
                    if isPlaying {
                        player.pause()
                    } else {
                        player.play()
                    }
                    isPlaying.toggle()
                    scheduleHideControls()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 76))
                        .foregroundStyle(.white)
                }

                Button {
                    guard let player = viewModel.player else { return }
                    let duration = player.currentItem?.duration.seconds ?? 0
                    let target = min(duration, player.currentTime().seconds + 10)
                    player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
            }

            Spacer()
        }
        .background(
            LinearGradient(
                colors: [.black.opacity(0.7), .clear, .clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private func scheduleHideControls() {
        controlsTask?.cancel()
        controlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls = false
                }
            }
        }
    }

    private func loadVideo() async {
        isPlaying = false
        await viewModel.loadVideo(for: movie)
        if viewModel.player != nil {
            isPlaying = true
            scheduleHideControls()
        }
    }
}
