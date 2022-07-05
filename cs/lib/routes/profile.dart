// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:cs/routes/seller.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:cs/utils/colors.dart';
import 'package:cs/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs/utils/sharedpreferences.dart';
import 'package:cs/routes/feed.dart';
import 'dart:math';

class Profile extends StatefulWidget {
  const Profile({Key? key, required this.analytics, required this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _ProfileState createState() => _ProfileState();
}


class _ProfileState extends State<Profile> {

  Future deleteAccount() async {
    showAlertDialog("GOODBYE USER :(", "Bookstore will surely miss you!");
  }

  Future deleteAccountDialog() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    String uid = currentUser!.uid;
    auth.currentUser!.delete().catchError((error) async {
      Navigator.pop(context);
      await Future.delayed(const Duration(seconds: 2), (){});
      showAlertDialog("ERROR", "You must re-login to delete your account!");
    }).then((value) async {
      FirebaseFirestore.instance.collection("users").doc(uid).delete().then((value) {
        MySharedPreferences.instance.setBooleanValue("isLoggedIn", false);
        auth.signOut();
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushNamed(context, '/welcome');
      });
      List<String> bookIDs = [];
      final CollectionReference collection = FirebaseFirestore.instance.collection('books');
      await collection.get().then<dynamic>((QuerySnapshot snapshot) async{
        snapshot.docs.forEach((doc) {
          String docID = doc.id;
          if(docID.contains(uid)){
            bookIDs.add(docID.substring(docID.indexOf('-') + 1));
            FirebaseFirestore.instance.collection('books').doc(docID).delete();
          }
        });
      });
      final CollectionReference collection2 = FirebaseFirestore.instance.collection('users');
      await collection2.get().then<dynamic>((QuerySnapshot snapshot) async{
        snapshot.docs.forEach((doc) {
          String docID = doc.id;
          var cart = {};
          var bookmarks = {};
          var notifications = {};
          final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(docID);
          document.get().then<dynamic>((DocumentSnapshot snapshot2) async {
            data = snapshot2.data();
            cart = data['cart'];
            bookmarks = data['bookmarks'];
            notifications = data['notifications'];

            for (int i = 0; i < bookIDs.length; i++){
              if (cart.containsKey(bookIDs[i])){
                cart.remove(bookIDs[i]);
                String notiID = "${bookIDs[i]}-";
                var rng = Random();
                for (int i = 0; i < 8; i++){
                  notiID += rng.nextInt(9).toString();
                }
                String notiContent = "A book has been removed from your cart since it is no longer available on the Bookstore.";
                Timestamp timeAndDate = Timestamp.fromDate(DateTime.now());
                var array = [notiContent, timeAndDate, bookIDs[i], "noSeller", pictureURL, notiID, false];
                notifications[notiID] = array;
              }
              if (bookmarks.containsKey(bookIDs[i])){
                bookmarks.remove(bookIDs[i]);
                String notiID = "${bookIDs[i]}-";
                var rng = Random();
                for (int i = 0; i < 8; i++){
                  notiID += rng.nextInt(9).toString();
                }
                String notiContent = "A book has been removed from your bookmarks since it is no longer available on the Bookstore.";
                Timestamp timeAndDate = Timestamp.fromDate(DateTime.now());
                var array = [notiContent, timeAndDate, bookIDs[i], "noSeller", pictureURL, notiID, false];
                notifications[notiID] = array;
              }
            }
            await FirebaseFirestore.instance.collection('users').doc(docID).update({
              'notifications': notifications,
              'cart': cart,
              'bookmarks': bookmarks,
            });
          });
        });
      });
    });

  }

  Future deactivateAccount() async {
    showAlertDialog("UNTIL NEXT TIME :)", "Bookstore will look forward to having you back!");
  }

  Future deactivateAccountDialog() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      'deactivated': true,
    }).then((value) async {
      MySharedPreferences.instance.setBooleanValue("isLoggedIn", false);
      auth.signOut();
      Navigator.pop(context);
      await Future.delayed(const Duration(seconds: 2), (){});
      showAlertDialog("REACTIVATION", "You may login anytime with your credentials to reactivate your account.");
    });
  }

  Future<void> showAlertDialog(String title, String message) async {
    bool isiOS = Platform.isIOS;

    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if (isiOS) {
            return CupertinoAlertDialog(
              title: Text(title, textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Text(message, textAlign: TextAlign.center),
              ),
              actions: [
                if (message == "Bookstore will surely miss you!")
                  TextButton(
                      style: button,
                      onPressed: deleteAccountDialog,
                      child: Container(
                          color: AppColors.feedPrimary,
                          child: Text(
                            'GOODBYE!',
                            style: buttonText,
                          )
                      )
                  ),
                if (message == "You must re-login to delete your account!")
                  TextButton(
                      style: button,
                      onPressed: () {
                        auth.signOut();
                        Navigator.popUntil(context, (route) => route.isFirst);
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Container(
                          color: AppColors.feedPrimary,
                          child: Text(
                            'PROCEED',
                            style: buttonText,
                          )
                      )
                  ),
                if (message == "Bookstore will look forward to having you back!")
                  TextButton(
                      style: button,
                      onPressed: deactivateAccountDialog,
                      child: Container(
                          color: AppColors.feedPrimary,
                          child: Text(
                            'GOODBYE!',
                            style: buttonText,
                          )
                      )
                  ),
                message == "You may login anytime with your credentials to reactivate your account" ? TextButton(
                  style: button,
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Container(
                    color: AppColors.feedPrimary,
                    child: Text(
                      'OK',
                      style: buttonText,
                    )
                  )
                ) : TextButton(
                  onPressed: () {
                  Navigator.pop(context);
                  },
                  child: Text(
                  'CANCEL',
                  style: buttonText,
                  )
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Text(title, textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Text(message, textAlign: TextAlign.center),
              ),
              actions: [
                if (message == "Bookstore will surely miss you!")
                  TextButton(
                      style: button,
                      onPressed: deleteAccountDialog,
                      child: Container(
                          color: AppColors.feedPrimary,
                          child: Text(
                            'GOODBYE!',
                            style: buttonText,
                          )
                      )
                  ),
                if (message == "You must re-login to delete your account!")
                  TextButton(
                      style: button,
                      onPressed: () {
                        auth.signOut();
                        Navigator.popUntil(context, (route) => route.isFirst);
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Container(
                          color: AppColors.feedPrimary,
                          child: Text(
                            'PROCEED',
                            style: buttonText,
                          )
                      )
                  ),
                if (message == "Bookstore will look forward to having you back!")
                  TextButton(
                      style: button,
                      onPressed: deactivateAccountDialog,
                      child: Container(
                          color: AppColors.feedPrimary,
                          child: Text(
                            'GOODBYE!',
                            style: buttonText,
                          )
                      )
                  ),
                message == "You may login anytime with your credentials to reactivate your account." ? TextButton(
                  style: button,
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Container(
                      color: AppColors.feedPrimary,
                      child: Text(
                        'OK',
                        style: buttonText,
                      )
                  )
                ) : TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'CANCEL',
                    style: buttonText,
                  )
                ),
              ],
            );
          }
        });
  }

  Future<void> _setLogEvent(n) async {
    await widget.analytics.logEvent(
        name: n,
        parameters: <String, dynamic> {
          "bool" : true,
        }
    );
  }

  FirebaseAuth auth = FirebaseAuth.instance;

  dynamic data;
  String username = "";
  String mail = "";
  String pictureURL = "";
  String uid = "";

  Future<dynamic> getData() async {
    User user = auth.currentUser!;
    final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await document.get().then<dynamic>((DocumentSnapshot snapshot) async{
      setState(() {
        data = snapshot.data();
        username = data['username'];
        mail = data['email'];
        pictureURL = data['pictureURL'];
        uid = data['uid'];
      });
    });
  }

  _ProfileState() {
    _setLogEvent("Profile_page_reached");
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_outlined),
          onPressed: (){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Feed(analytics: widget.analytics, observer: widget.observer,)));
          },
        ),
        title: Text("Profile",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
          padding: EdgeInsets.all(12),
          physics: BouncingScrollPhysics(),
          children: [
            userTile(),
            divider(),
            firstTiles(),
            divider(),
            secondTiles(),
            divider(),
            thirdTiles(),
            divider(),
            forthTiles(),
          ]),
    );
  }

  Widget userTile() {
    return GestureDetector(
      child: ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(
                pictureURL),
            radius: 30,
          ),
          title: Text('${username}', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${mail}')
      ),
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => Seller(
          analytics: widget.analytics,
          observer: widget.observer,
          seller: username,
          sellerID: uid,
        )));
      }
    );
  }

  Widget divider() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Divider(thickness: 1.5),
    );
  }

  Widget firstTiles() {
    return Column(
      children: [
        firstTile(Icons.history, Color(0xFFfabe66), "Orders", "/orderhistory"),
        firstTile(Icons.menu_book, Color(0xFFfabe66), "My Products", "/myofferedproducts"),
        firstTile(Icons.comment, Color(0xFFfabe66), "My Comments", "/mycomments"),
        firstTile(Icons.bookmark, Color(0xFFfabe66), "My Bookmarks", "/mybookmarks"),
      ],
    );
  }

  Widget secondTiles() {
    return Column(children: [
      firstTile(Icons.person, Color(0xFFfabe66), "Edit Profile", "/editprofile"),
    ]);
  }

  Widget thirdTiles() {
    return Column(children: [
      deactivateTile(Icons.person_remove, Color(0xFFfabe66), "Deactivate Account"),
      deleteTile(Icons.person_remove, Color(0xFFfabe66), "Delete Account"),
    ]);
  }

  Widget forthTiles() {
    return Column(children: [
      logoutTile(Icons.logout, Color(0xFFfabe66), "Logout", '/welcome'),
    ]);
  }


  Widget firstTile(IconData icon, Color color, String text,String destination) {
    return ListTile(
      leading: Container(
        child: Icon(icon, color: color),
        height: 45,
        width: 45,
        decoration: BoxDecoration(
            color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(18)),
      ),
      title: Text(text, style: TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.black, size: 20),
      onTap: () {
        Navigator.pushNamed(context, destination);
      },
    );
  }

  Widget logoutTile(IconData icon, Color color, String text,String destination) {
    return ListTile(
      leading: Container(
        child: Icon(icon, color: color),
        height: 45,
        width: 45,
        decoration: BoxDecoration(
            color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(18)),
      ),
      title: Text(text, style: TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        MySharedPreferences.instance.setBooleanValue("isLoggedIn", false);
        auth.signOut();
        Navigator.pushNamed(context, destination);
      },
    );
  }

  Widget deleteTile(IconData icon, Color color, String text) {
    return ListTile(
      leading: Container(
        child: Icon(icon, color: color),
        height: 45,
        width: 45,
        decoration: BoxDecoration(
            color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(18)),
      ),
      title: Text(text, style: TextStyle(fontWeight: FontWeight.w500)),
      onTap: deleteAccount,
    );
  }

  Widget deactivateTile(IconData icon, Color color, String text) {
    return ListTile(
      leading: Container(
        child: Icon(icon, color: color),
        height: 45,
        width: 45,
        decoration: BoxDecoration(
            color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(18)),
      ),
      title: Text(text, style: TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        deactivateAccount();
      },
    );
  }
}