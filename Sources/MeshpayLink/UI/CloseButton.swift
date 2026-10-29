#if canImport(UIKit)
import UIKit

/// The native ✕ shown over the WebView whenever Link's own close isn't available
/// (while loading, after a load failure, on a non-Link page). Full-screen flows
/// must always have a way out (solution design §2.8).
final class CloseButton: UIControl {
    private let backdrop = UIView()
    private let xmark = UIImageView()

    init(tint: UIColor) {
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityLabel = "Close"
        accessibilityTraits = .button

        backdrop.backgroundColor = tint.withAlphaComponent(0.08)
        backdrop.layer.cornerRadius = 20
        backdrop.isUserInteractionEnabled = false
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backdrop)

        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        xmark.image = UIImage(systemName: "xmark", withConfiguration: configuration)
        xmark.tintColor = tint
        xmark.contentMode = .center
        xmark.isUserInteractionEnabled = false
        xmark.translatesAutoresizingMaskIntoConstraints = false
        addSubview(xmark)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 40),
            heightAnchor.constraint(equalToConstant: 40),
            backdrop.leadingAnchor.constraint(equalTo: leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: trailingAnchor),
            backdrop.topAnchor.constraint(equalTo: topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: bottomAnchor),
            xmark.centerXAnchor.constraint(equalTo: centerXAnchor),
            xmark.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Grow the touch target past the 40pt circle.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: -12, dy: -12).contains(point)
    }
}
#endif
