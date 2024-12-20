import Foundation
import SwiftUI
import CoreData

class JSonViewModel: ObservableObject {
    @Published var products: [ProductViewModel] = []
    @Published var isLoading: Bool = false
    
    func fetchData(context: NSManagedObjectContext) {
        isLoading = true
        
        let url = "https://app.getswipe.in/api/public/get"
        var request = URLRequest(url: URL(string: url)!)
        request.addValue("swiftui2.0", forHTTPHeaderField: "field")
        
        URLSession.shared.dataTask(with: request) { [weak self] (data, res, _) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                defer { self.isLoading = false }
                
                guard let jsonData = data else {
                    print("No data received")
                    return
                }
                
                if let response = res as? HTTPURLResponse, response.statusCode == 404 {
                    print("API Error: Not Found")
                    return
                }
                
                do {
                    let decodedProducts = try JSONDecoder().decode([ProductViewModel].self, from: jsonData)
                    
                   
                    let uniqueProducts = Dictionary(
                        grouping: decodedProducts,
                        by: { $0.product_name }
                    ).compactMap { $0.value.first }
                    
                  
                    let favorites = try context.fetch(ProductEntity.fetchRequest())
                        .filter { $0.isFavorite }
                        .compactMap { $0.product_name }
                    
                   
                    self.products = uniqueProducts.sorted { $0.product_name < $1.product_name }
                        .map { product in
                            var updatedProduct = product
                            updatedProduct.isFavorite = favorites.contains(product.product_name)
                            return updatedProduct
                        }
                    
                } catch {
                    print("Decoding error: \(error)")
                }
            }
        }.resume()
    }
}
