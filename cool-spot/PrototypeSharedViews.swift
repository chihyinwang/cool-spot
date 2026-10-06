import SwiftUI

// Proximity follows meaning: metadata, related content, then distinct sections.
enum LayoutSpacing {
    static let metadata: CGFloat = 4
    static let text: CGFloat = 8
    static let related: CGFloat = 12
    static let group: CGFloat = 16
    static let section: CGFloat = 24
    static let majorSection: CGFloat = 32
    static let page: CGFloat = 20
}

struct SourceBadge: View {
    let source: SpotSource
    var body: some View {
        Label(source.rawValue, systemImage: source == .gla ? "checkmark.seal.fill" : source == .community ? "person.2.fill" : "mappin")
            .font(.caption.weight(.bold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(source == .gla ? AppStyle.mint : AppStyle.blue, in: Capsule())
    }
}

struct InfoPill: View {
    let feature: CoolingFeature
    var body: some View {
        Label(feature.rawValue, systemImage: feature.symbol)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppStyle.mint, in: Capsule())
    }
}

struct FactRow: View {
    let symbol: String
    let title: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(AppStyle.informationAccent).frame(width: 24)
                .accessibilityHidden(true)
            Text(title).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? Color.white : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(isEnabled ? (configuration.isPressed ? AppStyle.actionPressedFill : AppStyle.actionFill)
                                  : AppStyle.controlSurface,
                        in: RoundedRectangle(cornerRadius: 14))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? (configuration.isPressed ? AppStyle.actionPressedForeground : AppStyle.actionForeground) : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(configuration.isPressed && isEnabled ? AppStyle.pressedControlSurface : Color(uiColor: .systemBackground),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isEnabled ? (configuration.isPressed ? AppStyle.actionPressedForeground : AppStyle.actionBorder)
                                      : AppStyle.subtleBorder, lineWidth: 1)
            }
    }
}

struct SelectionCard: View {
    let symbol: String
    let title: String
    var subtitle: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutSpacing.related) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(selected ? .white : AppStyle.actionForeground)
                    .frame(width: 44, height: 44)
                    .background(selected ? AppStyle.actionFill : AppStyle.blue, in: Circle())
                VStack(alignment: .leading, spacing: LayoutSpacing.metadata) {
                    Text(title).font(.headline)
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? AppStyle.actionForeground : Color.secondary)
            }
            .padding(LayoutSpacing.group)
            .background(Color.secondary.opacity(selected ? 0.12 : 0.06),
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(selected ? AppStyle.actionForeground : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

struct PlaceCover: View {
    let type: PlaceType
    let environment: PlaceEnvironment
    var isIllustration = false

    var body: some View {
        ZStack {
            LinearGradient(colors: environment == .outdoors
                           ? [Color.green.opacity(0.72), AppStyle.blue]
                           : [AppStyle.blue, AppStyle.mint],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(.white.opacity(0.34)).frame(width: 180).offset(x: 110, y: -30)
            Image(systemName: type.symbol)
                .font(.system(size: 76, weight: .light))
                .foregroundStyle(AppStyle.actionForeground.opacity(0.88))
            VStack {
                Spacer()
                HStack {
                    Label(isIllustration ? "Place illustration" : "Community photo",
                          systemImage: isIllustration ? "building.2" : "photo.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                }
                .padding(14)
            }
        }
        .clipped()
        .accessibilityLabel(isIllustration ? "Place illustration" : "Photo that helps people find this cooling place")
    }
}

struct DetailAction: View {
    let symbol: String
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: LayoutSpacing.text) {
                Image(systemName: symbol).font(.title3).frame(width: 46, height: 46)
                    .background(AppStyle.blue, in: Circle())
                Text(title).font(.caption.weight(.medium)).lineLimit(1)
            }
            .foregroundStyle(AppStyle.actionForeground)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(subviews, width: proposal.width ?? 0).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews, width: bounds.width)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                                  proposal: ProposedViewSize(width: result.sizes[index].width,
                                                             height: result.sizes[index].height))
        }
    }

    private func layout(_ subviews: Subviews, width: CGFloat) -> (size: CGSize, points: [CGPoint], sizes: [CGSize]) {
        var points: [CGPoint] = []
        var sizes: [CGSize] = []
        var cursor = CGPoint.zero
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let ideal = subview.sizeThatFits(.unspecified)
            let itemWidth = max(0, min(ideal.width, width))
            let size = subview.sizeThatFits(ProposedViewSize(width: itemWidth, height: nil))
            if cursor.x > 0, cursor.x + size.width > width {
                cursor.x = 0
                cursor.y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(cursor)
            sizes.append(CGSize(width: itemWidth, height: size.height))
            cursor.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (.init(width: width, height: cursor.y + rowHeight), points, sizes)
    }
}
