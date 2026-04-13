import StoreKit
import SwiftUI

// MARK: - PaywallView

/// Красивый paywall с социальным доказательством, преимуществами, и мягким CTA.
/// Показывается при попытке доступа к premium-контенту.
struct PaywallView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator
    @Environment(\.dismiss)
    var dismiss

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.accent, secondaryColor: SP.Colors.warmth)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Close button
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(SP.Colors.textTertiary)
                        }
                    }
                    .padding(.top, 8)

                    // Hero
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(SP.Colors.accent.opacity(0.15))
                                .frame(width: 100, height: 100)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(SP.Colors.heroGradient)
                        }

                        Text(String(localized: "paywall_title"))
                            .font(SP.Typography.heroTitle)
                            .foregroundColor(SP.Colors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text(String(localized: "paywall_subtitle"))
                            .font(SP.Typography.callout)
                            .foregroundColor(SP.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Features
                    VStack(spacing: 12) {
                        premiumFeature(icon: "lungs.fill", title: String(localized: "paywall_feature_breathing"), color: SP.Colors.calm)
                        premiumFeature(icon: "chart.line.uptrend.xyaxis", title: String(localized: "paywall_feature_analytics"), color: SP.Colors.accent)
                        premiumFeature(icon: "book.fill", title: String(localized: "paywall_feature_diary"), color: SP.Colors.warmth)
                        premiumFeature(icon: "paintpalette.fill", title: String(localized: "paywall_feature_themes"), color: SP.Colors.success)
                        premiumFeature(icon: "heart.text.square.fill", title: String(localized: "paywall_feature_heart"), color: SP.Colors.danger)
                    }
                    .padding(.vertical, 8)

                    // Price cards
                    VStack(spacing: 12) {
                        if let yearly = premium.products.first(where: { $0.id == PremiumManager.yearlyID }) {
                            priceCard(
                                product: yearly,
                                title: String(localized: "paywall_yearly"),
                                badge: String(localized: "paywall_save_50"),
                                isPopular: true
                            )
                        }

                        if let monthly = premium.products.first(where: { $0.id == PremiumManager.monthlyID }) {
                            priceCard(
                                product: monthly,
                                title: String(localized: "paywall_monthly"),
                                badge: nil,
                                isPopular: false
                            )
                        }

                        // Fallback if products not loaded
                        if premium.products.isEmpty && !premium.isLoading {
                            Text(String(localized: "paywall_loading_error"))
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.textTertiary)
                        }
                    }

                    // Restore
                    Button {
                        Task { await premium.restorePurchases() }
                    } label: {
                        Text(String(localized: "paywall_restore"))
                            .font(SP.Typography.caption)
                            .foregroundColor(SP.Colors.textTertiary)
                    }

                    // Legal
                    VStack(spacing: 8) {
                        Text(String(localized: "paywall_legal"))
                            .font(SP.Typography.caption2)
                            .foregroundColor(SP.Colors.textTertiary.opacity(0.7))
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Link(String(localized: "paywall_terms"),
                                 destination: URL(string: "https://stillo.app/terms") ?? URL(string: "https://apple.com")!)
                            Link(String(localized: "paywall_privacy"),
                                 destination: URL(string: "https://stillo.app/privacy") ?? URL(string: "https://apple.com")!)
                        }
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.accent.opacity(0.8))
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, SP.Layout.padding)
            }
        }
        .task {
            await premium.loadProducts()
        }
    }

    // MARK: Private

    private let premium = PremiumManager.shared

    @State private var purchasing = false

    private func premiumFeature(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 36)

            Text(title)
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(SP.Colors.success)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.warmGlass)
        )
    }

    private func priceCard(product: Product, title: String, badge: String?, isPopular: Bool) -> some View {
        Button {
            guard !purchasing else { return }
            purchasing = true
            Task {
                _ = await premium.purchase(product)
                purchasing = false
                if premium.isPremium { dismiss() }
            }
        } label: {
            VStack(spacing: 8) {
                if let badge {
                    Text(badge)
                        .font(SP.Typography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(SP.Colors.success))
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(SP.Typography.headline)
                            .foregroundColor(SP.Colors.textPrimary)
                        Text(product.displayPrice)
                            .font(SP.Typography.title2)
                            .foregroundColor(SP.Colors.accent)
                    }

                    Spacer()

                    if purchasing {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(SP.Colors.accent)
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isPopular ? AnyShapeStyle(SP.Colors.accent.opacity(0.08)) : AnyShapeStyle(.warmGlass))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isPopular ? SP.Colors.accent.opacity(0.4) : SP.Colors.textTertiary.opacity(0.15), lineWidth: isPopular ? 1.5 : 0.5)
                    )
            )
        }
        .buttonStyle(PremiumButtonStyle())
        .disabled(purchasing)
    }
}
