//
// Copyright © Suguru Kishimoto. All rights reserved.
//

import FirebaseFirestore
import Foundation

@dynamicMemberLookup
public final class Snapshot<D>: SnapshotType where D: SnapshotData {
    public typealias Data = D
    public typealias DataFactory = (DocumentReference) -> D
    public private(set) var data: D
    public let reference: DocumentReference
    public var path: DocumentPath<D> {
        DocumentPath(reference.path)
    }

    public private(set) var snapshot: DocumentSnapshot?

    private var _createTime: Timestamp?
    private var _updateTime: Timestamp?

    public init(data: D, reference: DocumentReference) {
        self.reference = reference
        self.data = data
    }

    public convenience init(data: D, path: DocumentPath<D>) {
        self.init(data: data, reference: path.documentReference)
    }

    public convenience init(dataFactory: DataFactory, path: DocumentPath<D>) {
        let ref = path.documentReference
        self.init(data: dataFactory(ref), reference: ref)
    }

    public convenience init(data: D, path: CollectionPath<D>, id: String? = nil) {
        self.init(data: data, reference: path.documentRefernce(id: id))
    }

    public convenience init(dataFactory: DataFactory, path: CollectionPath<D>, id: String? = nil) {
        let ref = path.documentRefernce(id: id)
        self.init(data: dataFactory(ref), reference: ref)
    }

    public convenience init(snapshot: DocumentSnapshot) throws {
        guard let data = try? snapshot.data(as: D.self), snapshot.exists else {
            throw SnapshotError.notExists
        }

        self.init(data: data, reference: snapshot.reference)
        self.snapshot = snapshot
        if data is HasTimestamps {
            _createTime = snapshot.data()?[SnapshotTimestampKey.createTime.rawValue] as? Timestamp
            _updateTime = snapshot.data()?[SnapshotTimestampKey.updateTime.rawValue] as? Timestamp
        }
    }

    public subscript<V>(dynamicMember keyPath: WritableKeyPath<D, V>) -> V {
        get {
            return data[keyPath: keyPath]
        }
        set {
            data[keyPath: keyPath] = newValue
        }
    }

    public subscript<T, U>(dynamicMember keyPath: KeyPath<D, Reference<T, U>>) -> Reference<T, U> where T: SnapshotData, U: ReferenceWrappable & Codable & Equatable {
        return data[keyPath: keyPath]
    }

    public func replicated(path: DocumentPath<D>? = nil) throws -> Snapshot<D> {
        let replicated = Snapshot<D>(
            data: try Firestore.Decoder().decode(D.self, from: try Firestore.Encoder().encode(data)),
            path: path ?? self.path
        )
        if data is HasTimestamps {
            replicated._createTime = _createTime
            replicated._updateTime = _updateTime
        }
        return replicated
    }
}

extension Snapshot: Equatable where D: Equatable {
    public static func == (lhs: Snapshot<D>, rhs: Snapshot<D>) -> Bool {
        return lhs.reference.path == rhs.reference.path
            && lhs.data == rhs.data
    }
}

public extension Snapshot where D: HasTimestamps {
    var createTime: Timestamp? {
       _createTime
    }

    var updateTime: Timestamp? {
        _updateTime
    }
}
