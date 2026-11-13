import Foundation
import Security
import LocalAuthentication
import os

/// Capability probes shared by the app and the AutoFill extension.
enum Probe {
    static let service = "spike", shared = "dev.example.spike.shared"

    static func provision() -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let s = String(data: data, encoding: .isoLatin1),
              let a = s.range(of: "<?xml"), let b = s.range(of: "</plist>"),
              let xml = String(s[a.lowerBound..<b.upperBound]).data(using: .isoLatin1) else { return nil }
        return (try? PropertyListSerialization.propertyList(from: xml, format: nil)) as? [String: Any]
    }
    static var prefix: String? { (provision()?["ApplicationIdentifierPrefix"] as? [String])?.first }
    static var profileEnts: [String: Any] { provision()?["Entitlements"] as? [String: Any] ?? [:] }
    static var groups: [String] { profileEnts["com.apple.security.application-groups"] as? [String] ?? [] }

    static func footprintMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let r = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return r == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : -1
    }
    static func availableMB() -> Double { Double(os_proc_available_memory()) / 1_048_576 }

    static func group() -> (id: String, url: URL)? {
        for g in groups {
            if let u = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: g) { return (g, u) }
        }
        return nil
    }

    static func base(_ group: String?, _ bio: Bool) -> [String: Any] {
        var q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
                                kSecAttrAccount as String: bio ? "bio" : "plain"]
        if let g = group { q[kSecAttrAccessGroup as String] = g }
        return q
    }
    static func kcWrite(_ group: String?, bio: Bool) -> OSStatus {
        var q = base(group, bio)
        SecItemDelete(q as CFDictionary)
        q[kSecValueData as String] = Data("secret".utf8)
        if bio {
            guard let ac = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .biometryCurrentSet, nil) else { return -1 }
            q[kSecAttrAccessControl as String] = ac
        } else {
            q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        }
        return SecItemAdd(q as CFDictionary, nil)
    }
    static func kcRead(_ group: String?, bio: Bool) -> OSStatus {
        var q = base(group, bio)
        q[kSecReturnData as String] = true
        if bio { let c = LAContext(); c.localizedReason = "spike"; q[kSecUseAuthenticationContext as String] = c }
        var out: CFTypeRef?
        return SecItemCopyMatching(q as CFDictionary, &out)
    }
    static var candidates: [String?] { [nil, prefix.map { "\($0).\(shared)" }, shared] }

    /// Environment, file and keychain probes. write = true in the app (creates items), false in the extension (reads them).
    static func report(write: Bool, bio: Bool = false) -> String {
        let prov = provision()
        var l = ["bundle: \(Bundle.main.bundleIdentifier ?? "?")",
                 "team prefix: \(prefix ?? "none")",
                 "profile: \((prov?["Name"] as? String) ?? "none")  expires: \(String(describing: prov?["ExpirationDate"] ?? "?"))",
                 "profile app groups: \(groups)",
                 "profile keychain groups: \(profileEnts["keychain-access-groups"] ?? "none")",
                 "profile autofill-credential-provider: \(profileEnts["com.apple.developer.authentication-services.autofill-credential-provider"] ?? "ABSENT")",
                 "profile entitlement keys: \(profileEnts.keys.sorted())"]
        if let g = group() {
            let mine = g.url.appendingPathComponent(write ? "app.txt" : "ext.txt")
            let other = g.url.appendingPathComponent(write ? "ext.txt" : "app.txt")
            try? "\(Date())".write(to: mine, atomically: true, encoding: .utf8)
            let seen = (try? String(contentsOf: other, encoding: .utf8)) ?? "not found"
            l.append("group container OK: \(g.id); wrote \(mine.lastPathComponent); other side's file: \(seen)")
        } else {
            l.append("group container: UNAVAILABLE")
        }
        for c in candidates {
            let name = c ?? "(default)"
            if write { l.append("keychain plain write [\(name)]: \(kcWrite(c, bio: false))") }
            l.append("keychain plain read [\(name)]: \(kcRead(c, bio: false))")
            if write { l.append("keychain bio write [\(name)]: \(kcWrite(c, bio: true))") }
            if bio { l.append("keychain bio read [\(name)]: \(kcRead(c, bio: true))") }
        }
        return l.joined(separator: "\n")
    }
}
