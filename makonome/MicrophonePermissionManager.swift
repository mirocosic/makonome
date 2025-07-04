import AVFoundation
import Foundation

class MicrophonePermissionManager: ObservableObject {
    @Published var permissionStatus: AVAudioSession.RecordPermission = .undetermined
    
    init() {
        updatePermissionStatus()
    }
    
    func updatePermissionStatus() {
        permissionStatus = AVAudioSession.sharedInstance().recordPermission
    }
    
    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.updatePermissionStatus()
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    var isPermissionGranted: Bool {
        return permissionStatus == .granted
    }
    
    var isPermissionDenied: Bool {
        return permissionStatus == .denied
    }
    
    var isPermissionUndetermined: Bool {
        return permissionStatus == .undetermined
    }
}