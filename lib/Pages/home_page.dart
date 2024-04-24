import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat/Pages/log_in_screen_.dart';
import 'package:firebase_chat/Screens/group_screen.dart';
import 'package:firebase_chat/Screens/message_screen.dart';
import 'package:firebase_chat/Screens/online_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final stringList = <StringModel>[
    StringModel(stringValue: "Messages"),
    StringModel(stringValue: "Online"),
    StringModel(stringValue: "Group"),
  ];

  int selectedTabIndex = 0;

  String? userEmail;

  /// Avtar image pick
  final ImagePicker picker = ImagePicker();
  XFile? image;
  String? imageURL;

  @override
  void initState() {
    super.initState();
    // Call a separate async function to initialize data
    initializeData();
  }

  Future<String?> getUserUID() async {
    final user = auth.currentUser;
    return user?.uid;
  }

  Future<void> initializeData() async {
    // Retrieve the user's UID
    final userUID = await getUserUID();

    if (userUID != null) {
      // Retrieve the user's email from SharedPreferences
      final userEmail = await getUserEmail();

      // Retrieve the stored image path for the specific user
      final prefs = await SharedPreferences.getInstance();
      final storedImagePath = prefs.getString('imagePath_$userUID');

      setState(() {
        this.userEmail = userEmail;
        imageURL = storedImagePath;
      });
    }
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        image = pickedFile;
      });
    }
  }

  Future<void> uploadImageToStorage() async {
    if (image == null) {
      // No image picked
      return;
    }

    final storage = FirebaseStorage.instance;
    final user = auth.currentUser;

    if (user == null) {
      // User is not logged in
      return;
    }

    final Reference storageRef = storage.ref().child('images/${user.uid}.png');

    final UploadTask uploadTask = storageRef.putFile(File(image!.path));

    // Monitor the upload task
    await uploadTask.whenComplete(() async {
      // Store the image path in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('imagePath_${user.uid}', image!.path);

      setState(() {
        imageURL = image!.path;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff363636),
      appBar: AppBar(
        backgroundColor: const Color(0xff363636),
        iconTheme: const IconThemeData(
          color: Colors.white,
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
      drawer: Drawer(
        backgroundColor: const Color(0xff363636),
        child: Padding(
          padding: const EdgeInsets.only(left: 25.0, top: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  await pickImage();
                  await uploadImageToStorage();
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF00BFA5),
                      backgroundImage: imageURL != null ? FileImage(File(imageURL!)) : null,
                      radius: 30,
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: Text(
                        "${auth.currentUser!.email}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: Row(
                  children: [
                    Icon(Icons.key_rounded, color: Colors.white),
                    Padding(
                      padding: EdgeInsets.only(left: 25.0),
                      child: Text(
                        "Account",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.white),
                    Padding(
                      padding: EdgeInsets.only(left: 25.0),
                      child: Text(
                        "Chat",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.white),
                    Padding(
                      padding: EdgeInsets.only(left: 25.0),
                      child: Text(
                        "Notification",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: Row(
                  children: [
                    Icon(Icons.storage, color: Colors.white),
                    Padding(
                      padding: EdgeInsets.only(left: 25.0),
                      child: Text(
                        "Data And Storage",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: Row(
                  children: [
                    Icon(Icons.help, color: Colors.white),
                    Padding(
                      padding: EdgeInsets.only(left: 25.0),
                      child: Text(
                        "Help",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: Divider(
                  color: Colors.teal,
                  endIndent: 40,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: Row(
                  children: [
                    Icon(Icons.group, color: Colors.white),
                    Padding(
                      padding: EdgeInsets.only(left: 25.0),
                      child: Text(
                        "Invite a Friend",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              /// Log Out
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Row(
                  children: [
                    const Icon(Icons.logout_outlined, color: Colors.white),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: TextButton(
                        onPressed: () {
                          auth.signOut();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LogInScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Log Out",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: DefaultTabController(
        length: stringList.length,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xff363636),
              child: TabBar(
                padding: const EdgeInsets.all(8),
                isScrollable: true,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: Colors.transparent,
                ),
                indicatorWeight: 0,
                dividerColor: const Color(0xff363636),
                /// to manage tabs with selected and unselected text style
                tabs: stringList.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final stringList = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                      child: Tab(
                        child: Text(
                          stringList.stringValue!,
                          style: TextStyle(
                            fontSize: 20,
                            color: selectedTabIndex == index ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
                onTap: (index) {
                  setState(() {
                    selectedTabIndex = index;
                  });
                },
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  MessageScreen(),
                  OnlineScreen(),
                  GroupScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StringModel {
  String? stringValue;

  StringModel({this.stringValue});
}

