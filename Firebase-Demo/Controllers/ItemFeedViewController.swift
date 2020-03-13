//
//  ItemFeedViewController.swift
//  Firebase-Demo
//
//  Created by Pursuit on 3/2/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ItemFeedViewController: UIViewController {

        @IBOutlet weak var tableView: UITableView!
        
        private var listener: ListenerRegistration?
        
    private let databaseService = DatabaseService()

        private var items = [Item]() {
            didSet{
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.dataSource = self
            
             // register a nib/ xib file
            tableView.register(UINib(nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "itemCell")
            
            tableView.delegate = self

        }
        
        // setting up the listener
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(true)
            listener = Firestore.firestore().collection(DatabaseService.itemsCollection)
            .addSnapshotListener({[weak self ](snapshot, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Firestore Error", message: "\(error.localizedDescription)")
                    }
                } else if let snapshot = snapshot {
                    print("there are \(snapshot.documents.count) items for sell")
                    let items = snapshot.documents.map {Item($0.data()) }
                    // maps for thru each element in the array
                    // each element represents $0
                    //$0.data is a dictonary
                    // for item in item is item and that is $0.data
                    self?.items = items
                }
            })
        }
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillAppear(true)
            listener?.remove() // no longer are we listening for changes from Firebase
        }
    }

    extension ItemFeedViewController: UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return items.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ItemCell else {
                fatalError("could not downcast to ItemCell")
            }
            
            let item = items[indexPath.row]
            cell.configureCell(for: item)
    //        cell.textLabel?.text = item.itemName
    //        let price = String(format: "% 2f", item.price)
    //        cell.detailTextLabel?.text = "@\(item.sellerName) price: $\(price)"
            return cell
        }
        
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                //perform deletion on item
                // since we have a listener we just need to delete from the firebase .
                
                // this is where we actually delete
                //perform deletion on item
                let item = items[indexPath.row]
                databaseService.delete(item: item) { [weak self] (result) in
                    switch result {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self?.showAlert(title: "Deletion error", message: error.localizedDescription)
                        }
                    case .success:
                        print("deleted successfully")
                    }
                }
                
            }
        }
        
        
}

    extension ItemFeedViewController: UITableViewDelegate {
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 140
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let item = items[indexPath.row]
            
            // need to access the other storyboard to inject it into it
            let storyboard = UIStoryboard(name: "MainView", bundle: nil)
            let detailVC = storyboard.instantiateViewController(identifier: "ItemDetailController") { (coder) in
                return ItemDetailController(coder: coder, item: item)
                
            }
            // notice if this controller is not embedded in a navController then it will not show the next controller even if the next controller that are seguing to is already embedded in a nav controller
            
            // all you need to do is embedd it. 
            navigationController?.pushViewController(detailVC, animated: true)

        }
        
        
    }
