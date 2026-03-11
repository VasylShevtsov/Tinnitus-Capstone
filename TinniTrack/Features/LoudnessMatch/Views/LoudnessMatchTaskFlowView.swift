import SwiftUI
import UIKit
import Combine

struct LoudnessMatchTaskFlowView: View {
    let scheduledTask: ScheduledTask
    let enrollment: StudyEnrollment
    let studyService: StudyServiceProtocol
    let onSubmitted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: LoudnessMatchTaskFlowViewModel
    @State private var isSubmitConfirmationPresented = false
    @State private var isErrorAlertPresented = false

    init(
        scheduledTask: ScheduledTask,
        enrollment: StudyEnrollment,
        studyService: StudyServiceProtocol,
        routeMonitor: HeadphoneRouteMonitoring = HeadphoneRouteMonitor(),
        ambientNoiseMonitor: AmbientNoiseMonitoring = AmbientNoiseMonitor(),
        onSubmitted: @escaping () -> Void
    ) {
        self.scheduledTask = scheduledTask
        self.enrollment = enrollment
        self.studyService = studyService
        self.onSubmitted = onSubmitted

        _viewModel = StateObject(
            wrappedValue: LoudnessMatchTaskFlowViewModel(
                scheduledTask: scheduledTask,
                enrollment: enrollment,
                studyService: studyService,
                routeMonitor: routeMonitor,
                ambientNoiseMonitor: ambientNoiseMonitor
            )
        )
    }

