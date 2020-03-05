# SizUI-iOS
UI Utilities for iOS(Swift)

# Requirements

* iOS 8.0+
* XCode 11.0+
* Swift 5

# Installation

#### Swift Package Manager

Go to Project -> Swift Packages and add the repository:
```
https://github.com/Sizuha/SizUI-iOS
```

# Alert Dialog
```swift
SizAlertBuilder(message: "MESSAGE")
	.addAction(title: "Cancel", style: .cancel)
	.addAction(title: "OK", style: .default) { _ in
		// OKボンタンが押された時の処理
	}
	.show(parent: self /* UIViewController */)
```

# Loading Indicator
```swift
// ローティング表示
UIAlertController.showIndicatorAlert(viewController: self, message: "MESSAGE") { alert: UIAlertController in
  // ここで、次の処理
  
  // ローティング表示を消す
  alert.dissmis(animated: false) {
    // 次の処理
  }
}
```

