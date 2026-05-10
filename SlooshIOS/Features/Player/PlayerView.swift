import SwiftUI
import AVKit

struct PlayerView: View {
    let movie: Movie
    @StateObject private var viewModel = VideoPlayerViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showControls = true
    @State private var showEpisodePicker = false
    @State private var isPlaying = false
    @State private var controlsTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Video Player
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showControls.toggle()
                            if showControls {
                                scheduleHideControls()
                            }
                        }
                    }
            } else if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Загрузка видео...")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                    Text("Ошибка загрузки")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Повторить") {
                        Task {
                            await loadVideo()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                }
            }
            
            // Controls Overlay
            if showControls {
                controlsOverlay
            }
            
            // Episode Picker
            if showEpisodePicker && viewModel.isSeries {
                episodePickerOverlay
            }
        }
        .onAppear {
            Task {
                await loadVideo()
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    private func scheduleHideControls() {
        controlsTask?.cancel()
        controlsTask = Task {
            try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
            await MainActor.run {
                withAnimation {
                    showControls = false
                }
            }
        }
    }
    
    private var controlsOverlay: some View {
        VStack {
            // Top Bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                if viewModel.isSeries {
                    Button {
                        withAnimation {
                            showEpisodePicker.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet")
                            Text("Сезон \(viewModel.currentSeason), Серия \(viewModel.currentEpisode)")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                // Spacer for symmetry
                Circle()
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
            
            // Center Play/Pause Button
            HStack(spacing: 40) {
                Button {
                    // Rewind 10s
                    guard let player = viewModel.player else { return }
                    let newTime = max(0, player.currentTime().seconds - 10)
                    player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
                
                Button {
                    if isPlaying {
                        viewModel.pause()
                    } else {
                        viewModel.play()
                    }
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                }
                
                Button {
                    // Forward 10s
                    guard let player = viewModel.player else { return }
                    let duration = player.currentItem?.duration.seconds ?? 0
                    let newTime = min(duration, player.currentTime().seconds + 10)
                    player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 40))
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
    
    private var episodePickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showEpisodePicker = false
                    }
                }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Выберите эпизод")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            showEpisodePicker = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // Episodes List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.availableEpisodes) { episode in
                            Button {
                                Task {
                                    await viewModel.switchEpisode(season: episode.season, episode: episode.episode)
                                    withAnimation {
                                        showEpisodePicker = false
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Сезон \(episode.season), Серия \(episode.episode)")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        
                                        if !episode.title.isEmpty && episode.title != "Episode \(episode.episode)" {
                                            Text(episode.title)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if episode.season == viewModel.currentSeason && episode.episode == viewModel.currentEpisode {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .frame(maxWidth: 500, maxHeight: 600)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
            )
            .padding()
        }
    }
    
    private func loadVideo() async {
        guard let kpId = movie.kpId else {
            viewModel.errorMessage = "Неверный ID фильма"
            return
        }
        
        // Setup NeoID
        viewModel.setupNeoId("uid_49e6d1fd-3b86-4d6f-8a24-2c44898a0901")
        
        await viewModel.loadVideo(kpId: kpId)
    }
}
