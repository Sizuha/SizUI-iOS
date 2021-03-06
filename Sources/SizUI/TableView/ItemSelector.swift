//
//  ItemSelector.swift
//  
//
//  Created by Sizuha on 2020/05/23.
//

import Foundation

import UIKit

@available(iOS 9.0, *)
open class ItemSelector: UIViewController {
    
    open class func present(
        from: UINavigationController,
        title: String,
        items: [String],
        selected: Int? = nil,
        onSelected: @escaping (_ index: Int)->Void
    ) {
        let vc = ItemSelector()
        vc.title = title
        vc.items = items
        vc.prevSelected = selected ?? -1
        vc.onSelected = onSelected
        
        from.pushViewController(vc, animated: true)
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

@available(iOS 9.0, *)
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
