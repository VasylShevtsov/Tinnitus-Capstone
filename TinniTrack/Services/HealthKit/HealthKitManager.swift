//
//  HealthKitManager.swift
//  TinniTrack
//
//  HealthKit service implementation for fetching and importing hearing test data
//

import Foundation
import HealthKit

@MainActor
final class HealthKitManager: HealthKitServiceProtocol {
    private let healthStore = HKHealthStore()
    
    /// Standard audiogram frequencies (Hz)
    private static let standardFrequencies: [Double] = [250, 500, 1000, 2000, 3000, 4000, 6000, 8000]
    
    // Track if we've simulated authorization for testing
    private static var simulatedAuthorizationGranted = false
    
    // MARK: - HealthKitServiceProtocol Implementation
    
    func getAuthorizationStatus() -> HealthKitAuthorizationStatus {
        // For simulator/testing: if we simulated authorization, return authorized
        if Self.isSimulator() && Self.simulatedAuthorizationGranted {
            return .authorized
        }
        
        let audiogramType = HKObjectType.audiogramSampleType()
        let status = healthStore.authorizationStatus(for: audiogramType)
        
        switch status {
        case .notDetermined:
            return .notDetermined
        case .sharingDenied:
            return .denied
        case .sharingAuthorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    
    func requestHealthKitAuthorization() async throws {
        print("📱 [HealthKitManager] requestHealthKitAuthorization() called")
        
        // Simulator workaround for testing
        if Self.isSimulator() {
            print("📱 [HealthKitManager] Running on simulator - simulating authorization")
            Self.simulatedAuthorizationGranted = true
            print("📱 [HealthKitManager] simulatedAuthorizationGranted = true")
            return
        }
        
        print("📱 [HealthKitManager] Running on real device - requesting real HealthKit access")
        guard HKHealthStore.isHealthDataAvailable() else {
            print("📱 [HealthKitManager] HealthKit data not available")
            throw HealthKitError.noDataAvailable
        }
        
        let audiogramType = HKObjectType.audiogramSampleType()
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [audiogramType])
            print("📱 [HealthKitManager] Real authorization successful")
        } catch {
            print("📱 [HealthKitManager] Real authorization failed: \(error)")
            if getAuthorizationStatus() == .denied {
                throw HealthKitError.authorizationDenied
            }
            throw HealthKitError.queryFailed(error.localizedDescription)
        }
    }
    
    func hasExistingHearingTests() async throws -> Bool {
        let samples = try await fetchAudiogramsFromHealthKit()
        return !samples.isEmpty
    }
    
    func fetchAudiogramsFromHealthKit() async throws -> [HealthKitAudiogramSample] {
        print("📱 [HealthKitManager] fetchAudiogramsFromHealthKit() called")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("📱 [HealthKitManager] HealthKit data not available")
            throw HealthKitError.noDataAvailable
        }
        
        let status = getAuthorizationStatus()
        print("📱 [HealthKitManager] Authorization status: \(status)")
        
        switch status {
        case .denied:
            print("📱 [HealthKitManager] Authorization denied")
            throw HealthKitError.authorizationDenied
        case .notDetermined:
            print("📱 [HealthKitManager] Authorization not determined")
            throw HealthKitError.authorizationNotDetermined
        case .authorized:
            print("📱 [HealthKitManager] Authorization granted")
            break
        }
        
        // On simulator, return mock data for testing
        if Self.isSimulator() {
            print("📱 [HealthKitManager] Running on simulator - returning mock data")
            let mockData = Self.mockAudiogramSamples()
            print("📱 [HealthKitManager] Returned \(mockData.count) mock audiogram samples")
            return mockData
        }
        
        print("📱 [HealthKitManager] Running on real device - querying HealthKit")
        let audiogramType = HKObjectType.audiogramSampleType()
        let samples: [HKSample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: audiogramType,
                predicate: nil,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    print("📱 [HealthKitManager] Query error: \(error)")
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                } else {
                    print("📱 [HealthKitManager] Query returned \(samples?.count ?? 0) samples")
                    continuation.resume(returning: samples ?? [])
                }
            }
            
            healthStore.execute(query)
        }
        
        let audiogramSamples = samples.compactMap { sample -> HealthKitAudiogramSample? in
            guard let audiogram = sample as? HKAudiogramSample else {
                return nil
            }
            
            // Extract frequency-threshold pairs from HKAudiogramSample
            var pairs: [(frequency: Double, threshold: Double)] = []

            for point in audiogram.sensitivityPoints {
                let frequency = point.frequency.doubleValue(for: .hertz())

                // HKAudiogramSensitivityPoint exposes leftEarSensitivity and rightEarSensitivity.
                // Prefer the average when both are present; otherwise use the available ear.
                let left = point.leftEarSensitivity?.doubleValue(for: .decibelHearingLevel())
                let right = point.rightEarSensitivity?.doubleValue(for: .decibelHearingLevel())

                let threshold: Double?
                if let l = left, let r = right {
                    threshold = (l + r) / 2.0
                } else {
                    threshold = left ?? right
                }

                if let threshold { pairs.append((frequency, threshold)) }
            }

            guard !pairs.isEmpty else { return nil }

            // Sort by frequency to keep frequencies and thresholds aligned
            let sorted = pairs.sorted { $0.frequency < $1.frequency }
            let frequencies = sorted.map { $0.frequency }
            let thresholds = sorted.map { $0.threshold }

            return HealthKitAudiogramSample(
                date: audiogram.startDate,
                frequencies: frequencies,
                thresholds: thresholds,
                sourceApp: audiogram.sourceRevision.source.name
            )
        }
        
        print("📱 [HealthKitManager] Processed \(audiogramSamples.count) valid audiograms")
        return audiogramSamples
    }
    
    // MARK: - Private Helpers
    
    private static func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    private static func mockAudiogramSamples() -> [HealthKitAudiogramSample] {
        return [
            HealthKitAudiogramSample(
                date: Date(),
                frequencies: [250, 500, 1000, 2000, 3000, 4000, 6000, 8000],
                thresholds: [15, 20, 25, 30, 35, 40, 45, 50],
                sourceApp: "Health"
            )
        ]
    }
}

// MARK: - Mock Implementation for Testing

final class MockHealthKitManager: HealthKitServiceProtocol {
    var shouldReturnData = false
    var authorizationStatus = HealthKitAuthorizationStatus.authorized
    var shouldThrowError: HealthKitError?
    
    nonisolated func getAuthorizationStatus() -> HealthKitAuthorizationStatus {
        return authorizationStatus
    }
    
    nonisolated func requestHealthKitAuthorization() async throws {
        if let error = shouldThrowError {
            throw error
        }
    }
    
    nonisolated func hasExistingHearingTests() async throws -> Bool {
        if let error = shouldThrowError {
            throw error
        }
        return shouldReturnData
    }
    
    nonisolated func fetchAudiogramsFromHealthKit() async throws -> [HealthKitAudiogramSample] {
        if let error = shouldThrowError {
            throw error
        }
        
        guard shouldReturnData else {
            return []
        }
        
        // Return mock data
        return [
            HealthKitAudiogramSample(
                date: Date(),
                frequencies: [250, 500, 1000, 2000, 3000, 4000, 6000, 8000],
                thresholds: [20, 25, 30, 35, 40, 45, 50, 55],
                sourceApp: "Health"
            )
        ]
    }
}

