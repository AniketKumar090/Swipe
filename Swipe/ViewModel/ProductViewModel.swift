import Foundation
import SwiftUI
import CoreData

struct ProductViewModel: Decodable, Hashable, Encodable {
    var product_name: String
    var product_type: String
    var price: Double
    var image: String?  // Optional field
    var tax: Double
    var isFavorite: Bool = false

    enum CodingKeys: String, CodingKey {
        case product_name
        case product_type
        case price
        case image
        case tax
    }
    
    init(product_name: String = "", product_type: String = "", price: Double = 0.0, image: String? = nil, tax: Double = 0.0, isFavorite: Bool = false) {
        self.product_name = product_name
        self.product_type = product_type
        self.price = price
        self.image = image
        self.tax = tax
        self.isFavorite = isFavorite
    }
}

extension ProductViewModel {
    init(from entity: ProductEntity) {
        self.product_name = entity.product_name ?? ""
        self.product_type = entity.product_type ?? ""
        self.price = entity.price
        self.image = entity.image
        self.tax = entity.tax
        self.isFavorite = entity.isFavorite
    }
}
