import SwiftUI

struct PortfolioSummaryCard: View {
    let portfolio: PortfolioSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio summary")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("Total assets")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer()

                Text(portfolio.totalValue.moneyText)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
            }

            HStack(alignment: .center, spacing: 14) {
                PortfolioPieChart(categories: portfolio.categories)
                    .frame(width: 106, height: 106)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(portfolio.categories) { category in
                        PortfolioLegendRow(category: category)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: 360, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
    }
}

private struct PortfolioPieChart: View {
    let categories: [PortfolioCategory]

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let total = categories.reduce(0.0) { $0 + $1.percentage }
            var startAngle = Angle(degrees: -90)

            for category in categories {
                let degrees = 360 * category.percentage / total
                let endAngle = startAngle + Angle(degrees: degrees)
                var path = Path()
                path.move(to: CGPoint(x: rect.midX, y: rect.midY))
                path.addArc(
                    center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: min(size.width, size.height) / 2,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.closeSubpath()
                context.fill(path, with: .color(Color(hex: category.colorHex)))
                startAngle = endAngle
            }
        }
        .clipShape(Circle())
        .accessibilityLabel("Portfolio allocation chart")
    }
}

private struct PortfolioLegendRow: View {
    let category: PortfolioCategory

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Circle()
                .fill(Color(hex: category.colorHex))
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(category.name) (\(category.percentage.percentText))")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                Text(category.value.moneyText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
            }
        }
    }
}

struct TopFundsCard: View {
    let fundsList: TopFundsList

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(fundsList.title)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(fundsList.funds.enumerated()), id: \.element.id) { index, fund in
                    TopFundRow(fund: fund)
                    if index < fundsList.funds.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: 360, alignment: .leading)
        .background(.white)
    }
}

private struct TopFundRow: View {
    let fund: TopFund

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(fund.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(fund.code)
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                    if let badge = fund.badge {
                        Text(badge)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color(red: 59 / 255, green: 130 / 255, blue: 246 / 255))
                            .padding(.horizontal, 7)
                            .frame(height: 24)
                            .background(Color(red: 230 / 255, green: 240 / 255, blue: 255 / 255))
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                }
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 8) {
                Text("+\(fund.oneYearReturn.percentText)")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(Color(red: 36 / 255, green: 171 / 255, blue: 91 / 255))
                    .lineLimit(1)
                Text("1Y return")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .padding(.vertical, 12)
    }
}

private extension Double {
    var percentText: String {
        String(format: "%.2f%%", self)
    }
}
