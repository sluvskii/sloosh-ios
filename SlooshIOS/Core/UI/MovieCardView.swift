import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster
            ZStack {
                if let url = movie.posterURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(movie.posterColor.gradient)
                                .overlay {
                                    ProgressView()
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                    .frame(width: 140, height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(movie.posterColor.gradient)
                        .frame(width: 140, height: 210)
                        .overlay {
                            Image(systemName: "film")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption2)
                        Text(String(format: "%.1f", movie.rating))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(width: 140, height: 210)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(movie.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(movie.genre)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 140)
    }
}

#Preview {
    ZStack {
        SlooshTheme.background.ignoresSafeArea()
        MovieCardView(movie: MockData.trendingMovies[0])
    }
}
