//
//  ItemSelector.swift
//  
//
//  Created by Sizuha on 2020/05/23.
//

import Foundation

import UIKit

@available(iOS 9.0, *)
class ItemSelector: UIViewController {
    
    static func present(
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        listView = UITableView(frame: .zero, style: .grouped)
        listView.register(UITableViewCell.self, forCellReuseIdentifier: cell_reuseId)
        listView.dataSource = self
        listView.delegate = self
        
        view.addSubview(listView)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        listView.scaleFill(to: view)
    }

}

@available(iOS 9.0, *)
extension ItemSelector: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: cell_reuseId)!
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.text = items[indexPath.row]
        cell.accessoryType = prevSelected == indexPath.row ? .checkmark : .none
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        popSelf()
        onSelected?(indexPath.row)
    }
}
