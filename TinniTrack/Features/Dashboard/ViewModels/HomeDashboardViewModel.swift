//
//  HomeDashboardViewModel.swift
//  TinniTrack
//

import Foundation
import Combine

@MainActor
final class HomeDashboardViewModel: ObservableObject {
    @Published private(set) var state: State = .loading
    @Published private(set) var studies: [DashboardStudyCard] = []
    @Published private(set) var enrollingStudyID: UUID?

    enum State: Equatable {
        case loading
        case loaded
        case empty
    }

    private let studyService: StudyServiceProtocol
    private var hasLoadedOnce = false

    init(studyService: StudyServiceProtocol) {
        self.studyService = studyService
    }

    func loadIfNeeded() async {
        guard !hasLoadedOnce else { return }
        await refresh()
    }

    func refresh() async {
        state = .loading
        do {
            async let studiesTask = studyService.fetchStudies()
            async let enrollmentsTask = studyService.fetchMyEnrollments()

            let studyRows = try await studiesTask
            let enrollmentRows = try await enrollmentsTask
            let enrollmentByStudyID = Dictionary(
                enrollmentRows.map { ($0.studyID, $0) },
                uniquingKeysWith: { first, _ in first }
            )

            studies = studyRows.map {
                DashboardStudyCard(study: $0, enrollment: enrollmentByStudyID[$0.id])
            }

            state = studies.isEmpty ? .empty : .loaded
        } catch {
            print("HomeDashboardViewModel.refresh() failed with error:", error)
            studies = []
            state = .empty
        }
        hasLoadedOnce = true
    }

    func enroll(studyID: UUID) async throws {
        enrollingStudyID = studyID
        defer { enrollingStudyID = nil }
        try await studyService.enroll(studyID: studyID)
        await refresh()
    }
}

struct DashboardStudyCard: Identifiable, Equatable {
    let study: Study
    let enrollment: StudyEnrollment?

    var id: UUID { study.id }

    var isEnrolledActive: Bool {
        enrollment?.status == .enrolled
    }

    var badgeText: String {
        if isEnrolledActive {
            return "ACTIVE"
        }

        switch study.status {
        case .recruiting:
            return "RECRUITING"
        case .recruitingPaused:
            return "PAUSED"
        case .closed:
            return "CLOSED"
        case .unknown(let raw):
            return raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }
    }

    var callToActionText: String {
        isEnrolledActive ? "Go to Tasks" : "View Details"
    }
}
