import CoreData
import Foundation

@objc(PlaylistEntity)
final class PlaylistEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var deletedFlag: Bool
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var syncStateRaw: String
}

extension PlaylistEntity {
    @nonobjc static func fetchRequest() -> NSFetchRequest<PlaylistEntity> {
        NSFetchRequest<PlaylistEntity>(entityName: "PlaylistEntity")
    }
}
