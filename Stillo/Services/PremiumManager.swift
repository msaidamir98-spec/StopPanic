import Observation
import os.log
import StoreKit
import SwiftUI

// MARK: - PremiumManager

/// StoreKit 2 менеджер подписок.
/// Free tier: 1 техника дыхания (4-7-8) + 7 записей дневника + SOS.
/// Premium ($4.99/мес | $24.99/год | RU ₽299/мес | ₽1,490/год): всё + MoodMap + PanicRadar + темы + безлимит.
/// Intro offers: yearly = 7 days free trial, monthly = $1.99 first month.
/// Grandfather policy: первая уплаченная цена фиксируется навсегда (GrandfatherInfo).
@Observable
@MainActor
final class PremiumManager {
    // MARK: Lifecycle

    private init() {
        realIsPremium = UserDefaults.standard.bool(forKey: Self.premiumKey)
        if let data = UserDefaults.standard.data(forKey: Self.grandfatherKey),
           let info = try? JSONDecoder().decode(GrandfatherInfo.self, from: data) {
            grandfatheredInfo = info
        }
        #if !DEBUG
        // Release guard: стираем любые следы God Mode (на случай если DEBUG-сборка
        // когда-то запускалась на этом устройстве — теперь TestFlight/Release
        // не должны наследовать bypass).
        UserDefaults.standard.removeObject(forKey: Self.godModeKey)
        #endif
    }

