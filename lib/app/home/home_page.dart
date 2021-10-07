import 'dart:async';
import 'package:firebase_user_avatar_flutter/app/home/about_page.dart';
import 'package:firebase_user_avatar_flutter/common_widgets/avatar.dart';
import 'package:firebase_user_avatar_flutter/common_widgets/loading.dart';
import 'package:firebase_user_avatar_flutter/models/avatar_reference.dart';
import 'package:firebase_user_avatar_flutter/services/firebase_auth_service.dart';
import 'package:firebase_user_avatar_flutter/services/firebase_storage_service.dart';
import 'package:firebase_user_avatar_flutter/services/firestore_service.dart';
import 'package:firebase_user_avatar_flutter/services/image_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool inProgress = false;
  User _user;

  Future<bool> isButtonPressed() async {
    return inProgress ? true : null;
  }

  Future<void> _signOut(BuildContext context) async {

    setState(() {
      inProgress = true;
    });

    try {
      final auth = Provider.of<FirebaseAuthService>(context, listen: false);
      await auth.signOut();
    } catch (e) {
      print(e);
    }
  }

  Future<void> _onAbout(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AboutPage(user: _user),
      ),
    );
  }

  Future<void> _chooseAvatar(BuildContext context) async {
    
    try {
      // 1. Get image from picker
      final imagePicker = Provider.of<ImagePickerService>(context, listen: false);
      final file = await imagePicker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          inProgress = true;
        });
        // 2. Upload to storage
        final storage = Provider.of<FirebaseStorageService>(context, listen: false);
        final user = Provider.of<User>(context, listen: false);
        final downloadUrl = await storage.uploadAvatar(uid: user.uid, file: file);
        // 3. Save url to Firestore
        final database = Provider.of<FirestoreService>(context, listen: false);
        await database.setAvatarReference(uid: user.uid, avatarReference: AvatarReference(downloadUrl));
        setState(() {
          inProgress = false;
        });
        // 4. (optional) delete local file as no longer needed
        await file.delete();
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        leading: IconButton(
          icon: Icon(Icons.help),
          onPressed: () => _onAbout(context),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Logout',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
              ),
            ),
            onPressed: () => _signOut(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(130.0),
          child: Column(
            children: <Widget>[
              _buildUserInfo(context: context),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: FutureBuilder(
                future: isButtonPressed(),
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return Center(
                      child: Loading());
                  }
                  return Container();
                },
              ),
    );
  }

  Widget _buildUserInfo({BuildContext context}) {
    final database = Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<User>(context, listen: false);
    _user = user;
    return StreamBuilder<AvatarReference>(
      stream: database.avatarReferenceStream(uid: user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final avatarReference = snapshot.data;
          return Avatar(
            photoUrl: avatarReference?.downloadUrl,
            radius: 50,
            borderColor: Colors.black54,
            borderWidth: 2.0,
            onPressed: () => _chooseAvatar(context),
          );
        }
        return CircularProgressIndicator(backgroundColor: Colors.white);
      }
    );
  }
}
