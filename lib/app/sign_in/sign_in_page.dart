import 'package:firebase_user_avatar_flutter/common_widgets/loading.dart';
import 'package:firebase_user_avatar_flutter/services/firebase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {

  bool inProgress = false;

  Future<bool> isButtonPressed() async {
    return inProgress ? true : null;
  }

  Future<void> _signInAnonymously(BuildContext context) async {

    setState(() {
      inProgress = true;
    });

    try {
      final auth = Provider.of<FirebaseAuthService>(context, listen: false);
      await auth.signInAnonymously();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Sign in')),
        body: Stack(
          children: [
            Center(
              child: ElevatedButton(
                  child: Text('Sign in anonymously'),
                  onPressed: () => _signInAnonymously(context)),
            ),
            Center(
              child: FutureBuilder(
                future: isButtonPressed(),
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return Loading();
                  }
                  return Container();
                },
              ),
            )
          ],
        ));
  }
}
