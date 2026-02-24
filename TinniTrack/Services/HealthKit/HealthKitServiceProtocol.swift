//
//  HealthKitServiceProtocol.swift
//  TinniTrack
//

import Foundation

protocol HealthKitServiceProtocol {
    /// Check if user has authorized HealthKit access
    func getAuthorizationStatus() -> HealthKitAuthorizationStatus
    
    /// Request permission to read hearing test data from Apple Health
    func requestHealthKitAuthorization() async throws
    
    /// Check if user has any existing hearing tests in Apple Health
    func hasExistingHearingTests() async throws -> Bool
    
    /// Fetch all hearing test audiograms from Apple Health
    func fetchAudiogramsFromHealthKit() async throws -> [HealthKitAudiogramSample]
}
