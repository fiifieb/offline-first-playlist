import CoreData
import Foundation

actor CoreDataPlaylistRepository: PlaylistRepository {
    private enum RepositoryError: Error {
        case playlistNotFound
    }

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchActivePlaylists() async throws -> [Playlist] {
        try await fetchPlaylists(isDeleted: false)
    }

    func fetchDeletedPlaylists() async throws -> [Playlist] {
        try await fetchPlaylists(isDeleted: true)
    }

    func createPlaylist(named name: String) async throws -> Playlist {
        try await perform {
            let now = Date()
            let entity = PlaylistEntity(context: self.context)
            entity.id = UUID()
            entity.name = name
            entity.deletedFlag = false
            entity.createdAt = now
            entity.updatedAt = now
            entity.syncStateRaw = "pending"

            try self.context.save()
            return Self.map(entity)
        }
    }

    func renamePlaylist(id: UUID, name: String) async throws -> Playlist {
        try await perform {
            let entity = try self.fetchEntity(id: id)
            entity.name = name
            entity.updatedAt = Date()
            entity.syncStateRaw = "pending"
            try self.context.save()
            return Self.map(entity)
        }
    }

    func softDeletePlaylist(id: UUID) async throws {
        try await perform {
            let entity = try self.fetchEntity(id: id)
            entity.deletedFlag = true
            entity.updatedAt = Date()
            entity.syncStateRaw = "pending"
            try self.context.save()
        }
    }

    func restorePlaylist(id: UUID) async throws {
        try await perform {
            let entity = try self.fetchEntity(id: id)
            entity.deletedFlag = false
            entity.updatedAt = Date()
            entity.syncStateRaw = "pending"
            try self.context.save()
        }
    }

    func setSyncState(id: UUID, syncState: SyncState) async throws {
        try await perform {
            let entity = try self.fetchEntity(id: id)
            entity.syncStateRaw = syncState.rawValue
            entity.updatedAt = Date()
            try self.context.save()
        }
    }

    private func fetchPlaylists(isDeleted: Bool) async throws -> [Playlist] {
        try await perform {
            let request = PlaylistEntity.fetchRequest()
            request.predicate = NSPredicate(format: "deletedFlag == %@", NSNumber(value: isDeleted))
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

            let entities = try self.context.fetch(request)
            return entities.map(Self.map)
        }
    }

    private func fetchEntity(id: UUID) throws -> PlaylistEntity {
        let request = PlaylistEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        guard let entity = try context.fetch(request).first else {
            throw RepositoryError.playlistNotFound
        }

        return entity
    }

    private func perform<T>(_ block: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    continuation.resume(returning: try block())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func map(_ entity: PlaylistEntity) -> Playlist {
        Playlist(
            id: entity.id,
            name: entity.name,
            isDeleted: entity.deletedFlag,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            syncState: SyncState(rawValue: entity.syncStateRaw)
        )
    }
}

private extension SyncState {
    var rawValue: String {
        switch self {
        case .pending:
            return "pending"
        case .synced:
            return "synced"
        case .failed:
            return "failed"
        }
    }

    init(rawValue: String) {
        switch rawValue {
        case "synced":
            self = .synced
        case "failed":
            self = .failed
        default:
            self = .pending
        }
    }
}
