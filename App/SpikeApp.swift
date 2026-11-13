import SwiftUI

@main
struct SpikeApp: App {
    @State private var text = "tap Run"
    var body: some Scene {
        WindowGroup {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("rust core selftest: \(spike_selftest())")
                    Text("footprint \(Probe.footprintMB(), specifier: "%.1f") MB, available \(Probe.availableMB(), specifier: "%.0f") MB")
                    Button("Run probes (writes items)") { text = Probe.report(write: true) }
                    Button("Read Face ID items") { text = Probe.report(write: false, bio: true) }
                    Button("Show extension result") {
                        text = Probe.group().flatMap { try? String(contentsOf: $0.url.appendingPathComponent("ext.txt"), encoding: .utf8) } ?? "no ext.txt"
                    }
                    Text(text).font(.system(size: 11, design: .monospaced)).textSelection(.enabled)
                }.padding()
            }
        }
    }
}
