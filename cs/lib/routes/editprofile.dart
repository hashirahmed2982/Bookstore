import 'package:cs/routes/profile.dart';
import 'package:cs/utils/colors.dart';
import 'package:cs/utils/styles.dart';
import 'package:flutter/material.dart';
import '../utils/dimensions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:path/path.dart';


class EditProfile extends StatefulWidget {
  const EditProfile({Key? key, required this.analytics, required this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {

  final _formKey = GlobalKey<FormState>();
  FirebaseAuth auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  XFile? _image;
  final defaultImage = "https://t4.ftcdn.net/jpg/03/46/93/61/360_F_346936114_RaxE6OQogebgAWTalE1myseY1Hbb5qPM.jpg";

  TextEditingController userController = TextEditingController();
  TextEditingController pass1Controller = TextEditingController();
  TextEditingController pass2Controller = TextEditingController();
  TextEditingController currController = TextEditingController();

  dynamic data;
  String userName = "";
  String pictureURL = "https://t4.ftcdn.net/jpg/03/46/93/61/360_F_346936114_RaxE6OQogebgAWTalE1myseY1Hbb5qPM.jpg";
  String uid = "";

  String? userNameField;
  String? passwordField1;
  String? passwordField2;
  String? passwordField3;

  Future pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile;
    });
  }

