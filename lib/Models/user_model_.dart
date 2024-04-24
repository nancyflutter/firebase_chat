class UserModelForChat {
  final List<UserModel>? userModel;

  UserModelForChat({
    this.userModel,
  });

  UserModelForChat.fromJson(Map<String, dynamic> json)
      : userModel = (json['user_model'] as List?)
      ?.map((dynamic e) => UserModel.fromJson(e as Map<String, dynamic>))
      .toList();

  Map<String, dynamic> toJson() =>
      {'user_model': userModel?.map((e) => e.toJson()).toList()};
}

class UserModel {
  final String? email;
  final String? fullName;
  final String? image;
  final String? userId;

  UserModel({
    this.email,
    this.fullName,
    this.image,
    this.userId,
  });

  UserModel.fromJson(Map<String, dynamic> json)
      : email = json['email'] as String?,
        fullName = json['full_name'] as String?,
        image = json['image'] as String?,
        userId = json['user_id'] as String?;

  Map<String, dynamic> toJson() =>
      {
        'email': email,
        'full_name': fullName,
        'image': image,
        'user_id': userId
      };
}


// {
//   "user_model":[
//   {
//   "email":"dhorajiyanency@gmail.com",
//   "full_name":"nency",
//   "image":"https://firebasestorage.googleapis.com/v0/b/chat-app-d877c.appspot.com/o/profile%2Ff2bdd282-dd54-42d7-8323-535bfc0bd9b2730320190092692223.jpg?alt=media&token=6becfd86-fdf9-47de-a48c-41de3cea5dde",
//   "user_id":"KviEW5bZ8pU17DSBIB2rIOlEV6l2"
//   }
//   ]
// }


// class ChatUser extends Equatable {
//   final String id;
//   final String photoUrl;
//   final String displayName;
//   final String phoneNumber;
//   final String aboutMe;
//
//   const ChatUser(
//       {required this.id,
//         required this.photoUrl,
//         required this.displayName,
//         required this.phoneNumber,
//         required this.aboutMe});