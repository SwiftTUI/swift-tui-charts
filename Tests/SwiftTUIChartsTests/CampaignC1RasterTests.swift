import Testing

@testable import SwiftTUICharts

@Suite("Campaign C1 raster contracts")
struct CampaignC1RasterTests {
  @Test(arguments: Array(41...60))
  func raster(id: Int) {
    let domain = LineChartDomain(x: 0...4, y: -2...2)
    func line(_ points: [LineChartPoint]) -> [[LineRasterCell?]] {
      rasterizeLine(points: points, domain: domain, plotWidth: 5, plotHeight: 5)
    }
    func area(_ points: [LineChartPoint], baseline: Int) -> [[LineRasterCell?]] {
      rasterizeArea(
        points: points, domain: domain, plotWidth: 5, plotHeight: 5, baselineRow: baseline)
    }
    switch id {
    case 41:
      let grid = area([.init(x: 2, y: -1)], baseline: 0)
      #expect(grid[3][2]?.glyph == "•")
      c1Known("STUI-1177: area fill omits cells above the line") {
        #expect((0...2).allSatisfy { grid[$0][2]?.glyph == "▒" })
      }
    case 42:
      let grid = area([.init(x: 0, y: 1), .init(x: 2, y: .nan), .init(x: 4, y: -1)], baseline: 2)
      #expect(grid[1][0]?.glyph == "•" && grid[3][4]?.glyph == "•")
      c1Known("STUI-1177: area fill omits cells above the line") {
        #expect(grid[2][0]?.glyph == "▒" && grid[2][4]?.glyph == "▒")
      }
    case 43:
      let grid = area([.init(x: 2, y: 0)], baseline: 99)
      #expect(grid[2][2]?.glyph == "•")
      #expect(grid[3][2]?.glyph == "▒" && grid[4][2]?.glyph == "▒")
    case 44:
      let grid = area([.init(x: 2, y: 0)], baseline: -10)
      #expect(grid[2][2]?.glyph == "•")
      c1Known("STUI-1177: area fill omits cells above the line") {
        #expect(grid[0][2]?.glyph == "▒" && grid[1][2]?.glyph == "▒")
      }
    case 45:
      let grid = area([.init(x: 0, y: 1), .init(x: 2, y: .nan), .init(x: 4, y: 1)], baseline: 4)
      #expect(grid.allSatisfy { $0[1] == nil && $0[2] == nil && $0[3] == nil })
      #expect(grid[4][0]?.glyph == "▒" && grid[4][4]?.glyph == "▒")
    case 46:
      let grid = area([.init(x: 2, y: 0)], baseline: 2)
      #expect(grid.flatMap { $0 }.compactMap { $0 }.map(\.glyph) == ["•"])
    case 47:
      let grid = line([.init(x: 4, y: -2), .init(x: 0, y: 2)])
      #expect((0...4).allSatisfy { grid[4][$0] != nil && grid[$0][0] != nil })
      // Authored direction leaves the first sample toward its left neighbor.
      // Accept every connector with a left port; do not mandate an exact glyph.
      c1Known("STUI-1178: descending-X source connector points right") {
        #expect("─╮╯".contains(grid[4][4]?.glyph ?? " "))
      }
    case 48:
      let grid = line([.init(x: 2, y: -2), .init(x: 2, y: 2)])
      #expect((0...4).allSatisfy { grid[$0][2] != nil })
      #expect("│╰╯".contains(grid[4][2]?.glyph ?? " "))
      #expect("│╭╮".contains(grid[0][2]?.glyph ?? " "))
    case 49:
      let grid = rasterizeStep(
        points: [.init(x: 4, y: -2), .init(x: 0, y: 2)],
        domain: domain, plotWidth: 5, plotHeight: 5)
      #expect((1...4).allSatisfy { grid[4][$0]?.glyph == "─" })
      #expect((0...4).allSatisfy { grid[$0][0]?.glyph == "│" })
    case 50:
      let grid = rasterizeStep(
        points: [.init(x: 2, y: -2), .init(x: 2, y: 2)],
        domain: domain, plotWidth: 5, plotHeight: 5)
      #expect((0...4).allSatisfy { grid[$0][2]?.glyph == "│" })
      #expect(grid.allSatisfy { $0[0] == nil && $0[1] == nil })
    case 51:
      let grid = rasterizeStep(
        points: [.init(x: 1, y: 0), .init(x: 3, y: .nan)],
        domain: domain, plotWidth: 5, plotHeight: 5)
      #expect(grid[2][1]?.glyph == "─")
      #expect(grid.allSatisfy { $0[2] == nil && $0[3] == nil && $0[4] == nil })
    case 52:
      let grid = rasterizeStep(
        points: [.init(x: 0, y: .nan), .init(x: 3, y: 0)],
        domain: domain, plotWidth: 5, plotHeight: 5)
      #expect(grid.allSatisfy { $0[0] == nil && $0[1] == nil && $0[2] == nil })
      #expect(grid[2][3]?.glyph == "─" && grid[2][4]?.glyph == "─")
    case 53:
      let grid = line([
        .init(x: 0, y: 0), .init(x: 1, y: .nan), .init(x: 2, y: 0),
        .init(x: 3, y: .nan), .init(x: 4, y: 0),
      ])
      #expect(grid[2].map { $0?.glyph } == ["•", nil, "•", nil, "•"])
      #expect(
        grid.enumerated().filter { $0.offset != 2 }.allSatisfy {
          $0.element.allSatisfy { $0 == nil }
        })
    case 54:
      let grid = rasterizeLine(
        points: [.init(x: 2, y: 0)], domain: domain, plotWidth: 0, plotHeight: 0)
      #expect(grid == [[LineRasterCell(glyph: "•")]])
    case 55...59:
      let points: [LineChartPoint] = [.init(x: 0, y: 0), .init(x: 4, y: 0)]
      let series: [LineChartSeries]
      if id == 55 {
        series = [.init("a", points: points), .init("b", points: points)]
      } else if id == 56 {
        series = [
          .init("line", points: points),
          .init("area", points: [.init(x: 0, y: 2), .init(x: 4, y: 2)], style: .area),
        ]
      } else if id == 57 {
        series = [.init("line", points: points), .init("empty", points: [])]
      } else if id == 58 {
        series = [
          .init("a", points: points, tone: .warning),
          .init("b", points: [.init(x: 1, y: 1)], tone: .critical),
        ]
      } else {
        series = [
          .init("missing", points: [.init(x: .nan, y: 0), .init(x: 0, y: .infinity)], style: .area)
        ]
      }
      let composed = composeSeriesGrids(
        series: series, domain: domain, plotWidth: 5, plotHeight: 5, baselineRow: 4)
      switch id {
      case 55: #expect(composed.seriesIndex[2] == [1, 1, 1, 1, 1])
      case 56:
        #expect(composed.seriesIndex[2] == [0, 0, 0, 0, 0])
        #expect(composed.grid[2].allSatisfy { $0?.glyph == "─" })
      case 57: #expect(composed.seriesIndex[2] == [0, 0, 0, 0, 0])
      case 58:
        let changed = series.map {
          LineChartSeries($0.label, points: $0.points, style: $0.style, tone: .success)
        }
        #expect(
          composed
            == composeSeriesGrids(
              series: changed, domain: domain, plotWidth: 5, plotHeight: 5, baselineRow: 4))
      default:
        #expect(composed.grid.flatMap { $0 }.allSatisfy { $0 == nil })
        #expect(composed.seriesIndex.flatMap { $0 }.allSatisfy { $0 == nil })
      }
    case 60:
      let points: [LineChartPoint] = [.init(x: 0, y: -1), .init(x: 2, y: 2), .init(x: 4, y: 0)]
      let expectedLine = line(points)
      let filled = area(points, baseline: -3)
      for row in 0..<5 {
        for col in 0..<5 where expectedLine[row][col] != nil {
          #expect(filled[row][col] == expectedLine[row][col])
        }
      }
    default: Issue.record("unassigned C1 raster scenario")
    }
  }
}
