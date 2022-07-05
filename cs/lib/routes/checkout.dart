import 'package:cs/routes/cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'dart:math';

class CardFormatter extends TextInputFormatter {
  final String sample;
  final String separator;

  CardFormatter({
    required this.sample,
    required this.separator,
  }) {
    assert(sample != null);
    assert(separator != null);
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue){
    if (newValue.text.length > 0){
      if (newValue.text.length > oldValue.text.length){
        if (newValue.text.length > sample.length) return oldValue;
        if (newValue.text.length < sample.length && sample[newValue.text.length - 1] == separator){
          return TextEditingValue(
            text: '${oldValue.text}$separator${newValue.text.substring(newValue.text.length - 1)}',
            selection: TextSelection.collapsed(
              offset: newValue.selection.end + 1,
            )
          );
        }
      }
    }
    return newValue;
  }
}


class Checkout extends StatefulWidget {
  const Checkout({Key? key, required this.analytics, required this.observer, this.cart, this.address}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  final cart;
  final String? address;

  @override
  _CheckoutState createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {

  final _formKeyCheckout = GlobalKey<FormState>();
  String cardNumber = "";
  String expiryDate = "";
  String codeCVC = "";
  String cardHolderName = "";
  TextEditingController nameController = TextEditingController();

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
  var ordersPlaced = {};
  var ordersReceived = {};
  String orderID = "";
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
        ordersPlaced = data['ordersPlaced'];
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

  Future confirmOrder() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }

    for (var entry in cart.entries) {
      String bookID = entry.key;
      String bookName = entry.value[0];
      String pictureURL = entry.value[7];
      String quantity = entry.value[6];
      String price = entry.value[5];
      String bookType = entry.value[8];
      String bookCategory = entry.value[1];
      String sellerID = entry.value[4];
      var array = [currentUser!.uid, sellerID, price, widget.address, bookID, bookName, quantity, bookType, bookCategory, pictureURL, "Placed"];
      ordersPlaced[bookID + '-' + orderID + '-' + total.toString()] = array;

      String seller = entry.value[4];

      await FirebaseFirestore.instance.collection('users').doc(seller).get().then((DocumentSnapshot snapshot) async{
        setState(() {
          data = snapshot.data();
          ordersReceived = data['ordersReceived'];
        });
        ordersReceived[bookID + '-' + orderID + '-' + total.toString()] = array;
        await FirebaseFirestore.instance.collection('users').doc(seller).update({
          "ordersReceived": ordersReceived,
        });
      });
    }

    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      "ordersPlaced": ordersPlaced,
    });

    await notifySellers().then((value)async {
      cart.clear();
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        "cart": cart,
      });
    });

  }

  Future notifySellers() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    List<String> sellers = [];
    List<String> bookIDs = [];
    List<String> quantities = [];
    List<String> titles = [];
    List<String> pictures = [];
    cart.forEach((key, value) {
      sellers.add(value[4]);
      bookIDs.add(key);
      quantities.add(value[6]);
      titles.add(value[0]);
      pictures.add(value[7]);
    });
    for (int i = 0; i < sellers.length; i++){
      var notifications = {};
      await FirebaseFirestore.instance.collection('users').doc(sellers[i]).get().then((DocumentSnapshot snapshot){
        data = snapshot.data();
        notifications = data['notifications'];
      });
      String notiID = "${bookIDs[i]}-";
      var rng = Random();
      for (int i = 0; i < 8; i++){
        notiID += rng.nextInt(9).toString();
      }

      String notiContent = "Your book ${titles[i].toUpperCase()} has just been sold. Quantity: ${quantities[i]}";
      Timestamp timeAndDate = Timestamp.fromDate(DateTime.now());
      var array = [notiContent, timeAndDate, bookIDs[i], sellers[i], pictures[i], notiID, false];
      notifications[notiID] = array;

      await FirebaseFirestore.instance.collection('users').doc(sellers[i]).update({
        'notifications': notifications,
      });
    }

  }

  Future<void> showAlertDialog(String title, String message) async {
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
                TextButton(
                  style: button,
                  onPressed: () {
                    confirmOrder().then((value) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                      Navigator.pushNamed(context, '/feed');
                    });
                  },
                  child: Text(
                    'CONTINUE SHOPPING',
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
                TextButton(
                    style: button,
                    onPressed: () {
                      confirmOrder().then((value) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                        Navigator.pushNamed(context, '/feed');
                      });
                    },
                    child: Text(
                      'CONTINUE SHOPPING',
                      style: buttonText,
                    )
                ),
              ],
            );
          }
        });
  }

  _CheckoutState() {
    _setLogEvent("Feed_page_reached");
    getData();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    String ID = "";
    var rng = Random();
    for (int i = 0; i < 4; i++){
      ID += rng.nextInt(9).toString();
    }
    setState(() {
      orderID = ID;
    });
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
                    },
                  ),
                  title: Text("Checkout",
                    style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)
                  ),
                  centerTitle: true,
                ),
                bottomNavigationBar: cart.isNotEmpty ? Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextButton.icon(
                          style: button,
                          onPressed: (){
                            if(_formKeyCheckout.currentState!.validate()) {
                              _formKeyCheckout.currentState!.save();
                              showAlertDialog("PAYMENT CONFIRMED!",
                                  "Your order ID#$orderID is being processed.");
                            }

                          },
                          icon: Icon(Icons.attach_money_rounded, size: 40, color: Colors.white),
                          label: Text(
                            'PAY & CONFIRM ORDER',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ]
                ) : Center(
                  child: CircularProgressIndicator(
                    color: AppColors.feedPrimary,
                  ),
                ),
                bottomSheet:
                cart.isNotEmpty ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 100,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Address: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: 'Open Sans',
                              ),
                            ),
                          ]
                        ),
                        const SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${widget.address}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                fontFamily: 'Open Sans',
                              ),
                            )
                          ]
                        ),
                        const SizedBox(height: 10),
                        Row(
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
                      ],
                    ),
                  ),
                ) : Text(''),
                body: cart.isNotEmpty ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKeyCheckout,
                    child: Column(
                      children: [
                        TextFormField(
                          inputFormatters: [
                            CardFormatter(
                                sample: 'xxxx-xxxx-xxxx-xxxx',
                                separator: '-'
                            ),
                          ],
                          keyboardType: TextInputType.number,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                            ),
                            floatingLabelStyle: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ) ,
                            labelText: 'Card Number',
                          ),
                          validator: (value) {
                            if (value == null){
                              return 'Card Number field cannot be empty!';
                            } else {
                              String trimmedValue = value.trim();
                              if (trimmedValue.isEmpty){
                                return 'Card Number field cannot be empty!';
                              }
                              if (trimmedValue.length > 20){
                                return 'Invalid Card Number length!';
                              }
                            }
                            return null;
                          },
                          onSaved: (value) {
                            if (value != null){
                              cardNumber = value;
                            }
                          }
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: nameController,
                          keyboardType: TextInputType.text,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                            ),
                            floatingLabelStyle: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ) ,
                            labelText: 'Card Holder Name',
                          ),
                          validator: (value) {
                            if (value == null){
                              return 'Card Holder Name field cannot be empty!';
                            } else {
                              String trimmedValue = value.trim();
                              if (trimmedValue.isEmpty){
                                return 'Card Holder Name field cannot be empty!';
                              }
                            }
                            return null;
                          },
                          onSaved: (value) {
                            if (value != null){
                              cardHolderName = value;
                            }
                          },
                          onChanged: (value) {
                            nameController.value = TextEditingValue(
                              text: value.toUpperCase(),
                              selection: nameController.selection
                            );
                          },

                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                  inputFormatters: [
                                    CardFormatter(
                                        sample: 'xx/xx',
                                        separator: '/'
                                    ),
                                  ],
                                  keyboardType: TextInputType.number,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                                    ),
                                    floatingLabelStyle: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ) ,
                                    labelText: 'Expiry Date',
                                  ),
                                  validator: (value) {
                                    if (value == null){
                                      return 'Expiry Date field cannot be empty!';
                                    } else {
                                      String trimmedValue = value.trim();
                                      if (trimmedValue.isEmpty){
                                        return 'Expiry Date field cannot be empty!';
                                      }
                                      if (trimmedValue.length > 5){
                                        return 'Invalid Expiry Date length!';
                                      }
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    if (value != null){
                                      expiryDate = value;
                                    }
                                  }
                              ),
                            ),
                            SizedBox(width: MediaQuery.of(context).size.width/3),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                  inputFormatters: [
                                    CardFormatter(
                                        sample: 'xxx',
                                        separator: ''
                                    ),
                                  ],
                                  keyboardType: TextInputType.number,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                                    ),
                                    floatingLabelStyle: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ) ,
                                    labelText: 'CVC',
                                  ),
                                  validator: (value) {
                                    if (value == null){
                                      return 'CVC field cannot be empty!';
                                    } else {
                                      String trimmedValue = value.trim();
                                      if (trimmedValue.isEmpty){
                                        return 'CVC field cannot be empty!';
                                      }
                                      if (trimmedValue.length > 3){
                                        return 'Invalid CVC length!';
                                      }
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    if (value != null){
                                      codeCVC = value;
                                    }
                                  }
                              ),
                            ),
                          ],
                        ),
                      ]
                    ),
                  ),
                ) : Container(),
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


