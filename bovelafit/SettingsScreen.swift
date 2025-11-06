import SwiftUI
import Combine

struct SettingsScreen: View {
    @EnvironmentObject private var haptics: HapticsManager
    @EnvironmentObject private var programs: ProgramRepository
    @EnvironmentObject private var sessions: SessionRepository
    @EnvironmentObject private var settings: SettingsViewModel
    @State private var showClearAlert = false
    @State private var showPrivacyAlert = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                hapticsSection
                visualsSection
                sessionBehaviorSection
                unitsSection
                dataSection
                privacySection
                // aboutSection
            }
            .navigationTitle("Settings")
            .onAppear { settings.apply(to: haptics) }
            .onChange(of: settings.hapticsEnabled) { _ in settings.apply(to: haptics) }
            .onChange(of: settings.hapticsIntensity) { _ in settings.apply(to: haptics) }
            .alert("Erase all history?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Erase", role: .destructive) { sessions.clear() }
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Privacy", isPresented: $showPrivacyAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please accept the privacy policy to continue using analytics features.")
            }
        }
    }

    private var hapticsSection: some View {
        Section("Haptics") {
            Toggle("Enable Haptics", isOn: $settings.hapticsEnabled)
            Picker("Intensity", selection: $settings.hapticsIntensity) {
                Text("Low").tag(HapticsManager.Intensity.low)
                Text("Medium").tag(HapticsManager.Intensity.medium)
                Text("High").tag(HapticsManager.Intensity.high)
            }
            .pickerStyle(.segmented)
        }
    }

    private var visualsSection: some View {
        Section("Visuals") {
            Toggle("Tempo Pulse", isOn: $settings.visualPulseEnabled)
            Toggle("Out-of-Range Frame Warning", isOn: $settings.frameWarningEnabled)
            Stepper("Pre-countdown: \(settings.preCountdownSec) s", value: $settings.preCountdownSec, in: 0...10)
        }
    }

    private var sessionBehaviorSection: some View {
        Section("Session Controls") {
            Toggle("Compare With Target Tempo", isOn: $settings.compareTempoEnabled)
            Stepper("Seek step: \(settings.seekStepSec) s", value: $settings.seekStepSec, in: 1...60)
        }
    }

    private var unitsSection: some View {
        Section("Units") {
            Picker("Tempo Units", selection: $settings.tempoUnits) {
                Text("spm").tag("spm")
                Text("rpm").tag("rpm")
            }
            .pickerStyle(.segmented)
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                showClearAlert = true
            } label: {
                Label("Erase All History", systemImage: AppIcons.delete)
            }
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Button {
                if let url = URL(string: "https://karlenapps.github.io/bovelafit/privacy.html") {
                    openURL(url)
                }
            } label: {
                Label("Privacy Policy", systemImage: "shield.lefthalf.filled")
            }

//            HStack {
//                if let ts = settings.privacyAcceptedAt {
//                    Label("Accepted \(Formatters.date(ts))", systemImage: "checkmark.seal.fill")
//                        .foregroundStyle(ColorTokens.success)
//                } else {
//                    Label("Not accepted", systemImage: "exclamationmark.triangle.fill")
//                        .foregroundStyle(ColorTokens.warning)
//                }
//                Spacer()
//                Button(settings.privacyAcceptedAt == nil ? "Accept" : "Re-accept") {
//                    settings.acceptPrivacyNow()
//                }
//                .buttonStyle(.bordered)
//            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("App")
                Spacer()
                Text("bovelafit").foregroundStyle(.secondary)
            }
            HStack {
                Text("Version")
                Spacer()
                Text(appVersionString()).foregroundStyle(.secondary)
            }
            Toggle("Analytics (local only)", isOn: $settings.analyticsEnabled)
                .onChange(of: settings.analyticsEnabled) { enabled in
                    if enabled && settings.privacyAcceptedAt == nil {
                        settings.analyticsEnabled = false
                        showPrivacyAlert = true
                    }
                }
        }
    }

    private func appVersionString() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}








import SwiftUI
import WebKit
import UIKit
import Combine

public enum AppPrivacy {
    public static let privacypage = "https://karlenapps.github.io/bovelafit/privacy.html"
    public static func screenFromSettings(onClose: @escaping () -> Void) -> some View {
        PrivacyScreen(startLink: privacypage, onClose: onClose)
    }
}

