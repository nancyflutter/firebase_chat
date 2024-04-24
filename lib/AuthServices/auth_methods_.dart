import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat/Constants/common_controller_.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;

  /// SignInWithGoogle
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final String username = Constants.nameController.text;
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Add user information to Firestore
      await addUserToFirestore(username, userCredential.user?.email ?? 'Unknown');

      return userCredential;
    } catch (e) {
      print('Google Sign-In Error:------------ $e');
      return null;
    }
  }

  /// Create User With Email and Password
  Future<UserCredential?> createUserWithEmailPassword({required String email, required String password}) async {
    try {
      final String username = Constants.nameController.text;
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user information to Firestore
      await addUserToFirestore(username, email);

      return credential;
    } on FirebaseAuthException catch (e) {
      print("Firebase Authentication Error:-------------- ${e.code}");
      print("Firebase Authentication Error Message:------------ ${e.message}");
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  /// Sign In With Email and Password  ------ LogIn User
  Future<UserCredential?> logInWithEmailPassword({required String email, required String password}) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save the email to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('userEmail', email);

      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  /// Function to create a Firestore collection and add a document with user name and email ID
  Future<void> addUserToFirestore(String name, String email) async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Create a reference to the Firestore collection
        CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

        // Add a new document to the collection with user data
        await usersCollection.add({
          'name': name,
          'email': email,
          'user_id': user.uid,
          'status': "Unavailable"
        });

        print('User added to Firestore:---------------------- $name, $email, ${user.uid}');
      } else {
        print('No user is signed in.-----------');
      }
    } catch (e) {
      print('Error adding user to Firestore:--------------- $e');
    }
  }

  Future<User?> getCurrentUser() async {
    final user = _auth.currentUser;
    return user;
  }
}
