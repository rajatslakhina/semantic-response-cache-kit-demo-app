import SwiftUI
import SemanticResponseCache
import SemanticResponseCacheUI

/// The demo app for `semantic-response-cache-kit`.
///
/// The app owns the launch configuration and hands it to the library's
/// explorer view. That split is deliberate: "what does this screen show on
/// launch" is a product decision and belongs to the app, not to a library
/// initializer. It is also why this file imports `SemanticResponseCache` as
/// well as `SemanticResponseCacheUI` — the defaults below are validated
/// against the core module's own `CachePolicy` / `ShadowConfiguration`
/// rules (via `ExplorerDefaults.init`) before the view ever sees them, and
/// the fallback screen reports the core module's `CacheError` if they fail.
@main
struct DemoApp: App {

    var body: some Scene {
        WindowGroup {
            switch DemoApp.launch {
            case .success(let defaults):
                SemanticCacheExplorerView(defaults: defaults)
            case .failure(let error):
                // Unreachable with the constants below (see `launch`), but a
                // configuration error must degrade to a readable screen, never
                // to a crash at launch.
                ContentUnavailableFallback(message: DemoApp.describe(error))
            }
        }
    }

    /// Threshold 0.50 — the right neighbourhood for the bundled
    /// `HashedTrigramEmbedder`; the server-side 0.92 is a hit rate of zero
    /// with it, and the slider lets you prove that. A 16-entry budget so the
    /// 30-prompt trace actually evicts. Shadow sampling at 100% so every
    /// semantic hit is verified and the false-hit interval fills in (production
    /// would sample at 2–5%). A 250 ms simulated generation so the break-even
    /// line has something to measure against.
    ///
    /// `ExplorerDefaults.init` throws for any value the cache would refuse:
    /// threshold outside (0, 1], budget < 1, sample rate outside [0, 1],
    /// latency outside [0, 5000] ms. None of these constants trips it, so the
    /// `.failure` branch is unreachable as written — it exists so that editing
    /// the constants can never turn a typo into a launch crash.
    static let launch: Result<ExplorerDefaults, any Error> = Result {
        try ExplorerDefaults(threshold: 0.50,
                             maxEntries: 16,
                             shadowSampleRate: 1.0,
                             generatorLatencyMilliseconds: 250,
                             useCoverageEviction: true)
    }

    static func describe(_ error: any Error) -> String {
        if let cacheError = error as? CacheError {
            switch cacheError {
            case .invalidThreshold(let value): return "Invalid similarity threshold: \(value)"
            case .invalidBudget(let message): return "Invalid budget: \(message)"
            case .invalidSampleRate(let rate): return "Invalid shadow sample rate: \(rate)"
            }
        }
        return String(describing: error)
    }
}

/// Shown only if the launch configuration is rejected by the library.
struct ContentUnavailableFallback: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
            Text("The demo configuration was rejected by SemanticResponseCache.")
                .multilineTextAlignment(.center)
            Text(message)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