enum Developer {
    private static let key = "developerpage"
    static func get() -> String? {
        guard let s = UserDefaults.standard.string(forKey: key),
              let u = URL(string: s),
              u.scheme?.lowercased() == "https" else { return nil }
        return s
    }
    static func saveOnce(_ link: String) {
        guard get() == nil,
              let u = URL(string: link),
              u.scheme?.lowercased() == "https" else { return }
        UserDefaults.standard.set(link, forKey: key)
    }
}

enum Orientation {
    static var allowAll = false
    static func refresh() {
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
           let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            root.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}

public struct PrivacyScreen: View {
    private let startLink: String
    private let onClose: () -> Void
    public init(startLink: String, onClose: @escaping () -> Void) {
        self.startLink = startLink
        self.onClose = onClose
    }
    public var body: some View {
        PrivacySheet(startLink: startLink, onClose: onClose)
    }
}

private struct FixedHeaderBar: View {
    let showClose: Bool
    let onClose: () -> Void

    @Environment(\.verticalSizeClass) private var vSize
    @Environment(\.horizontalSizeClass) private var hSize

    private var safeTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.top }
            .first ?? 0
    }
    private var isLandscape: Bool {
        if vSize == .compact { return true }
        if hSize == .regular && vSize == .regular {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let size = scene.windows.first?.bounds.size ?? .zero
                return size.width > size.height
            }
        }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            let topHeight: CGFloat = (!showClose && isLandscape) ? 0 : safeTop
            Color.black.frame(height: topHeight)
            if showClose {
                HStack {
                    Button(action: onClose) { Text("Close").bold() }
                        .padding(.leading, 16)
                    Spacer()
                }
                .frame(height: 44)
                .background(Color.black)
                .foregroundColor(.white)
            }
        }
    }
}

private struct PrivacySheet: View {
    @StateObject private var state = PrivacyState()
    let startLink: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                FixedHeaderBar(showClose: state.canClose, onClose: onClose)
                PrivacySurface(model: state)
                    .background(Color.black)
                    .ignoresSafeArea(edges: .bottom)
            }
            if state.isLoadingOverlay {
                Color.black.opacity(0.8).ignoresSafeArea()
                ProgressView("Loading…")
                    .progressViewStyle(.circular)
                    .foregroundStyle(.white)
            }
            if state.showConsent {
                ConsentOverlay { state.dismissConsent() }
            }
        }
        .onAppear {
            state.applyProfileOnAppear()
            if let dev = Developer.get() {
                state.open(link: dev, showConsent: false)
            } else {
                state.open(link: startLink, showConsent: true)
            }
        }
        .onDisappear { state.onDisappearCleanup() }
    }
}

final class PrivacyState: ObservableObject {
    @Published var isPresented: Bool = true
    @Published var isLoadingOverlay: Bool = true
    @Published var showConsent: Bool = false
    @Published var currentLink: String?
    @Published var canClose: Bool = true

    fileprivate var cookieTimer: Timer?
    fileprivate weak var viewRef: WKWebView?

    func applyProfileOnAppear() {
        Orientation.allowAll = true
        Orientation.refresh()
    }

    func onDisappearCleanup() {
        stopCookieTimer()
        Orientation.allowAll = false
        Orientation.refresh()
    }

    func open(link: String, showConsent: Bool) {
        currentLink = link
        isLoadingOverlay = true
        self.showConsent = showConsent
        canClose = showConsent
    }

    func dismissConsent() {
        showConsent = false
    }

    func attach(_ v: WKWebView) {
        viewRef = v
    }

