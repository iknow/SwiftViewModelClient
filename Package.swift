// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "ViewModels",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
  ],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "ViewModels",
      targets: ["ViewModels"]
    ),
    // Product executable has to have the same name as the executable target because otherwise, there is a bug
    // that prevents the plugin from using it.
    .executable(
      name: "Generator",
      targets: ["Generator"]
    ),
    .executable(
      name: "ConfigGenerator",
      targets: ["ConfigGenerator"]
    ),
    .plugin(
      name: "GenerateViewModels",
      targets: ["GenerateViewModelsPlugin"]
    ),
    .plugin(
      name: "GenerateConfig",
      targets: ["GenerateConfigPlugin"]
    ),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", from: "602.0.0"),
    .package(url: "https://github.com/michaeleisel/ZippyJSONCFamily", exact: "1.2.14"),
    // .package(
    //   url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")
    // ),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "ViewModels",
      dependencies: [
        "ViewModelsMacros",
        .product(name: "ZippyJSONCFamily", package: "ZippyJSONCFamily"),
      ]
    ),
    .target(
      name: "Shared"
    ),
    .target(
      name: "TestModels",
      dependencies: ["ViewModels"],
      resources: [
        .copy("Resources/categories.json"),
        .copy("Resources/conversation.json"),
        .copy("Resources/scenarios.json"),
      ]
    ),
    .macro(
      name: "ViewModelsMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ]
    ),
    .executableTarget(
      name: "Generator",
      dependencies: [
        "ViewModels",
        "Shared",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .executableTarget(
      name: "ConfigGenerator",
      dependencies: [
        "Shared",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .executableTarget(
      name: "ParserTest",
      dependencies: [
        "ViewModels",
        "TestModels",
      ]
    ),
    .plugin(
      name: "GenerateViewModelsPlugin",
      capability: .command(
        intent: .custom(
          verb: "generate-viewmodels",
          description: "Generates swift files of the provided ViewModel names"
        ),
        permissions: [
          .allowNetworkConnections(scope: .all(ports: []), reason: "Fetch view model data"),
          .writeToPackageDirectory(reason: "To save the generated model files")
        ]
      ),
      dependencies: [
        "Generator"
      ],
      path: "Plugins/ViewModels",
    ),
    .plugin(
      name: "GenerateConfigPlugin",
      capability: .command(
        intent: .custom(
          verb: "generate-config",
          description: "Generates the default config used for model generation."
        ),
        permissions: [
          .writeToPackageDirectory(reason: "To save the generated config")
        ]
      ),
      dependencies: [
        "ConfigGenerator"
      ],
      path: "Plugins/Config",
    ),
    // When benchmarking the parser, enable this, and its dependency.
    //
    // .executableTarget(
    //   name: "ParserBenchmark",
    //   dependencies: [
    //     "ViewModels",
    //     "TestModels",
    //     .product(name: "Benchmark", package: "package-benchmark"),
    //   ],
    //   path: "Benchmarks/ParserBenchmark",
    //   plugins: [
    //     .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
    //   ]
    // ),
    .testTarget(
      name: "ViewModelsTests",
      dependencies: [
        "ViewModels",
        "TestModels",
      ]
    ),
  ]
)
