//
//  BaseTableViewController.swift
//  SplitGreens
//
//  Created by Oleksii Pylko on 20/02/16.
//  Copyright © 2016 Oleksii Pylko. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import ChameleonFramework
import Toucan

class BaseTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        setupRevealGestures()
        deselectSelectedRow()
    }

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if var detailsController = segue.destinationViewController as? ActiveModelSourceProtocol,
            let selectedModel = self.selectedActiveModel {
            detailsController.activeModel = selectedModel
        }
    }
    
    func deselectSelectedRow() {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
    }
    
    func setupUI() {
        setupRightBarItems()
        setupLeftBarItems()
        setupDZNEmptyView()
    }

    func setupRightBarItems() {
        navigationItem.rightBarButtonItem = editButtonItem()
    }
    
    func setupLeftBarItems() {
        setupMenuButtonAtLeftBar()
    }
    
    func configureCell(cell: UITableViewCell, withActiveModel activeModel: ActiveModelProtocol) {
        fatalError("Should be implemented")
    }
    
    var cellIdintifier:String {
        fatalError("Should be implemented")
    }
    
    var activeCollection: ActiveCollectionProtocol {
        fatalError("Should be implemented")
    }
    
}

// MARK: - ActiveCollectionSourceProtocol

extension BaseTableViewController: ActiveCollectionSourceProtocol {
    
    var selectedActiveModel: ActiveModelProtocol? {
        if let selectedIndexPath:NSIndexPath = tableView.indexPathForSelectedRow {
            return activeCollection[selectedIndexPath.row]
        }
        return nil
    }
    
}


// MARK: - UITableViewDataSource

extension BaseTableViewController: UITableViewDataSource {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeCollection.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdintifier, forIndexPath: indexPath)
        configureCell(cell, withActiveModel: activeCollection[indexPath.row]!)
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            activeCollection.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
}

// MARK: - UITableViewDelegate

extension BaseTableViewController: UITableViewDelegate {
}


//  MARK: - DZNEmptyDataSetComplianceProtocol

extension BaseTableViewController: DZNEmptyDataSetComplianceProtocol {
    
    var emptyViewTitle:String {
        fatalError("Should be implemented")
    }
    
    var emptyViewDescription:String {
        fatalError("Should be implemented")
    }
    
    var emptyViewImageName:String {
        fatalError("Should be implemented")
    }

}

//  MARK: - DZNEmptyDataSet

extension BaseTableViewController: DZNEmptyDataSetSource {
    
    func setupDZNEmptyView() {
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return Toucan(image: UIImage(named: emptyViewImageName)!).maskWithEllipse().image
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let font = UIFont.systemFontOfSize(17, weight: 2.0)
        let textColor = FlatRedDark()
        
        return NSAttributedString(string: emptyViewTitle, attributes: [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: textColor
        ])
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let font = UIFont.systemFontOfSize(16.0)
        let textColor = FlatRedDark()
        
        return NSAttributedString(string: emptyViewDescription, attributes: [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: textColor
        ])
    }
    
}

//  MARK: - DZNEmptyDataSetDelegate

extension BaseTableViewController: DZNEmptyDataSetDelegate  {
}


//  MARK: - Actions

extension BaseTableViewController {
 
    @IBAction func cancel(segue: UIStoryboardSegue) {
    }
    
    @IBAction func save(segue: UIStoryboardSegue) {
        if let sourceViewController = segue.sourceViewController as? ActiveModelSourceProtocol {
            let activeModel = sourceViewController.activeModel
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                activeModel.save()
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .None)
            }
            else {
                activeCollection.add(activeModel)
                tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Bottom)
                tableView.reloadEmptyDataSet()
            }
        }
    }
    
    @IBAction func editButtonTaped(sender: UIBarButtonItem) {
        tableView.setEditing(!tableView.editing, animated: true)
    }
    
}
