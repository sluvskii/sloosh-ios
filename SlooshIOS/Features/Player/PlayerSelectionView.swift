import SwiftUI
import AVKit

struct PlayerSelectionView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTranslation: Translation?
    @State private var selectedSeason: Season?
    @State private var isPlaying = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SlooshTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(movie.title)
                                .font(.title.weight(.bold))
                                .foregroundStyle(.primary)
                            
                            Text("Выберите параметры для просмотра")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        
                        // Translations
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Озвучка")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Translation.mocks) { translation in
                                        Button {
                                            selectedTranslation = translation
                                        } label: {
                                            Text(translation.name)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(selectedTranslation == translation ? SlooshTheme.accent : Color.primary.opacity(0.1))
                                                .foregroundStyle(selectedTranslation == translation ? .black : .primary)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Seasons & Episodes (Только для сериалов)
                        if movie.type == "tv" {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Сезон")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal)
                                
                                Picker("Сезон", selection: $selectedSeason) {
                                    ForEach(Season.mocks) { season in
                                        Text("Сезон \(season.number)").tag(Optional(season))
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal)
                                
                                if let season = selectedSeason ?? Season.mocks.first {
                                    VStack(spacing: 8) {
                                        ForEach(season.episodes) { episode in
                                            Button {
                                                // Начать воспроизведение серии
                                                isPlaying = true
                                            } label: {
                                                HStack {
                                                    Text("\(episode.number). \(episode.title)")
                                                        .foregroundStyle(.primary)
                                                    Spacer()
                                                    Image(systemName: "play.circle.fill")
                                                        .foregroundStyle(SlooshTheme.accent)
                                                }
                                                .padding()
                                                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        } else {
                            // Фильм
                            Button {
                                isPlaying = true
                            } label: {
                                Label("Включить фильм", systemImage: "play.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(SlooshTheme.accent)
                            .foregroundStyle(.black)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Смотреть")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .tint(.primary)
                }
            }
            .onAppear {
                selectedTranslation = Translation.mocks.first
                selectedSeason = Season.mocks.first
            }
            .fullScreenCover(isPresented: $isPlaying) {
                // Заглушка для нативного плеера
                NativePlayerView()
            }
        }
    }
}

struct NativePlayerView: View {
    @Environment(\.dismiss) private var dismiss
    // URL-заглушка для теста плеера
    let testURL = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            VideoPlayer(player: AVPlayer(url: testURL))
                .ignoresSafeArea()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .padding()
            }
        }
    }
}
