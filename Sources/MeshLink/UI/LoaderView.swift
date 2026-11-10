#if canImport(UIKit)
import UIKit

/// A small spinning ring shown in the centre while Link is still loading.
/// Matches the React Native SDK's `Loader`: a 24pt ring with a 2pt stroke, a
/// faint full track and a quarter arc that turns once every 0.9 s.
final class LoaderView: UIView {
    private static let diameter: CGFloat = 24
    private static let lineWidth: CGFloat = 2
    private static let rotationKey = "mesh.loader.rotation"

    private let track = CAShapeLayer()
    private let arc = CAShapeLayer()

    init(tint: UIColor) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isAccessibilityElement = true
        accessibilityLabel = "Loading"
        accessibilityTraits = .updatesFrequently

        for layer in [track, arc] {
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = Self.lineWidth
            self.layer.addSublayer(layer)
        }
        // Same faint tint as the close button's circle.
        track.strokeColor = tint.withAlphaComponent(0.08).cgColor
        arc.strokeColor = tint.cgColor
        arc.lineCap = .butt

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.diameter),
            heightAnchor.constraint(equalToConstant: Self.diameter)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let rect = bounds.insetBy(dx: Self.lineWidth / 2, dy: Self.lineWidth / 2)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = rect.width / 2
        track.frame = bounds
        arc.frame = bounds
        track.path = UIBezierPath(ovalIn: rect).cgPath
        // The top quarter of the ring, like a circle with only its top border coloured.
        arc.path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -3 * .pi / 4,
            endAngle: -.pi / 4,
            clockwise: true
        ).cgPath
    }

    override var isHidden: Bool {
        didSet { isHidden ? stopSpinning() : startSpinning() }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Core Animation drops animations when a view leaves the window.
        if window != nil, !isHidden {
            startSpinning()
        }
    }

    private func startSpinning() {
        guard arc.animation(forKey: Self.rotationKey) == nil else {
            return
        }
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = 2 * CGFloat.pi
        rotation.duration = 0.9
        rotation.repeatCount = .infinity
        rotation.timingFunction = CAMediaTimingFunction(name: .linear)
        arc.add(rotation, forKey: Self.rotationKey)
    }

    private func stopSpinning() {
        arc.removeAnimation(forKey: Self.rotationKey)
    }
}
#endif
