public import Foundation

/// Calendar stride for the X axis when X is interpreted as a date.
public enum DateAxisStride: Hashable, Sendable {
  case day, week, month, quarter, year
}

/// The Y-axis anchor for `.area` and `.step` rasters.
public enum LineChartBaseline: Hashable, Sendable {
  /// Area and step fills use 0 as the anchor.
  /// If 0 is outside the visible Y range, the plot clips the fill.
  case zero
  /// Area and step fills use `min(Y)` across the visible series as the anchor.
  case auto
}

/// The X-axis configuration.
/// Use `.values(...)`, `.dates(...)`, `.automatic`, or `.hidden` to create this value.
/// Then use `.chartXAxis(_:)` to apply it to a `LineChart`.
public struct LineChartXAxis: Hashable, Sendable {
  public enum Ticks: Hashable, Sendable {
    /// The renderer selects ~5 evenly spaced ticks.
    case automatic
    /// The renderer selects exactly `N` evenly spaced ticks across the plot.
    case count(Int)
    /// The renderer selects approximately one tick for each `stride` of the domain.
    /// The renderer calculates the number of ticks from `span / stride`.
    /// Then it spaces the ticks evenly across the plot, not at exact multiples of `stride`.
    /// Use `.dates(every:)` to align ticks with calendar boundaries.
    case every(stride: Double)
    /// Aligns ticks with calendar boundaries of the specified stride, such as month starts.
    case dates(every: DateAxisStride)
  }

  public enum Format: Hashable, Sendable {
    case automatic
    case number(FloatingPointFormatStyle<Double>)
    case date(Date.FormatStyle)
  }

  public var ticks: Ticks
  public var format: Format
  public var isHidden: Bool

  public init(ticks: Ticks, format: Format, isHidden: Bool = false) {
    self.ticks = ticks
    self.format = format
    self.isHidden = isHidden
  }

  public static let automatic = Self(ticks: .automatic, format: .automatic)
  public static let hidden = Self(ticks: .automatic, format: .automatic, isHidden: true)

  public static func values(
    count: Int = 5,
    format: FloatingPointFormatStyle<Double> = .number
  ) -> Self {
    .init(ticks: .count(count), format: .number(format))
  }

  public static func dates(
    every stride: DateAxisStride,
    format: Date.FormatStyle = .dateTime
      .month(.abbreviated)
      .day()
      .locale(Locale(identifier: "en_US_POSIX"))
  ) -> Self {
    .init(ticks: .dates(every: stride), format: .date(format))
  }
}

/// The Y-axis configuration.
/// It has the same structure as `LineChartXAxis`, but it has no `.dates` tick or format variants.
public struct LineChartYAxis: Hashable, Sendable {
  public enum Ticks: Hashable, Sendable {
    /// The renderer selects ~5 evenly spaced ticks.
    case automatic
    /// The renderer selects exactly `N` evenly spaced ticks across the plot.
    case count(Int)
    /// The renderer selects approximately one tick for each `stride` of the domain.
    /// The renderer calculates the number of ticks from `span / stride`.
    /// Then it spaces the ticks evenly across the plot, not at exact multiples of `stride`.
    case every(stride: Double)
  }

  public var ticks: Ticks
  public var format: FloatingPointFormatStyle<Double>
  public var isHidden: Bool

  public init(
    ticks: Ticks,
    format: FloatingPointFormatStyle<Double> = .number.notation(.compactName),
    isHidden: Bool = false
  ) {
    self.ticks = ticks
    self.format = format
    self.isHidden = isHidden
  }

  public static let automatic = Self(ticks: .automatic)
  public static let hidden = Self(ticks: .automatic, isHidden: true)

  public static func values(
    count: Int = 5,
    format: FloatingPointFormatStyle<Double> = .number.notation(.compactName)
  ) -> Self {
    .init(ticks: .count(count), format: format)
  }
}

/// Legend strip placement around the chart body.
public struct LineChartLegendConfig: Hashable, Sendable {
  public enum Position: Hashable, Sendable { case top, bottom, hidden }

  public var position: Position
  public var itemSpacing: Int

  public init(position: Position, itemSpacing: Int = 2) {
    self.position = position
    self.itemSpacing = itemSpacing
  }

  public static let bottom = Self(position: .bottom)
  public static let top = Self(position: .top)
  public static let hidden = Self(position: .hidden)
}
