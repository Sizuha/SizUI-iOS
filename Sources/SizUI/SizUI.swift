//
// UI Utilities for Swift(iOS)
//

import UIKit

// MARK: - UIColor
// Color extention to hex
public extension UIColor {
	convenience init(hexString: String, alpha: CGFloat = 1.0) {
		let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		let startWithSharp = hexString.hasPrefix("#")
		let startWithAlpha = startWithSharp && hexString.count == 9 // #aarrggbb
		
		let scanner: Scanner
		if startWithSharp && hexString.count == 4 {
			// need convert: "#rgb" --> "#rrggbb"
			var converted = ""
			for c in hexString {
				if c != "#" { converted.append("\(c)\(c)") }
			}
			scanner = Scanner(string: converted)
			scanner.scanLocation = 0
		}
		else {
			scanner = Scanner(string: hexString)
			scanner.scanLocation = startWithSharp ? 1 : 0
		}
		
		var color: UInt32 = 0
		scanner.scanHexInt32(&color)
		
		let mask = 0x000000FF
		let a = Int(color >> 24) & mask
		let r = Int(color >> 16) & mask
		let g = Int(color >> 8) & mask
		let b = Int(color) & mask

		let red   = CGFloat(r) / 255.0
		let green = CGFloat(g) / 255.0
		let blue  = CGFloat(b) / 255.0
		let alphaCode = startWithAlpha
			? CGFloat(a) / 255.0
			: alpha
		
		self.init(red:red, green:green, blue:blue, alpha: alphaCode)
	}
	
	func toHexString(withAlpha: Bool = false) -> String {
		var r:CGFloat = 0
		var g:CGFloat = 0
		var b:CGFloat = 0
		var a:CGFloat = 0
		
		getRed(&r, green: &g, blue: &b, alpha: &a)
		let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
		
		return withAlpha
			? String(format:"#%02x%06x", a, rgb)
			: String(format:"#%06x", rgb)
	}
	
	static var placeholderGray: UIColor {
		return UIColor(red: 0, green: 0, blue: 0.0980392, alpha: 0.22)
	}
	
	func toColor(_ color: UIColor, percentage: CGFloat) -> UIColor {
		let percentage = max(min(percentage, 100), 0) / 100
		switch percentage {
		case 0: return self
		case 1: return color
		default:
			var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
			var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
			guard self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return self }
			guard color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return self }
			
			return UIColor(
				red: CGFloat(r1 + (r2 - r1) * percentage),
				green: CGFloat(g1 + (g2 - g1) * percentage),
				blue: CGFloat(b1 + (b2 - b1) * percentage),
				alpha: CGFloat(a1 + (a2 - a1) * percentage)
			)
		}
	}
	
	class func transitionColor(fromColor:UIColor, toColor:UIColor, progress:CGFloat) -> UIColor {
		var percentage = progress < 0 ?  0 : progress
		percentage = percentage > 1 ?  1 : percentage
		
		var fRed:CGFloat = 0
		var fBlue:CGFloat = 0
		var fGreen:CGFloat = 0
		var fAlpha:CGFloat = 0
		
		var tRed:CGFloat = 0
		var tBlue:CGFloat = 0
		var tGreen:CGFloat = 0
		var tAlpha:CGFloat = 0
		
		fromColor.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
		toColor.getRed(&tRed, green: &tGreen, blue: &tBlue, alpha: &tAlpha)
		
		let red:CGFloat = (percentage * (tRed - fRed)) + fRed;
		let green:CGFloat = (percentage * (tGreen - fGreen)) + fGreen;
		let blue:CGFloat = (percentage * (tBlue - fBlue)) + fBlue;
		let alpha:CGFloat = (percentage * (tAlpha - fAlpha)) + fAlpha;
		
		return UIColor(red: red, green: green, blue: blue, alpha: alpha)
	}
	
	/// iOS 13以上の場合は「UIColor.label」、他は「UIColor.darkText」
	static var defaultText: UIColor {
		if #available(iOS 13, *) {
			return UIColor.label
		}
		return UIColor.darkText
	}
	
	static var inputText: UIColor {
		if #available(iOS 13, *) {
			return UIColor.secondaryLabel
		}
		return UIColor.darkGray
	}
}

