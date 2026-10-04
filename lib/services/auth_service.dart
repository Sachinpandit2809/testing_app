// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import '../models/user_model.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<UserModel?> register({
//     required String name,
//     required String email,
//     required String password,
//   }) async {
//     try {
//       UserCredential credential =
//           await _auth.createUserWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );

//       User? firebaseUser = credential.user;

//       if (firebaseUser == null) {
//         return null;
//       }

//       UserModel user = UserModel(
//         uid: firebaseUser.uid,
//         name: name.trim(),
//         email: email.trim(),
//         isOnline: true,
//         lastSeen: DateTime.now(),
//       );

//       await _firestore
//           .collection('users')
//           .doc(firebaseUser.uid)
//           .set(user.toMap());

//       return user;
//     } on FirebaseAuthException catch (e) {
//       throw Exception(e.message ?? 'Registration failed');
//     }
//   }

//   Future<UserModel?> login({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       UserCredential credential =
//           await _auth.signInWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );

//       User? firebaseUser = credential.user;

//       if (firebaseUser == null) {
//         return null;
//       }

//       DocumentSnapshot document = await _firestore
//           .collection('users')
//           .doc(firebaseUser.uid)
//           .get();

//       if (!document.exists) {
//         return null;
//       }

//       await _firestore
//           .collection('users')
//           .doc(firebaseUser.uid)
//           .update({
//         'isOnline': true,
//         'lastSeen': DateTime.now(),
//       });

//       return UserModel.fromMap(
//         document.data() as Map<String, dynamic>,
//       );
//     } on FirebaseAuthException catch (e) {
//       throw Exception(e.message ?? 'Login failed');
//     }
//   }

//   Future<void> logout() async {
//     User? user = _auth.currentUser;

//     if (user != null) {
//       await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .update({
//         'isOnline': false,
//         'lastSeen': DateTime.now(),
//       });
//     }

//     await _auth.signOut();
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================
  // REGISTER
  // =========================

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('User creation failed');
      }

      UserModel user = UserModel(
        uid: firebaseUser.uid,
        name: name.trim(),
        email: email.trim(),
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toMap())
          .timeout(
            const Duration(seconds: 10),
          );

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(
        _getAuthErrorMessage(e.code),
      );
    } on FirebaseException catch (e) {
      throw Exception(
        e.message ?? 'Firebase error occurred',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // =========================
  // LOGIN
  // =========================

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Login failed');
      }

      DocumentSnapshot document = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
          );

      if (!document.exists) {
        throw Exception(
          'User data not found in Firestore',
        );
      }

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .update({
        'isOnline': true,
        'lastSeen': DateTime.now().toIso8601String(),
      }).timeout(
        const Duration(seconds: 10),
      );

      return UserModel.fromMap(
        document.data() as Map<String, dynamic>,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(
        _getAuthErrorMessage(e.code),
      );
    } on FirebaseException catch (e) {
      throw Exception(
        e.message ?? 'Firebase error occurred',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({
          'isOnline': false,
          'lastSeen': DateTime.now().toIso8601String(),
        }).timeout(
          const Duration(seconds: 10),
        );
      }

      await _auth.signOut();
    } on FirebaseException catch (e) {
      throw Exception(
        e.message ?? 'Logout failed',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // =========================
  // FIREBASE AUTH ERRORS
  // =========================

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';

      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'weak-password':
        return 'Password should be at least 6 characters.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'user-disabled':
        return 'This account has been disabled.';

      default:
        return 'Authentication failed: $code';
    }
  }
}