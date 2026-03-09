//
//  MigrationWarning.swift
//
//
//  Created by Andrew Childs on 2024/03/08.
//

import Foundation
import os

#if DEBUG
public struct MigrationWarning: Sendable {
  let haveWarned = OSAllocatedUnfairLock<Bool>(initialState: false)

  public init() {}

  public func warn(forViewModel viewModel: (some ViewModel).Type) {
    let shouldWarn = haveWarned.withLock { haveWarned in
      if haveWarned {
        return false
      } else {
        haveWarned = true
        return true
      }
    }

    if shouldWarn {
      ViewModelsLogger.logMigrationWarning(viewModel.self)
    }
  }
}
#endif
