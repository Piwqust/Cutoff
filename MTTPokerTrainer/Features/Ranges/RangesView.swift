import SwiftUI

/// Root of the Ranges tab. Hosts a drill-down: library → matrix → chart.
/// Root of the Ranges tab.
///
/// The shared `RangesViewModel` and `RangeBrowsingStore` must be installed on
/// the *enclosing* `NavigationStack` rather than on `RangeLibraryView`, because
/// SwiftUI's `.navigationDestination(for:)` resolves its destination view in
/// the environment of the NavigationStack — not the view where the modifier
/// is attached. Without this, every push (position / depth / facing / chart)
/// crashes when the pushed view tries to read those environment values.
struct RangesView: View {
    @State private var vm = RangesViewModel()
    @StateObject private var browsing = RangeBrowsingStore()

    var body: some View {
        RangeLibraryView()
            .onAppear { vm.load() }
    }

    /// Convenience for the tab root: wraps `RangesView` in a NavigationStack
    /// and installs the shared model/store at the stack level so all pushed
    /// destinations inherit them.
    static func tabRoot() -> some View {
        TabRoot()
    }

    private struct TabRoot: View {
        @State private var vm = RangesViewModel()
        @StateObject private var browsing = RangeBrowsingStore()

        var body: some View {
            NavigationStack {
                RangeLibraryView()
                    .onAppear { vm.load() }
            }
            .environment(vm)
            .environmentObject(browsing)
        }
    }
}

#Preview {
    NavigationStack { RangesView() }
}
