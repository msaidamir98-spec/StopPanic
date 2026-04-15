import CoreData
import Foundation
import os.log

// MARK: - MoodPoint

/// Точка настроения на графике
struct MoodPoint: Codable, Identifiable {
    // MARK: Lifecycle

    init(id: UUID = UUID(), date: Date = Date(), mood: Int, note: String = "") {
        self.id = id
        self.date = date
        self.mood = mood
        self.note = note
    }

    // MARK: Internal

    let id: UUID
    let date: Date
    let mood: Int // 1-10
    let note: String
}

// MARK: - MoodMapService

/// Сервис карты настроения (Core Data + CloudKit)
@MainActor
@Observable
final class MoodMapService {
    // MARK: Lifecycle

    init() {
        persistence = PersistenceController.shared
        loadPoints()
    }

    // MARK: Internal

    var points: [MoodPoint] = []

    func addPoint(mood: Int, note: String = "") {
        let point = MoodPoint(mood: mood, note: note)
        points.append(point)

        let cd = CDMoodPoint(context: persistence.viewContext)
        cd.id = point.id
        cd.date = point.date
        cd.mood = Int16(point.mood)
        cd.note = point.note
        persistence.save()
    }

    func removePointById(_ id: UUID) {
        points.removeAll { $0.id == id }
        let request: NSFetchRequest<CDMoodPoint> = CDMoodPoint.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let results = try? persistence.viewContext.fetch(request), let obj = results.first {
            persistence.viewContext.delete(obj)
            persistence.save()
        }
    }

    func updatePoint(id: UUID, mood: Int, note: String) {
        if let index = points.firstIndex(where: { $0.id == id }) {
            let old = points[index]
            points[index] = MoodPoint(id: old.id, date: old.date, mood: mood, note: note)

            let request: NSFetchRequest<CDMoodPoint> = CDMoodPoint.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let results = try? persistence.viewContext.fetch(request), let obj = results.first {
                obj.mood = Int16(mood)
                obj.note = note
                persistence.save()
            }
        }
    }

    // MARK: Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "MoodMapService")

    private let persistence: PersistenceController

    private func loadPoints() {
        let request: NSFetchRequest<CDMoodPoint> = CDMoodPoint.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDMoodPoint.date, ascending: true)]
        do {
            let results = try persistence.viewContext.fetch(request)
            points = results.map {
                MoodPoint(
                    id: $0.id ?? UUID(),
                    date: $0.date ?? Date(),
                    mood: Int($0.mood),
                    note: $0.note ?? ""
                )
            }
        } catch {
            Self.log.error("Failed to load mood points from Core Data: \(error.localizedDescription)")
        }
    }
}
