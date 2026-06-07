import Foundation

struct PlaylistSyncJob: Identifiable, Equatable {
    enum Operation: Equatable {
        case create
        case rename
        case delete
        case restore
    }

    let id: UUID
    let playlistID: UUID
    let operation: Operation
}

protocol PlaylistSyncEngine {
    var pendingCount: Int { get }
    var failedCount: Int { get }

    func enqueue(playlistID: UUID, operation: PlaylistSyncJob.Operation) async
    func flush() async
}

final class MockPlaylistSyncEngine: PlaylistSyncEngine {
    enum Outcome {
        case success
        case failure
    }

    private let repository: any PlaylistRepository
    private var queue: [PlaylistSyncJob] = []
    private var failedJobs: [PlaylistSyncJob] = []
    private let outcomeProvider: (PlaylistSyncJob) -> Outcome

    init(repository: any PlaylistRepository, outcomeProvider: @escaping (PlaylistSyncJob) -> Outcome = { _ in .success }) {
        self.repository = repository
        self.outcomeProvider = outcomeProvider
    }

    var pendingCount: Int {
        queue.count
    }

    var failedCount: Int {
        failedJobs.count
    }

    func enqueue(playlistID: UUID, operation: PlaylistSyncJob.Operation) async {
        let job = PlaylistSyncJob(id: UUID(), playlistID: playlistID, operation: operation)
        queue.append(job)
        try? await repository.setSyncState(id: playlistID, syncState: .pending)
    }

    func flush() async {
        let jobs = queue
        queue.removeAll()

        for job in jobs {
            switch outcomeProvider(job) {
            case .success:
                try? await repository.setSyncState(id: job.playlistID, syncState: .synced)
            case .failure:
                failedJobs.append(job)
                try? await repository.setSyncState(id: job.playlistID, syncState: .failed)
            }
        }
    }
}
