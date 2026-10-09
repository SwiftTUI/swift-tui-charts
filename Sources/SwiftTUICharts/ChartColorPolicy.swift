import SwiftTUIViews

func chartUsesColorCues(_ preferences: AccessibilityPreferences) -> Bool {
  preferences.differentiateWithoutColor == true || preferences.contrast == .increased
    || (preferences.colorProfile ?? .standard) != .standard
}

/// A textual tone cue stays useful with an unknown terminal palette and with
/// any simulated or user-selected color profile.
struct ChartToneCue: View {
  var tone: BannerTone
  @Environment(\.accessibilityPreferences) private var preferences

  var body: some View {
    if chartUsesColorCues(preferences), let name = chartDataTone(tone) {
      Text("[\(name)]").foregroundStyle(.foreground)
    }
  }
}
