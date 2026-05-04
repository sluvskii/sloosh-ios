import SwiftUI

struct GlassCard<Content: View>: View {
    @ViewBuilder private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            }
    }
}

#Preview {
    ZStack {
        SlooshTheme.background.ignoresSafeArea()

        GlassCard {
            Text("Liquid-like card")
                .foregroundStyle(.primary)
        }
        .padding()
    }
}
