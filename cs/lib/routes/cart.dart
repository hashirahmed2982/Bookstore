/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

class Feed extends StatefulWidget {
  const Feed({Key? key, required this.analytics, required this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _FeedState createState() => _FeedState();
}

class _FeedState extends State<Feed> {

  makeListWidget(AsyncSnapshot snapshot) {
    return snapshot.data.docs.map<Widget>((document) {
      return const Text('DATA');

    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot){
            return ListView(
              children: makeListWidget(snapshot),
            );
          }
        )
      )
    );
  }
}*/

// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, prefer_const_literals_to_create_immutables
import 'package:cs/routes/address.dart';
import 'package:flutter/material.dart';
import '../utils/dimensions.dart';
import '../utils/colors.dart';
import 'package:cs/utils/styles.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:cs/routes/feed.dart';

class Cart extends StatefulWidget {
  const Cart({Key? key, required this.analytics, required this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {

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
  var cart = {};
  String username = "";
  int total = 0;
  bool remove = false;

  Future<dynamic> getData() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    await document.get().then<dynamic>((DocumentSnapshot snapshot) async{
      setState(() {
        data = snapshot.data();
        username = data['username'];
        cart = data['cart'];
      });
    }).then((value) {
      int totalCart = total;
      cart.forEach((k,v) {
        totalCart += int.parse(cart[k][5]) * int.parse(cart[k][6]);
      });
      setState(() {
        total = totalCart;
      });
    });
  }

  Future<void> showAlertDialog(String title, String message) async {
    bool isiOS = Platform.isIOS;

    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if(isiOS) {
            return CupertinoAlertDialog(
              title: Text(title, textAlign: TextAlign.center,),
              content: SingleChildScrollView(
                child: Text(message, textAlign: TextAlign.center),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      remove = true;
                      Navigator.pop(context);
                    });
                  },
                    child: Text(
                        'YES',
                      style: buttonText,
                    )
                ),
                TextButton(
                    style: button,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      color: AppColors.feedPrimary,
                        child: Text(
                          'NO',
                          style: buttonText,
                        )
                    )
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Text(title, textAlign: TextAlign.center,),
              content: SingleChildScrollView(
                child: Text(message, textAlign: TextAlign.center),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        remove = true;
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                      'YES',
                      style: buttonText,
                    )
                ),
                TextButton(
                    style: button,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                        color: AppColors.feedPrimary,
                        child: Text(
                          'NO',
                          style: buttonText,
                        )
                    )
                ),
              ],
            );
          }
        });
  }

  Future incrementQuantity(String bookID) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    setState(() {
      cart[bookID][6] = (int.parse(cart[bookID][6]) + 1).toString();

    });
    int totalCart = total;
    totalCart += int.parse(cart[bookID][5]);
    setState(() {
      total = totalCart;
    });
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      "cart": cart,
    });
  }

  Future decrementQuantity(String bookID, String bookName) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    String bookNameUpper = bookName.toUpperCase();
    if (cart[bookID][6] == "1") {
      await showAlertDialog("WARNING!", "You are about to remove $bookNameUpper from your cart. Do you wish to proceed?");
    }
    else {
      setState(() {
        cart[bookID][6] = (int.parse(cart[bookID][6]) - 1).toString();
      });
      int totalCart = total;
      totalCart -= int.parse(cart[bookID][5]);
      setState(() {
        total = totalCart;
      });
    }
    if (remove) {
      int totalCart = total;
      totalCart -= int.parse(cart[bookID][5]);
      setState(() {
        total = totalCart;
      });
      setState(() {
        cart.remove(bookID);
        remove = false;
      });
    }
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      "cart": cart,
    });
  }

  _CartState() {
    _setLogEvent("Feed_page_reached");
    getData();
  }

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Scaffold(
              backgroundColor: AppColors.bgColor,
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_outlined),
                    onPressed: (){
                      Navigator.pop(context);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Feed(analytics: widget.analytics, observer: widget.observer,)));
                    },
                  ),
                  title: Text("Cart",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  centerTitle: true,
              ),
              bottomNavigationBar: cart.isNotEmpty ? Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextButton.icon(
                        onPressed: (){
                          Navigator.popAndPushNamed(context, '/feed');
                        },
                        icon: Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.black),
                        label: Text(
                          'SHOP MORE',
                          style: buttonText,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextButton.icon(
                        style: button,
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Address(analytics: widget.analytics, observer: widget.observer, cart: cart,)));
                        },
                        icon: Icon(Icons.shopping_bag, size: 40, color: Colors.white),
                        label: Text(
                          'CHECKOUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ]
              ) : Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextButton.icon(
                      style: button,
                      onPressed: (){
                        Navigator.popAndPushNamed(context, '/feed');
                      },
                      icon: Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.white),
                      label: Text(
                        'SHOP MORE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ]
              ),
              bottomSheet:
              cart.isNotEmpty ? Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Open Sans',
                      ),
                    ),
                    Text(
                      '${total.toString()}.00 TL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Open Sans',
                      ),
                    )
                  ]
                ),
              ) : Text(''),
              body: cart.length != 0 ? Padding(
                padding: const EdgeInsets.only(bottom: 65),
                child: ListView(
                  children: cart.entries.map((entry) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          Divider(color: Colors.black,
                            indent: 20,
                            endIndent: 20,
                          ),
                          ListTile(
                            leading: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: GestureDetector(
                                child: Image.network(entry.value[7]),
                                onTap: (){

                                }
                              ),
                            ),
                            title: Column(
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    entry.value[0].length <= 13 ? entry.value[0].toString().toUpperCase() : entry.value[0].substring(0, 10).toUpperCase() + '...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      fontFamily: 'Open Sans',
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        entry.value[5] + ' TL',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          fontFamily: 'Open Sans',
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            iconSize: 20,
                                            padding: const EdgeInsets.all(0),
                                            icon: Icon(Icons.indeterminate_check_box),
                                            onPressed: (){
                                              decrementQuantity(entry.key, entry.value[0]);
                                            },
                                          ),
                                          Text(
                                            entry.value[6],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              fontFamily: 'Open Sans',
                                            ),
                                          ),
                                          IconButton(
                                            iconSize: 20,
                                            padding: const EdgeInsets.all(0),
                                            icon: Icon(Icons.add_box_rounded),
                                            onPressed: (){
                                              incrementQuantity(entry.key);
                                            },
                                          ),
                                        ]
                                      )
                                    )
                                  ]
                                ),

                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    entry.value[1],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        fontFamily: 'Open Sans',
                                        color: Colors.grey.shade700
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    'Receive within: ${entry.value[2]} day(s)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        fontFamily: 'Open Sans',
                                        color: Colors.grey.shade700
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ]
                            ),
                            /*subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add_box_rounded),
                                  onPressed: (){},
                                ),
                                Text(
                                    '1'
                                ),
                                IconButton(
                                  icon: Icon(Icons.indeterminate_check_box),
                                  onPressed: (){},
                                )
                              ]
                            ),*/

                            //title:
                            //isThreeLine: true,
                          ),
                          Divider(
                            color: Colors.black,
                            indent: 20,
                            endIndent: 20,
                          ),
                        ],
                      ),
                    );
                  }).toList()),
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      'Cart is empty! :(',
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                  )
                ],
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


