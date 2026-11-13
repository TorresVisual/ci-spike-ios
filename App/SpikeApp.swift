import SwiftUI

@main
struct SpikeApp: App {
    var body: some Scene {
        WindowGroup { Text("core selftest: \(spike_selftest())") }
    }
}
