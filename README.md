# PhotoLibrary

Simple Swift wrapper for Photos framework that works on iOS.

## Usage

```swift
let fetchOptions = PHFetchOptions()
fetchOptions.fetchLimit = 1
fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
PhotoLibrary.shared.addObserver(self, options: fetchOptions) { (imageView, photoLibrary, changes) in
    guard let asset = changes.fetchResultAfterChanges.firstObject else { return }
    let requestOptions = PHImageRequestOptions()
    requestOptions.version = .current
    requestOptions.resizeMode = .fast
    requestOptions.deliveryMode = .fastFormat
    requestOptions.isNetworkAccessAllowed = true
    PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 90, height: 160), contentMode: .aspectFill, options: requestOptions) { (image, _) in
        DispatchQueue.main.async {
            imageView.image = image
        }
    }
}
```