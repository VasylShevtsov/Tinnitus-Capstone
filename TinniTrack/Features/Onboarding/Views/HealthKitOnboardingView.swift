//
//  HealthKitOnboardingView.swift
//  TinniTrack
//

import SwiftUI

@MainActor
struct HealthKitOnboardingView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var viewModel: HealthKitOnboardingViewModel
    
    init(healthKitService: HealthKitServiceProtocol? = nil) {
        _viewModel = StateObject(wrappedValue: HealthKitOnboardingViewModel(healthKitService: healthKitService ?? HealthKitManager()))
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Scrollable content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        // Hero Section
                        heroSection

                        if let errorMessage = viewModel.errorMessage {
                            errorSection(message: errorMessage)
                        }
                        
                        // Content based on state
                        if viewModel.isLoading {
                            loadingSection
                        } else if viewModel.hasHealthKitData {
                            dataFoundSection
                        } else {
                            noDataSection
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                }
                
                // Fixed Action Buttons at bottom
                Divider()
                    .padding(.vertical, 12)
                
                VStack(spacing: 12) {
                    if viewModel.isLoading {
                        loadingButton
                    } else if viewModel.hasHealthKitData {
                        importButton
                    } else {
                        connectButton
                    }
                    
                    skipButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Health")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(red: 1.0, green: 0.2, blue: 0.2))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connect Apple Health")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundStyle(.primary)
                    
                    Text("Import your hearing tests")
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Content Sections
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.1, anchor: .center)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Checking Apple Health")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text("This may take a moment")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var dataFoundSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hearing Tests Found")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text("\(viewModel.healthKitDataCount) test\(viewModel.healthKitDataCount == 1 ? "" : "s") available for import")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("What happens next:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    infoRow("1", "Your tests will be imported securely")
                    infoRow("2", "Data is encrypted in transit")
                    infoRow("3", "Used only for this research study")
                }
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var noDataSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ready to Connect")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text("Grant access to Apple Health")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    infoRow("•", "Authorization is secure and encrypted")
                    infoRow("•", "You can revoke access anytime in Settings")
                    infoRow("•", "Your privacy is fully protected")
                }
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private func errorSection(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
    
    private func infoRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(3)
            
            Spacer()
        }
    }
    
    // MARK: - Buttons
    
    private var connectButton: some View {
        Button(action: grantAccessAndCheck) {
            HStack(spacing: 8) {
                Image(systemName: "lock.open.fill")
                Text("Connect Apple Health")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading || sessionStore.state.isBusy)
    }
    
    private var importButton: some View {
        Button(action: importHealthData) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.doc.fill")
                Text("Import Hearing Tests")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.green)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading || sessionStore.state.isBusy)
    }
    
    private var loadingButton: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
            Text("Processing...")
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color.gray)
        .cornerRadius(12)
    }
    
    private var skipButton: some View {
        Button(action: skipHealthKit) {
            Text("Skip for Now")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
        .disabled(sessionStore.state.isBusy)
    }
    
    // MARK: - Actions
    
    private func grantAccessAndCheck() {
        print("🔵 Connect Apple Health tapped")
        Task {
            await viewModel.requestHealthKitAuthorization()
        }
    }
    
    private func importHealthData() {
        print("🟢 Import Health Data tapped")
        Task {
            do {
                let healthKitManager = HealthKitManager()
                let samples = try await healthKitManager.fetchAudiogramsFromHealthKit()
                
                if !samples.isEmpty {
                    let audiograms = viewModel.convertToAudiogramData(from: samples)
                    await sessionStore.completeHealthKitSetup(with: audiograms)
                } else {
                    await sessionStore.skipHealthKitSetup()
                }
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func skipHealthKit() {
        print("⏭️ Skip Health Kit tapped")
        Task {
            await sessionStore.skipHealthKitSetup()
        }
    }
}

#Preview {
    HealthKitOnboardingView()
        .environmentObject(SessionStore(authService: SupabaseAuthService(), profileService: SupabaseProfileService()))
}
