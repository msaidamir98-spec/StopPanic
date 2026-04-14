import Observation
import StoreKit
import SwiftUI

// MARK: - PremiumManager

/// StoreKit 2 менеджер подписок.
/// Free tier: 1 техника дыхания (4-7-8) + 3 записи дневника + SOS.
/// Premium ($4.99/мес | $29.99/год): всё + MoodMap + PanicRadar + темы + безлимит дневник.
@Observable
@MainActor
final class PremiumManager {
    // MARK: Lifecycle

    private init() {
        isPremium = UserDefaults.standard.bool(forKey: Self.premiumKey)
    }

    // MARK: Internal

    static let shared = PremiumManager()

    // Product IDs — настроить в App Store Connect
    static let monthlyID = "com.stillo.premium.monthly"
    static let yearlyID = "com.stillo.premium.yearly"

    // MARK: - Free Tier Limits

    /// Максимум записей дневника для Free
    static let freeDiaryLimit = 3

    /// Бесплатная техника — только 4-7-8
    static let freeTechniqueID = "fourSevenEight"

    /// Продукты из App Store
    private(set) var products: [Product] = []

    /// Загрузка при старте
    private(set) var isLoading = false

    /// Текущий статус подписки
    private(set) var isPremium: Bool {
        didSet { UserDefaults.standard.set(isPremium, forKey: Self.premiumKey) }
    }

    /// Проверка доступа к технике
    func canAccessTechnique(_ id: String) -> Bool {
        isPremium || id == Self.freeTechniqueID
    }

    /// Проверка лимита дневника
    func canAddDiaryEntry(currentCount: Int) -> Bool {
        isPremium || currentCount < Self.freeDiaryLimit
    }

    // MARK: - StoreKit 2

    /// Загрузить продукты из App Store
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: [Self.monthlyID, Self.yearlyID])
        } catch {
            print("[Premium] Failed to load products: \(error)")
        }
    }

    /// Купить подписку
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()

            switch result {
            case let .success(verification):
                let transaction = try checkVerified(verification)
                isPremium = true
                await transaction.finish()
                return true

            case .userCancelled:
                return false

            case .pending:
                return false

            @unknown default:
                return false
            }
        } catch {
            print("[Premium] Purchase failed: \(error)")
            return false
        }
    }

    /// Восстановить покупки
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == Self.monthlyID || transaction.productID == Self.yearlyID {
                    isPremium = true
                    return
                }
            }
        }
    }

    /// Слушать обновления транзакций (вызывать при старте).
    /// Ссылка на Task хранится, чтобы предотвратить сборку мусора.
    func listenForTransactions() {
        transactionListener?.cancel()
        transactionListener = Task.detached(priority: .utility) { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? await self?.checkVerified(result) {
                    let isActive = transaction.productID == Self.monthlyID ||
                        transaction.productID == Self.yearlyID
                    await MainActor.run {
                        self?.isPremium = isActive
                    }
                    await transaction.finish()
                }
            }
        }
    }

    /// Проверить статус при старте
    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == Self.monthlyID || transaction.productID == Self.yearlyID {
                    isPremium = true
                    return
                }
            }
        }
        // Нет активных подписок
        isPremium = false
    }

    // MARK: Private

    private static let premiumKey = "stillo_is_premium"

    /// Хранимая ссылка на Task для предотвращения GC
    @ObservationIgnored
    private var transactionListener: Task<Void, Never>?

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case let .unverified(_, error):
            throw error
        case let .verified(safe):
            return safe
        }
    }
}