// MARK: - UIImage

public extension UIImage {
    
    convenience init?(url: URL, noCache: String? = nil) {
        var imgUrl = url
        if let noCache = noCache {
            let has_q = url.absoluteString.contains("?")
            imgUrl = url.appendingPathComponent(has_q ? "&\(noCache)" : "?\(noCache)")
        }
        
        guard let data = try? Data(contentsOf: imgUrl) else { return nil }
        self.init(data: data)
    }
    
}


// MARK: - UIApplication
public extension UIApplication {
	@available(iOS, introduced: 11.0, obsoleted: 13.0, message: "iOS 13で廃止されました")
	var statusBarView: UIView? {
		if responds(to: Selector(("statusBar"))) {
			return value(forKey: "statusBar") as? UIView
		}
		return nil
	}
	
	func getKeyWindow() -> UIWindow? {
		for window in windows {
			if window.isKeyWindow { return window }
		}
		return nil
	}
}

// MARK: - UIView
public extension UIView {
	func makeRoundCornor(_ radius: CGFloat = 5) {
		self.layer.cornerRadius = radius
	}
	
	@available(iOS 9.0, *)
	func setMatchTo(parent: UIView) {
        scaleFill(to: parent)
	}
    
    @available(iOS 9.0, *)
    func scaleFill(to targetView: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.leftAnchor.constraint(equalTo: targetView.leftAnchor).isActive = true
        self.rightAnchor.constraint(equalTo: targetView.rightAnchor).isActive = true
        self.topAnchor.constraint(equalTo: targetView.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: targetView.bottomAnchor).isActive = true
    }
	
	var isDarkMode: Bool {
		if #available(iOS 12.0, *) {
			return traitCollection.userInterfaceStyle == .dark
		}
		return false
	}
    
    @available(iOS 9.0, *)
    func alignBottomOf(navigationBar: UINavigationBar?, parent: UIView, marginTop: CGFloat = 0) {
        guard let navigationBar = navigationBar else { return }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: marginTop).isActive = true
        self.heightAnchor.constraint(equalToConstant: self.frame.height).isActive = true
        self.leftAnchor.constraint(equalTo: parent.leftAnchor).isActive = true
        self.rightAnchor.constraint(equalTo: parent.rightAnchor).isActive = true
    }
    
    @available(iOS 9.0, *)
    func alignBottomOf(view: UIView, parent: UIView, constant: CGFloat = 0) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: view.bottomAnchor, constant: constant).isActive = true
        self.heightAnchor.constraint(equalToConstant: self.frame.height).isActive = true
        self.leftAnchor.constraint(equalTo: parent.leftAnchor).isActive = true
        self.rightAnchor.constraint(equalTo: parent.rightAnchor).isActive = true
    }

}

public enum FadeType: TimeInterval {
	case
	Normal = 0.2,
	Slow = 1.0
}

// MARK: - UIViewController

public extension UIViewController {
	var isDarkMode: Bool {
		if #available(iOS 12.0, *) {
			return traitCollection.userInterfaceStyle == .dark
		}
		return false
	}
	
	func setupKeyboardDismissRecognizer(view: UIView? = nil) {
		let tapRecognizer: UITapGestureRecognizer =
			UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		
		(view ?? self.view).addGestureRecognizer(tapRecognizer)
	}
	
	@objc
	func dismissKeyboard() {
		self.view.endEditing(true)
	}
	
	func popSelf(animated: Bool = true) {
		if let naviCtrl = self.navigationController {
            if naviCtrl.viewControllers.last == self {
                naviCtrl.popViewController(animated: animated)
            }
            else if naviCtrl.viewControllers.first == self {
                self.dismiss(animated: true, completion: nil)
            }
            else {
                if let i = naviCtrl.viewControllers.lastIndex(of: self) {
                    naviCtrl.viewControllers.remove(at: i)
                }
            }
		}
		else {
			removeFromParent()
		}
	}
	
	func removeAllSubViews() {
		if let subViews = self.parent?.children {
			for v in subViews {
				v.removeFromParent()
			}
		}
	}
	
	@available(iOS 11.0, *)
	func changeStatusBar(color: UIColor) {
		if #available(iOS 13, *) {
			let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height

			let statusbarView = UIView()
			statusbarView.backgroundColor = color
			view.addSubview(statusbarView)

			statusbarView.translatesAutoresizingMaskIntoConstraints = false
			statusbarView.heightAnchor.constraint(equalToConstant: statusBarHeight).isActive = true
			statusbarView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0).isActive = true
			statusbarView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
			statusbarView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		}
		else {
			UIApplication.shared.statusBarView?.backgroundColor = color
		}
	}

}

