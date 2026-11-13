import AuthenticationServices
import UIKit

final class CredentialProviderViewController: ASCredentialProviderViewController {
    private let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        label.numberOfLines = 0
        label.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        let scroll = UIScrollView(); scroll.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        let use = UIButton(type: .system); use.setTitle("Fill test credential", for: .normal)
        use.addTarget(self, action: #selector(fill), for: .touchUpInside)
        let cancel = UIButton(type: .system); cancel.setTitle("Cancel", for: .normal)
        cancel.addTarget(self, action: #selector(cancelTap), for: .touchUpInside)
        let bar = UIStackView(arrangedSubviews: [use, cancel])
        bar.distribution = .fillEqually; bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar); view.addSubview(scroll); scroll.addSubview(label)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: bar.bottomAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.topAnchor.constraint(equalTo: scroll.topAnchor),
            label.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 8),
            label.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -16)])
    }

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        let m0 = Probe.footprintMB(), a0 = Probe.availableMB()
        let core = spike_selftest()
        let m1 = Probe.footprintMB()
        label.text = "EXTENSION RAN\nfootprint start \(m0) MB, after rust selftest(\(core)) \(m1) MB, available \(a0) -> \(Probe.availableMB()) MB\n"
            + Probe.report(write: false, bio: true)
    }

    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userInteractionRequired.rawValue))
    }

    @objc private func fill() {
        extensionContext.completeRequest(withSelectedCredential: ASPasswordCredential(user: "spike", password: "spike"))
    }
    @objc private func cancelTap() {
        extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue))
    }
}
