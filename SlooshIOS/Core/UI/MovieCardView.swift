import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(movie.posterColor.gradient)
                    .aspectRatio(2/3, contentMode: .fit)
                
                Image(systemName: "film")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.5))
                
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