// MARK: - UITableView

public extension UITableView {
	var selectedCount: Int {
		return self.indexPathsForSelectedRows?.count ?? 0
	}
}

public protocol SizViewUpdater {
	func refreshViews()
}

//MARK: - Alert Dialog

public extension UIAlertController {
		
	/// ローディング表示と共にAlertポップアップを表示する.
	///
	/// 注意！ViewControllerのpresent()メソッドで表示されるので、基本的に非同期（Async）処理となっている
	/// - Parameters:
	///   - viewController: このViewControllerの上にポップアップが現れる
	///   - message: メッセージ
	///   - style: IndicatorのStyle。nilの場合、基本は「.gary」でDarkModeの場合は「.white」
	///   - indicatorCenter: Indicatorの位置
	///   - mainAsync: ポップアップを表示する時（present）、DispatchQueue.main.asyncを使う
	///   - completion: 表示が完了した後の処理
	class func showIndicatorAlert(
		viewController: UIViewController,
		message: String,
		style: UIActivityIndicatorView.Style? = nil,
		indicatorCenter: CGPoint = CGPoint(x: 25, y: 30),
		mainAsync: Bool = true,
		completion: ((_ alert: UIAlertController)->Void)? = nil)
		-> UIAlertController
	{
		let alert: UIAlertController = self.init(title: nil, message: message, preferredStyle: .alert)
		
		// Add Indicator
		let indicator = UIActivityIndicatorView(style: style ?? (viewController.isDarkMode ? .white : .gray))
		indicator.center = indicatorCenter
		alert.view.addSubview(indicator)
		
		func show() {
			indicator.startAnimating()
			viewController.present(alert, animated: true) {
				completion?(alert)
			}
		}
		
		if mainAsync {
			DispatchQueue.main.async { show() }
		}
		else {
			show()
		}
		
		return alert
	}
}

public class SizAlertBuilder {
	private let alert: UIAlertController
	private var actions: [UIAlertAction]
	
	public var title: String? {
		get { return alert.title }
		set(text) { alert.title = text }
	}
	public var message: String? {
		get { return alert.message }
		set(text) { alert.message = text }
	}
	
	public init(
		title: String? = nil,
		message: String? = nil,
		style: UIAlertController.Style = .alert,
		actions: [UIAlertAction] = [])
	{
		self.alert = UIAlertController(title: title, message: message, preferredStyle: style)
		self.actions = actions
	}
	
	public func set(title: String?) -> Self {
		return setTitle(title)
	}
	
	public func setTitle(_ title: String?) -> Self {
		self.title = title
		return self
	}
	
	public func set(message: String?) -> Self {
		return setMessage(message)
	}
	
	public func setMessage(_ message: String?) -> Self {
		self.message = message
		return self
	}
	
	public func setAttributed(message: NSAttributedString) -> Self {
		self.alert.setValue(message, forKey: "attributedMessage")
		return self
	}
	
	public func set(
		message: String,
		textAlign: NSTextAlignment,
		textColor: UIColor = UIColor.defaultText,
		font: UIFont) -> Self
	{
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = textAlign
		
		let messageText = NSAttributedString(
			string: message,
			attributes: [
				NSAttributedString.Key.paragraphStyle: paragraphStyle,
				NSAttributedString.Key.foregroundColor : textColor,
				NSAttributedString.Key.font : font
			]
		)
		return setAttributed(message: messageText)
	}
	
