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
                        Button {
                            SP.Haptic.light()
                            dismiss()
                        } label: {
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
                                .font(.system(.largeTitle))
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
                        premiumFeature(
                            icon: "chart.line.uptrend.xyaxis",
                            title: String(localized: "paywall_feature_analytics"),
                            color: SP.Colors.accent
                        )
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
                                badge: String(localized: "paywall_save_58"),
                                isPopular: true,
                                anchorPrice: yearlyAnchorPrice,
                                freeTrialAvailable: yearlyHasFreeTrial
                            )
                        }

                        if let lifetime = premium.products.first(where: { $0.id == PremiumManager.lifetimeID }) {
                            priceCard(
                                product: lifetime,
                                title: String(localized: "paywall_lifetime"),
                                badge: String(localized: "paywall_lifetime_badge"),
                                isPopular: false,
                                subtitle: String(localized: "paywall_lifetime_subtitle")
                            )
                        }

                        if let monthly = premium.products.first(where: { $0.id == PremiumManager.monthlyID }) {
                            priceCard(
                                product: monthly,
                                title: String(localized: "paywall_monthly"),
                                badge: nil,
                                isPopular: false,
                                introPrice: monthlyIntroPrice
                            )
                        }

                        // Fallback if products not loaded
                        if premium.products.isEmpty, !premium.isLoading {
                            Text(String(localized: "paywall_loading_error"))
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.textTertiary)
                        }
                    }

                    // Restore
                    Button {
                        SP.Haptic.light()
                        Task {
                            await premium.restorePurchases()
                            if premium.isPremium { SP.Haptic.success() }
                        }
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
                            if let termsURL = URL(string: "https://msaidamir98-spec.github.io/StopPanic/terms.html") {
                                Link(
                                    String(localized: "paywall_terms"),
                                    destination: termsURL
                                )
                            }
                            if let privacyURL = URL(string: "https://msaidamir98-spec.github.io/StopPanic/privacy.html") {
                                Link(
                                    String(localized: "paywall_privacy"),
                                    destination: privacyURL
                                )
                            }
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
            await computeIntroOffers()
        }
    }

    // MARK: Private

    @State
    private var purchasing = false

    @State
    private var yearlyHasFreeTrial = false

    @State
    private var monthlyIntroPrice: String?

    @State
    private var yearlyAnchorPrice: String?

    private let premium = PremiumManager.shared

    private func computeIntroOffers() async {
        // Yearly: detect eligible free-trial introductory offer
        if let yearly = premium.products.first(where: { $0.id == PremiumManager.yearlyID }),
           let sub = yearly.subscription,
           let offer = sub.introductoryOffer,
           offer.paymentMode == .freeTrial,
           await sub.isEligibleForIntroOffer {
            yearlyHasFreeTrial = true
        }
        // Monthly: detect eligible paid introductory offer (e.g. $1.99 first month)
        if let monthly = premium.products.first(where: { $0.id == PremiumManager.monthlyID }),
           let sub = monthly.subscription,
           let offer = sub.introductoryOffer,
           offer.paymentMode != .freeTrial,
           await sub.isEligibleForIntroOffer {
            monthlyIntroPrice = offer.displayPrice
        }
        // Anchor price for yearly card: monthly × 12, formatted in monthly's currency style
        if let monthly = premium.products.first(where: { $0.id == PremiumManager.monthlyID }) {
            let anchor = monthly.price * Decimal(12)
            yearlyAnchorPrice = anchor.formatted(monthly.priceFormatStyle)
        }
    }

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

    private func priceCard(
        product: Product,
        title: String,
        badge: String?,
        isPopular: Bool,
        anchorPrice: String? = nil,
        freeTrialAvailable: Bool = false,
        introPrice: String? = nil,
        subtitle: String? = nil
    ) -> some View {
        Button {
            guard !purchasing else { return }
            SP.Haptic.medium()
            purchasing = true
            Task {
                let success = await premium.purchase(product)
                purchasing = false
                if success, premium.isPremium {
                    SP.Haptic.success()
                    dismiss()
                } else if !success {
                    SP.Haptic.warning()
                }
            }
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    if let badge {
                        Text(badge)
                            .font(SP.Typography.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(SP.Colors.success))
                    }
                    if freeTrialAvailable {
                        Text(String(localized: "paywall_free_trial_badge"))
                            .font(SP.Typography.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(SP.Colors.accent))
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(SP.Typography.headline)
                            .foregroundColor(SP.Colors.textPrimary)

                        if let anchorPrice {
                            Text(anchorPrice)
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.textTertiary)
                                .strikethrough(true, color: SP.Colors.textTertiary)
                        }

                        Text(product.displayPrice)
                            .font(SP.Typography.title2)
                            .foregroundColor(SP.Colors.accent)

                        if let subtitle {
                            Text(subtitle)
                                .font(SP.Typography.caption2)
                                .foregroundColor(SP.Colors.textSecondary)
                        }

                        if let introPrice {
                            Text(
                                String(
                                    format: NSLocalizedString("paywall_intro_monthly", comment: ""),
                                    introPrice,
                                    product.displayPrice
                                )
                            )
                            .font(SP.Typography.caption2)
                            .foregroundColor(SP.Colors.textSecondary)
                        }
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
                            .stroke(
                                isPopular ? SP.Colors.accent.opacity(0.4) : SP.Colors.textTertiary.opacity(0.15),
                                lineWidth: isPopular ? 1.5 : 0.5
                            )
                    )
            )
        }
        .buttonStyle(PremiumButtonStyle())
        .disabled(purchasing)
    }
}
