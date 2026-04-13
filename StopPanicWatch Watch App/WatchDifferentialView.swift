import SwiftUI

// MARK: - Premium Watch Differential View

/// Справочная карточка: ПА vs Инфаркт — premium дизайн для Apple Watch
struct WatchDifferentialView: View {
    @State private var selectedTab: DiffTab = .panic
    
    enum DiffTab: String, CaseIterable {
        case panic = "panic"
        case cardiac = "cardiac"

        var text: String {
            switch self {
            case .panic: String(localized: "watch.diff_pa_tab")
            case .cardiac: String(localized: "watch.diff_cardiac_tab")
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Tab selector
                HStack(spacing: 0) {
                    ForEach(DiffTab.allCases, id: \.rawValue) { tab in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedTab = tab
                            }
                        } label: {
                            Text(tab.text)
                                .font(.system(.caption2, design: .rounded, weight: .semibold))
                                .foregroundStyle(selectedTab == tab ? .white : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    selectedTab == tab
                                    ? AnyShapeStyle(tabColor(tab).opacity(0.3))
                                    : AnyShapeStyle(.clear),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(.ultraThinMaterial, in: Capsule())
                
                // Content
                if selectedTab == .panic {
                    panicCard
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    cardiacCard
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                
                // Warning
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text(String(localized: "watch.diff_call_112"))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.orange)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(.orange.opacity(0.1), in: Capsule())
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle(String(localized: "watch.diff_title"))
    }
    
    // MARK: - Panic Attack Card
    
    private var panicCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                Text(String(localized: "watch.diff_panic"))
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.yellow)
            }
            
            symptomRow(icon: "heart.fill", text: String(localized: "watch.diff_pa_hr"), color: .yellow)
            symptomRow(icon: "waveform.path", text: String(localized: "watch.diff_pa_rhythm"), color: .yellow)
            symptomRow(icon: "clock.fill", text: String(localized: "watch.diff_pa_peak"), color: .yellow)
            symptomRow(icon: "wind", text: String(localized: "watch.diff_pa_breathing"), color: .yellow)
            symptomRow(icon: "hand.raised.fill", text: String(localized: "watch.diff_pa_tingling"), color: .yellow)
            symptomRow(icon: "bolt.fill", text: String(localized: "watch.diff_pa_unreality"), color: .yellow)
        }
        .padding(10)
        .background(.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.yellow.opacity(0.15), lineWidth: 0.5)
        )
    }
    
    // MARK: - Cardiac Card
    
    private var cardiacCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "heart.slash.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                Text(String(localized: "watch.diff_cardiac"))
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.red)
            }
            
            symptomRow(icon: "heart.fill", text: String(localized: "watch.diff_card_pulse"), color: .red)
            symptomRow(icon: "waveform.path.ecg", text: String(localized: "watch.diff_card_arrhythmia"), color: .red)
            symptomRow(icon: "clock.fill", text: String(localized: "watch.diff_card_duration"), color: .red)
            symptomRow(icon: "figure.arms.open", text: String(localized: "watch.diff_card_jaw_arm"), color: .red)
            symptomRow(icon: "drop.fill", text: String(localized: "watch.diff_card_sweat"), color: .red)
            symptomRow(icon: "lungs.fill", text: String(localized: "watch.diff_card_chest"), color: .red)
        }
        .padding(10)
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.red.opacity(0.15), lineWidth: 0.5)
        )
    }
    
    // MARK: - Helpers
    
    private func tabColor(_ tab: DiffTab) -> Color {
        switch tab {
        case .panic: return .yellow
        case .cardiac: return .red
        }
    }
    
    private func symptomRow(icon: String, text: String, color: Color) -> some View {
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