  Future getImageFromFirebase() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    String fileName = currentUser!.uid;
    try {
      String downloadURL = await FirebaseStorage.instance.ref().child('profilePictures/$fileName').getDownloadURL();
      setState(() {
        pictureURL = downloadURL;
      });
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'pictureURL': pictureURL,
      });
    } on FirebaseException catch(e) {
      print('ERROR: ${e.code} - ${e.message}');
    } catch (e) {
      print(e.toString());
    }
  }

  Future getUser() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    await document.get().then<dynamic>((DocumentSnapshot snapshot) async{
      setState(() {
        data = snapshot.data();
        userName = data['username'];
        userController.text = userName;
        uid = data['uid'];
        pictureURL = data['pictureURL'];
      });
    });
  }

  Future deleteImageFromFirebase(BuildContext context) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    String fileName = currentUser!.uid;

    Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('profilePictures/$fileName');
    try {
      await firebaseStorageRef.delete();
      print("Delete complete");
      setState(() {
        _image = null;
        pictureURL = defaultImage;
      });
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'pictureURL': pictureURL,
      });
    } on FirebaseException catch(e) {
      print('ERROR: ${e.code} - ${e.message}');
    } catch (e) {
      print(e.toString());
    }
  }

  Future uploadImageToFirebase(BuildContext context) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    String fileName = currentUser!.uid;
    //String fileName = basename(_image!.path);
    Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('profilePictures/$fileName');
    try {
      await firebaseStorageRef.putFile(File(_image!.path));
      print("Upload complete");
      setState(() {
        _image = null;
      });
    } on FirebaseException catch(e) {
      print('ERROR: ${e.code} - ${e.message}');
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> showAlertDialog(BuildContext context, String title, String message) async {
    bool isiOS = Platform.isIOS;

    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if(isiOS) {
            return CupertinoAlertDialog(
              title: Text(title, textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Text(message, textAlign: TextAlign.center),
              ),
              actions: [
                message == "You must re-login to change your password!" ?
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'CANCEL',
                      style: buttonText,
                    )
                ) : const Text(''),
                TextButton(
                    style: button,
                    onPressed: () {
                      Navigator.pop(context);
                      if (message == "You must re-login to change your password!"){
                        auth.signOut();
                        Navigator.popUntil(context, (route) => route.isFirst);
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                    child: Container(
                        color: AppColors.feedPrimary,
                        child: Text(
                          'OK',
                          style: buttonText,
                        )
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
                message == "You must re-login to change your password!" ?
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'CANCEL',
                        style: buttonText,
                      )
                  ) : const Text(''),
                TextButton(
                    style: button,
                    onPressed: () {
                      Navigator.pop(context);
                      if (message == "You must re-login to change your password!"){
                        auth.signOut();
                        Navigator.popUntil(context, (route) => route.isFirst);
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                    child: Container(
                        color: AppColors.feedPrimary,
                        child: Text(
                          'OK',
                          style: buttonText,
                        )
                    )
                ),
              ],
            );
          }
        });
  }

  Future changePassword(BuildContext context) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    if(currController.text.isNotEmpty) {
      if(pass1Controller.text.isNotEmpty){
        if(pass2Controller.text.isNotEmpty) {
          FirebaseFirestore.instance.collection("users").doc(currentUser!.uid).get().then((querySnapshot) {
            if(currController.text == querySnapshot.data()!['password']) {
              if(pass1Controller.text == pass2Controller.text) {
                currentUser.updatePassword(pass1Controller.text).then((value) {
                  FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
                    'password': pass1Controller.text
                  });
                  showAlertDialog(context, "SUCCESS", "Password changed successfully!").then((value) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.pushNamed(context, '/feed');
                  });

                }).catchError((error) {
                  showAlertDialog(context, "ERROR", "You must re-login to change your password!");
                });
              }
              else{showAlertDialog(context, "ERROR", "New pass and Reconfirm pass does not match!");}
            }
            else{showAlertDialog(context, "ERROR", "Current password is wrong!");}
          });
        }
        else{showAlertDialog(context, "ERROR", "New password field cannot be empty!");}
      }
      else{showAlertDialog(context, "ERROR", "Reconfirm password field cannot be empty!");}
    }
    else{showAlertDialog(context, "ERROR", "Current password field cannot be empty");}
  }

  Future changeUsername(BuildContext context) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      'username': userController.text,
    }).then((value) {
      showAlertDialog(context, "SUCCESS", "Username changed successfully!").then((value) {
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushNamed(context, '/feed');
      });
    });
  }

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Scaffold(
                backgroundColor: AppColors.bgColor,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_outlined),
                    onPressed: (){
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Profile(analytics: widget.analytics, observer: widget.observer,)));
                    },
                  ),
                  title: Text("Edit Profile",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold
                      )
                  ),
                  centerTitle: true,
                ),
                body: Padding(
                    padding: Dimen.regularPadding,
                    child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    flex: 2,
                                    child: Column(
                                        children: [
                                          ClipOval(
                                            child: _image != null ? Image.file(File(_image!.path), height:120, width:120) : Image.network(pictureURL, height:120, width:120)
                                          )
                                        ]
                                    )
                                ),
                                Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        if(_image == null) OutlinedButton(
                                          onPressed: pickImage,
                                          child: Text(
                                            'Change',
                                            style: buttonText,
                                          ),
                                          style: button,
                                        ),
                                        if(_image != null) OutlinedButton(
                                          onPressed: (){
                                            uploadImageToFirebase(context).then((value) => getImageFromFirebase()).then((value) {
                                                showAlertDialog(context, "SUCCESS", "Profile picture changed successfully!").then((value) {
                                                  Navigator.popUntil(context, (route) => route.isFirst);
                                                  Navigator.pushNamed(context, '/feed');
                                                });
                                            });
                                          },
                                          child: Text(
                                            'Upload',
                                            style: buttonText,
                                          ),
                                          style: button,
                                        ),

                                        SizedBox(height: 10),

                                        if (_image == null && pictureURL != defaultImage) OutlinedButton(
                                          onPressed: (){
                                            deleteImageFromFirebase(context);
                                          },

                                          style: button,
                                          child: Text(
                                            'Remove',
                                            style: buttonText,
                                          ),
                                        ),

                                        if(_image != null) OutlinedButton(
                                          onPressed: (){
                                            setState(() {
                                              _image = null;
                                            });
                                          },
                                          style: button,
                                          child: Text(
                                            'Cancel',
                                            style: buttonText,
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                              ],
                            ),
                            SizedBox(height:30),
                            Divider(
                              indent: 40,
                              endIndent: 40,
                              color: Colors.grey.shade200,
                              thickness: 2,
                            ),
                            SizedBox(height:30),
                            Column(
                                children: [
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text("Username",
                                              style: captiontitle
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(width: MediaQuery.of(context).size.width/3),
                                              Expanded(
                                                flex: 1,
                                                child: TextFormField(
                                                  textAlign: TextAlign.center,
                                                  enableSuggestions: false,
                                                  autocorrect: false,
                                                  decoration: const InputDecoration(
                                                    hintText: 'New Username',
                                                    focusedBorder: UnderlineInputBorder(
                                                      borderSide: BorderSide(color: Colors.black, width: 1.5),
                                                    ),
                                                  ),
                                                  controller: userController,
                                                  onChanged: (value){
                                                    setState(() {
                                                      userNameField = value;
                                                    });
                                                  }
                                                ),
                                              ),
                                              SizedBox(width: MediaQuery.of(context).size.width/3),
                                            ],
                                          ),
                                          Padding(
                                              padding: Dimen.largePadding,
                                              child: ElevatedButton(
                                                child: Text(
                                                  "CHANGE USERNAME", style: buttonText,),
                                                onPressed: userNameField != null && userNameField != userName && userNameField!.isNotEmpty ? () {
                                                  changeUsername(context);
                                                } : null,
                                                style: userNameField != null && userNameField != userName && userNameField!.isNotEmpty ? button :
                                                ButtonStyle(
                                                  backgroundColor: MaterialStateProperty.all(Colors.grey.shade200),
                                                ),
                                              )
                                          ),
                                          SizedBox(height:30),
                                          Divider(
                                            indent: 40,
                                            endIndent: 40,
                                            color: Colors.grey.shade200,
                                            thickness: 2,
                                          ),
                                          SizedBox(height:30),
                                          Text("Password",
                                              style: captiontitle),
                                          SizedBox(height: 10),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(width: MediaQuery.of(context).size.width/4),
                                              Expanded(
                                                flex: 1,
                                                child: TextFormField(
                                                  textAlign: TextAlign.center,
                                                  enableSuggestions: false,
                                                  obscureText: true,
                                                  autocorrect: false,
                                                  decoration: const InputDecoration(
                                                    hintText: 'Current Password',
                                                    focusedBorder: UnderlineInputBorder(
                                                      borderSide: BorderSide(color: Colors.black, width: 1.5),
                                                    ),
                                                  ),
                                                  controller: currController,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      passwordField1 = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: MediaQuery.of(context).size.width/4),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(width: MediaQuery.of(context).size.width/4),
                                              Expanded(
                                                flex: 1,
                                                child: TextFormField(
                                                  textAlign: TextAlign.center,
                                                  enableSuggestions: false,
                                                  obscureText: true,
                                                  autocorrect: false,
                                                  decoration: const InputDecoration(
                                                    hintText: 'New Password',
                                                    focusedBorder: UnderlineInputBorder(
                                                      borderSide: BorderSide(color: Colors.black, width: 1.5),
                                                    ),
                                                  ),
                                                  controller: pass1Controller,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      passwordField2 = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: MediaQuery.of(context).size.width/4),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(width: MediaQuery.of(context).size.width/4),
                                              Expanded(
                                                flex: 1,
                                                child: TextFormField(
                                                  textAlign: TextAlign.center,
                                                  enableSuggestions: false,
                                                  obscureText: true,
                                                  autocorrect: false,
                                                  decoration: const InputDecoration(
                                                    hintText: 'Reconfirm',
                                                    focusedBorder: UnderlineInputBorder(
                                                      borderSide: BorderSide(color: Colors.black, width: 1.5),
                                                    ),
                                                  ),
                                                  controller: pass2Controller,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      passwordField3 = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: MediaQuery.of(context).size.width/4),
                                            ],
                                          ),
                                          Padding(
                                              padding: Dimen.largePadding,
                                              child: ElevatedButton(
                                                child: Text(
                                                  "CHANGE PASSWORD",
                                                  style: buttonText,
                                                ),
                                                onPressed: passwordField1 != null && passwordField2 != null && passwordField3 != null ? () {
                                                  changePassword(context);
                                                } : null,
                                                style: passwordField1 != null && passwordField2 != null && passwordField3 != null ? button : ButtonStyle(
                                                  backgroundColor: MaterialStateProperty.all(Colors.grey.shade200),
                                                ),
                                              )
                                          ),
                                          SizedBox(
                                            height: 16,
                                          ),
                                        ]
                                    ),
                                  ),
                                ]
                            ),
                          ],
                        )
                    )
                )
            );
          }

          return MaterialApp(
            home: Center(
              child: Text('Connecting to Firebase'),
            ),
          );
        }
    );
  }
}