    // MARK: Internal

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "Premium")

    static let shared = PremiumManager()

    // Product IDs — настроить в App Store Connect
    static let monthlyID = "com.stillo.premium.monthly"
    static let yearlyID = "com.stillo.premium.yearly"
    static let lifetimeID = "com.stillo.premium.lifetime"

    /// Все product IDs для `Product.products(for:)`.
    static let allProductIDs: [String] = [monthlyID, yearlyID, lifetimeID]

    /// IDs всех подписок (subscription group). Lifetime сюда не входит — non-consumable.
    private static let subscriptionIDs: Set<String> = [monthlyID, yearlyID]

    /// Lifetime — non-consumable one-time purchase.
    private static let nonConsumableIDs: Set<String> = [lifetimeID]

    /// Любой ID, дающий premium-доступ.
    private static let premiumProductIDs: Set<String> = subscriptionIDs.union(nonConsumableIDs)

    // MARK: - Free Tier Limits

    /// Максимум записей дневника для Free (Phase 21 Monetization Strategy: 7).
    static let freeDiaryLimit = 7

    /// Бесплатная техника — только 4-7-8
    static let freeTechniqueID = "fourSevenEight"

    /// Продукты из App Store
    private(set) var products: [Product] = []

    /// Загрузка при старте
    private(set) var isLoading = false

    /// Покупка в статусе Ask to Buy (ожидает одобрения)
    private(set) var purchasePending = false

    /// Ошибка загрузки продуктов (для UI)
    private(set) var loadError: String?

    /// Настоящий статус подписки (из StoreKit).
    /// Используется только внутри менеджера + в UI подписки.
    /// Все проверки доступа (`canAccessTechnique`, `canAddDiaryEntry`, `isPremium`) идут через computed-геттер,
    /// чтобы DEBUG God Mode работал консистентно.
    private(set) var realIsPremium: Bool {
        didSet { UserDefaults.standard.set(realIsPremium, forKey: Self.premiumKey) }
    }

    #if DEBUG
    /// DEBUG-only observable storage. В Release-сборке не компилируется.
    private var godModeActive: Bool = UserDefaults.standard.bool(forKey: PremiumManager.godModeKey)

    /// Developer toggle. Доступен ТОЛЬКО в DEBUG-сборке.
    /// UI-реактивен через @Observable (меняем stored property → все getters re-evaluated).
    var isGodModeEnabled: Bool {
        get { godModeActive }
        set {
            godModeActive = newValue
            UserDefaults.standard.set(newValue, forKey: Self.godModeKey)
            Self.log.info("🛠 God Mode: \(newValue ? "ON" : "OFF")")
        }
    }
    #endif

    /// Эффективный premium-статус: `realIsPremium || DEBUG god mode`.
    /// В Release-сборке ветка god-mode физически не компилируется — `return realIsPremium`.
    var isPremium: Bool {
        #if DEBUG
        if godModeActive { return true }
        #endif
        return realIsPremium
    }

    /// Grandfather lock — цена первой успешной покупки сохраняется навсегда.
    /// При будущем повышении baseline-цен существующий юзер платит старую.
    private(set) var grandfatheredInfo: GrandfatherInfo?

    struct GrandfatherInfo: Codable {
        let price: String
        let productID: String
        let date: Date
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
        loadError = nil
        defer { isLoading = false }

        do {
            products = try await Product.products(for: Self.allProductIDs)
            if products.isEmpty {
                loadError = "No products found"
            }
        } catch {
            loadError = error.localizedDescription
            Self.log.error("Failed to load products: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Купить подписку
    func purchase(_ product: Product) async -> Bool {
        purchasePending = false

        do {
            let result = try await product.purchase()

            switch result {
            case let .success(verification):
                let transaction = try checkVerified(verification)
                realIsPremium = true
                lockGrandfatherIfNeeded(product: product)
                await transaction.finish()
                return true

            case .userCancelled:
                return false

            case .pending:
                // Ask to Buy — ожидаем одобрения родителем
                purchasePending = true
                return false

            @unknown default:
                return false
            }
        } catch {
            Self.log.error("Purchase failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Восстановить покупки
    func restorePurchases() async {
        var foundActive = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               Self.premiumProductIDs.contains(transaction.productID) {
                realIsPremium = true
                foundActive = true
                break
            }
        }
        if !foundActive {
            realIsPremium = false
        }
    }

    /// Слушать обновления транзакций (вызывать при старте).
    /// Ссылка на Task хранится, чтобы предотвратить сборку мусора.
    func listenForTransactions() {
        transactionListener?.cancel()
        let premiumIDs = Self.premiumProductIDs
        let nonConsumableIDs = Self.nonConsumableIDs
        transactionListener = Task.detached(priority: .utility) { [weak self] in
            for await result in Transaction.updates {
                // 2026-05-03 (Master Plan День 3): try? проглатывал unverified
                // транзакции — потенциальный path для jailbreak / fake receipts.
                // Заменено на do/catch с логом. НЕ finish() unverified —
                // StoreKit повторит, и если повтор тоже unverified — это
                // не наша проблема, юзер получит refund от Apple.
                let transaction: StoreKit.Transaction
                do {
                    guard let verified = try await self?.checkVerified(result) else { continue }
                    transaction = verified
                } catch {
                    Self.log.error("Unverified transaction skipped: \(error.localizedDescription, privacy: .public)")
                    continue
                }
                let isPremiumProduct = premiumIDs.contains(transaction.productID)
                // Lifetime revocation (refund) → revoked ≠ nil; subscriptions handle expiry автоматически.
                let isRevoked = transaction.revocationDate != nil
                let isActive = isPremiumProduct && !isRevoked
                // Для lifetime не сбрасываем флаг на false если транзакция не наша (inapp типа consumable):
                // флаг меняем только если это один из наших premium-products.
                if isPremiumProduct || nonConsumableIDs.contains(transaction.productID) {
                    await MainActor.run { [weak self] in
                        self?.realIsPremium = isActive
                        self?.purchasePending = false
                    }
                }
                await transaction.finish()
            }
        }
    }

    /// Проверить статус при старте
    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               Self.premiumProductIDs.contains(transaction.productID) {
                realIsPremium = true
                return
            }
        }
        // Нет активных подписок / lifetime
        realIsPremium = false
    }

    // MARK: Private

    private static let premiumKey = "stillo_is_premium"
    private static let grandfatherKey = "stillo_grandfather_info"
    private static let godModeKey = "stillo_debug_god_mode"

    private func lockGrandfatherIfNeeded(product: Product) {
        guard grandfatheredInfo == nil else { return }
        let info = GrandfatherInfo(
            price: product.displayPrice,
            productID: product.id,
            date: Date()
        )
        grandfatheredInfo = info
        if let data = try? JSONEncoder().encode(info) {
            UserDefaults.standard.set(data, forKey: Self.grandfatherKey)
        }
    }

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
