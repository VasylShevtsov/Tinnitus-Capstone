//
//  HealthKitModels.swift
//  TinniTrack
//

import Foundation

// MARK: - Data Transfer Objects

/// Represents hearing test data from Apple Health or in-app testing
struct AudiogramData: Codable, Equatable {
    let source: String  // "apple_health" or "in_app_test"
    let measuredAt: Date
    let frequencyData: [String: Double]  // e.g., ["250": 20.0, "500": 25.0, "1000": 30.0]
    let headphoneName: String
    
    enum CodingKeys: String, CodingKey {
        case source
        case measuredAt = "measured_at"
        case frequencyData = "frequency_data"
        case headphoneName = "headphone_name"
    }
}

/// Represents a hearing test sample from Apple Health
struct HealthKitAudiogramSample {
    let date: Date
    let frequencies: [Double]  // Hz values
    let thresholds: [Double]   // dB values corresponding to frequencies
    let sourceApp: String
}

// MARK: - HealthKit Service Errors

enum HealthKitError: LocalizedError {
    case authorizationDenied
    case authorizationNotDetermined
    case noDataAvailable
    case queryFailed(String)
    case invalidData(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Apple Health access was denied. You can enable it in Settings."
        case .authorizationNotDetermined:
            return "Apple Health authorization is pending."
        case .noDataAvailable:
            return "No hearing test data found in Apple Health."
        case .queryFailed(let reason):
            return "Failed to query Apple Health: \(reason)"
        case .invalidData(let reason):
            return "Invalid health data: \(reason)"
        case .saveFailed(let reason):
            return "Failed to save audiogram: \(reason)"
        }
    }
}

// MARK: - HealthKit Authorization Status

enum HealthKitAuthorizationStatus: Equatable {
    case notDetermined
    case denied
    case authorized
}
