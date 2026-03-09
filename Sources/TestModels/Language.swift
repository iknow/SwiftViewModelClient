//
//  Language.swift
//  Eikaiwa
//
//  Created by Kevin Griffin on 2023/07/23.
//

import Foundation
import ViewModels

public enum Language: String, CaseIterable, Codable {
  case en
  case ja
  case es
  case id
  case it
  case ko
  case ru
  case th
  case tr
  case vi
  case ptBR = "pt-BR"
  case zhHans = "zh-Hans"
  case zhHant = "zh-Hant"
  case tlh

  public func name(locale: Locale) -> String {
    locale.localizedString(forLanguageCode: rawValue) ?? ""
  }
}

extension Language: ViewModelParserRawCodable {}
