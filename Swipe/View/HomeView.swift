import Foundation
import SwiftUI

struct Home: View {
    @StateObject var jsonModel = JSonViewModel()
    @Environment(\.managedObjectContext) var context
    @FetchRequest(entity: ProductEntity.entity(), sortDescriptors: [
        NSSortDescriptor(keyPath: \ProductEntity.isFavorite, ascending: false),
        NSSortDescriptor(keyPath: \ProductEntity.product_name, ascending: true)
    ]) var results: FetchedResults<ProductEntity>

    @State private var searchText = ""
    @State private var showingAddProduct = false
    @State private var isRefreshing = false
    @State private var selectedTab = 0
    @State private var selectedProductTypes: Set<String> = []

    // MARK: - Computed Properties
    
    var sortedProducts: [ProductViewModel] {
        let favorites = results
            .filter { $0.isFavorite }
            .map { ProductViewModel(from: $0) }

        let nonFavorites = jsonModel.products
            .filter { product in
                !favorites.contains(where: { $0.product_name == product.product_name })
            }

        return favorites + nonFavorites
    }

    var filteredProducts: [ProductViewModel] {
        sortedProducts.filter { product in
            let matchesSearch = searchText.isEmpty ||
                product.product_name.localizedCaseInsensitiveContains(searchText)
            let matchesType = selectedProductTypes.isEmpty ||
                selectedProductTypes.contains(product.product_type)
            return matchesSearch && matchesType
        }
    }

    var filteredFavorites: [ProductEntity] {
        results.filter { product in
            let matchesSearch = searchText.isEmpty ||
                (product.product_name?.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesType = selectedProductTypes.isEmpty ||
                (selectedProductTypes.contains(product.product_type ?? ""))
            return product.isFavorite && matchesSearch && matchesType
        }
    }

    var productTypes: Set<String> {
        Set(jsonModel.products.map { $0.product_type })
    }

    var productType: [String] {
        Array(productTypes).sorted()
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                searchBarView
                filterView
                mainContentView
                tabView
            }
        }
        .sheet(isPresented: $showingAddProduct) {
            AddProductView(onProductAdded: refreshData)
        }
        .onAppear {
            if jsonModel.products.isEmpty {
                jsonModel.fetchData(context: context)
            }
        }
    }

    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            Text("PRODUCTS")
                .font(.headline)
            
            Spacer()
            
            Button(action: refreshData) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
            }
            .disabled(isRefreshing)
            
            Button(action: { showingAddProduct = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var searchBarView: some View {
        EnhancedSearchBar(text: $searchText)
            .padding()
    }

    private var filterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(productType, id: \.self) { type in
                    FilterButton(
                        type: type,
                        isSelected: selectedProductTypes.contains(type),
                        action: { toggleProductType(type) }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    private var mainContentView: some View {
        Group {
            if jsonModel.isLoading && jsonModel.products.isEmpty {
                LoadingView()
            } else if (selectedTab == 0 ? filteredProducts.isEmpty : filteredFavorites.isEmpty) {
                EmptyStateView(
                    icon: "photo.fill",
                    title: "No Products Found",
                    message: searchText.isEmpty && selectedProductTypes.isEmpty ?
                        "Add your first product" : "Try adjusting your search or filters"
                )
            } else {
                productGridView
            }
        }
    }
    private var tabView: some View {
        HStack {
            TabButton(title: "All", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabButton(title: "Favorites", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

   

    private var productGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                if selectedTab == 0 {
                    ForEach(filteredProducts, id: \.product_name) { product in
                        productCard(for: product)
                    }
                } else {
                    ForEach(filteredFavorites, id: \.self) { entity in
                        productCard(for: ProductViewModel(from: entity))
                    }
                }
            }
            .padding()
        }
    }

    private func productCard(for product: ProductViewModel) -> some View {
        CardView(
            product: product,
            toggleFavorite: {
                withAnimation {
                    toggleFavorite(for: product)
                }
            }
        )
        .frame(width: 180,height: 250)
    }

    // MARK: - Helper Methods
    
    private func toggleProductType(_ type: String) {
        withAnimation {
            if selectedProductTypes.contains(type) {
                selectedProductTypes.remove(type)
            } else {
                selectedProductTypes.insert(type)
            }
        }
    }

    private func refreshData() {
        isRefreshing = true
        jsonModel.fetchData(context: context)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRefreshing = false
        }
    }

    private func toggleFavorite(for product: ProductViewModel) {
        if let existingEntity = results.first(where: { $0.product_name == product.product_name }) {
            existingEntity.isFavorite.toggle()
        } else {
            let entity = ProductEntity(context: context)
            entity.product_name = product.product_name
            entity.product_type = product.product_type
            entity.price = product.price
            entity.tax = product.tax
            entity.image = product.image
            entity.isFavorite = true
        }

        do {
            try context.save()
            if let index = jsonModel.products.firstIndex(where: { $0.product_name == product.product_name }) {
                jsonModel.products[index].isFavorite.toggle()
            }
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct FilterButton: View {
    let type: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.gray.opacity(0.8) : Color.gray.opacity(0.1))
                )
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Capsule()
                        .fill(isSelected ? Color.gray.opacity(0.8) : Color.gray.opacity(0.2))
                )
        }
    }
}



struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading products...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

