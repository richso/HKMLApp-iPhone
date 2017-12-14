//
// got from:
// https://stackoverflow.com/questions/1823317/get-the-current-first-responder-without-using-a-private-api/27140764#27140764
//


import UIKit

extension UIResponder {
    private weak static var _currentFirstResponder: UIResponder? = nil
    
    public static var first: UIResponder? {
        UIResponder._currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder(sender:)), to: nil, from: nil, for: nil)
        return UIResponder._currentFirstResponder
    }
    
    @objc internal func findFirstResponder(sender: AnyObject) {
        UIResponder._currentFirstResponder = self
    }
}
