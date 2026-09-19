import SwiftUI

struct PlacePhotoAsset: Codable, Identifiable, Hashable {
    let id: String
    let thumbnailURL: URL
    let imageURL: URL
    let width: Int
    let height: Int
    let caption: String?
    let capturedAt: String?
    let publishedAt: String?
    let attribution: String
    let source: String
    let contributionID: String?

    var isDisplayable: Bool {
        !id.isEmpty && width > 0 && height > 0 &&
        ["https", "bundle", "prototype-photo"].contains(thumbnailURL.scheme ?? "") &&
        ["https", "bundle", "prototype-photo"].contains(imageURL.scheme ?? "")
    }

    // Same response shape as remote photos, using bundled URLs only for labelled fixtures.
    static var examples: [Self] {
        guard let url = Bundle.main.url(forResource: "ExamplePlacePhotos", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let photos = try? JSONDecoder().decode([Self].self, from: data) else { return [] }
        return photos.filter(\.isDisplayable)
    }

    static var legacyLibrary: [Self] {
        guard let url = Bundle.main.url(forResource: "RiversideLibraryPrototype", withExtension: "png"),
              let image = UIImage(contentsOfFile: url.path) else { return [] }
        let reference = URL(string: "bundle://RiversideLibraryPrototype.png")!
        return [.init(id: "example-riverside-photo", thumbnailURL: reference, imageURL: reference,
                      width: Int(image.size.width), height: Int(image.size.height), caption: "Riverside Library",
                      capturedAt: nil, publishedAt: nil, attribution: "Riverside Library example photo",
                      source: "illustration", contributionID: nil)]
    }
}

private struct PhotoSelection: Identifiable {
    let id: String
}

struct PlacePhotoStrip: View {
    let photos: [PlacePhotoAsset]
    let placeName: String
    @State private var selection: PhotoSelection?

    var body: some View {
        if !photos.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Photos · \(photos.count)").font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    if photos.count > 1 {
                        NavigationLink("See all") { PlacePhotoGallery(photos: photos, placeName: placeName) }
                            .font(.subheadline.weight(.semibold))
                            .frame(minHeight: 44)
                            .accessibilityLabel("See all \(photos.count) photos")
                    }
                }
                GeometryReader { geometry in
                HStack(spacing: 8) {
                    ForEach(Array(photos.prefix(3))) { photo in
                        Button { selection = .init(id: photo.id) } label: {
                            PlacePhotoImage(url: photo.thumbnailURL, fill: true)
                                .frame(width: (geometry.size.width - 16) / 3, height: 108).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(photo.caption ?? "View place photo")
                    }
                }
                }.frame(height: 108)
            }
            .fullScreenCover(item: $selection) { selection in
                PlacePhotoViewer(photos: photos, selectedID: selection.id, placeName: placeName)
            }
        }
    }
}

struct PlacePhotoGallery: View {
    let photos: [PlacePhotoAsset]
    let placeName: String
    @State private var selection: PhotoSelection?
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 8)], spacing: 8) {
                ForEach(photos) { photo in
                    Button { selection = .init(id: photo.id) } label: {
                        GeometryReader { geometry in
                            PlacePhotoImage(url: photo.thumbnailURL, fill: true)
                                .frame(width: geometry.size.width, height: 160).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }.frame(height: 160)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(photo.caption ?? "View place photo")
                }
            }.padding(20)
        }
        .navigationTitle("Photos").navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selection) { selection in
            PlacePhotoViewer(photos: photos, selectedID: selection.id, placeName: placeName)
        }
    }
}

private struct PlacePhotoViewer: View {
    let photos: [PlacePhotoAsset]
    @State var selectedID: String
    let placeName: String
    @Environment(\.dismiss) private var dismiss
    private var selected: PlacePhotoAsset? { photos.first { $0.id == selectedID } }
    private var index: Int { photos.firstIndex { $0.id == selectedID } ?? 0 }
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $selectedID) {
                    ForEach(photos) { photo in
                        PlacePhotoImage(url: photo.imageURL, fill: false)
                            .tag(photo.id)
                            .accessibilityLabel(photo.caption ?? "Place photo")
                    }
                }.tabViewStyle(.page(indexDisplayMode: .never))
                HStack {
                    Button { selectedID = photos[index - 1].id } label: {
                        Label("Previous", systemImage: "chevron.left")
                    }.disabled(index == 0)
                    Spacer()
                    Button { selectedID = photos[index + 1].id } label: {
                        Label("Next", systemImage: "chevron.right")
                    }.disabled(index == photos.count - 1)
                }.font(.subheadline).frame(minHeight: 44).padding(.horizontal, 20)
                if let photo = selected {
                    VStack(alignment: .leading, spacing: 6) {
                        if let caption = photo.caption, !caption.isEmpty { Text(caption) }
                        Text(photo.attribution).font(.caption).foregroundStyle(.secondary)
                        if let time = photo.capturedAt,
                           let date = ISO8601DateFormatter().date(from: time) {
                            Text("Taken \(date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
                }
            }
            .navigationTitle("\(index + 1) of \(photos.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }.tint(AppStyle.brand)
    }
}

private struct PlacePhotoImage: View {
    let url: URL
    let fill: Bool
    @State private var attempt = 0
    private var bundledImage: UIImage? {
        if let file = PrototypePhotoStorage.fileURL(for: url) { return UIImage(contentsOfFile: file.path) }
        guard url.scheme == "bundle", let filename = url.host,
              let file = Bundle.main.url(forResource: (filename as NSString).deletingPathExtension,
                                         withExtension: (filename as NSString).pathExtension) else { return nil }
        return UIImage(contentsOfFile: file.path)
    }
    var body: some View {
        Group {
            if let image = bundledImage {
                rendered(Image(uiImage: image))
            } else if url.scheme == "https" {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image): rendered(image)
                    case .failure:
                        if fill {
                            Image(systemName: "photo").foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            Button { attempt += 1 } label: { Label("Retry photo", systemImage: "arrow.clockwise") }
                                .font(.caption).frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    @unknown default: EmptyView()
                    }
                }.id(attempt)
            } else {
                Label("Photo unavailable", systemImage: "photo")
                    .font(.caption).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }.background(Color(uiColor: .secondarySystemBackground))
    }
    private func rendered(_ image: Image) -> some View {
        image.resizable().aspectRatio(contentMode: fill ? .fill : .fit)
    }
}
