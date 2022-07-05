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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:flutter/cupertino.dart';

class Sell extends StatefulWidget {
  const Sell({Key? key, required this.analytics, required this.observer, required this.userName}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  final String userName;

  @override
  _SellState createState() => _SellState();
}

class _SellState extends State<Sell> {
  final _formKey = GlobalKey<FormState>();
  FirebaseAuth auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  dynamic data;
  var map = {};
  var comments = {};

  XFile? _image;
  final defaultImage = "https://logopond.com/logos/c9615b066d9baa5342ea4cc5312b4af7.png";
  dynamic imageShowing = "https://logopond.com/logos/c9615b066d9baa5342ea4cc5312b4af7.png";
  String _message = "";

  String bookID = "";
  String bookTitle = "";
  String author = "";
  String bookType = "";
  String description = "";
  String deliveryWithin = "";
  String seller = "";
  String price = "";
  String inventory = "";
  String pictureURL = "";
  String sellerID = "";
  String bookCategory = "";

  var currentSelectedValue;
  final bookTypes = ["Hardcover", "Paperback"];
  var currentSelectedValue2;
  final bookCategories = ["New", "Old"];

  Future<void> _setLogEvent(n) async {
    await widget.analytics.logEvent(
        name: n,
        parameters: <String, dynamic> {
          "bool" : true,
        }
    );
  }

