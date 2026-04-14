import SwiftUI

// MARK: - Stress Response Reference Card (Watch)

/// Educational reference card: what happens in a stress response
/// Single-topic view — no differential diagnosis, no medical comparisons
struct WatchDifferentialView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text(String(localized: "watch.ref_title"))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.yellow)
                }

                // Body signs during stress
                VStack(alignment: .leading, spacing: 8) {
                    signRow(icon: "heart.fill", text: String(localized: "watch.ref_hr"))
                    signRow(icon: "waveform.path", text: String(localized: "watch.ref_rhythm"))
                    signRow(icon: "clock.fill", text: String(localized: "watch.ref_peak"))
                    signRow(icon: "wind", text: String(localized: "watch.ref_breathing"))
                    signRow(icon: "hand.raised.fill", text: String(localized: "watch.ref_tingling"))
                    signRow(icon: "bolt.fill", text: String(localized: "watch.ref_unreality"))
                }
                .padding(10)
                .background(.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.yellow.opacity(0.15), lineWidth: 0.5)
                )

                // Disclaimer banner
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 10))
                    Text(String(localized: "watch.ref_disclaimer"))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(.secondary.opacity(0.1), in: Capsule())
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle(String(localized: "watch.ref_nav_title"))
    }

    // MARK: - Private

    private func signRow(icon: String, text: String, color: Color = .yellow) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(color.opacity(0.7))
                .frame(width: 12)
            Text(text)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

#Preview {
    WatchDifferentialView()
}
