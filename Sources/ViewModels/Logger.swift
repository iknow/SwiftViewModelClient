//
//  Logger.swift
//
//
//  Created by Andrew Childs on 2023/10/18.
//

import OSLog

#if DEBUG
public enum ViewModelsLogger {
  static let logger = Logger(subsystem: "jp.iknow.ViewModels", category: "ViewModels")

  public static func logMigrationWarning(
    _ viewModel: (some ViewModel).Type
  ) {
    logger.warning("\(viewModel) is relying on migrations")
  }
}
#endif
