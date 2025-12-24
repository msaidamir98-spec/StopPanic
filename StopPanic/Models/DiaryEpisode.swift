import Foundation

/// Запись в дневнике паники
struct DiaryEpisode: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let intensity: Int          // 1-10
    let notes: String

    init(id: UUID = UUID(), date: Date = Date(), intensity: Int, notes: String) {
        self.id = id
        self.date = date
        self.intensity = intensity
        self.notes = notes
    }
}
