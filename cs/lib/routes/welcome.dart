// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cs/utils/dimensions.dart';
import 'package:cs/utils/colors.dart';
import 'package:cs/utils/styles.dart';
import 'package:cs/utils/sharedpreferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

class Welcome extends StatefulWidget {
  const Welcome({Key? key, required this.analytics, required this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {

  bool isLoggedIn = false;

  Future<void> _setLogEvent(n) async {
    await widget.analytics.logEvent(
        name: n,
        parameters: <String, dynamic> {
          "bool" : true,
        }
    );
  }

  _WelcomeState() {
    MySharedPreferences.instance.setBooleanValue("firstTimeOpen", true);
    _setLogEvent("Walkthrough_completed");
    _setLogEvent("Welcome_page_reached");
    MySharedPreferences.instance
      .getBooleanValue("isLoggedIn")
      .then((value) => setState(() {
        isLoggedIn = value;
    })).then((value){
      if (isLoggedIn){
        Navigator.popAndPushNamed(context, '/feed');
      }
    });
  }

  FirebaseAuth auth = FirebaseAuth.instance;

  Future loginAnonymously() async {
    try{
      await auth.signInAnonymously().then((value) async {
        User? currentUser = await auth.currentUser;
        if (currentUser != null) {
          await currentUser.reload();
        }
        FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
          "email": "ANONYMOUS USER",
          "password": "ANONYMOUS USER",
          "username": "ANONYMOUS USER",
          "uid": currentUser.uid,
          "offeredProducts": {},
          "cart": {},
          "notifications": {},
          "ordersPlaced": {},
          "ordersReceived": {},
          "deactivated": false,
          "bookmarks": {},
          "pictureURL": "https://t4.ftcdn.net/jpg/03/46/93/61/360_F_346936114_RaxE6OQogebgAWTalE1myseY1Hbb5qPM.jpg",
        });
        Navigator.pushNamed(context, '/feed');
        MySharedPreferences.instance.setBooleanValue("isLoggedIn", true);
      });
    } on FirebaseAuthException catch (e) {
      print(e.code);
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        maintainBottomViewPadding: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: CircleAvatar(
                backgroundColor: AppColors.circleAvatarBackground,
                child: ClipOval(
                  child: Image.network(
                    'https://logopond.com/logos/c9615b066d9baa5342ea4cc5312b4af7.png',
                    fit: BoxFit.cover,
                  ),
                ),
                radius: 100,
              ),
            ),
            Center(
              child: Padding(
                  padding: Dimen.regularPadding,
                  child: Text(
                    "Welcome",
                    style: text,
                  )),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                        //_setCurrentScreen();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'Register',
                          style: buttonText,
                        ),
                      ),
                      style: button,
                    ),
                  ),
                  SizedBox(
                    width: 8.0,
                  ),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'Login',
                          style: buttonText,
                        ),
                      ),
                      style: button,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: <Widget>[
                  SizedBox(width: MediaQuery.of(context).size.width/5),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        loginAnonymously();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'Continue as Guest',
                          style: buttonText,
                        ),
                      ),
                      style: gmailButton,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width/5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
