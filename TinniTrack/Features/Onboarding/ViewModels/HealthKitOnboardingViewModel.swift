//
//  HealthKitOnboardingViewModel.swift
//  TinniTrack
//

import Foundation
import Combine
import UIKit

@MainActor
final class HealthKitOnboardingViewModel: ObservableObject {
        /// Opens the Apple Health app using the public URL scheme.
        func openHealthApp() {
            if let url = URL(string: "x-apple-health://") {
                UIApplication.shared.open(url)
            }
        }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasHealthKitData = false
    @Published var healthKitDataCount = 0
    
    private let healthKitService: HealthKitServiceProtocol
    
    init(healthKitService: HealthKitServiceProtocol) {
        self.healthKitService = healthKitService
        Task {
            await checkForHealthKitData()
        }
    }

    convenience init() {
        self.init(healthKitService: HealthKitManager())
    }
    
    func onAppear() {
        Task { [weak self] in
            await self?.checkForHealthKitData()
        }
    }
    
    func checkForHealthKitData() async {
        print("🟢 [ViewModel] checkForHealthKitData() called")
        isLoading = true
        errorMessage = nil
        
        do {
            print("🟢 [ViewModel] Fetching audiograms from HealthKit...")
            let samples = try await healthKitService.fetchAudiogramsFromHealthKit()
            print("🟢 [ViewModel] Fetched \(samples.count) samples")
            
            hasHealthKitData = !samples.isEmpty
            healthKitDataCount = samples.count
            
            print("🟢 [ViewModel] hasHealthKitData = \(hasHealthKitData), count = \(healthKitDataCount)")
        } catch let error as HealthKitError {
            print("🟡 [ViewModel] HealthKit error: \(error.localizedDescription)")
            // Don't show error for "not determined" - just show no data
            switch error {
            case .authorizationNotDetermined:
                hasHealthKitData = false
                healthKitDataCount = 0
            default:
                errorMessage = error.localizedDescription
                hasHealthKitData = false
            }
        } catch {
            print("🔴 [ViewModel] Unexpected error: \(error.localizedDescription)")
            // For other errors, treat as "no data available"
            hasHealthKitData = false
            healthKitDataCount = 0
        }
        
        isLoading = false
    }
    
    func requestHealthKitAuthorization() async {
        print("🟢 [ViewModel] requestHealthKitAuthorization() called")
        isLoading = true
        errorMessage = nil
        
        do {
            print("🟢 [ViewModel] Requesting authorization from service...")
            try await healthKitService.requestHealthKitAuthorization()
            print("🟢 [ViewModel] Authorization successful")
            await checkForHealthKitData()
        } catch let error as HealthKitError {
            print("🟡 [ViewModel] HealthKit auth error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            print("🔴 [ViewModel] Unexpected auth error: \(error.localizedDescription)")
            errorMessage = "Failed to request HealthKit access."
        }
        
        isLoading = false
    }
    
    func convertToAudiogramData(from samples: [HealthKitAudiogramSample]) -> [AudiogramData] {
        return samples.map { sample in
            var frequencyData: [String: Double] = [:]
            for (frequency, threshold) in zip(sample.frequencies, sample.thresholds) {
                frequencyData[String(Int(frequency))] = threshold
            }
            
            return AudiogramData(
                source: "apple_health",
                measuredAt: sample.date,
                frequencyData: frequencyData,
                headphoneName: sample.sourceApp
            )
        }
    }
}
