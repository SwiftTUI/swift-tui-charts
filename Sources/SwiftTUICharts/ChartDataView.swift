import SwiftTUIViews

/// One named source value in a chart or a custom graphic's data alternative.
public struct ChartDataRecord: Hashable, Sendable {
  /// The category, coordinate or event name.
  public var category: String
  /// The series name, if the source has multiple series.
  public var series: String?
  /// The exact numeric value, or nil for descriptive records and missing data.
  public var value: Double?
  /// Additional meaning such as a baseline, threshold or event detail.
  public var detail: String?
  /// The value's unit. A record unit overrides the inherited chart unit.
  public var unit: String?
  /// Optional stable source identity, independent of the displayed value.
  public var id: String?

  /// Creates a numeric or descriptive source record.
  public init(
    _ category: String, value: Double? = nil, series: String? = nil,
    detail: String? = nil, unit: String? = nil, id: String? = nil
  ) {
    self.category = category
    self.value = value
    self.series = series
    self.detail = detail
    self.unit = unit
    self.id = id
  }
}

private enum ChartDataUnitKey: EnvironmentKey {
  static let defaultValue: String? = nil
}

extension EnvironmentValues {
  var chartDataUnit: String? {
    get { self[ChartDataUnitKey.self] }
    set { self[ChartDataUnitKey.self] = newValue }
  }
}

extension View {
  /// Supplies units for built-in chart data when the numeric source cannot infer them.
  public func chartDataUnit(_ unit: String?) -> some View {
    environment(\.chartDataUnit, unit)
  }
}

/// A bounded, stateful data alternative with direct position, search and comparison.
///
/// Built-in charts use this view as semantic children without adding visual rows.
/// Applications can also display it directly, or use it in an accessibility
/// representation for a custom graphic. Review never changes application data.
public struct ChartDataView: View {
  private let records: [ChartDataRecord]
  private let identities: [String]
  private let positions: [String: Int]
  private let title: String
  @Environment(\.chartDataUnit) private var inheritedUnit
  @State private var currentID: String?
  @State private var rememberedID: String?
  @State private var query = ""
  @State private var searchRan = false
  @State private var searchMatchID: String?

  /// Creates a data review. Duplicate category/series keys or IDs use occurrence order.
  /// Supply unique explicit IDs when duplicates need identity across reordering.
  public init(_ records: [ChartDataRecord], title: String = "Chart data") {
    self.records = records
    self.title = title
    var occurrences: [String: Int] = [:]
    var identities: [String] = []
    var positions: [String: Int] = [:]
    for (index, record) in records.enumerated() {
      let series = record.series ?? ""
      let key =
        record.id.map { "explicit:\($0)" }
        ?? "implicit:\(series.utf8.count):\(series)\(record.category.utf8.count):\(record.category)"
      let occurrence = occurrences[key, default: 0]
      occurrences[key] = occurrence + 1
      let identity = "\(key)#\(occurrence)"
      identities.append(identity)
      positions[identity] = index
    }
    self.identities = identities
    self.positions = positions
  }

  private var currentIndex: Int? {
    currentID.flatMap { positions[$0] } ?? (records.isEmpty ? nil : 0)
  }
  private var rememberedIndex: Int? { rememberedID.flatMap { positions[$0] } }
  private var position: Binding<Double> {
    Binding(
      get: { Double((currentIndex ?? 0) + 1) },
      set: { value in
        guard value.isFinite, value.rounded() == value,
          value >= 1, value <= Double(records.count)
        else { return }
        currentID = identities[Int(value) - 1]
      })
  }
  private func description(_ index: Int) -> String {
    let record = records[index]
    var parts = [record.category]
    if let series = record.series, !series.isEmpty { parts.append("Series \(series)") }
    if let value = record.value {
      parts.append(value.isFinite ? "Value \(String(value))" : "Missing data")
      if let unit = record.unit ?? inheritedUnit, !unit.isEmpty { parts.append(unit) }
    }
    if let detail = record.detail, !detail.isEmpty { parts.append(detail) }
    return parts.joined(separator: ", ")
  }
  private func findNext() {
    guard !records.isEmpty, !query.isEmpty else { return }
    searchRan = true
    let needle = query.lowercased()
    let start = currentIndex ?? -1
    for offset in 1...records.count {
      let index = (start + offset) % records.count
      if description(index).lowercased().contains(needle) {
        currentID = identities[index]
        searchMatchID = identities[index]
        return
      }
    }
    searchMatchID = nil
  }
  private var searchResult: String {
    guard searchRan else { return "" }
    guard let searchMatchID else { return "No matching data" }
    guard let index = positions[searchMatchID] else { return "Search match removed" }
    return "Found \(description(index))"
  }
  private var comparison: String {
    guard let current = currentIndex, let remembered = rememberedIndex else {
      return rememberedID == nil ? "No remembered point" : "Remembered point removed"
    }
    var result = "Remembered: \(description(remembered))"
    let lhs = records[current]
    let rhs = records[remembered]
    if let currentValue = lhs.value, let referenceValue = rhs.value,
      currentValue.isFinite, referenceValue.isFinite,
      (lhs.unit ?? inheritedUnit) == (rhs.unit ?? inheritedUnit)
    {
      let difference = currentValue - referenceValue
      if difference.isFinite {
        result += "; difference \(String(difference))"
        if let unit = lhs.unit ?? inheritedUnit, !unit.isEmpty { result += " \(unit)" }
      }
    }
    return result
  }
  private func reading(_ text: String) -> some View {
    Text(text).accessibilityLabel(text).accessibilityProperties(.init(textKind: .plain))
  }

  /// Presents one current record and one remembered record, independent of source size.
  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      reading("\(records.count) data records")
      if let index = currentIndex {
        Stepper("Data position", value: position, in: 1...Double(records.count), step: 1)
          .accessibilityProperties(.init(valueDescription: description(index)))
        reading("Current: \(description(index))")
        if let currentID, positions[currentID] == nil {
          reading("Current point removed; reviewing first point")
        }
        HStack {
          Button("First point") { currentID = identities.first }
          Button("Last point") { currentID = identities.last }
          Button("Remember point") { rememberedID = identities[index] }
          Button("Return to remembered point") { currentID = rememberedID }
            .disabled(rememberedIndex == nil)
        }
        reading(comparison)
        TextField("Find data", text: $query).onSubmit { findNext() }
        Button("Find next match") { findNext() }.disabled(query.isEmpty)
        if !searchResult.isEmpty { reading(searchResult) }
      } else {
        reading("No data")
      }
    }.accessibilityElement(children: .contain).accessibilityLabel(title)
  }
}
