//
//  StudyTaskDashboardView.swift
//  TinniTrack
//

import SwiftUI
import UIKit

struct StudyTaskDashboardView: View {
    let study: Study

    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: StudyTaskDashboardViewModel

    init(
        study: Study,
        coordinator: AudiogramImportCoordinating = AudiogramImportCoordinator()
    ) {
        self.study = study
        _viewModel = StateObject(
            wrappedValue: StudyTaskDashboardViewModel(
                study: study,
                coordinator: coordinator
            )
        )
    }

    var body: some View {
        content
            .navigationTitle(study.title)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadIfNeeded()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert(
                "Info",
                isPresented: Binding(
                    get: { viewModel.bannerMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.dismissBanner()
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.dismissBanner()
                }
            } message: {
                Text(viewModel.bannerMessage ?? "")
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.contentState {
        case .loading:
            ProgressView("Checking study prerequisites…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemGroupedBackground))
        case .blocked(let state):
            blockedContent(for: state)
        case .ready(let latestAudiogramDate):
            readyContent(latestAudiogramDate: latestAudiogramDate)
        }
    }

    @ViewBuilder
    private func blockedContent(for state: AudiogramPrerequisiteState) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch state {
                case .needsPermission:
                    prerequisiteCard(
                        title: "Apple Health Access Required",
                        message: "Study No. 1 requires importing your audiogram from Apple Health before tasks can start."
                    )

                    actionButton(
                        title: viewModel.isSyncing ? "Connecting…" : "Connect Apple Health",
                        isPrimary: true,
                        isLoading: viewModel.isSyncing
                    ) {
                        Task { await viewModel.importOrSyncAudiograms() }
                    }

                    actionButton(title: "Open App Settings", isPrimary: false) {
                        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }
                        openURL(settingsURL)
                    }
                case .noAudiogramInHealth:
                    prerequisiteCard(
                        title: "No Audiogram Found",
                        message: "Complete a hearing test in Apple Health or Settings, then return here and retry import."
                    )

                    actionButton(title: "Open Health App", isPrimary: false) {
                        guard let healthAppURL = URL(string: "x-apple-health://") else {
                            return
                        }
                        openURL(healthAppURL)
                    }

                    actionButton(
                        title: viewModel.isSyncing ? "Retrying…" : "Retry Import",
                        isPrimary: true,
                        isLoading: viewModel.isSyncing
                    ) {
                        Task { await viewModel.importOrSyncAudiograms() }
                    }
                case .error(let message):
                    prerequisiteCard(
                        title: "Import Unavailable",
                        message: message
                    )

                    actionButton(
                        title: viewModel.isSyncing ? "Retrying…" : "Try Again",
                        isPrimary: true,
                        isLoading: viewModel.isSyncing
                    ) {
                        Task { await viewModel.importOrSyncAudiograms() }
                    }
                case .met:
                    EmptyView()
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func readyContent(latestAudiogramDate: Date?) -> some View {
        List {
            if viewModel.requiresAudiogramImport {
                Section("Audiogram Baseline") {
                    if let latestAudiogramDate {
                        LabeledContent("Last Imported", value: Self.dateFormatter.string(from: latestAudiogramDate))
                    } else {
                        Text("Imported")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task { await viewModel.importOrSyncAudiograms() }
                    } label: {
                        HStack {
                            if viewModel.isSyncing {
                                ProgressView()
                            }
                            Text(viewModel.isSyncing ? "Syncing from Health…" : "Sync from Health")
                        }
                    }
                    .disabled(viewModel.isSyncing)
                }
            }

            Section("Future Tasks") {
                Text("No upcoming tasks yet.")
                    .foregroundStyle(.secondary)
            }

            Section("Completed Tasks") {
                Text("No completed tasks yet.")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func prerequisiteCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
    }

    private func actionButton(
        title: String,
        isPrimary: Bool,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(isPrimary ? .white : .blue)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .background(isPrimary ? Color.blue : Color.white)
        .foregroundStyle(isPrimary ? Color.white : Color.blue)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(isPrimary ? 0 : 0.08), radius: 3, x: 0, y: 1)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationStack {
        StudyTaskDashboardView(
            study: Study(
                id: UUID(),
                slug: StudyPrerequisiteRules.studyNo1Slug,
                title: "Study No. 1",
                description: "Audiogram prerequisite preview",
                status: .recruiting,
                createdAt: Date()
            ),
            coordinator: AudiogramImportCoordinator()
        )
    }
}
