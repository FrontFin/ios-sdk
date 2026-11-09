#if canImport(UIKit)
import UIKit

/// The native ✕ shown over the WebView whenever Link's own close isn't available
/// (while loading, after a load failure, on a non-Link page). Full-screen flows
/// must always have a way out (solution design §2.8).
final class CloseButton: UIControl {
    private let backdrop = UIView()
    private let lineDown = UIView()
    private let lineUp = UIView()

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

        // Two thin strokes rather than an SF Symbol, matching the React Native SDK's ✕.
        for (line, angle) in [(lineDown, CGFloat.pi / 4), (lineUp, -CGFloat.pi / 4)] {
            line.backgroundColor = tint
            line.layer.cornerRadius = 0.5
            line.isUserInteractionEnabled = false
            line.translatesAutoresizingMaskIntoConstraints = false
            line.transform = CGAffineTransform(rotationAngle: angle)
            addSubview(line)
            NSLayoutConstraint.activate([
                line.widthAnchor.constraint(equalToConstant: 16),
                line.heightAnchor.constraint(equalToConstant: 1),
                line.centerXAnchor.constraint(equalTo: centerXAnchor),
                line.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 40),
            heightAnchor.constraint(equalToConstant: 40),
            backdrop.leadingAnchor.constraint(equalTo: leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: trailingAnchor),
            backdrop.topAnchor.constraint(equalTo: topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: bottomAnchor)
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
