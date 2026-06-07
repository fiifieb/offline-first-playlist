import SwiftUI

struct PlaylistListView: View {
    @ObservedObject var viewModel: PlaylistListViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.syncStatusLabel)
                            .font(.headline)
                        Text("Pending: \(viewModel.pendingSyncCount) • Failed: \(viewModel.failedSyncCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Playlists") {
                    if viewModel.activePlaylists.isEmpty {
                        Text("No playlists yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.activePlaylists) { playlist in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(playlist.name)
                                    Text(playlist.syncState.label)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Edit") {
                                    viewModel.beginRename(playlist: playlist)
                                }
                                .buttonStyle(.borderless)
                                Button("Delete") {
                                    Task { await viewModel.softDeletePlaylist(id: playlist.id) }
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }

                Section("Deleted") {
                    if viewModel.deletedPlaylists.isEmpty {
                        Text("No deleted playlists")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.deletedPlaylists) { playlist in
                            HStack {
                                Text(playlist.name)
                                Spacer()
                                Button("Restore") {
                                    Task { await viewModel.restorePlaylist(id: playlist.id) }
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Playlists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isPresentingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create playlist")
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK") { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
            .sheet(isPresented: $viewModel.isPresentingCreateSheet) {
                NavigationStack {
                    Form {
                        TextField("Playlist name", text: $viewModel.newPlaylistName)
                    }
                    .navigationTitle("New Playlist")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                viewModel.isPresentingCreateSheet = false
                                viewModel.newPlaylistName = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                Task { await viewModel.createPlaylist() }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.isPresentingRenameSheet) {
                NavigationStack {
                    Form {
                        TextField("Playlist name", text: $viewModel.renamePlaylistName)
                    }
                    .navigationTitle("Rename Playlist")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                viewModel.isPresentingRenameSheet = false
                                viewModel.renamePlaylistName = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                Task { await viewModel.renamePlaylist() }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

private extension SyncState {
    var label: String {
        switch self {
        case .pending:
            return "Pending"
        case .synced:
            return "Synced"
        case .failed:
            return "Failed"
        }
    }
}

#Preview {
    PlaylistListView(viewModel: PlaylistListViewModel(repository: InMemoryPlaylistRepository()))
}
