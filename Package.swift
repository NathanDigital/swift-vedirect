// swift-tools-version: 6.4

import PackageDescription

let settings: [SwiftSetting] = [
  .strictMemorySafety(),
  .treatAllWarnings(as: .error),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("InternalImportsByDefault"),
  .enableUpcomingFeature("MemberImportVisibility"),
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  .enableUpcomingFeature("InferIsolatedConformances"),
  .enableUpcomingFeature("ImmutableWeakCaptures"),
]

let package = Package(
  name: "swift-vedirect",
  products: [
    .library(name: "VEDirect", targets: ["VEDirect"])
  ],
  targets: [
    .target(
      name: "VEDirect",
      swiftSettings: settings
    ),
    .testTarget(
      name: "VEDirectTests",
      dependencies: ["VEDirect"],
      exclude: ["Fixtures/LICENSE-karioja-vedirect.txt"],
      resources: [
        .embedInCode("Fixtures/bluesolar_1.23.dump"),
        .embedInCode("Fixtures/bvm702.dump"),
        .embedInCode("Fixtures/smartsolar_1.39.dump"),
      ],
      swiftSettings: settings
    ),
  ],
  swiftLanguageModes: [.v6]
)
