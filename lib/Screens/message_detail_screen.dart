import 'dart:io';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class WidgetDetailScreen extends StatefulWidget {
  final String title;
  final String details;
  final String receiverUserID;
  final String profileImageURL;

  const WidgetDetailScreen({
    Key? key,
    required this.title,
    required this.details,
    required this.receiverUserID,
    required this.profileImageURL,
  }) : super(key: key);

  @override
  State<WidgetDetailScreen> createState() => _WidgetDetailScreenState();
}

class _WidgetDetailScreenState extends State<WidgetDetailScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  late User currentUser;

  CollectionReference? chatMessages;

  Stream<QuerySnapshot>? chatMessagesStream;

  File? imageFile;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // DateTime? lastDisplayedDate;
  DateTime? displayedDate;

  @override
  void initState() {
    super.initState();
    currentUser = auth.currentUser!;
    // generates a unique chat ID using the getChatId
    final chatId = getChatId(currentUser.uid, widget.receiverUserID);
    // assigned stream of chat messages
    chatMessagesStream = getChatMessages(chatId);

    // If the user is authenticated, it proceeds to set up the chatMessages reference in Firestore:
    if (auth.currentUser != null) {
      chatMessages = FirebaseFirestore.instance.collection('messages').doc(auth.currentUser?.uid).collection("chat");
      if (kDebugMode) {
        print("groupChatId------------------${auth.currentUser?.uid}");
      }
    } else {
      if (kDebugMode) {
        print("user null --------------------");
      }
    }

    // user's status
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");
  }

  /// update user's status
  void setStatus(String status) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      firestore.collection('users').doc(user.uid).update({"status": status});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setState(() {
        setStatus("Online");
      });
    } else {
      setState(() {
        setStatus("Offline");
      });
    }
  }

  /// Create a unique chat ID based on user IDs.// group of two user for chat
  String getChatId(String userId1, String userId2) {
    List<String> participants = [userId1, userId2];
    participants.sort();
    return participants.join('_');
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

  /// Use the chat ID to fetch chat messages.
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').orderBy('timestamp').snapshots();
  }

  /// send user's message on cloud
  void sendMessage() async {
    final messageText = _messageController.text.trim();
    // create two User's unique chat id
    final chatId = getChatId(currentUser.uid, widget.receiverUserID);

    if (messageText.isNotEmpty || imageFile != null) {
      // Create a map to store the message data
      Map<String, dynamic> messageData = {
        'sender_id': currentUser.uid, // current user means sender
        'timestamp': FieldValue.serverTimestamp(),
        'user_email': currentUser.email,
        'type': "text",
        'status': "Offline",
      };

      // Add either text or image data based on whether an image is selected
      if (messageText.isNotEmpty) {
        messageData['text'] = messageText;
      }

      if (imageFile != null) {
        // Upload the image and get the download URL
        String? imageUrl = await uploadImages();
        messageData['type'] = "image";
        messageData['image_url'] = imageUrl ?? "";
      }

      // Add the message data to Firestore
      await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add(messageData);

      // Clear the message input field and imageFile
      _messageController.clear();
      imageFile = null;
    }
  }

  /// Image upload
  bool isImagePickerOpen = false;

  Future<void> getImages() async {
    if (!isImagePickerOpen) {
      isImagePickerOpen = true;
      ImagePicker picker = ImagePicker();
      await picker.pickImage(source: ImageSource.gallery).then(
        (xFile) {
          if (xFile != null) {
            imageFile = File(xFile.path);
            uploadImages();
          }
          isImagePickerOpen = false; // Reset the flag after selection is complete.
        },
      );
    }
  }

  Future<String?> uploadImages() async {
    if (imageFile == null) {
      return null;
    }

    String fileName = const Uuid().v1();
    var ref = FirebaseStorage.instance.ref().child("images_").child("$fileName.jpg");
    var uploadTask = await ref.putFile(imageFile!);
    String imageUrl = await uploadTask.ref.getDownloadURL();

    if (kDebugMode) {
      print("------------------------>> $imageUrl");
    }
    return imageUrl;
  }

  /// upload files and document's on cloud storage

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!); // Get the selected file
      sendFile(file);
    }
  }

  Future<void> sendFile(File file) async {
    const messageText = "";
    final chatId = getChatId(currentUser.uid, widget.receiverUserID);

    String? fileUrl = await uploadFile(file);

    // Create a message with the file URL
    Map<String, dynamic> messageData = {
      'sender_id': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'user_email': currentUser.email,
      'type': 'file',
      'file_url': fileUrl ?? "",
      'text': messageText,
    };

    // Add the message data to Firestore
    await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add(messageData);

    // Clear any previous message in the input field
    _messageController.clear();
  }

  Future<String?> uploadFile(File file) async {
    if (file == null) {
      return null;
    }

    String fileName = const Uuid().v1();
    var ref = FirebaseStorage.instance.ref().child("files").child("$fileName.pdf");
    var uploadTask = await ref.putFile(file);
    String fileUrl = await uploadTask.ref.getDownloadURL();

    return fileUrl;
  }

  /// Delete
  Future<void> deleteMessage(String messageId) async {
    final chatId = getChatId(currentUser.uid, widget.receiverUserID);

    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel deletion
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm deletion
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .delete();
      } catch (e) {
        // Handle any errors that may occur during deletion
        if (kDebugMode) {
          print('Error deleting message: $e');
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: const Color(0xff363636),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xff363636),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Center(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              Center(
                child: Text(
                  widget.details,
                  style: const TextStyle(fontSize: 12),
                ),
              ),

              /// Working User's Online Offline Status
              // StreamBuilder<QuerySnapshot>(
              //   stream: firestore.collection("users").orderBy("status").snapshots(),
              //   // stream: firestore.collection("users").doc(widget.receiverUserID).snapshots(),
              //   builder: (context, snapshot) {
              //     if (snapshot.connectionState == ConnectionState.waiting) {
              //       return const SizedBox(height: 10, width: 10, child: CircularProgressIndicator());
              //     } else if (snapshot.hasError) {
              //       return Text("Error: ${snapshot.error}");
              //     } else if (snapshot.hasData) {
              //       final querySnapshot = snapshot.data as QuerySnapshot<Map<String, dynamic>>;
              //       if (querySnapshot.docs.isNotEmpty) {
              //         final data = querySnapshot.docs.first.data();
              //         if (data.containsKey('status')) {
              //           return Text(data['status'].toString());
              //         } else {
              //           return const Text("Status field not found");
              //         }
              //       } else {
              //         return const Text("No documents found");
              //       }
              //     } else {
              //       return const Text("No data available");
              //     }
              //   },
              // ),
              StreamBuilder<DocumentSnapshot>(
                stream: firestore.collection("users").doc(currentUser.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 10,
                      width: 10,
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (snapshot.hasData) {
                    final documentSnapshot = snapshot.data as DocumentSnapshot<Map<String, dynamic>>;
                    if (documentSnapshot.exists) {
                      final data = documentSnapshot.data();
                      if (data!.containsKey('status')) {
                        return Text(data['status'].toString());
                      } else {
                        return const Text("Status field not found");
                      }
                    } else {
                      return const Text("User not found");
                    }
                  } else {
                    return const Text("No data available");
                  }
                },
              ),
              Expanded(
                // if massages are null -- show grey container
                child: chatMessages == null
                    ? Container(color: Colors.grey)
                    : StreamBuilder<QuerySnapshot>(
                        stream: chatMessagesStream,
                        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.connectionState == ConnectionState.active || snapshot.connectionState == ConnectionState.done) {
                            // if no chat messages data
                            if (!snapshot.hasData) return const Text("No Chat");

                            // else there is chat messages data available
                            final messages = snapshot.data!.docs.reversed;

                            // initializes an empty list messageWidgets to hold individual chat messages.
                            List<Widget> messageWidgets = [];


                            for (var message in messages) {
                              final data = message.data() as Map<String, dynamic>?;

                              if (data != null) {
                                final messageText = data['text'];
                                final senderID = data['sender_id'];
                                final Timestamp? messageTimestamp = data['timestamp'];

                                // Check if the message has a timestamp
                                if (messageTimestamp != null) {
                                  // Convert the timestamp to a DateTime object
                                  final DateTime dateTime = messageTimestamp.toDate();

                                  // Determine if the message was sent by the current user
                                  final isCurrentUser = senderID == currentUser.uid;


                                  // Create a MessageWidget for the current message
                                  final messageWidget = MessageWidget(
                                    text: messageText ?? "",
                                    isCurrentUser: isCurrentUser,
                                    timestamp: dateTime,
                                    profileImageURL: isCurrentUser ? widget.profileImageURL : widget.profileImageURL,
                                    imageUrl: data['type'] == 'image' ? data['image_url'] : null,
                                    fileUrl: data['type'] == 'file' ? data['file_url'] : null,
                                    onDeletePressed: () {
                                      deleteMessage(message.id);
                                    },
                                  );
                                  // Add the message widget to the list of widgets
                                  messageWidgets.add(messageWidget);
                                }
                              }
                            }
                            // Return a ListView to display the chat messages
                            return ListView(
                              // Display messages in reverse order (latest at the bottom)
                              reverse: true,
                              padding: const EdgeInsets.all(10.0),
                              children: messageWidgets, // List of message widgets to display
                            );
                          } else {
                            return Text('State: ${snapshot.connectionState}');
                          }
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  color: Colors.teal[50],
                  height: 50,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.mood,
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: "Message",
                                    hintStyle: TextStyle(color: Colors.white),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.file_upload_outlined,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    pickFile();
                                  });
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.image_outlined,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      getImages();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: () {
                          sendMessage();
                        },
                        child: const Icon(
                          Icons.send,
                          color: Color(0xFF00BFA5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.teal[50],
    );
  }
}

