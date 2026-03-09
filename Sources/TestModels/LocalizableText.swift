import Foundation
import ViewModels

@ViewModel
public class LocalizableText: ViewModelRecord<UUID> {
  override public class var typeName: String { "Text" }
  override public class var version: Int { 2 }

  @Association(name: "text_translations")
  public var textTranslations: [TextTranslation]

  @Attribute(name: "text", default: "")
  public var text: String

  @Attribute(name: "formatted", default: false)
  public var formatted: Bool

  @Attribute(name: "lock_version")
  public var lockVersion: Int

  public init(text: String) {
    super.init(isNew: true, defaultValues: true)
    self.text = text
  }

  public required init(isNew: Bool, defaultValues: Bool) {
    super.init(isNew: isNew, defaultValues: defaultValues)
  }

  public lazy var byLanguage: [Language: TextTranslation] = Dictionary(uniqueKeysWithValues: textTranslations.map { ($0.language, $0) })
}
