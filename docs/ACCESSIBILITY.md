# Accessible chart data

Every chart family supplies a bounded semantic data review. With standard color preferences, the painted header
and plot keep their existing layout. A review exposes the exact source values
instead of asking readers to reconstruct them from a rounded summary or glyphs.
The standard constructors retain their summary names; generic constructors retain
the authored label and summary views.

Use **Data position** to jump to an arbitrary record, **First point** / **Last
point** to move to endpoints, and **Find data** / **Find next match** to search
category, series, value, unit or detail text. **Remember point** retains a reference;
the current record and remembered record can be read together, including the
numeric difference when their units match. **Return to remembered point** restores
the reference. These operations change review state only.

```swift
BarChart("Requests", entries: [
  .init("Monday", value: 125),
  .init("Friday", value: 180),
])
.chartDataUnit("requests")
```

Units cannot be inferred from a `Double`. Supply them with `chartDataUnit(_:)`.
An individual `ChartDataRecord.unit` overrides that environment value. Finite
numeric values use the source `Double` representation without display rounding;
nonfinite values are marked missing. Percentages explicitly use `%`.

The data views include these relationships:

- Comparisons expose current, baseline and optional total for each category.
- Meters and bullets expose source value, total, displayed fraction and target.
- Stacks expose each segment and the effective displayed total.
- Thresholds retain authored boundaries and separately name their displayed,
  clamped boundaries and tones. An empty band list describes the default band.
- Lines retain series and authored point order, exact X coordinates, configured
  X formatting, gaps, interpolation and fill baseline. Date X values use the
  configured date formatter and its timezone.
- Calendar heatmaps expose every civil day in the effective range, including
  missing days. Duplicate dates use the same daily sum as the graphic; labels
  include calendar and timezone context. Days outside the range are excluded.
- Legends expose item names and semantic tones; timelines expose event titles,
  details and tones. Sparklines use one-based sample positions.

The semantic tree contains only a current record, a remembered record and review
controls, regardless of dataset size. The source records and identity lookup
still take O(N) memory; a search scans the source. Review controls add no painted
rows or ordinary terminal keyboard focus stops. Browser hosts expose them through
the shared semantic sidecar. This contract does not constitute validation with a
screen reader or a claim that a particular terminal reader supports the controls.

## Custom graphics and interactions

Use `ChartDataView` directly as a visible data explorer, or as the semantic
representation of a custom Canvas or image. Explicit IDs preserve the current,
remembered and search records across reordering. Without IDs, category/series
pairs identify records; duplicates use occurrence order. Duplicate explicit IDs
also use occurrence order, so provide unique IDs when duplicates can reorder.
Removal is reported and review falls back to the first available point.

```swift
Image(data: plotPNG)
  .accessibilityRepresentation {
    VStack {
      ChartDataView([
        .init("Monday", value: 125, unit: "requests", id: "mon"),
        .init("Friday", value: 180, unit: "requests", id: "fri"),
      ], title: "Request history")
      Button("Inspect Friday") { selectedDay = .friday }
    }
  }
```

Bind any inspection, selection or other operation to the same application state
as its visual interaction. A descriptive label alone cannot infer operations or
source data from arbitrary drawing commands. The framework's unlabeled-graphic
warning suggests a simple label, a representation for data and operations, or
`accessibilityHidden(true)` for decoration. Hiding a chart hides its review;
disabling it disables the review controls. A representation replaces the visual
subtree's semantics so glyphs and image bytes are not read as duplicate data.

## Color-independent presentation

Increased contrast, any nonstandard color profile, or differentiate-without-color
enables visible status words alongside semantic tones. Stacks show a named track
for each segment on the same total; threshold gauges list their named band
boundaries. Multi-series line plots use labeled small multiples with a common X/Y
domain, including coincident series, so hue is unnecessary to identify a series.
These presentations can require more rows than the standard chart. Place tall
charts in a scrollable container. The exact-data review remains unchanged.

The framework applies the selected palette and contrast policy to chart text and
glyphs. Author units, labels and meaningful status text; no color profile can infer
meaning from arbitrary colors or certify whole-application WCAG conformance.
