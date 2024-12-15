import DeveloperToolsSupport
import SwiftUI

struct LibraryContent: @preconcurrency LibraryContentProvider {

    @MainActor @LibraryContentBuilder
    var views: [LibraryItem] {
        LibraryItem(TitleView(), category: .control)
    }
}
