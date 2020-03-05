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

# DarkModeの確認
```swift
import SizUI

// UIViewの場合
if view.isDarkMode { 
	... 
} else { 
	... 
}

// UIViewControllerの場合
class XXXViewController: UIViewController {
	func some() {
		if self.isDarkMode {
			...
		} else {
			...
		}
	}
}


```

# Alert Dialog
```swift
import SizUI

// OK, Cancel
SizAlertBuilder(message: "MESSAGE")
	.addAction(title: "Cancel", style: .cancel)
	.addAction(title: "OK", style: .default) { _ in
		// OKボンタンが押された時の処理
	}
	.show(parent: self /* UIViewController */)
	
// OK Only
SizAlertBuilder(message: "MESSAGE")
	.addAction(title: "OK")
	.show(parent: self /* UIViewController */)
```

# Loading Indicator
```swift
// ローティング表示
import SizUI

UIAlertController.showIndicatorAlert(viewController: self, message: "MESSAGE") { alert: UIAlertController in
	// ここで、次の処理
  
	// ローティング表示を消す
	alert.dissmis(animated: false) {
		// 次の処理
	}
}
```

# 入力画面や詳細情報などを表現する為のTableView (SizPropertyTableView)

全体図
```swift
import SizUI

class XXXViewController: UIViewController {
	private var inputTable: SizPropertyTableView!

	override func viewDidLoad() {
        	super.viewDidLoad()
		self.inputTable = SizPropertyTableView(frame: .zero, style: .grouped)
		setupInputTableView()
		view.addSubview(self.inputTable)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()		
		self.inputTable.translatesAutoresizingMaskIntoConstraints = false
		self.inputTable.setMatchTo(parent: view) // 大きさを画面全体に合わせる
	}

	private func setupInputTableView() {
		var sections = [SizPropertyTableSection]()

		// Sectionを追加
		sections.append(SizPropertyTableSection(title: "Section A", rows: [ ... ])
		sections.append(SizPropertyTableSection(title: "Section B", rows: [ ... ])
		sections.append(SizPropertyTableSection(title: "Section C", rows: [ ... ])

		self.inputTable.setDataSource(sections)		
	}
}
```

各Section毎に、Cellを定義する
```swift
sections.append(SizPropertyTableSection(title: "Section A", rows: [
/*
	下記のクラスから選んで追加
	
	TextCell(label: "ラベル", attrs: [ ...]) // テキスト表示
	EditTextCell(...) // InputFildでテキストを入力
	OnOffCell(...) // SwitchコントロールでOn/OffをToggle
	ButtonCell(...) // ボタンとして扱う
	
*/

	TextCell(label: "ラベル", attrs: [ 
		.hint(/* placeholder text */),
		.read { return /* Cellに表示するデータを読み込む */ },
		.created { cell: UITableViewCell, index: IndexPath in
			// Cellが生成された時
			let cell = TextCell.cellView(cell)
		},
		.valueChanged { value: Any in
			// 入力可能なCellの場合、入力した内容が変化した時
		},
		.selected { index: IndexPath in
			// Cellをタッチした時
		}
	]),
]

```
