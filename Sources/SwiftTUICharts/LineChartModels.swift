public import Foundation

/// A `(x, y)` point in a line chart's continuous coordinate space.
public struct LineChartPoint: Hashable, Sendable {
  public var x: Double
  public var y: Double

  public init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }
}

extension LineChartPoint {
  /// Maps a `Date` to `x` with `timeIntervalSinceReferenceDate`.
  /// The X-axis formatter decides whether to show `x` as a date or a number.
  public init(date: Date, value: Double) {
    self.init(x: date.timeIntervalSinceReferenceDate, y: value)
  }
}

/// Rendering style for a single `LineChartSeries`.
public enum LineChartSeriesStyle: Hashable, Sendable {
  /// Single-cell line raster between consecutive samples.
  case line
  /// Includes the complete `.line` rendering and adds a shaded fill from the line to the chart baseline.
  case area
  /// Draws a horizontal segment at the Y value of each sample.
  /// Then it draws a vertical segment to the Y value of the next sample.
  case step
}

/// A series of `LineChartPoint` values with a label and tone.
public struct LineChartSeries: Hashable, Sendable {
  public var label: String
  public var points: [LineChartPoint]
  public var style: LineChartSeriesStyle
  public var tone: BannerTone

  public init<S: StringProtocol>(
    _ label: S,
    points: [LineChartPoint],
    style: LineChartSeriesStyle = .line,
    tone: BannerTone = .automatic
  ) {
    self.label = String(label)
    self.points = points
    self.style = style
    self.tone = tone
  }
}
