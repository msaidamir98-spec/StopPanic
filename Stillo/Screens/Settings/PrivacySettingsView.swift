import SwiftUI

// MARK: - PrivacySettingsView

/// Секция «Приватность» в настройках. Apple Guideline 5.1.1 (iv) +
/// GDPR Right to Erasure: пользователь должен иметь возможность
/// удалить все свои данные одним действием в самом приложении.
///
/// 2026-05-03: добавлено в рамках Master Plan День 2.
struct PrivacySettingsView: View {
    @Environment(AppCoordinator.self)
    private var coordinator

    @State
    private var showConfirm = false
    @State
    private var showSecondConfirm = false
    @State
    private var showDoneAlert = false
    @State
    private var deletedCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(SP.Colors.accent)
                    .font(.system(.title3))
                Text(String(localized: "settings.privacy.title"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
            }

            Text(String(localized: "settings.privacy.body"))
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textSecondary)
                .lineSpacing(3)

            Button {
                showConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text(String(localized: "settings.privacy.delete_btn"))
                        .font(SP.Typography.body.weight(.semibold))
                    Spacer()
                }
                .foregroundColor(SP.Colors.danger)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(SP.Colors.danger.opacity(0.08))
                .cornerRadius(SP.Layout.cornerSmall)
            }
            .buttonStyle(.plain)
            .accessibilityHint(String(localized: "settings.privacy.delete_a11y_hint"))
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .alert(String(localized: "settings.privacy.confirm1_title"),
               isPresented: $showConfirm) {
            Button(String(localized: "general.cancel"), role: .cancel) { }
            Button(String(localized: "settings.privacy.confirm1_btn"), role: .destructive) {
                showSecondConfirm = true
            }
        } message: {
            Text(String(localized: "settings.privacy.confirm1_body"))
        }
        .alert(String(localized: "settings.privacy.confirm2_title"),
               isPresented: $showSecondConfirm) {
            Button(String(localized: "general.cancel"), role: .cancel) { }
            Button(String(localized: "settings.privacy.confirm2_btn"), role: .destructive) {
                performWipe()
            }
        } message: {
            Text(String(localized: "settings.privacy.confirm2_body"))
        }
        .alert(String(localized: "settings.privacy.done_title"),
               isPresented: $showDoneAlert) {
            Button(String(localized: "general.done"), role: .cancel) { }
        } message: {
            Text(String(localized: "settings.privacy.done_body \(deletedCount)"))
        }
    }

    @MainActor
    private func performWipe() {
        let count = PersistenceController.shared.wipeAllData()
        deletedCount = max(count, 0)
        showDoneAlert = true
    }
}

#Preview {
    PrivacySettingsView()
        .environment(AppCoordinator())
        .padding()
}
