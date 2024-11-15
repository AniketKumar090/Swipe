import Foundation
import SwiftUI

struct CardView: View {
    var product: ProductViewModel?
    var toggleFavorite: () -> Void
    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 12) {
               
                AsyncImage(url: URL(string: product?.image?.isEmpty == true ? "https://via.placeholder.com/150" : product?.image ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.1)
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(height: 100)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(product?.product_name ?? "Unknown Product")
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .truncationMode(.tail)
                    
                    Label(product?.product_type ?? "Unknown Type", systemImage: "tag")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    PriceTag(title: "₹", value: "\(String(format: "%.2f", product?.price ?? 0))")
                    PriceTag(title: "Tax", value: "\(product?.tax.formatted() ?? "0")%")
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

           
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    toggleFavorite()
                }
            }) {
                Image(systemName: product?.isFavorite ?? false ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundColor(product?.isFavorite ?? false ? .red : .gray)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
                    .padding(8)
            }
            
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .buttonStyle(PlainButtonStyle())
       
    }
}


struct PriceTag: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 10))
                .fontWeight(.semibold)
                .foregroundColor(.black)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
