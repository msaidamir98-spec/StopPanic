import SwiftUI

// MARK: - CrisisLineView

/// Экран телефона доверия — номер, кнопка вызова, информация.
struct CrisisLineView: View {
    // MARK: Internal

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.success, secondaryColor: SP.Colors.calm)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    heroSection
                    crisisLinesCard
                    importantInfoCard
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(String(localized: "crisis.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(SP.Anim.spring) { appear = true }
        }
    }

    // MARK: Private

    @State
    private var appear = false

    private var currentLine: String {
        SOSService.getCrisisLine()
    }

    private var currentRegion: String {
        Locale.current.language.region?.identifier ?? "US"
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(SP.Colors.success.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .modifier(GlowPulse(color: SP.Colors.success, radius: 0.2))

                Circle()
                    .fill(SP.Colors.success.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: "phone.fill")
                    .font(.system(size: 26))
                    .foregroundColor(SP.Colors.success)
            }

            Text(String(localized: "crisis.not_alone"))
                .font(SP.Typography.title1)
                .foregroundColor(SP.Colors.textPrimary)

            Text(String(localized: "crisis.subtitle"))
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)
                .multilineTextAlignment(.center)

            // Main call button
            Button {
                callCrisisLine()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "phone.arrow.up.right.fill")
                        .font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "crisis.call"))
                            .font(SP.Typography.headline)
                        Text(currentLine)
                            .font(SP.Typography.caption)
                            .opacity(0.8)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: SP.Layout.cornerMedium, style: .continuous)
                        .fill(SP.Colors.success.gradient)
                )
                .shadow(color: SP.Colors.success.opacity(0.3), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .spGlassCard()
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
    }

    private var crisisLinesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "crisis.lines_by_country"))
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            ForEach(sortedLines, id: \.key) { entry in
                HStack(spacing: 12) {
                    Text(flag(for: entry.key))
                        .font(.system(size: 20))

                    Text(countryName(for: entry.key))
                        .font(SP.Typography.callout)
                        .foregroundColor(SP.Colors.textPrimary)

                    Spacer()

                    Button {
                        callNumber(entry.value)
                    } label: {
                        Text(entry.value)
                            .font(SP.Typography.headline)
                            .foregroundColor(entry.key == currentRegion ? SP.Colors.success : SP.Colors.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)

                if entry.key != sortedLines.last?.key {
                    Divider().background(SP.Colors.textTertiary.opacity(0.2))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .spGlassCard()
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .animation(SP.Anim.spring.delay(0.1), value: appear)
    }

    private var importantInfoCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 28))
                .foregroundColor(SP.Colors.warmth)

            Text(String(localized: "crisis.important"))
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                infoPoint(String(localized: "crisis.info_free"))
                infoPoint(String(localized: "crisis.info_24h"))
                infoPoint(String(localized: "crisis.info_any_issue"))
                infoPoint(String(localized: "crisis.info_panic_safe"))
            }

            Text(String(localized: "crisis.emergency_112"))
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.danger)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .spGlassCard()
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .animation(SP.Anim.spring.delay(0.2), value: appear)
    }

    // MARK: - Helpers

    private var sortedLines: [(key: String, value: String)] {
        SOSService.crisisLines.sorted { lhs, rhs in
            // Current region first
            if lhs.key == currentRegion { return true }
            if rhs.key == currentRegion { return false }
            return lhs.key < rhs.key
        }
    }

    private func infoPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(SP.Colors.success)
                .padding(.top, 2)
            Text(text)
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textSecondary)
        }
    }

    private func callCrisisLine() {
        callNumber(currentLine)
    }

    private func callNumber(_ number: String) {
        let cleaned = number.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel://\(cleaned)") {
            SP.Haptic.medium()
            UIApplication.shared.open(url)
        }
    }

    private func flag(for region: String) -> String {
        let base: UInt32 = 0x1F1E6 - 65 // 🇦 minus ASCII 'A'
        return region.uppercased().unicodeScalars.compactMap {
            UnicodeScalar(base + $0.value)
        }.map { String($0) }.joined()
    }

    private func countryName(for code: String) -> String {
        let names: [String: String] = [
            "RU": String(localized: "country.ru"), "US": String(localized: "country.us"), "UK": String(localized: "country.uk"),
            "DE": String(localized: "country.de"), "FR": String(localized: "country.fr"), "ES": String(localized: "country.es"),
            "IT": String(localized: "country.it"), "JP": String(localized: "country.jp"),
            "BR": String(localized: "country.br"), "CN": String(localized: "country.cn"),
            "PT": String(localized: "country.pt"), "KR": String(localized: "country.kr"),
        ]
        return names[code] ?? code
    }
}