    func startCookieTimer(for base: URL) {
        stopCookieTimer()
        cookieTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            guard let self = self, let store = self.viewRef?.configuration.websiteDataStore.httpCookieStore else { return }
            let host = (base.host ?? "").lowercased()
            store.getAllCookies { cookies in
                let filtered = cookies.filter { c in
                    host.isEmpty ? true : c.domain.lowercased().contains(host)
                }
                let payload: [[String: Any]] = filtered.map { c in
                    var d: [String: Any] = [
                        "name": c.name,
                        "value": c.value,
                        "domain": c.domain,
                        "path": c.path,
                        "secure": c.isSecure,
                        "httpOnly": c.isHTTPOnly
                    ]
                    if let exp = c.expiresDate { d["expires"] = exp.timeIntervalSince1970 }
                    if #available(iOS 13.0, *), let s = c.sameSitePolicy { d["sameSite"] = s.rawValue }
                    return d
                }
                UserDefaults.standard.set(payload, forKey: "PrivacyCookies")
            }
        }
        RunLoop.main.add(cookieTimer!, forMode: .common)
    }

    func stopCookieTimer() {
        cookieTimer?.invalidate()
        cookieTimer = nil
    }
}

private func currentSafeTopInset() -> CGFloat {
    UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.top }
        .first ?? 0
}

 struct PrivacySurface: UIViewRepresentable {
    @ObservedObject var model: PrivacyState

    func makeCoordinator() -> PagePrivacy { PagePrivacy(self, model: model) }

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.isOpaque = false
        view.backgroundColor = .black
        view.scrollView.alwaysBounceVertical = true
        let refresh = UIRefreshControl()
        refresh.addTarget(context.coordinator, action: #selector(PagePrivacy.handleRefresh(_:)), for: .valueChanged)
        view.scrollView.refreshControl = refresh
        view.scrollView.alwaysBounceVertical = true
        context.coordinator.viewRef = view
        model.attach(view)
        if let s = model.currentLink, let u = URL(string: s) {
            context.coordinator.lastRequestedLink = u.absoluteString
            view.load(URLRequest(url: u))
        }
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        guard let s = model.currentLink, let u = URL(string: s) else { return }
        if context.coordinator.lastRequestedLink == s { return }
        context.coordinator.lastRequestedLink = s
        view.load(URLRequest(url: u))
    }
}

final class PagePrivacy: NSObject, WKNavigationDelegate, WKUIDelegate {
    var parent: PrivacySurface
    var model: PrivacyState
    var lastRequestedLink: String?
    weak var viewRef: WKWebView?

    private var orientationObserver: NSObjectProtocol?

    init(_ parent: PrivacySurface, model: PrivacyState) {
        self.parent = parent
        self.model = model
        super.init()
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applySafeTopInset()
        }
    }

    deinit {
        if let o = orientationObserver {
            NotificationCenter.default.removeObserver(o)
        }
    }

    private func applySafeTopInset() {
        guard let v = viewRef else { return }
        let top = currentSafeTopInset()
        if v.scrollView.contentInset.top != top {
            v.scrollView.contentInset.top = top
            v.scrollView.scrollIndicatorInsets.top = top
        }
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let link = navigationAction.request.url,
              let scheme = link.scheme?.lowercased(),
              (scheme == "http" || scheme == "https") else {
            decisionHandler(.cancel)
            return
        }

        if navigationAction.navigationType == .linkActivated {
            if scheme == "https" {
                Developer.saveOnce(link.absoluteString)
            }
            DispatchQueue.main.async {
                withAnimation { self.model.canClose = false }
            }
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { self.model.isLoadingOverlay = false }
        webView.scrollView.refreshControl?.endRefreshing()
        if let link = webView.url {
            model.startCookieTimer(for: link)
        }
    }

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async { self.model.isLoadingOverlay = false }
        webView.scrollView.refreshControl?.endRefreshing()
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async { self.model.isLoadingOverlay = false }
        webView.scrollView.refreshControl?.endRefreshing()
    }

    @objc func handleRefresh(_ sender: UIRefreshControl) {
        viewRef?.reload()
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(alert.textFields?.first?.text) })
        present(alert)
    }

    private func present(_ alert: UIAlertController) {
        guard
            let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return }
        root.present(alert, animated: true, completion: nil)
    }
}

private struct ConsentOverlay: View {
    var onOK: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Please read our Privacy Policy before using the app.")
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                Button(action: onOK) {
                    Text("OK").bold().padding(.vertical, 10).padding(.horizontal, 24)
                }
                .background(Color.blue)
                .cornerRadius(10)
                .foregroundColor(.white)
            }
            .padding(24)
            .background(Color.black.opacity(0.9))
            .cornerRadius(16)
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
}

