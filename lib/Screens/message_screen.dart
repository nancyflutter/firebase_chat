import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_chat/Screens/message_detail_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  /// for Avtar Image
  Future<String?> getImageURL() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('imageURL');
  }

  /// Function to get the profile picture URL for a user.
  Future<String?> getProfilePictureURL(String userId) async {
    final ref = FirebaseStorage.instance.ref().child('images/$userId.png');
    try {
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // Handle errors if the profile picture doesn't exist or other exceptions.
      return null;
    }
  }

  /// Define a method to handle navigation to WidgetDetailScreen
  void navigateToDetailScreen(String title, String details, String receiverUserId, String? profileImageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return WidgetDetailScreen(
            title: title,
            details: details,
            receiverUserID: receiverUserId,
            profileImageURL: profileImageUrl ?? '', // Pass the profile image URL here
            // imageURL: "$imageURL"
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff363636),
      body: Stack(
        children: [
          Container(
            height: 700,
            decoration: const BoxDecoration(
              color: Color(0xFF00BFA5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 35, left: 30, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Favorite Contacts",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 35.0),
                        child: IconButton(
                          onPressed: () {
                            // // Log a custom event
                            print("object------------------------");
                            analytics.logEvent(name: 'more_icon_event', parameters: Map());
                            print("object------------------------${analytics.app.toString()}");


                            // // // Set user properties
                            // analytics.setUserProperty(name: 'moreiconuserproperty', value: 'blue.....');
                          },
                          icon: const Icon(
                            Icons.keyboard_control_sharp,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: StreamBuilder(
                    /// Call Collection -- cloud Storage
                    stream: FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      return SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,

                          /// Collection Document Access
                          itemCount: snapshot.data?.docs.length ?? 0,
                          itemBuilder: (context, index) {
                            var data = snapshot.data!.docs[index];
                            return GestureDetector(
                              onTap: () async {
                                String? profileImageURL = await getProfilePictureURL(data["user_id"]); // Fetch the profile image URL
                                navigateToDetailScreen(data["name"], data["email"], data["user_id"], profileImageURL);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0, right: 8),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white70,
                                      radius: 30.0,
                                      child: FutureBuilder<String?>(
                                        future: getProfilePictureURL(data["user_id"]), // Fetch profile picture URL
                                        builder: (context, imageURLSnapshot) {
                                          if (imageURLSnapshot.connectionState == ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          } else if (imageURLSnapshot.hasError) {
                                            return const Icon(Icons.error);
                                          } else if (imageURLSnapshot.hasData) {
                                            final imageURL = imageURLSnapshot.data;
                                            if (imageURL != null) {
                                              return CircleAvatar(
                                                radius: 28,
                                                backgroundImage: NetworkImage(imageURL),
                                              );
                                            }
                                          }
                                          return const CircleAvatar(
                                            radius: 30,
                                            child: Icon(Icons.person),
                                          );
                                        },
                                      ),
                                    ),
                                    Text(
                                      data["name"],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 700,
            child: DraggableScrollableSheet(
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: StreamBuilder(
                      /// Call Collection -- cloud Storage
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                      builder: (context, snapshot) {
                        return ListView.separated(
                          separatorBuilder: (context, index) => const Divider(
                            indent: 75,
                          ),
                          controller: scrollController,

                          /// Collection Document Access
                          itemCount: snapshot.data?.docs.length ?? 0,
                          itemBuilder: (context, index) {
                            var data = snapshot.data!.docs[index];

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.white70,
                                radius: 30.0,
                                child: FutureBuilder<String?>(
                                  future: getProfilePictureURL(data["user_id"]), // Fetch profile picture URL
                                  builder: (context, imageURLSnapshot) {
                                    if (imageURLSnapshot.connectionState == ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    } else if (imageURLSnapshot.hasError) {
                                      return const Icon(Icons.error);
                                    } else if (imageURLSnapshot.hasData) {
                                      final imageURL = imageURLSnapshot.data;
                                      if (imageURL != null) {
                                        return CircleAvatar(
                                          radius: 28,
                                          backgroundImage: NetworkImage(imageURL),
                                        );
                                      }
                                    }
                                    return const CircleAvatar(
                                      radius: 35,
                                      child: Icon(Icons.person),
                                    );
                                  },
                                ),
                              ),
                              title: Text(data["name"]),
                              subtitle: Text(data["email"]),
                              onTap: () async {
                                String? profileImageURL = await getProfilePictureURL(data["user_id"]); // Fetch the profile image URL
                                navigateToDetailScreen(data["name"], data["email"], data["user_id"], profileImageURL);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