  Future pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile;
    });
  }

  Future uploadImageToFirebase(BuildContext context) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    String ID = "";
    var rng = Random();
    for (int i = 0; i < 8; i++){
      ID += rng.nextInt(9).toString();
    }
    setState(() {
      bookID = ID;
    });
    String fileName = currentUser!.uid + "-" + ID;
    //String fileName = basename(_image!.path);
    Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('books/$fileName');
    try {
      await firebaseStorageRef.putFile(File(_image!.path));
      print("Upload complete");
    } on FirebaseException catch(e) {
      print('ERROR: ${e.code} - ${e.message}');
    } catch (e) {
      print(e.toString());
    }
  }

  Future getImageFromFirebase() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    String fileName = currentUser!.uid + "-" + bookID;
    try {
      String downloadURL = await FirebaseStorage.instance.ref().child('books/$fileName').getDownloadURL();
      setState(() {
        imageShowing = downloadURL;
        pictureURL = downloadURL;
      });
    } on FirebaseException catch(e) {
      print('ERROR: ${e.code} - ${e.message}');
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> showAlertDialog(String title, String message, rName) async {
    bool isiOS = Platform.isIOS;

    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if(isiOS) {
            return CupertinoAlertDialog(
              title: Text(title, textAlign: TextAlign.center,),
              content: SingleChildScrollView(
                child: Text(message, textAlign: TextAlign.center,),
              ),
              actions: [
                TextButton(
                  style: button,
                    onPressed: () {
                      Navigator.popAndPushNamed(context, rName);
                    },
                    child: Text(
                      'PROCEED',
                      style: buttonText,
                    )
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Text(title, textAlign: TextAlign.center,),
              content: SingleChildScrollView(
                child: Text(message, textAlign: TextAlign.center,),
              ),
              actions: [
                TextButton(
                  style: button,
                    onPressed: () {
                      Navigator.popAndPushNamed(context, rName);
                    },
                    child: Text(
                      'PROCEED',
                      style: buttonText,
                    )
                ),
              ],
            );
          }
        });
  }

  Future<void> addBook() async {
    try {
      User? currentUser = await auth.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
      }
      String docName = currentUser!.uid + "-" + bookID;
      String downloadURL = await FirebaseStorage.instance.ref().child('books/$docName').getDownloadURL();
      setState(() {
        imageShowing = downloadURL;
        pictureURL = downloadURL;
        sellerID = currentUser.uid;
      });
      FirebaseFirestore.instance.collection('books').doc(docName).set({
        "bookTitle": bookTitle,
        "author": author,
        "bookType": bookType,
        "description": description,
        "deliveryWithin": deliveryWithin,
        "seller": seller,
        "sellerID": sellerID,
        "price": price,
        "discountedPrice": price,
        "inventory": inventory,
        "sold": "0",
        "pictureURL": pictureURL,
        "comments": comments,
        "bookID": bookID,
        "bookCategory": bookCategory,
      }).then((value) async {
        final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
        await document.get().then<dynamic>((DocumentSnapshot snapshot) async{
          setState(() {
            data = snapshot.data();
            map = data['offeredProducts'];
          });
      });
      }).then((value) {
        var array = [bookTitle, author, bookType, bookCategory, description, deliveryWithin, seller, sellerID, price, price, inventory, "0", pictureURL, comments];
        map[bookID] = array;
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          "offeredProducts": map,
        });
      });
      showAlertDialog("Congratulations!", "${bookTitle.toUpperCase()} has been added to the marketplace successfully!", "/feed");

    } on FirebaseAuthException catch (e) {
      print('ERROR: ${e.code} - ${e.message}');
    } catch (e) {
      print(e.toString());
    }
  }

  Future notifySeller() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    var notifications = {};
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get().then((DocumentSnapshot snapshot){
      data = snapshot.data();
      notifications = data['notifications'];
    });
    String notiID = "$bookID-";
    var rng = Random();
    for (int i = 0; i < 8; i++){
      notiID += rng.nextInt(9).toString();
    }

    String notiContent = "Your book ${bookTitle.toUpperCase()} has been added to the marketplace successfully!";
    Timestamp timeAndDate = Timestamp.fromDate(DateTime.now());
    var array = [notiContent, timeAndDate, bookID, sellerID, pictureURL, notiID, false];
    notifications[notiID] = array;

    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
      'notifications': notifications,
    });
  }

  Future notifyUsers() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    final CollectionReference collection = FirebaseFirestore.instance.collection('users');
    await collection.get().then<dynamic>((QuerySnapshot snapshot) async{
      snapshot.docs.forEach((doc) {
        var notifications = {};
        String docID = doc.id;
        if (docID != currentUser!.uid){
          final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(docID);
          document.get().then<dynamic>((DocumentSnapshot snapshot2) async {
            setState(() {
              data = snapshot2.data();
              notifications = data['notifications'];
            });
            String notiID = "$bookID-";
            var rng = Random();
            for (int i = 0; i < 8; i++){
              notiID += rng.nextInt(9).toString();
            }
            String notiContent = "The book ${bookTitle.toUpperCase()} has been recently added to the marketplace. Check it out!";
            Timestamp timeAndDate = Timestamp.fromDate(DateTime.now());
            var array = [notiContent, timeAndDate, bookID, sellerID, pictureURL, notiID, false];
            notifications[notiID] = array;
            await FirebaseFirestore.instance.collection('users').doc(docID).update({
              'notifications': notifications,
            });
          });
        }
      });
    });
  }

  @override
  _SellState() {
    _setLogEvent("Sell_Page_reached");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: Dimen.regularPadding,
        child: SingleChildScrollView(
          child: Column(
            children: [
              //picture uploading
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: ClipRect(
                        //borderRadius: BorderRadius.circular(30),
                          child: _image != null ? Image.file(File(_image!.path), width: MediaQuery.of(context).size.width - 100,) : Image.network(imageShowing, width: MediaQuery.of(context).size.width - 100,)
                      )
                  ),

                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          if(_image == null) Column(
                            children: [
                              OutlinedButton(
                                onPressed: (){
                                  pickImage().then((value) {uploadImageToFirebase(context);});
                                },
                                child: Text(
                                  'Add Image',
                                  style: buttonText,
                                ),
                                style: button,
                              ),

                              if (_message.isNotEmpty) Text(
                                _message,
                                style: TextStyle(
                                  color: AppColors.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          /*if(_image != null) OutlinedButton(
                            onPressed: (){
                              uploadImageToFirebase(context).then((value) => getImageFromFirebase());
                            },
                            child: Text(
                              'Confirm',
                              style: buttonText,
                            ),
                            style: button,
                          ),*/

                          SizedBox(height: 10),

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
                ]
              ),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 16,),
                    //Title
                    Row(
                      children: [
                        //title
                        Expanded(
                            flex: 1,
                            child: TextFormField(
                              keyboardType: TextInputType.text,
                              enableSuggestions: false,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                                ),
                                floatingLabelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ) ,
                                labelText: 'Book Title',
                              ),
                              validator: (value) {
                                if (value == null){
                                  return 'Book Title field cannot be empty!';
                                } else {
                                  String trimmedValue = value.trim();
                                  if (trimmedValue.isEmpty){
                                    return 'Book Title field cannot be empty!';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) {
                                if (value != null){
                                  bookTitle = value;
                                }
                              }
                            )
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    //author, bookType, category
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                              hint: Text("New / Old"),
                              value: currentSelectedValue2,
                              isDense: true,
                              onChanged: (newValue) {
                                setState(() {
                                  currentSelectedValue2 = newValue;
                                });
                              },
                              items: bookCategories.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              validator: (value) {
                                if (value == null){
                                  return 'Please choose a type!';
                                } else {
                                  String trimmedValue = value.trim();
                                  if (trimmedValue.isEmpty){
                                    return 'Please choose a type!';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) {
                                if (value != null){
                                  bookCategory = value;
                                }
                              }
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                            flex: 1,
                            child: TextFormField(
                              keyboardType: TextInputType.text,
                              enableSuggestions: false,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                                ),
                                floatingLabelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ) ,
                                labelText: 'Author',
                              ),
                              validator: (value) {
                                if (value == null){
                                  return 'Author field cannot be empty!';
                                } else {
                                  String trimmedValue = value.trim();
                                  if (trimmedValue.isEmpty){
                                    return 'Author field cannot be empty!';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) {
                                if (value != null){
                                  author = value;
                                }
                              },
                            )
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            hint: Text("Book Type"),
                            value: currentSelectedValue,
                            isDense: true,
                            onChanged: (newValue) {
                              setState(() {
                                currentSelectedValue = newValue;
                              });
                              print(currentSelectedValue);
                            },
                            items: bookTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            validator: (value) {
                              if (value == null){
                                return 'Please choose a type!';
                              } else {
                                String trimmedValue = value.trim();
                                if (trimmedValue.isEmpty){
                                  return 'Please choose a type!';
                                }
                              }
                              return null;
                            },
                            onSaved: (value) {
                              if (value != null){
                                bookType = value;
                              }
                            }
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // description
                    Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: TextFormField(
                              keyboardType: TextInputType.text,
                              enableSuggestions: false,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                                ),
                                floatingLabelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ) ,
                                labelText: 'Description',
                                suffixText: '(max 250 chars)'
                              ),
                              maxLength: 250,
                              //onSaved: (value) {}
                              onSaved: (value) {
                                if (value != null){
                                  description = value;
                                }
                              }
                            )
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // delivery within and seller
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              focusedBorder: UnderlineInputBorder(
                                borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                              ),
                              floatingLabelStyle: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ) ,
                              labelText: 'Delivery Within',
                              suffixText: '(days)',
                            ),
                            validator: (value) {
                              if (value == null){
                                return 'Delivery Within field cannot be empty!';
                              } else {
                                String trimmedValue = value.trim();
                                if (trimmedValue.isEmpty){
                                  return 'Delivery Within field cannot be empty!';
                                }
                                if (trimmedValue == '0') {
                                  return 'Delivery days cannot be zero!';
                                }
                              }
                              return null;
                            },
                            onSaved: (value) {
                              if (value != null){
                                deliveryWithin = value;
                              }
                            }
                          ),
                        ),
                        SizedBox(width: 20,),
                        widget.userName.isEmpty ?
                        Expanded(
                            flex: 1,
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              enableSuggestions: false,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                                ),
                                floatingLabelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ) ,
                                labelText: 'Phone No.',
                              ),
                              initialValue: '5',
                              validator: (value) {
                                if (value == null){
                                  return 'Seller field cannot be empty!';
                                } else {
                                  String trimmedValue = value.trim();
                                  if (trimmedValue.isEmpty){
                                    return 'Seller field cannot be empty!';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) {
                                if (value != null){
                                  seller = value;
                                }
                              },
                            )
                        ) : Expanded(
                            flex: 1,
                            child: TextFormField(
                              keyboardType: TextInputType.text,
                              enableSuggestions: false,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                                ),
                                floatingLabelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ) ,
                                labelText: 'Seller',
                              ),
                              initialValue: widget.userName,
                              readOnly: true,
                              validator: (value) {
                                if (value == null){
                                  return 'Seller field cannot be empty!';
                                } else {
                                  String trimmedValue = value.trim();
                                  if (trimmedValue.isEmpty){
                                    return 'Seller field cannot be empty!';
                                  }
                                }
                                return null;
                              },
                              onSaved: (value) {
                                if (value != null){
                                  seller = value;
                                }
                              }
                            )
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    //quantity and price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 20,),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              focusedBorder: UnderlineInputBorder(
                                borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                              ),
                              floatingLabelStyle: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ) ,
                              labelText: 'Price',
                              suffixText: '(TL)'
                            ),
                            validator: (value) {
                              if (value == null){
                                return 'Price field cannot be empty!';
                              } else {
                                String trimmedValue = value.trim();
                                if (trimmedValue.isEmpty){
                                  return 'Price field cannot be empty!';
                                }
                                if (trimmedValue == '0') {
                                  return 'Price cannot be zero!';
                                }
                              }
                              return null;
                            },
                            onSaved: (value) {
                              if (value != null){
                                price = value;
                              }
                            }
                          )
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              focusedBorder: UnderlineInputBorder(
                                borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                              ),
                              floatingLabelStyle: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ) ,
                              labelText: 'Inventory',
                            ),
                            validator: (value) {
                              if (value == null){
                                return 'Inventory field cannot be empty!';
                              } else {
                                String trimmedValue = value.trim();
                                if (trimmedValue.isEmpty){
                                  return 'Inventory field cannot be empty!';
                                }
                                if (trimmedValue == '0') {
                                  return 'Inventory cannot be zero!';
                                }
                              }
                              return null;
                            },
                            onSaved: (value) {
                              if (value != null){
                                inventory = value;
                              }
                            }
                          ),
                        ),
                        SizedBox(width: 20),
                      ],
                    ),

                    SizedBox(height: 25),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () {
                              if (_image == null){
                                setState(() {
                                  _message = "Please upload a picture of the book!";
                                });
                              }
                              if (_formKey.currentState!.validate() && _image != null){
                                _formKey.currentState!.save();
                                //uploadImageToFirebase(context);
                                addBook().then((value){
                                  notifySeller();
                                  notifyUsers();
                                });
                              }
                            },
                            child: Padding(
                                padding: Dimen.regularPadding,
                                child: Text(
                                  'Start Selling',
                                  style: buttonText,
                                )
                            ),
                            style: button,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
