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

    enum OrientationImportState: Equatable {
        case waitingForPermission
        case requestingOrChecking
        case success(hearingTestDate: Date?)
        case authorizedNoHearingTest
        case permissionDenied
        case error(message: String)
    }

    @Published private(set) var contentState: ContentState = .loading
    @Published private(set) var isSyncing = false
    @Published private(set) var orientationImportState: OrientationImportState = .requestingOrChecking

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

    var isAudiogramPrerequisiteMet: Bool {
        if case .ready = contentState {
            return true
        }
        return false
    }

    func loadIfNeeded() async {
        guard !hasLoadedOnce else { return }
        await refresh()
    }

    func refresh() async {
        await evaluatePrerequisite(showLoadingState: true)
        hasLoadedOnce = true
    }

    func importOrSyncAudiograms() async {
        await requestImportThenReevaluate()
    }

    func connectAppleHealthForOrientation() async {
        await requestImportThenReevaluate()
    }

    func checkOrientationImportStatus() async {
        await evaluatePrerequisite(showLoadingState: false)
    }

    private func requestImportThenReevaluate() async {
        guard requiresAudiogramImport else { return }

        isSyncing = true
        orientationImportState = .requestingOrChecking

        do {
            _ = try await coordinator.importFromHealthKit()
        } catch {
            // The prerequisite reevaluation below maps final UX state.
        }

        isSyncing = false
        await evaluatePrerequisite(showLoadingState: false)
    }

    private func evaluatePrerequisite(showLoadingState: Bool) async {
        guard requiresAudiogramImport else {
            contentState = .ready(latestAudiogramDate: nil)
            orientationImportState = .success(hearingTestDate: nil)
            return
        }

        if showLoadingState {
            contentState = .loading
        }

        orientationImportState = .requestingOrChecking
        let prerequisiteState = await coordinator.evaluatePrerequisite()
        applyPrerequisiteState(prerequisiteState)
    }

    private func applyPrerequisiteState(_ state: AudiogramPrerequisiteState) {
        switch state {
        case .met(let latestMeasuredAt):
            contentState = .ready(latestAudiogramDate: latestMeasuredAt)
            orientationImportState = .success(hearingTestDate: latestMeasuredAt)
        case .needsPermission:
            contentState = .blocked(state)
            orientationImportState = .waitingForPermission
        case .permissionDenied:
            contentState = .blocked(state)
            orientationImportState = .permissionDenied
        case .noAudiogramInHealth:
            contentState = .blocked(state)
            orientationImportState = .authorizedNoHearingTest
        case .error(let message):
            contentState = .blocked(state)
            orientationImportState = .error(message: message)
        }
    }
}
