#if canImport(UIKit)
import UIKit

extension UIViewController {
    /// The view controller actually on screen above `self`, so Link presents over
    /// any sheet or modal already up rather than failing because `self` is already
    /// presenting.
    func topmostPresenter() -> UIViewController {
        var presenter: UIViewController = self
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        return presenter
    }
}
#endif
