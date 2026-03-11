//
//  StudyTaskDashboardViewModel.swift
//  TinniTrack
//

import Foundation
import Combine

@MainActor
final class StudyTaskDashboardViewModel: ObservableObject {
    enum ContentState: Equatable {
        case loading
        case blocked(AudiogramPrerequisiteState)
        case ready(latestAudiogramDate: Date?)
    }

    @Published private(set) var contentState: ContentState = .loading
    @Published private(set) var isSyncing = false
    @Published var bannerMessage: String?

    private let study: Study
    private let coordinator: AudiogramImportCoordinating
    private var hasLoadedOnce = false

    init(study: Study, coordinator: AudiogramImportCoordinating) {
        self.study = study
        self.coordinator = coordinator
    }

    var requiresAudiogramImport: Bool {
        StudyPrerequisiteRules.requiresAudiogramImport(for: study.slug)
    }

    func loadIfNeeded() async {
        guard !hasLoadedOnce else { return }
        await refresh()
    }

    func refresh() async {
        guard requiresAudiogramImport else {
            contentState = .ready(latestAudiogramDate: nil)
            hasLoadedOnce = true
            return
        }

        contentState = .loading
        let prerequisiteState = await coordinator.evaluatePrerequisite()
        applyPrerequisiteState(prerequisiteState)
        hasLoadedOnce = true
    }

    func importOrSyncAudiograms() async {
        guard requiresAudiogramImport else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let result = try await coordinator.importFromHealthKit()
            switch result {
            case .imported(let newRecords, _):
                let pluralized = newRecords == 1 ? "audiogram" : "audiograms"
                bannerMessage = "Imported \(newRecords) new \(pluralized)."
            case .noNewRecords:
                bannerMessage = "No new audiograms to import."
            case .noAudiogramInHealth:
                bannerMessage = "No audiogram found in Apple Health."
            }
        } catch {
            bannerMessage = error.localizedDescription
        }

        await refresh()
    }

    func dismissBanner() {
        bannerMessage = nil
    }

    private func applyPrerequisiteState(_ state: AudiogramPrerequisiteState) {
        switch state {
        case .met(let latestMeasuredAt):
            contentState = .ready(latestAudiogramDate: latestMeasuredAt)
        case .needsPermission, .noAudiogramInHealth, .error:
            contentState = .blocked(state)
        }
    }
}
