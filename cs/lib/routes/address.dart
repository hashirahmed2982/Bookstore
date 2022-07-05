import 'package:cs/routes/cart.dart';
import 'package:cs/routes/checkout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
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

class Address extends StatefulWidget {
  const Address({Key? key, required this.analytics, required this.observer, this.cart}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  final cart;

  @override
  _AddressState createState() => _AddressState();
}

class _AddressState extends State<Address> {

  final _formKeyAddress = GlobalKey<FormState>();
  String address = "";
  TextEditingController addressController = TextEditingController();

  Future<void> _setLogEvent(n) async {
    await widget.analytics.logEvent(
        name: n,
        parameters: <String, dynamic> {
          "bool" : true,
        }
    );
  }

  FirebaseAuth auth = FirebaseAuth.instance;

  var cart = {};

  _AddressState() {
    _setLogEvent("Feed_page_reached");
  }

  @override
  void initState(){
    super.initState();
    setState(() {
      cart = widget.cart;
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
                title: Text("Address Details",
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
                          if(_formKeyAddress.currentState!.validate()) {
                            _formKeyAddress.currentState!.save();
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Checkout(analytics: widget.analytics, observer: widget.observer, cart: cart, address: address)));
                          }
                        },
                        icon: Icon(Icons.check_circle, size: 40, color: Colors.white),
                        label: Text(
                          'PROCEED TO PAYMENT',
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
              body: cart.isNotEmpty ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKeyAddress,
                  child: Column(
                      children: [
                        TextFormField(
                          keyboardType: TextInputType.text,
                          maxLength: 60,
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
                            labelText: 'Address (House #, Street #, City, Postal Code)',
                          ),
                          validator: (value) {
                            if (value == null){
                              return 'Address field cannot be empty!';
                            } else {
                              String trimmedValue = value.trim();
                              if (trimmedValue.isEmpty){
                                return 'Address field cannot be empty!';
                              }
                            }
                            return null;
                            },
                            onSaved: (value) {
                              if (value != null){
                                address = value;
                              }
                            }
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


