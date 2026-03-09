//
//  ParserBenchmark.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/13.
//

import Benchmark
import Foundation
import TestModels
import ViewModels

let benchmarks = {
  let bytes = try! TestModelResources.loadJson(name: "scenarios")

  Benchmark("Parsing", configuration: .init(
    metrics: [.cpuTotal, .mallocCountSmall, .mallocCountLarge, .mallocCountTotal, .throughput]
  )) { benchmark in
    for _ in benchmark.scaledIterations {
      blackHole(try! ViewModel.deserialize(json: bytes, type: [RolePlayScenario].self))
    }
  }
}
