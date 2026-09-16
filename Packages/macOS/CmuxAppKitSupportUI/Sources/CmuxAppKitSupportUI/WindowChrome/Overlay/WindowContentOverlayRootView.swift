import AppKit

/// Owns window content and its overlays in the same AppKit content hierarchy.
@MainActor
final class WindowContentOverlayRootView: NSView {
    let originalContentView: NSView

    override var isOpaque: Bool { false }

    init(contentView: NSView) {
        originalContentView = contentView
        super.init(frame: contentView.frame)
        autoresizingMask = [.width, .height]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func install(in window: NSWindow) {
        window.contentView = self
        originalContentView.frame = bounds
        originalContentView.translatesAutoresizingMaskIntoConstraints = true
        originalContentView.autoresizingMask = [.width, .height]
        addSubview(originalContentView)
    }
}
