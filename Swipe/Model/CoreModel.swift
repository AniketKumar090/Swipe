import CoreData
import SwiftUI
import Network
import Foundation


extension OfflineProduct {
    static var offlineFetchRequest: NSFetchRequest<OfflineProduct> {
        return NSFetchRequest<OfflineProduct>(entityName: "OfflineProduct")
    }
}

// MARK: - Product Manager
class ProductManager: ObservableObject {
    static let shared = ProductManager()
    private let networkMonitor = NetworkMonitor()
    @Published var isOnline = true
    
    init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.startMonitoring { [weak self] isOnline in
            DispatchQueue.main.async {
                self?.isOnline = isOnline
                if isOnline {
                    self?.syncPendingProducts()
                }
            }
        }
    }
    
    func addProduct(product: ProductViewModel, image: UIImage?, context: NSManagedObjectContext) {
        
        let offlineProduct = OfflineProduct(context: context)
        offlineProduct.product_name = product.product_name
        offlineProduct.product_type = product.product_type
        offlineProduct.price = product.price
        offlineProduct.tax = product.tax
        offlineProduct.image = image?.jpegData(compressionQuality: 0.5)
        offlineProduct.uploadStatus = "pending"
        offlineProduct.createdAt = Date()
        
        do {
            try context.save()
            
            if isOnline {
                
                uploadProduct(offlineProduct, context: context)
            }
        } catch {
            print("Error saving locally: \(error)")
        }
    }
    
    private func syncPendingProducts() {
         let context = PersistenceController.shared.container.viewContext
            let fetchRequest: NSFetchRequest<OfflineProduct> = OfflineProduct.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "uploadStatus == %@", "pending")
            
            do {
                let pendingProducts = try context.fetch(fetchRequest)
                for product in pendingProducts {
                    uploadProduct(product, context: context)
                }
            } catch {
                print("Error fetching pending products: \(error)")
            }
        
    }
    
    private func uploadProduct(_ offlineProduct: OfflineProduct, context: NSManagedObjectContext) {
      
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
       
        let formFields: [String: String] = [
            "product_name": offlineProduct.product_name ?? "",
            "product_type": offlineProduct.product_type ?? "",
            "price": String(offlineProduct.price),
            "tax": String(offlineProduct.tax)
        ]
        
        for (key, value) in formFields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
       
        if let imageData = offlineProduct.image {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        
       
        guard let url = URL(string: "https://app.getswipe.in/api/public/add") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("swiftui2.0", forHTTPHeaderField: "field")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) {  data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    // Update local status
                    offlineProduct.uploadStatus = "uploaded"
                    try? context.save()
                }
            }
        }.resume()
    }
}
// MARK: - Network Monitor
class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    func startMonitoring(completion: @escaping (Bool) -> Void) {
        monitor.pathUpdateHandler = { path in
            completion(path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}

