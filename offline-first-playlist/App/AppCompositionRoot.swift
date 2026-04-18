import SwiftUI

struct AppCompositionRoot: View {
    let environment: AppEnvironment
    @StateObject private var viewModel: PlaylistListViewModel

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = StateObject(wrappedValue: PlaylistListViewModel(repository: environment.playlistRepository))
    }

    var body: some View {
        PlaylistListView(viewModel: viewModel)
    }
}
