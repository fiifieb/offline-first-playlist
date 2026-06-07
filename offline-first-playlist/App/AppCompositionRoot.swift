import SwiftUI

struct AppCompositionRoot: View {
    let environment: AppEnvironment
    @StateObject private var viewModel: PlaylistListViewModel

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = StateObject(wrappedValue: PlaylistListViewModel(repository: environment.playlistRepository))
        #if DEBUG
        Task {
            await DebugSeed.seedIfEmpty(repository: environment.playlistRepository)
        }
        #endif
    }

    var body: some View {
        PlaylistListView(viewModel: viewModel)
    }
}
