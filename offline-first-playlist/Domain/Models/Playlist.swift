import Foundation

enum SyncState: Equatable {
    case pending
    case synced
    case failed
}

struct Playlist: Identifiable, Equatable {
    let id: UUID
    var name: String
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var syncState: SyncState
}
