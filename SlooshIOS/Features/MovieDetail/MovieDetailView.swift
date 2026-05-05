import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Image Placeholder
                ZStack(alignment: .bottomLeading) {
                    if let url = movie.posterURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(movie.posterColor.gradient)
                                    .overlay {
                                        ProgressView()
                                    }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(movie.posterColor.gradient)
                                    .overlay {
                                        Image(systemName: "film")
                                            .font(.largeTitle)
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(height: 350)
                        .clipped()
                        .overlay {
                            LinearGradient(
                                colors: [.clear, SlooshTheme.background],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        }
                    } else {
                        Rectangle()
                            .fill(movie.posterColor.gradient)
                            .frame(height: 350)
                            .overlay {
                                LinearGradient(
                                    colors: [.clear, SlooshTheme.background],
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(movie.title)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 12) {
                            Label(String(format: "%.1f", movie.rating), systemImage: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("•")
                            Text(movie.year)
                            Text("•")
                            Text(movie.type == "tv" ? "Сериал" : "Фильм")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button {
                            // Play action
                        } label: {
                            Label("Смотреть", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SlooshTheme.accent)
                        .foregroundStyle(.black)
                        
                        Button {
                            // Save action
                        } label: {
                            Image(systemName: "bookmark")
                                .font(.headline)
                                .padding(14)
                                .background(.ultraThinMaterial, in: Circle())
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("О фильме")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        Text(movie.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    
                    // Additional info in GlassCard
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(title: "Жанр", value: movie.genre)
                            Divider().background(Color.primary.opacity(0.1))
                            InfoRow(title: "Год выхода", value: movie.year)
                            Divider().background(Color.primary.opacity(0.1))
                            InfoRow(title: "Тип", value: movie.type == "tv" ? "Сериал" : "Фильм")
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .padding()
            }
        }
        .background(SlooshTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        MovieDetailView(movie: MockData.trendingMovies[0])
    }
}
