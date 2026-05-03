import Foundation
import Testing
@testable import Stillo

struct DiaryEpisodeTests {
    @Test
    func codableRoundTrip() throws {
        let original = DiaryEpisode(
            id: UUID(),
            date: Date(timeIntervalSince1970: 1_700_000_000),
            intensity: 7,
            notes: "panic at supermarket — used 4-7-8"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DiaryEpisode.self, from: data)

        #expect(decoded == original)
    }

    @Test
    func equalityMatchesById() {
        let id = UUID()
        let a = DiaryEpisode(id: id, date: Date(), intensity: 5, notes: "x")
        let b = DiaryEpisode(id: id, date: a.date, intensity: 5, notes: "x")

        #expect(a == b)
    }

    @Test
    func intensityBoundariesAccepted() {
        let low = DiaryEpisode(intensity: 1, notes: "")
        let high = DiaryEpisode(intensity: 10, notes: "")

        #expect(low.intensity == 1)
        #expect(high.intensity == 10)
    }
}
