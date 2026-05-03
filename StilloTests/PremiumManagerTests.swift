import Foundation
import Testing
@testable import Stillo

@MainActor
struct PremiumManagerTests {
    @Test
    func freeTierConstantsAreSensible() {
        #expect(PremiumManager.freeDiaryLimit == 3)
        #expect(PremiumManager.freeTechniqueID == "fourSevenEight")
        #expect(PremiumManager.monthlyID == "com.stillo.premium.monthly")
        #expect(PremiumManager.yearlyID == "com.stillo.premium.yearly")
    }

    @Test
    func grandfatherInfoCodableRoundTrip() throws {
        let info = PremiumManager.GrandfatherInfo(
            price: "$24.99",
            productID: PremiumManager.yearlyID,
            date: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(PremiumManager.GrandfatherInfo.self, from: data)

        #expect(decoded.price == info.price)
        #expect(decoded.productID == info.productID)
        #expect(decoded.date == info.date)
    }
}
