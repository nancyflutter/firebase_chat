import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat/AuthServices/auth_methods_.dart';
import 'package:firebase_chat/Constants/common_controller_.dart';
import 'package:firebase_chat/Constants/common_widgets_.dart';
import 'package:firebase_chat/Pages/home_page.dart';
import 'package:firebase_chat/Pages/log_in_screen_.dart';
import 'package:flutter/material.dart';

class SingUpScreen extends StatefulWidget {
  const SingUpScreen({super.key});

  @override
  State<SingUpScreen> createState() => _SingUpScreenState();
}

class _SingUpScreenState extends State<SingUpScreen> {
  // TextEditingController userNameController = TextEditingController();
  // TextEditingController emailController = TextEditingController();
  // TextEditingController passWordController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  signIn() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      // Get user input
      final email = Constants.emailController.text.trim();
      final password = Constants.passWordController.text.trim();

      // Call your signInWithEmailPassword method
      final userCredential = await AuthServices().createUserWithEmailPassword(
        email: email,
        password: password,
      );

      setState(() {
        isLoading = false;
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
        print("login failed ----------------------------------- ");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xff363636),
      appBar: AppBar(
        backgroundColor: const Color(0xff363636),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          "Sing In",
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
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView(
          children: [
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    validator: (value) {
                      return value!.isEmpty ? "Please Enter UserName" : null;
                    },
                    cursorColor: Colors.teal,
                    controller: Constants.nameController,
                    style: textStyleForTextField(),
                    decoration: textFieldDecoration("UserName"),
                  ),
                  TextFormField(
                    validator: (value) => value!.isEmpty || !value.contains("@") ? "Enter a valid email" : null,
                    // if(value == null || value.isEmpty || !value.contains('@') || !value.contains('.')){
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
                /// To Check Validation
                signIn();
              },
              color: Colors.teal[200],
              child: const Text(
                "Sing In",
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
                "Sing In with Google",
                style: TextStyle(color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Already have Account?",
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const LogInScreen();
                        },
                      ),
                    );
                  },
                  child: Text(
                    "Log In  Now",
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
