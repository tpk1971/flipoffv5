import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake implementation of [FirebaseAuth] that operates entirely in memory
/// for unit and widget testing.
class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  /// The mock current user.
  User? _currentUser;

  /// Creates a [FakeFirebaseAuth] with an optional initial user.
  FakeFirebaseAuth({User? initialUser}) : _currentUser = initialUser;

  @override
  User? get currentUser => _currentUser;

  /// Explicitly sets the mock current user.
  ///
  /// Used in tests to simulate an already logged-in session.
  void mockSetCurrentUser(User? user) {
    _currentUser = user;
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    final fakeUser = FakeUser(uid: 'anonymous_fake_uid');
    _currentUser = fakeUser;
    return FakeUserCredential(fakeUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }
}

/// A fake implementation of [User] that simulates a Firebase user session.
class FakeUser extends Fake implements User {
  final String _uid;

  /// Creates a [FakeUser] with the specified [uid].
  FakeUser({required String uid}) : _uid = uid;

  @override
  String get uid => _uid;

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    if (_uid == 'invalid_token_uid') {
      throw FirebaseAuthException(
        code: 'user-token-expired',
        message: 'INVALID_REFRESH_TOKEN',
      );
    }
    return 'fake_token';
  }
}

/// A fake implementation of [UserCredential] containing a [FakeUser].
class FakeUserCredential extends Fake implements UserCredential {
  final User _user;

  /// Creates a [FakeUserCredential] wrapping the given [_user].
  FakeUserCredential(this._user);

  @override
  User? get user => _user;
}

/// A fake implementation of [FirebaseFirestore] that simulates basic document storage.
class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _data = {};

  /// Accesses the underlying mocked data store directly.
  Map<String, Map<String, dynamic>> get dataStore => _data;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(collectionPath, _data);
  }
}

/// A fake implementation of [CollectionReference] for simulated Firestore.
class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  final String _path;
  final Map<String, Map<String, dynamic>> _data;

  /// Creates a [FakeCollectionReference] pointing to [_path].
  FakeCollectionReference(this._path, this._data);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return FakeDocumentReference(_path, path ?? 'default_doc', _data);
  }
}

/// A fake implementation of [DocumentReference] for simulated Firestore.
class FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  final String _collectionPath;
  final String _docPath;
  final Map<String, Map<String, dynamic>> _data;

  /// Creates a [FakeDocumentReference] pointing to [_docPath] in [_collectionPath].
  FakeDocumentReference(this._collectionPath, this._docPath, this._data);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final key = '$_collectionPath/$_docPath';
    final docData = _data[key];
    return FakeDocumentSnapshot(docData != null, docData);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    final key = '$_collectionPath/$_docPath';
    if (options?.merge == true && _data.containsKey(key)) {
      _data[key]!.addAll(data);
    } else {
      _data[key] = Map<String, dynamic>.from(data);
    }
  }
}

/// A fake implementation of [DocumentSnapshot] containing retrieved document data.
class FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final bool _exists;
  final Map<String, dynamic>? _data;

  /// Creates a [FakeDocumentSnapshot] with existence check and payload data.
  FakeDocumentSnapshot(this._exists, this._data);

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;
}
