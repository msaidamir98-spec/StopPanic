import SwiftUI

// MARK: - DisclaimerFootnote

/// Тонкая ссылка-сноска вместо тревожного warning-блока с «103 / 112».
///
/// Создан 2026-05-01 по решению B-DIS (Live QA Sim Run): полноразмерный
/// дисклеймер с warning-треугольником и номерами экстренных служб
/// показывался на Heart-экране в panic-app и усиливал тревогу
/// у целевой аудитории. По нажатию открывается полный текст в bottom-sheet
/// (non-blocking — пользователь может закрыть и продолжить работу с Home).
struct DisclaimerFootnote: View {
    @State
    private var showFullText = false

    var body: some View {
        Button {
            showFullText = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(.footnote))
                Text(String(localized: "heart.important_info"))
                    .font(SP.Typography.caption)
                    .underline()
            }
            .foregroundColor(SP.Colors.textTertiary)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "heart.important_info"))
        .accessibilityHint(String(localized: "heart.disclaimer_a11y_hint"))
        .sheet(isPresented: $showFullText) {
            DisclaimerSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - DisclaimerSheet

/// Полный текст дисклеймера + crisis-line — внутри bottom-sheet,
/// открывается только по явному тапу пользователя.
private struct DisclaimerSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "heart.important_info"))
                    .font(SP.Typography.title2)
                    .foregroundColor(SP.Colors.textPrimary)

                Text(String(localized: "heart.disclaimer_body"))
                    .font(SP.Typography.body)
                    .foregroundColor(SP.Colors.textSecondary)
                    .lineSpacing(4)

                Divider()
                    .padding(.vertical, 4)

                Text(String(localized: "heart.crisis_line_title"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)

                Text(String(localized: "heart.crisis_line_hint"))
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textSecondary)

                Spacer(minLength: 24)

                Button {
                    dismiss()
                } label: {
                    Text(String(localized: "general.close"))
                        .font(SP.Typography.body.weight(.semibold))
                        .foregroundColor(SP.Colors.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(SP.Colors.accent)
                        .cornerRadius(SP.Layout.cornerMedium)
                }
            }
            .padding(20)
        }
        .background(SP.Colors.bg.ignoresSafeArea())
    }
}

#Preview {
    DisclaimerFootnote()
        .padding()
}
