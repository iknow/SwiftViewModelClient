import Foundation
import ViewModels

@ViewModel
public class TextTranslation: ViewModelRecord<UUID> {
  override public class var typeName: String { "TextTranslation" }
  override public class var version: Int { 2 }

  @Attribute(name: "translation", default: "")
  public var translation: String

  @Attribute(name: "lock_version")
  public var lockVersion: Int

  @Attribute(name: "language", default: Language.en)
  public var language: Language
}
