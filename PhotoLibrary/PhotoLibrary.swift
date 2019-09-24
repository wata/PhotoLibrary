//
//  PhotoLibrary.swift
//  PhotoLibrary
//
//  Created by Wataru Nagasawa on 2019/09/24.
//  Copyright © 2019 Wataru Nagasawa. All rights reserved.
//

import Foundation

import Photos

public final class PhotoLibrary: NSObject {
    static let shared = PhotoLibrary()

    private var observations = [UUID: (fetchResult: PHFetchResult<PHAsset>,
                                       closure: ((PhotoLibrary, PHFetchResultChangeDetails<PHAsset>) -> Void))]()

    private override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    public var authorizationStatus: PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }

    public var isAuthorized: Bool {
        return authorizationStatus == .authorized
    }
}

extension PhotoLibrary: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        observations.forEach {
            guard let changes = changeInstance.changeDetails(for: $1.fetchResult) else { return }
            observations[$0]?.fetchResult = changes.fetchResultAfterChanges
            $1.closure(self, changes)
        }
    }
}

extension PhotoLibrary {
    @discardableResult
    func addObserver<T: AnyObject>(
        _ observer: T,
        options: PHFetchOptions,
        using closure: @escaping (T, PhotoLibrary, PHFetchResultChangeDetails<PHAsset>) -> Void
        ) -> ObservationToken {
        let id = UUID()

        guard isAuthorized else {
            fatalError("The application is not authorized to access photo data")
        }

        // First call.
        let fetchResult = PHAsset.fetchAssets(with: options)
        let changes = PHFetchResultChangeDetails(from: PHFetchResult<PHAsset>(), to: fetchResult, changedObjects: [])
        closure(observer, self, changes)

        // Register closure to observations.
        observations[id] = (fetchResult, { [weak self, weak observer] (sender, changes) in
            // If the observer has been deallocated, we can
            // automatically remove the observation closure.
            guard let observer = observer else {
                self?.observations.removeValue(forKey: id)
                return
            }
            closure(observer, sender, changes)
        })

        return ObservationToken { [weak self] in
            self?.observations.removeValue(forKey: id)
        }
    }
}

public final class ObservationToken {
    private let cancellationClosure: () -> Void

    init(cancellationClosure: @escaping () -> Void) {
        self.cancellationClosure = cancellationClosure
    }

    public func cancel() {
        cancellationClosure()
    }
}
