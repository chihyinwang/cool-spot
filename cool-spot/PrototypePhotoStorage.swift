import UIKit

// Local prototype media only. Public responses contain opaque references, never file paths or image bytes.
enum PrototypePhotoStorage {
    static var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PrototypePlacePhotos", isDirectory: true)
    }

    static func stage(_ data: Data) throws -> String {
        guard let image = UIImage(data: data) else { throw PrototypePublicationError.missingPhoto }
        let id = UUID().uuidString
        let folder = directory.appendingPathComponent(id, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        do {
            try data.write(to: folder.appendingPathComponent("original"), options: .atomic)
            try jpeg(image, maxDimension: 1600).write(to: folder.appendingPathComponent("image.jpg"), options: .atomic)
            try jpeg(image, maxDimension: 400).write(to: folder.appendingPathComponent("thumb.jpg"), options: .atomic)
        } catch {
            try? FileManager.default.removeItem(at: folder)
            throw error
        }
        return id
    }

    static func original(id: String) -> Data? {
        guard UUID(uuidString: id) != nil else { return nil }
        return try? Data(contentsOf: directory.appendingPathComponent(id).appendingPathComponent("original"))
    }

    static func fileURL(for reference: URL) -> URL? {
        guard reference.scheme == "prototype-photo", let id = reference.host, UUID(uuidString: id) != nil,
              ["/image.jpg", "/thumb.jpg"].contains(reference.path) else { return nil }
        return directory.appendingPathComponent(id).appendingPathComponent(String(reference.path.dropFirst()))
    }

    static func publishedPhoto(id: String, contributionID: String, at time: String) throws -> PlacePhotoAsset {
        guard let url = URL(string: "prototype-photo://\(id)/image.jpg"), let file = fileURL(for: url),
              let image = UIImage(contentsOfFile: file.path), let pixels = image.cgImage else {
            throw PrototypePublicationError.missingPhoto
        }
        return .init(id: id, thumbnailURL: URL(string: "prototype-photo://\(id)/thumb.jpg")!, imageURL: url,
                     width: pixels.width, height: pixels.height, caption: nil, capturedAt: nil, publishedAt: time,
                     attribution: "Community photo · Local demo", source: "community", contributionID: contributionID)
    }

    private static func jpeg(_ image: UIImage, maxDimension: CGFloat) throws -> Data {
        let ratio = min(1, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: max(1, image.size.width * ratio), height: max(1, image.size.height * ratio))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = rendered.jpegData(compressionQuality: 0.85) else { throw PrototypePublicationError.missingPhoto }
        return data
    }
}