    var body: some View {
        VStack(spacing: 24) {
            header

            switch viewModel.step {
            case .headphoneGate:
                headphoneGateContent
            case .ambientGate:
                ambientGateContent
            case .matching:
                matchingContent
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .navigationTitle("Loudness Match")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
        .alert("Are you sure?", isPresented: $isSubmitConfirmationPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Submit", role: .destructive) {
                Task {
                    let didSubmit = await viewModel.submitMatch()
                    if didSubmit {
                        onSubmitted()
                        dismiss()
                    } else {
                        isErrorAlertPresented = true
                    }
                }
            }
        } message: {
            Text("Submit this loudness match and mark the task complete?")
        }
        .alert("Unable to Submit", isPresented: $isErrorAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Task Window")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(
                "\(Self.timeFormatter.string(from: scheduledTask.windowStart)) - \(Self.timeFormatter.string(from: scheduledTask.windowEnd))"
            )
            .font(.subheadline)
            .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headphoneGateContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 1: Connect AirPods Pro")
                .font(.title3)
                .fontWeight(.semibold)

            Text("We only allow loudness matching when AirPods Pro are connected.")
                .foregroundStyle(.secondary)

            statusPill(
                title: viewModel.isSupportedRoute ? "Connected" : "Not Connected",
                subtitle: viewModel.currentRoute?.name ?? "No audio output detected",
                isGood: viewModel.isSupportedRoute
            )

            if !viewModel.isSupportedRoute {
                Text("Connect your AirPods Pro 2 or AirPods Pro 3. We will continue automatically once detected.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ambientGateContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step 2: Quiet Room Check")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Ambient noise must stay at or below \(Int(StudyNo1Configuration.ambientThresholdDB)) dB.")
                .foregroundStyle(.secondary)

            switch viewModel.ambientPermissionStatus {
            case .notDetermined:
                Button("Enable Microphone") {
                    Task { await viewModel.requestAmbientPermission() }
                }
                .buttonStyle(.borderedProminent)

            case .denied:
                Text("Microphone access is required for ambient-noise validation.")
                    .foregroundStyle(.secondary)

                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .buttonStyle(.bordered)

            case .granted:
                statusPill(
                    title: viewModel.isAmbientQuiet ? "Quiet Enough" : "Too Loud",
                    subtitle: viewModel.ambientDisplayText,
                    isGood: viewModel.isAmbientQuiet
                )

                Text(viewModel.isAmbientQuiet
                     ? "Environment check passed."
                     : "Move to a quieter location and wait for the reading to drop.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("Start Loudness Match") {
                    viewModel.startMatching()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isAmbientQuiet)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var matchingContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Step 3: Match Ringing")
                .font(.title3)
                .fontWeight(.semibold)

            statusPill(
                title: viewModel.isAmbientQuiet ? "Quiet Enough" : "Environment Too Loud",
                subtitle: viewModel.ambientDisplayText,
                isGood: viewModel.isAmbientQuiet
            )

            if !viewModel.isAmbientQuiet {
                Text("Adjustment is paused until ambient noise returns below the threshold.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            CircularDial(
                value: Binding(
                    get: { viewModel.loudnessLevel },
                    set: { viewModel.updateLoudness($0) }
                ),
                isEnabled: viewModel.isAmbientQuiet
            )
            .frame(height: 280)

            Text("Current match level: \(viewModel.matchLevelPercentText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                isSubmitConfirmationPresented = true
            } label: {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Match Ringing")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(viewModel.isSubmitting)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusPill(title: String, subtitle: String, isGood: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(subtitle)
                .font(.footnote)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isGood ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

@MainActor
final class LoudnessMatchTaskFlowViewModel: ObservableObject {
    enum Step: Equatable {
        case headphoneGate
        case ambientGate
        case matching
    }

    @Published private(set) var step: Step = .headphoneGate
    @Published private(set) var currentRoute: AudioOutputRoute?
    @Published private(set) var ambientPermissionStatus: AmbientNoisePermissionStatus = .notDetermined
    @Published private(set) var ambientDB: Double?
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var loudnessLevel: Double = 0.3

    private let scheduledTask: ScheduledTask
    private let enrollment: StudyEnrollment
    private let studyService: StudyServiceProtocol
    private let routeMonitor: HeadphoneRouteMonitoring
    private let ambientNoiseMonitor: AmbientNoiseMonitoring

    private var hasStarted = false
    private var startedAt: Date?
    private var loudnessEvents: [(timestamp: Date, value: Double)] = []
    private var ambientEvents: [(timestamp: Date, value: Double)] = []

    init(
        scheduledTask: ScheduledTask,
        enrollment: StudyEnrollment,
        studyService: StudyServiceProtocol,
        routeMonitor: HeadphoneRouteMonitoring,
        ambientNoiseMonitor: AmbientNoiseMonitoring
    ) {
        self.scheduledTask = scheduledTask
        self.enrollment = enrollment
        self.studyService = studyService
        self.routeMonitor = routeMonitor
        self.ambientNoiseMonitor = ambientNoiseMonitor
    }

    var isSupportedRoute: Bool {
        guard let routeName = currentRoute?.name else { return false }
        return StudyNo1Configuration.isSupportedHeadphoneRouteName(routeName)
    }

    var isAmbientQuiet: Bool {
        guard let ambientDB else { return false }
        return ambientDB <= StudyNo1Configuration.ambientThresholdDB
    }

    var ambientDisplayText: String {
        guard let ambientDB else {
            return "Waiting for ambient reading…"
        }
        return String(format: "Ambient: %.1f dB (threshold: %.0f dB)", ambientDB, StudyNo1Configuration.ambientThresholdDB)
    }

    var matchLevelPercentText: String {
        "\(Int((loudnessLevel * 100).rounded()))%"
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        ambientPermissionStatus = ambientNoiseMonitor.permissionStatus()

        routeMonitor.startMonitoring { [weak self] route in
            guard let self else { return }
            self.currentRoute = route

            if self.isSupportedRoute && self.step == .headphoneGate {
                self.enterAmbientGate()
            }
        }
    }

    func stop() {
        routeMonitor.stopMonitoring()
        ambientNoiseMonitor.stopMonitoring()
        ToneGenerator.shared.stop()
    }

    func requestAmbientPermission() async {
        let granted = await ambientNoiseMonitor.requestPermission()
        ambientPermissionStatus = granted ? .granted : .denied

        if granted {
            startAmbientMonitoringIfNeeded()
        }
    }

    func startMatching() {
        guard step == .ambientGate else { return }
        guard isAmbientQuiet else { return }

        step = .matching
        startedAt = Date()

        ToneGenerator.shared.start()
        ToneGenerator.shared.setVolume(loudnessLevel)

        loudnessEvents.append((timestamp: Date(), value: loudnessLevel))
    }

    func updateLoudness(_ newValue: Double) {
        guard step == .matching else { return }
        guard isAmbientQuiet else { return }

        loudnessLevel = min(max(newValue, 0), 1)
        ToneGenerator.shared.setVolume(loudnessLevel)
        loudnessEvents.append((timestamp: Date(), value: loudnessLevel))
    }

    func submitMatch() async -> Bool {
        guard let startedAt else {
            errorMessage = "Task start timestamp is missing."
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let completedAt = Date()
        let baseTime = startedAt

        let loudnessTrace: [JSONValue] = loudnessEvents.map { event in
            .object([
                "offset_seconds": .number(event.timestamp.timeIntervalSince(baseTime)),
                "value": .number(event.value)
            ])
        }

        let ambientTrace: [JSONValue] = ambientEvents.map { event in
            .object([
                "offset_seconds": .number(event.timestamp.timeIntervalSince(baseTime)),
                "db": .number(event.value)
            ])
        }

        let gating: [String: JSONValue] = [
            "headphone_gate": .object([
                "route_name": .string(currentRoute?.name ?? ""),
                "route_port_type": .string(currentRoute?.portType ?? ""),
                "is_supported": .bool(isSupportedRoute)
            ]),
            "ambient": .object([
                "threshold_db": .number(StudyNo1Configuration.ambientThresholdDB),
                "db_at_submit": .number(ambientDB ?? -1),
                "within_threshold": .bool(isAmbientQuiet)
            ])
        ]

        let rawPayload: [String: JSONValue] = [
            "task_key": .string(scheduledTask.taskKey),
            "task_version": .number(Double(scheduledTask.taskVersion)),
            "matched_level": .number(loudnessLevel),
            "loudness_trace": .array(loudnessTrace),
            "ambient_trace": .array(ambientTrace)
        ]

        let deviceInfo: [String: JSONValue] = [
            "model": .string(UIDevice.current.model),
            "system_name": .string(UIDevice.current.systemName),
            "system_version": .string(UIDevice.current.systemVersion)
        ]

        let headphoneInfo: [String: JSONValue] = [
            "route_name": .string(currentRoute?.name ?? ""),
            "route_port_type": .string(currentRoute?.portType ?? "")
        ]

        do {
            try await studyService.submitLoudnessMatch(
                scheduledTaskID: scheduledTask.id,
                enrollmentID: enrollment.id,
                submission: LoudnessMatchSubmission(
                    startedAt: startedAt,
                    completedAt: completedAt,
                    matchedLevel: loudnessLevel,
                    gating: gating,
                    rawPayload: rawPayload,
                    deviceInfo: deviceInfo,
                    headphoneInfo: headphoneInfo,
                    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                    calibrationVersion: nil
                )
            )

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func enterAmbientGate() {
        step = .ambientGate

        if ambientPermissionStatus == .granted {
            startAmbientMonitoringIfNeeded()
        }
    }

    private func startAmbientMonitoringIfNeeded() {
        do {
            try ambientNoiseMonitor.startMonitoring { [weak self] db in
                guard let self else { return }
                self.ambientDB = db
                self.ambientEvents.append((timestamp: Date(), value: db))
                if self.ambientEvents.count > 2_000 {
                    self.ambientEvents.removeFirst(self.ambientEvents.count - 2_000)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct CircularDial: View {
    @Binding var value: Double
    let isEnabled: Bool

    private let minDegrees: Double = -150
    private let maxDegrees: Double = 150

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size * 0.36
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let angle = angleForValue(value)
            let knobPoint = point(for: angle, radius: radius, center: center)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                    .frame(width: radius * 2, height: radius * 2)

                Circle()
                    .trim(from: 0, to: CGFloat((value * 0.83) + 0.17))
                    .stroke(
                        isEnabled ? Color.blue : Color.gray,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(minDegrees + 90))
                    .frame(width: radius * 2, height: radius * 2)

                Circle()
                    .fill(isEnabled ? Color.blue : Color.gray)
                    .frame(width: 34, height: 34)
                    .position(knobPoint)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gestureValue in
                        guard isEnabled else { return }
                        value = valueForLocation(gestureValue.location, center: center)
                    }
            )
        }
    }

    private func angleForValue(_ value: Double) -> Double {
        minDegrees + ((maxDegrees - minDegrees) * min(max(value, 0), 1))
    }

    private func point(for angle: Double, radius: Double, center: CGPoint) -> CGPoint {
        let radians = (angle - 90) * .pi / 180
        return CGPoint(
            x: center.x + (radius * cos(radians)),
            y: center.y + (radius * sin(radians))
        )
    }

    private func valueForLocation(_ location: CGPoint, center: CGPoint) -> Double {
        let deltaX = location.x - center.x
        let deltaY = location.y - center.y

        var degrees = atan2(deltaY, deltaX) * 180 / .pi + 90
        if degrees < -180 {
            degrees += 360
        }
        if degrees > 180 {
            degrees -= 360
        }

        let clamped = min(max(degrees, minDegrees), maxDegrees)
        return (clamped - minDegrees) / (maxDegrees - minDegrees)
    }
}
