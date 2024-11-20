import SwiftUI

struct AddProductView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    var onProductAdded: () -> Void
    @StateObject private var productManager = ProductManager.shared
    
    @State private var productName = ""
    @State private var productType = ""
    @State private var price = ""
    @State private var taxRate = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isAnimating = false
    
    let productTypes = ["Electronics", "Clothing", "Food", "Books", "Accessories", "Other"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: selectedImage == nil ? 200 : 250)
                            
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .transition(.opacity)
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("Add Product Image")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .onTapGesture {
                            showImagePicker = true
                        }
                        .animation(.easeInOut, value: selectedImage)
                    }
                    .padding(.horizontal)
                    
                    
                    VStack(spacing: 20) {
                        CustomTextField(title: "Product Name", icon: "tag", text: $productName)
                        
                        CustomPicker(title: "Product Type", icon: "square.grid.2x2", selection: $productType, options: productTypes)
                        
                        CustomTextField(title: "Price", icon: "indianrupeesign.circle", text: $price, keyboardType: .decimalPad)
                        
                        CustomTextField(title: "Tax Rate (%)", icon: "percent", text: $taxRate, keyboardType: .decimalPad)
                    }
                    .padding(.horizontal)
                    
                  
                    Button(action: submitProduct) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                Text("Submit Product")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(isValidForm() ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .disabled(isLoading || !isValidForm())
                    .opacity(isValidForm() ? 1 : 0.7)
                }
                .padding(.vertical)
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert("Message", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("Success") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
                
            }
        }
    }
    private func handleSuccess() {
            alertMessage = "Success: Product added successfully"
            showingAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onProductAdded()  // Call the refresh callback
                dismiss()
            }
        }
    private func isValidForm() -> Bool {
        guard !productName.isEmpty,
              !productType.isEmpty,
              let priceValue = Double(price),
              let taxValue = Double(taxRate),
              priceValue > 0,
              taxValue >= 0 && taxValue <= 100 else {
            return false
        }
        return true
    }
    
    private func submitProduct() {
        
        guard let priceValue = Double(price),
              let taxValue = Double(taxRate) else {
            return
        }
        isLoading = true
        let product = ProductViewModel(
                    product_name: productName,
                    product_type: productType,
                    price: priceValue,
                    tax: taxValue
                )
        productManager.addProduct(product: product, image: selectedImage, context: context)
                handleSuccess()
        

        var imageBase64: String = ""
        if let image = selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.5) {
            imageBase64 = imageData.base64EncodedString()
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        let formFields = [
            "product_name": productName,
            "product_type": productType,
            "price": String(priceValue),
            "tax": String(taxValue)
        ]
        
        for (key, value) in formFields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        if !imageBase64.isEmpty {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            if let imageData = Data(base64Encoded: imageBase64) {
                body.append(imageData)
            }
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        
        guard let url = URL(string: "https://app.getswipe.in/api/public/add") else {
            handleError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("swiftui2.0", forHTTPHeaderField: "field") // Adding the required header
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    handleError(error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        handleSuccess()
                    case 500:
                        handleError("Server error. Please try again later.")
                    default:
                        if let data = data,
                           let errorMessage = String(data: data, encoding: .utf8) {
                            handleError("Error: \(errorMessage)")
                        } else {
                            handleError("Error: Server returned status code \(httpResponse.statusCode)")
                        }
                    }
                }
            }
        }.resume()
    }
    

    private func handleError(_ message: String) {
        isLoading = false
        alertMessage = message
        showingAlert = true
        print("Error: \(message)")
    }
}


extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
