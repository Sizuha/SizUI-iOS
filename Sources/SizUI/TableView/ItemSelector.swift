//
//  ItemSelector.swift
//  
//
//  Created by Sizuha on 2020/05/23.
//

import Foundation

import UIKit

open class ItemSelector: UIViewController {
    
    /// インスタンスを生成
    /// - Parameters:
    ///   - title: タイトル
    ///   - items: 選択できる項目（文字列）
    ///   - selected: 最初から選択せれるもの（index）
    ///   - onSelected: 選択された時
    open class func create(
        title: String,
        items: [String],
        selected: Int? = nil,
        onSelected: @escaping (_ index: Int)->Void
    ) -> Self {
        let vc = Self()
        vc.title = title
        vc.items = items
        vc.prevSelected = selected ?? -1
        vc.onSelected = onSelected
        return vc
    }
    
    /// 画面を表示する。
    /// - Parameters:
    ///   - from: 現在の画面。
    ///     - UINavigationControllerの場合：ナビゲーションにPushを行う
    ///     - それ以外：ポップアップで表示
    ///   - title: タイトル
    ///   - items: 選択できる項目（文字列）
    ///   - selected: 最初から選択せれるもの（index）
    ///   - onSelected: 選択された時
    open class func present(
        from: UIViewController,
        title: String,
        items: [String],
        selected: Int? = nil,
        modal: Bool = false,
        onSelected: @escaping (_ index: Int)->Void
    ) {
        let vc = create(title: title, items: items, selected: selected, onSelected: onSelected)
        
        if !modal, let navi = from as? UINavigationController {
            navi.pushViewController(vc, animated: true)
        }
        else {
            vc.modalTransitionStyle = .coverVertical
            vc.modalPresentationStyle = .formSheet
            vc.setDisablePullDownDismiss()
            from.present(vc, animated: true, completion: nil)
        }
    }
    
    /// 画面を表示する（ナビゲーション上）
    /// - Parameters:
    ///   - to:ナビゲーション
    ///   - title: タイトル
    ///   - items: 選択できる項目（文字列）
    ///   - selected: 最初から選択せれるもの（index）
    ///   - onSelected: 選択された時
    open class func push(
        to: UINavigationController,
        title: String,
        items: [String],
        selected: Int? = nil,
        onSelected: @escaping (_ index: Int)->Void
    ) {
        let vc = create(title: title, items: items, selected: selected, onSelected: onSelected)
        to.pushViewController(vc, animated: true)
    }

    private var items: [String] = []
    private var onSelected: ((_ index: Int)->Void)? = nil
    private var prevSelected: Int = -1
    
    private var listView: UITableView!
    private let cell_reuseId = "item_selector_cell"
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        listView = UITableView(frame: .zero, style: .grouped)
        listView.register(UITableViewCell.self, forCellReuseIdentifier: cell_reuseId)
        listView.dataSource = self
        listView.delegate = self
        
        view.addSubview(listView)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard prevSelected >= 0 else { return }
        
        DispatchQueue.main.async {
            let i = IndexPath(row: self.prevSelected, section: 0)
            self.listView.scrollToRow(at: i, at: .middle, animated: true)
        }
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        listView.scaleFill(to: view)
    }

}

extension ItemSelector: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: cell_reuseId)!
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.text = items[indexPath.row]
        cell.accessoryType = prevSelected == indexPath.row ? .checkmark : .none
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        popSelf()
        onSelected?(indexPath.row)
    }
}
