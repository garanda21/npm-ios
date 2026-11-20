import SwiftUI

struct DashboardGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ViewBuilder let content: Content

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : (horizontalSizeClass == .regular ? 4 : 2)
        return Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: count)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) { content }
    }
}