class MessageWidget extends StatelessWidget {
  final String _errorImage = "https://i.ytimg.com/vi/z8wrRRR7_qU/maxresdefault.jpg";
  final String? text;
  final bool isCurrentUser;
  final DateTime timestamp;
  final String profileImageURL;
  final String? imageUrl;
  final String? fileUrl;
  final VoidCallback onDeletePressed;


  const MessageWidget({
    Key? key,
    this.text,
    required this.isCurrentUser,
    required this.timestamp,
    required this.profileImageURL,
    this.imageUrl,
    this.fileUrl,
    required this.onDeletePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isTimestampDisplayed = false;

    return GestureDetector(
      onLongPress: onDeletePressed,
      child: Column(
        children: [
          if (!isTimestampDisplayed)
            Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.teal[200],
                borderRadius: BorderRadius.circular(13.0),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15, bottom: 8, top: 8),
                child: Text(
                  formatTimestampWithDay(timestamp),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.center : CrossAxisAlignment.center,
                mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.teal[100],
                        backgroundImage: NetworkImage(profileImageURL),
                      ),
                    ),
                  if (text != null && text!.isNotEmpty)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10.0),
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? Colors.teal : Colors.teal[100],
                            borderRadius: BorderRadius.circular(13.0),
                          ),
                          child: Wrap(
                            children: [
                              Linkify(
                                onOpen: (link) async {
                                  if (await canLaunch(link.url)) {
                                    await launch(link.url);
                                  } else {
                                    // Handle the case where the link cannot be launched
                                    if (kDebugMode) {
                                      print('Could not launch ${link.url}');
                                    }
                                    // Display an error message to the user
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Could not open link: ${link.url}'),
                                      ),
                                    );
                                  }
                                },
                                text: text!,
                                style: TextStyle(color: isCurrentUser ? Colors.white : Colors.teal[900], fontSize: 18),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  top: 3.0,
                                ),
                                child: Text(
                                  formatTimestamp(timestamp),
                                  style: TextStyle(color: isCurrentUser ? Colors.teal[100] : Colors.teal[700], fontSize: 12, height: 2.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrentUser ? Colors.teal : Colors.teal[100],
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Column(
                          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                imageUrl!,
                                width: 270,
                                height: 350,
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                                    decoration: BoxDecoration(
                                      color: isCurrentUser ? Colors.teal : Colors.teal[100],
                                      borderRadius: BorderRadius.circular(13.0),
                                    ),
                                    child: Wrap(
                                      children: [
                                        Icon(Icons.do_disturb, color: isCurrentUser ? Colors.white : Colors.teal[900]),
                                        Text(
                                          " Image not available!",
                                          style: TextStyle(
                                            color: isCurrentUser ? Colors.white : Colors.teal[900],
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 3, bottom: 3, right: isCurrentUser ? 15 : 0, left: isCurrentUser ? 0 : 15),
                              child: Text(
                                formatTimestamp(timestamp),
                                style: TextStyle(color: isCurrentUser ? Colors.teal[100] : Colors.teal[700], fontSize: 12, height: 2.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (fileUrl != null && fileUrl!.isNotEmpty)
                    Container(
                      width: 270,
                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        children: [
                          AnyLinkPreview(
                            link: fileUrl!,
                            displayDirection: UIDirection.uiDirectionHorizontal,
                            cache: const Duration(hours: 1),
                            backgroundColor: Colors.grey[300],
                            errorWidget: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                color: isCurrentUser ? Colors.teal : Colors.teal[100],
                                borderRadius: BorderRadius.circular(13.0),
                              ),
                              child: Wrap(
                                children: [
                                  Icon(Icons.downloading, size: 30, color: isCurrentUser ? Colors.teal.shade100 : Colors.teal.shade700),
                                  Text(
                                    '$fileUrl',
                                    style: TextStyle(
                                      color: isCurrentUser ? Colors.teal.shade100 : Colors.teal.shade700,
                                      decoration: TextDecoration.underline,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 3.0,
                                    ),
                                    child: Text(
                                      formatTimestamp(timestamp),
                                      style: TextStyle(color: isCurrentUser ? Colors.teal[100] : Colors.teal[700], fontSize: 12, height: 2.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            errorImage: _errorImage,
                            onTap: () async {
                              if (await canLaunch(fileUrl!)) {
                                await launch(fileUrl!);
                              } else {
                                // Handle the case when the URL cannot be launched
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                  // if (isCurrentUser)
                  //   const Padding(
                  //     padding: EdgeInsets.only(left: 8.0),
                  //     child: CircleAvatar(
                  //       backgroundColor: Colors.teal,
                  //       // backgroundImage: NetworkImage(profileImageURL),
                  //     ),
                  //   ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// For Showing Time with Message
  String formatTimestamp(DateTime time) {
    int hour = time.hour;
    int minute = time.minute;
    String amPm = hour < 12 ? 'AM' : 'PM';

    // Convert to 12-hour format and add leading zero to minute
    if (hour > 12) {
      hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }

    String formattedMinute = minute.toString().padLeft(2, '0');  // for 3:01 to 3:09 here to show "0" at 1 to 9
    String formattedTime = '$hour:$formattedMinute $amPm';
    return formattedTime;
  }

  /// For Showing Date and Today Yesterday
  String formatTimestampWithDay(DateTime time) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return 'Today';
      // return '${time.day}/${time.month}/${time.year}';
    } else if (time.year == yesterday.year && time.month == yesterday.month && time.day == yesterday.day) {
      return 'Yesterday';
      // return 'Yesterday ${time.day}/${time.month}/${time.year}';
    } else {
      // Message was sent on a different day
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

/// Example why use .trim() ?
// String userInput = "   Hello, World!   ";
// String trimmedInput = userInput.trim();
//
// print(trimmedInput);  // Output: "Hello, World!"
// used to remove leading and trailing whitespace (spaces, tabs, newlines, etc.)
// from the string stored in the _messageController.text variable.
