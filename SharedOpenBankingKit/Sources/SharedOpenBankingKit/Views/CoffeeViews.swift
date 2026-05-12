import SwiftUI

struct ShopCarousel: View {
    let shops: [CoffeeShop]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(shops) { shop in
                    ShopCard(shop: shop)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: 360)
    }
}

private struct ShopCard: View {
    @EnvironmentObject private var store: AppStore
    let shop: CoffeeShop

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(Color(hex: shop.brandColorHex))
                    .frame(width: 12, height: 12)
                Text(shop.name)
                    .font(.headline)
                    .lineLimit(1)
            }

            Text("\(shop.distanceMeters)m away · \(shop.estimatedPickupMinutes) min pickup")
                .font(.caption)
                .foregroundStyle(AppTheme.muted)

            VStack(spacing: 6) {
                ForEach(shop.menu) { item in
                    Button {
                        store.send(.selectShop(shop))
                        store.send(.selectCoffee(item))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.detail)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                            }
                            Spacer()
                            Text(item.price.moneyText)
                                .font(.subheadline)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                store.send(.selectShop(shop))
                store.send(.createOrder)
            } label: {
                Label("Order", systemImage: "cup.and.saucer.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: shop.brandColorHex))
        }
        .padding(14)
        .frame(width: 270, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
    }
}

struct OrderCard: View {
    @EnvironmentObject private var store: AppStore
    let order: CoffeeOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.item.name)
                        .font(.headline)
                    Text(order.shop.name)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Text(order.total.moneyText)
                    .font(.headline)
            }

            HStack {
                Label(order.size.rawValue, systemImage: "smallcircle.filled.circle")
                Label("Qty \(order.quantity)", systemImage: "number")
            }
            .font(.caption)
            .foregroundStyle(AppTheme.muted)

            HStack {
                Button {
                    store.send(.confirmPayment)
                } label: {
                    Label("Pay", systemImage: "faceid")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.hsbcRed)

                Button("Edit") {}
                    .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .frame(maxWidth: 320)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
    }
}

struct ReceiptCard: View {
    let receipt: PaymentReceipt

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Payment successful", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.green)

            Text("Reference \(receipt.paymentReference)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)

            Text(receipt.amount.moneyText)
                .font(.title3.weight(.semibold))
        }
        .padding(14)
        .frame(maxWidth: 320, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
    }
}
