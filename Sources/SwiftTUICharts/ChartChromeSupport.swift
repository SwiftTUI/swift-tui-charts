import SwiftTUIViews

/// Semantic tone used by chart banners, badges, and accent surfaces.
public struct BannerTone: Hashable, Sendable {
  private let rawValue: String

  private init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public static let automatic = Self("automatic")
  public static let info = Self("info")
  public static let success = Self("success")
  public static let warning = Self("warning")
  public static let critical = Self("critical")
}

func metricAccentStyle(
  for tone: BannerTone
) -> AnyShapeStyle {
  toneAccentStyle(for: tone)
}

func sparklineGlyphString(
  _ values: [Double]
) -> String {
  guard !values.isEmpty else {
    return "[]"
  }

  let finite = values.filter(\.isFinite)
  let minimum = finite.min() ?? 0
  let maximum = finite.max() ?? 0
  guard maximum > minimum else {
    return values.map { $0.isFinite ? "▄" : " " }.joined()
  }

  let glyphs = Array("▁▂▃▄▅▆▇█")
  return values.map { value in
    guard value.isFinite else { return " " }
    let normalized = chartUnitFraction(value, in: minimum...maximum)
    let index = chartCellOffset(normalized, maximum: glyphs.count - 1)
    return String(glyphs[index])
  }.joined()
}

func sparklineSummaryText(
  _ values: [Double]
) -> String {
  let finite = values.filter(\.isFinite)
  guard let minimum = finite.min(), let maximum = finite.max() else {
    return "no data"
  }

  return "lo \(metricValueString(minimum)) hi \(metricValueString(maximum))"
}

func trendTone(
  value: Double,
  preferred: BannerTone
) -> BannerTone {
  guard preferred == .automatic else {
    return preferred
  }

  if value > 0 {
    return .success
  }
  if value < 0 {
    return .warning
  }
  return .info
}

private func toneAccentStyle(
  for tone: BannerTone
) -> AnyShapeStyle {
  switch tone {
  case .success:
    return AnyShapeStyle(.success)
  case .warning:
    return AnyShapeStyle(.warning)
  case .critical:
    return AnyShapeStyle(.warning)
  case .info:
    return AnyShapeStyle(.info)
  default:
    return AnyShapeStyle(.tint)
  }
}
