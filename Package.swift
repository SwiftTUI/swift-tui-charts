// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

// `swift-tui-charts` is the chart library for SwiftTUI: compact charts and
// metric-oriented views (bar/column/line charts, meters, gauges, sparklines,
// heatmaps, timelines) composed from the public `SwiftTUIViews` authoring
// surface. The framework it draws with lives in the `swift-tui` package,
// consumed through a public, tagged HTTPS dependency.

let explicitPlatforms = ProcessInfo.processInfo.environment["DISABLE_EXPLICIT_PLATFORMS"] != "1"

let packagePlatforms: [SupportedPlatform]? = {
  if !explicitPlatforms {
    return nil
  }

  return [
    .macOS(.v15),
    .iOS(.v18),
  ]
}()

func swiftSettings(_ settings: PackageDescription.SwiftSetting...) -> [PackageDescription
  .SwiftSetting]
{
  [
    .swiftLanguageMode(.v6),
    .strictMemorySafety(),
    .defaultIsolation(.none),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  ] + settings
}

let package = Package(
  name: "swift-tui-charts",
  platforms: packagePlatforms,
  products: [
    .library(name: "SwiftTUICharts", targets: ["SwiftTUICharts"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/SwiftTUI/swift-tui.git",
      exact: "0.10.0"
    ),
    .package(
      url: "https://github.com/swiftlang/swift-docc-plugin.git",
      from: "1.5.0"
    ),
  ],
  targets: [
    .target(
      name: "SwiftTUICharts",
      dependencies: [
        .product(name: "SwiftTUIViews", package: "swift-tui")
      ],
      swiftSettings: swiftSettings()
    ),
    .testTarget(
      name: "SwiftTUIChartsTests",
      dependencies: [
        "SwiftTUICharts",
        .product(name: "SwiftTUIRuntime", package: "swift-tui"),
        .product(name: "SwiftTUITestSupport", package: "swift-tui"),
      ],
      exclude: ["Fixtures"],
      swiftSettings: swiftSettings()
    ),
  ]
)