	public func addAction(
		title: String,
		style: UIAlertAction.Style = UIAlertAction.Style.default,
		handler: ((UIAlertAction) -> Void)? = nil)
		-> Self
	{
		let action = UIAlertAction(title: title, style: style, handler: handler)
		self.actions.append(action)
		return self
	}

	public func create() -> UIAlertController {
		for action in self.actions {
			self.alert.addAction(action)
		}
		return self.alert
	}
	
	public func show(parent: UIViewController, animated: Bool = true, completion: (()->Void)? = nil) {
		parent.present(create(), animated: animated, completion: completion)
	}
}

public func createAlertDialog(
	title: String? = nil,
	message: String? = nil,
	buttonText: String = "OK",
	onClick: ((UIAlertAction) -> Void)? = nil
) -> UIAlertController
{
	return SizAlertBuilder()
		.setTitle(title)
		.setMessage(message)
		.addAction(title: buttonText, handler: onClick)
		.create()
}

public func createConfirmDialog(
	title: String? = nil,
	message: String? = nil,
	okText: String = "OK",
	cancelText: String = "Cancel",
	onOkClick: ((UIAlertAction) -> Void)? = nil,
	onCancelClick: ((UIAlertAction) -> Void)? = nil
) -> UIAlertController
{
	return SizAlertBuilder()
		.setTitle(title)
		.setMessage(message)
		.addAction(title: cancelText, handler: onCancelClick)
		.addAction(title: okText, handler: onOkClick)
		.create()
}



//MARK: - Swipe Actions

@available(iOS 11.0, *)
public class SizSwipeActionBuilder {
	
	public init() {}
	
	private var actions = [UIContextualAction]()
	
	public func addAction(
		title: String? = nil,
		image: UIImage? = nil,
		style: UIContextualAction.Style = .normal,
		bgColor: UIColor? = nil,
		handler: @escaping UIContextualAction.Handler
	) -> Self
	{
		let action = UIContextualAction(style: style, title: title, handler: handler)
		if let image = image {
			action.image = image
		}
		if let bgColor = bgColor {
			action.backgroundColor = bgColor
		}
		return addAction(action)
	}
	
	public func addAction(_ action: UIContextualAction) -> Self {
		self.actions.append(action)
		return self
	}
	
	public func getLastAddedAction() -> UIContextualAction? {
		return self.actions.last
	}
	
	public func createConfig(enableFullSwipe: Bool = false) -> UISwipeActionsConfiguration {
		let conf = UISwipeActionsConfiguration(actions: self.actions)
		conf.performsFirstActionWithFullSwipe = enableFullSwipe
		return conf
	}
	
}


// MARK: - PinchRect

public class PinchRect {
	public let rect: CGRect
	public let center: CGPoint
	
	public init(_ pinch: CGRect) {
		self.rect = pinch
		self.center = CGPoint(
			x: Double(pinch.maxX - pinch.minX)/2.0,
			y: Double(pinch.maxY - pinch.minY)/2.0
		)
	}
	
	public convenience init(gesture: UIPinchGestureRecognizer, in view: UIView) {
		let touchPoint1 = gesture.location(ofTouch: 0, in: view)
		let touchPoint2 = gesture.location(ofTouch: 1, in: view)
		
		let minX = min(touchPoint1.x, touchPoint2.x)
		let maxX = max(touchPoint1.x, touchPoint2.x)
		let minY = min(touchPoint1.y, touchPoint2.y)
		let maxY = max(touchPoint1.y, touchPoint2.y)

		self.init( CGRect(x: minX, y: minY, width: maxX-minX, height: maxY-minY) )
	}
	
	public func distanceXY(from: PinchRect) -> (CGFloat,CGFloat) {
		return (self.center.x - from.center.x, self.center.y - from.center.y)
	}
	
	public func scaleXY(from: PinchRect) -> (CGFloat,CGFloat) {
		return (self.rect.width / from.rect.width, self.rect.height / from.rect.height)
	}
}

