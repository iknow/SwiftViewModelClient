import Foundation
import ViewModels

@ViewModel
public class RemoteImage: ViewModelRecord<UUID> {
  override public class var typeName: String { "Image" }
  override public class var version: Int { 3 }

  @Attribute(name: "url")
  public var url: URL

  @Attribute(name: "dimensions")
  public var dimensions: CGSize

  @Attribute(name: "attribution", default: nil as String?)
  public var attribution: String?

  @Attribute(name: "public_attribution", default: false)
  public var publicAttribution: Bool

  @Attribute(name: "lock_version")
  public var lockVersion: Int

  @Attribute(name: "alt_text", default: "" as String?)
  public var altText: String?

  init(url: URL, altText: String?) {
    super.init(isNew: true, defaultValues: true)
    self.url = url
    self.altText = altText
  }

  required init(isNew: Bool, defaultValues: Bool) {
    super.init(isNew: isNew, defaultValues: defaultValues)
  }

  public var aspectRatio: CGFloat {
    round((dimensions.width / dimensions.height) * 100) / 100
  }

  /// Returns an AttributedString for displaying an attribution in the content system.
  /// Discussion:
  ///         The value is returned as an AttributedString to parse Markdown links.
  public var attributionForDisplay: AttributedString? {
    if let attribution, publicAttribution {
      do {
        return try .init(markdown: "© \(attribution)")
      } catch {
        debugPrint("Couldn't parse attribution Markdown: \(attribution)")
        return nil
      }
    } else {
      return nil
    }
  }
}
