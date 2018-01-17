//
//  Product.swift
//  skin
//
//  Created by Becky on 9/11/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import Foundation
import RealmSwift

final class Product: Object {
	dynamic var id: String = UUID().uuidString
	dynamic var name = ""
	dynamic var brand: String?
	let price = RealmOptional<Double>()
	dynamic var link: String?
	dynamic var expirationDate: Date?
	dynamic var category: String = ProductCategory.active.rawValue

	override static func primaryKey() -> String? {
		return "id"
	}
}
