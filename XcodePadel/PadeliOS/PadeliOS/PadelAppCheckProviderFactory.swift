import Foundation
import FirebaseCore
import FirebaseAppCheck

class PadelAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        // In Debug mode, use the Debug Provider.
        // This prints a UUID to the console which must be added to the Firebase Console.
        return AppCheckDebugProvider(app: app)
        #else
        // In Production/Release, use App Attest (modern)
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            // Fallback for older iOS versions if needed, though PadelScore targets iOS 17+
            return DeviceCheckProvider(app: app)
        }
        #endif
    }
}
