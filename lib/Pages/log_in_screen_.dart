import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat/AuthServices/auth_methods_.dart';
import 'package:firebase_chat/Constants/common_controller_.dart';
import 'package:firebase_chat/Constants/common_widgets_.dart';
import 'package:firebase_chat/Pages/home_page.dart';
import 'package:firebase_chat/Pages/sing_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final _formKey = GlobalKey<FormState>();
  bool isLoadingData = false;

  bool isSignIn = false;
  bool google = false;

  logIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoadingData = true;
      });

      // Get user input
      final email = Constants.emailController.text.trim();
      final password = Constants.passWordController.text.trim();

      // Call your signInWithEmailPassword method
      final userCredential = await AuthServices().logInWithEmailPassword(
        email: email,
        password: password,
      );

      setState(() {
        isLoadingData = false;
      });

      if (userCredential != null) {
        // Sign-in was successful, navigate to the next screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
        debugPrint("User signed in: ${userCredential.user!.email}");
      } else {
        // Sign-in failed, show an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login failed. Check your credentials."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xff363636),
      appBar: AppBar(
        backgroundColor: const Color(0xff363636),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          "Log In",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(
              right: 10.0,
            ),
            child: Icon(
              Icons.search,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(15.0),
              child: ListView(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          validator: (value) => value!.isEmpty || !value.contains("@") ? "Enter a valid email" : null,
                          cursorColor: Colors.teal,
                          controller: Constants.emailController,
                          style: textStyleForTextField(),
                          decoration: textFieldDecoration("Email"),
                        ),
                        TextFormField(
                          validator: (value) {
                            return value!.isEmpty ? "Please Enter PassWord" : null;
                          },
                          cursorColor: Colors.teal,
                          style: textStyleForTextField(),
                          controller: Constants.passWordController,
                          decoration: textFieldDecoration("PassWord"),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: FractionalOffset.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        "Forgot PassWord?",
                        style: textStyle(),
                      ),
                    ),
                  ),
                  MaterialButton(
                    onPressed: () {
                      /// For Check Validation
                      logIn();
                    },
                    color: Colors.teal[200],
                    child: const Text(
                      "Log In",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  MaterialButton(
                    onPressed: () async {
                      await AuthServices().signInWithGoogle().then(
                            (value) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                            ),
                          );
                      debugPrint("Auth ----------->> ${auth.currentUser!.displayName}");
                    },
                    color: Colors.teal[50],
                    child: const Text(
                      "Log In with Google",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Don't have Account?",
                          style: TextStyle(color: Colors.teal),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return const SingUpScreen();
                              },
                            ),
                          );
                        },
                        child: Text(
                          "Register Now",
                          style: textStyle(),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}
