//
//  StashViewController.swift
//  skin
//
//  Created by Becky Henderson on 9/19/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

let stashProductCellIdentifier = "stashProduct"
let stashProductSegue = "stashProductSegue"

enum StashTableSection: Int {
	case cleansers
	case actives
	case hydrators
	case occlusives
	case treatments
	
	static let tableSectionTitles = ["Cleansers", "Actives", "Hydrators", "Occlusives", "Treatments"]
}

class StashViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	var searchController: UISearchController?
	
	let productCategories = ProductCategory.allCases
	
	var stash: Stash?
	
	var products: List<Product>? {
		return stash?.products
	}
	
	var filteredProducts: [Product]? {
		didSet {
			updateCategoryProductLists()
		}
	}
	
	var cleansers: [Product]?
	var actives: [Product]?
	var hydrators: [Product]?
	var occlusives: [Product]?
	var treatments: [Product]?
	
	var realmConnectedNotification: NSObjectProtocol?
	var notificationToken: NotificationToken!
	var realm: Realm? {
		return (UIApplication.shared.delegate! as! AppDelegate).realm
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupUI()
		
		if realm == nil {
			realmConnectedNotification = NotificationCenter.default.addObserver(forName: realmConnected, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
				self?.setupRealm()
			}
		} else {
			setupRealm()
		}
	}
	
	func setupUI() {
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addProduct))
		
		searchController = UISearchController(searchResultsController: nil)
		searchController?.searchResultsUpdater = self
		searchController?.searchBar.delegate = self
		searchController?.dimsBackgroundDuringPresentation = false
		searchController?.searchBar.sizeToFit()
		definesPresentationContext = true
		
		tableView.tableHeaderView = self.searchController?.searchBar
	}
	
	func updateStashList() {
		self.tableView.reloadData()
	}
	
	func createStash() {
		try! self.realm!.write {
			let stash = Stash()
			self.realm!.add(stash)
			self.stash = stash
		}
	}
	
	func filterProducts(by category: ProductCategory) -> [Product] {
		let productsToSearch = filteredProducts ?? Array(products!)
		return productsToSearch.filter({ (product) -> Bool in
			let productCategory = ProductCategory(rawValue: product.category)!
			return productCategory == category
		})
	}
	
	func updateCategoryProductLists() {
		cleansers = filterProducts(by: .cleanser)
		actives = filterProducts(by: .active)
		hydrators = filterProducts(by: .hydrator)
		occlusives = filterProducts(by: .occlusive)
		treatments = filterProducts(by: .treatment)
		
		updateStashList()
	}
	
	func setupRealm() {
		if let stash = self.realm!.objects(Stash.self).first {
			self.stash = stash
		} else {
			createStash()
		}
		
		updateCategoryProductLists()
		
		// Notify us when Realm changes
		self.notificationToken = self.stash!.realm!.addNotificationBlock { [weak self] notification, realm in
			self?.updateCategoryProductLists()
		}
	}
	
	deinit {
		notificationToken.stop()
		realmConnectedNotification = nil
	}
	
	// MARK: - Add function
	
	func addProduct() {
		let alertController = UIAlertController(title: "Add Product To Stash", message: "Enter Product Name", preferredStyle: .alert)
		var alertTextField: UITextField!
		alertController.addTextField { textField in
			alertTextField = textField
			textField.placeholder = "Product Name"
		}
		
		alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
		
		alertController.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
			guard let strongSelf = self else { return }
			
			guard let text = alertTextField.text , !text.isEmpty else { return }
			
			let stash = strongSelf.stash!
			try! stash.realm?.write {
				var dateComponents = DateComponents()
				dateComponents.month = 6
				let defaultExpirationDate = Calendar.current.date(byAdding: dateComponents, to: Date())
				
				let newProduct = Product(value: ["name": text,
				                                 "category" : ProductCategory.active.rawValue,
				                                 "expirationDate" : defaultExpirationDate!] as Any)
				stash.products.insert(newProduct,
				                      at: strongSelf.products!.count)
				
				DispatchQueue.main.async {
					strongSelf.performSegue(withIdentifier: stashProductSegue, sender: newProduct)
				}
			}
		})
		present(alertController, animated: true, completion: nil)
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		if segue.identifier == stashProductSegue {
			let productToView: Product
			if let cell = sender as? UITableViewCell {
				let indexPath = tableView.indexPath(for: cell)!
				productToView = productForIndexPath(indexPath: indexPath)
			} else {
				productToView = sender as! Product
			}
			
			let navController = segue.destination as! UINavigationController
			let productViewController = navController.topViewController as! ProductViewController
			productViewController.product = productToView
			
			productViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
			productViewController.navigationItem.leftItemsSupplementBackButton = true
		}
	}
}

extension StashViewController: UITableViewDataSource {
	
	func productForIndexPath(indexPath: IndexPath) -> Product {
		let tableSection = StashTableSection(rawValue: indexPath.section)!
		
		let product: Product
		switch tableSection {
		case .cleansers:
			product = cleansers![indexPath.row]
		case .actives:
			product = actives![indexPath.row]
		case .hydrators:
			product = hydrators![indexPath.row]
		case .occlusives:
			product = occlusives![indexPath.row]
		case .treatments:
			product = treatments![indexPath.row]
		}
		
		return product
	}
	
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return productCategories.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		let tableSection = StashTableSection(rawValue: section)!
		switch tableSection {
			case .cleansers:
				return cleansers?.count ?? 0
			case .actives:
				return actives?.count ?? 0
			case .hydrators:
				return hydrators?.count ?? 0
			case .occlusives:
				return occlusives?.count ?? 0
			case .treatments:
				return treatments?.count ?? 0
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: stashProductCellIdentifier, for: indexPath)
		let product = productForIndexPath(indexPath: indexPath)
		cell.textLabel?.text = product.name
		cell.detailTextLabel?.text = product.brand
		return cell
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return StashTableSection.tableSectionTitles[section]
	}
	
	// MARK: - Delete function
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			try! self.realm?.write {
				let item: Product
				
				let tableSection = StashTableSection(rawValue:indexPath.section)!
				switch tableSection {
				case .actives:
					item = actives![indexPath.row]
				case .cleansers:
					item = cleansers![indexPath.row]
				case .hydrators:
					item = hydrators![indexPath.row]
				case .occlusives:
					item = occlusives![indexPath.row]
				case .treatments:
					item = treatments![indexPath.row]
				}
				
				self.realm?.delete(item)
				
				updateCategoryProductLists()
			}
		}
	}
}

extension StashViewController: UISearchResultsUpdating {
	
	func filterContentForSearchText(_ searchText: String) {
		guard let products = products else {
			return
		}
		
		if searchText == "" {
			filteredProducts = nil
		} else {
			filteredProducts = products.filter({( product : Product) -> Bool in
				return product.name.lowercased().contains(searchText.lowercased())
			})
		}
	}
	
	func updateSearchResults(for searchController: UISearchController) {
		filterContentForSearchText(searchController.searchBar.text!)
	}
}

extension StashViewController: UISearchBarDelegate {
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		filteredProducts = nil
	}
}
