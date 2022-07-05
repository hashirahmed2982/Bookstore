import 'package:cs/classes/comment.dart';
import 'package:cs/classes/usernotification.dart';
import 'package:cs/models/comment_list_container.dart';
import 'package:cs/routes/seller.dart';
import 'package:cs/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:cs/utils/styles.dart';
import 'package:cs/utils/dimensions.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:cs/routes/feed.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:math';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:cs/classes/interactiveimage.dart';

class Product extends StatefulWidget {
  const Product({Key? key,
    required this.analytics,
    required this.observer,
    this.ID,
    this.title,
    this.author,
    this.type,
    this.category,
    this.description,
    this.deliveryWithin,
    this.seller,
    this.sellerID,
    this.price,
    this.discountedPrice,
    this.inventory,
    this.sold,
    this.pictureURL,
    this.comments,
    this.currentUID,
    this.cartPassed,
    this.bookmarksPassed,
    this.notificationsPassed,
  }) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  final String? ID, title, author, type, category, description, deliveryWithin, seller, sellerID, price, discountedPrice, inventory, sold, pictureURL, currentUID;
  final dynamic comments, cartPassed, bookmarksPassed, notificationsPassed;

  @override
  _ProductState createState() => _ProductState();
}

class _ProductState extends State<Product> {

  FirebaseAuth auth = FirebaseAuth.instance;
  dynamic data;
  var cart = {};
  var bookmarks = {};
  String quantity = "1";
  String discountedPrice = "0";
  bool alreadyAddedToCart = false;
  bool alreadyAddedToBookmarks = false;
  bool showCartBadge = false;
  bool discountOffered = false;

  var removingCart = {};
  var removingBookmarks = {};
  var removingOfferedProducts = {};

  var discountedPriceCart = {};
  var discountedPriceBookmarks = {};
  var discountedPriceOfferedProducts = {};

  var commentsMap = {};
  List<Comment> comments = [];
  final _formKeyComments = GlobalKey<FormState>();
  String userProfilePictureURL = "";
  String username = "";
  String commentContent = "";
  String commentRating = "4.0";
  //var bookmarksComment = {};
  //var offeredProductsComment = {};
  //var approveCommentMap = {};
  //var deleteCommentMap = {};
  TextEditingController commentController = TextEditingController();

  TextEditingController discountController = TextEditingController();
  String _message = "";
  String? controllerPrice;

  String seller = "";
  String sellerID = "";

  TransformationController imageController = TransformationController();
  TapDownDetails? tapDownDetails;

  double? initialRating;

  var notifications = {};
  String uid = "";
  bool showNotificationsBadge = false;

  Future getSellerName() async {
    await FirebaseFirestore.instance.collection('users').doc(sellerID).get().then((DocumentSnapshot snapshot) {
      data = snapshot.data();
      setState(() {
        seller = data['username'];
      });
    });
  }

  Future addToCart() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    await document.get().then<dynamic>((DocumentSnapshot snapshot) async{
      setState(() {
        data = snapshot.data();
        cart = data['cart'];
      });
    }).then((value) async {
      var array = [];
      if (discountOffered) {
        array = [
          widget.title,
          widget.type,
          widget.deliveryWithin,
          widget.seller,
          widget.sellerID,
          discountedPrice,
          quantity,
          widget.pictureURL,
          widget.category
        ];
      }

      else {
        array = [
          widget.title,
          widget.type,
          widget.deliveryWithin,
          widget.seller,
          widget.sellerID,
          widget.price,
          quantity,
          widget.pictureURL,
          widget.category
        ];
      }

      if (cart.containsKey(widget.ID)) {
        cart['${widget.ID}'][6] = (int.parse(cart['${widget.ID}'][6]) + int.parse(quantity)).toString();
      }
      else {
        cart['${widget.ID}'] = array;
      }
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        "cart": cart,
      });
      setState(() {
        alreadyAddedToCart = true;
      });
    });
  }

  Future removeFromCart() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    cart.remove(widget.ID);
    if (cart.isEmpty){
      setState(() {
        showCartBadge = false;
      });
    }
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      "cart": cart,
    });
    setState(() {
      alreadyAddedToCart = false;
    });
  }

  Future addToBookmarks() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    await document.get().then<dynamic>((DocumentSnapshot snapshot) async{
      setState(() {
        data = snapshot.data();
        bookmarks = data['bookmarks'];
      });
    }).then((value) async {
      var array = [widget.title, widget.author, widget.type, widget.category, widget.description, widget.deliveryWithin, widget.seller, widget.sellerID, widget.price, widget.discountedPrice, widget.inventory, widget.sold, widget.pictureURL, widget.comments];
      if (!bookmarks.containsKey(widget.ID)) {
        bookmarks['${widget.ID}'] = array;
      }
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        "bookmarks": bookmarks,
      });
      setState(() {
        alreadyAddedToBookmarks = true;
      });
    });
  }

  Future removeFromBookmarks() async{
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    bookmarks.remove(widget.ID);
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      "bookmarks": bookmarks,
    });
    setState(() {
      alreadyAddedToBookmarks = false;
    });
  }

  Future<void> showAlertDialogAddToCart(String title, String message) async {
    bool isiOS = Platform.isIOS;

    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if(isiOS) {
            return CupertinoAlertDialog(
              title: Text(title,textAlign: TextAlign.center,),
              content: StatefulBuilder(
                  builder: (context, setState) {
                    return SingleChildScrollView(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 20,
                              padding: const EdgeInsets.all(0),
                              icon: Icon(Icons.indeterminate_check_box),
                              onPressed: (){
                                setState(() {
                                  quantity = (int.parse(quantity) - 1).toString();
                                });;
                              },
                            ),
                            Text(
                              quantity,
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
                                setState(() {
                                  quantity = (int.parse(quantity) + 1).toString();
                                });
                              },
                            ),
                          ]
                      ),
                    );
                  }
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        quantity = "1";
                      });
                    },
                    child: Text(
                      'CANCEL',
                      style: buttonText,
                    )
                ),
                TextButton(
                    style: button,
                    onPressed: () {
                      addToCart().then((value) {
                        showingCartBadge();
                        Navigator.pop(context);
                      });
                    },
                    child: Container(
                        color: AppColors.feedPrimary,
                        child: Text(
                          'ADD TO CART',
                          style: buttonText,
                        )
                    )
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Text(title,textAlign: TextAlign.center,),
              content: StatefulBuilder(
                builder: (context, setState) {
                  return SingleChildScrollView(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 20,
                            padding: const EdgeInsets.all(0),
                            icon: Icon(Icons.indeterminate_check_box),
                            onPressed: (){
                              setState(() {
                                quantity = (int.parse(quantity) - 1).toString();
                              });;
                            },
                          ),
                          Text(
                            quantity,
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
                              setState(() {
                                quantity = (int.parse(quantity) + 1).toString();
                              });
                            },
                          ),
                        ]
                    ),
                  );
                }
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        quantity = "1";
                      });
                    },
                    child: Text(
                      'CANCEL',
                      style: buttonText,
                    )
                ),
                TextButton(
                    style: button,
                    onPressed: () {
                      addToCart().then((value) {
                        showingCartBadge();
                        Navigator.pop(context);
                      });
                    },
                    child: Container(
                        color: AppColors.feedPrimary,
                        child: Text(
                          'ADD TO CART',
                          style: buttonText,
                        )
                    )
                ),
              ],
            );
          }
        });
  }

  Future<void> showAlertDialogDeleteProduct(String title, String message) async {
    bool isiOS = Platform.isIOS;

    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if(isiOS) {
            return CupertinoAlertDialog(
              title: Text(title,textAlign: TextAlign.center,),
              content: StatefulBuilder(
                  builder: (context, setState) {
                    return SingleChildScrollView(
                      child: Text(message, textAlign: TextAlign.center),
                    );
                  }
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'NO',
                      style: buttonText,
                    )
                ),
                TextButton(
                    style: cancelProductButton,
                    onPressed: () {
                      deleteProduct().then((value) async {
                        await Future.delayed(const Duration(seconds: 1), (){});
                        Navigator.popAndPushNamed(context, '/feed');
                      });
                    },
                    child: Container(
                        child: Text(
                          'YES',
                          style: buttonText,
                        )
                    )
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Text(title,textAlign: TextAlign.center,),
              content: StatefulBuilder(
                  builder: (context, setState) {
                    return SingleChildScrollView(
                      child: Text(message, textAlign: TextAlign.center),
                    );
                  }
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'NO',
                      style: buttonText,
                    )
                ),
                TextButton(
                    style: cancelProductButton,
                    onPressed: () {
                      deleteProduct().then((value) async {
                        await Future.delayed(const Duration(seconds: 1), (){});
                        Navigator.popAndPushNamed(context, '/feed');
                      });
                    },
                    child: Container(
                        child: Text(
                          'YES',
                          style: buttonText,
                        )
                    )
                ),
              ],
            );
          }
        });
  }

  Future<void> showAlertDialogOfferDiscount(String title, String message) async {
    bool isiOS = Platform.isIOS;

    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if(isiOS) {
            return StatefulBuilder(
                builder: (context, setState) {
                  return CupertinoAlertDialog(
                    title: Text(title,textAlign: TextAlign.center,),
                    content: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextFormField(
                              controller: discountController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              enableSuggestions: false,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                hintText: 'New Price',
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 1.5),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty){
                                  if (int.parse(value.toString()) < int.parse(widget.price!)){
                                    setState((){
                                      controllerPrice = value.toString();
                                      _message = "";
                                    });
                                  }
                                  else {
                                    setState((){
                                      _message = "Discounted price must be lower than the original price!";
                                    });
                                  }
                                }
                              }
                          ),
                          const SizedBox (height: 10),
                          Text(
                            _message,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            discountController.clear();
                            controllerPrice = null;
                          },
                          child: Text(
                            'CANCEL',
                            style: buttonText,
                          )
                      ),
                      TextButton(
                          style: (controllerPrice != null && controllerPrice!.isNotEmpty && _message.isEmpty) ? button : ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.grey.shade200),
                          ),
                          onPressed: (controllerPrice != null && controllerPrice!.isNotEmpty && _message.isEmpty) ? () {
                            if (controllerPrice != null && controllerPrice!.isNotEmpty){
                              offerDiscount(controllerPrice!).then((value) {
                                setState(() {
                                  discountedPrice = controllerPrice!;
                                });
                                discountController.clear();
                                showingDiscount();
                                Navigator.pop(context);
                              });
                            }
                          } : null,
                          child: Container(
                              child: Text(
                                'OFFER',
                                style: buttonText,
                              )
                          )
                      ),
                    ],
                  );
                }
            );
          } else {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text(title,textAlign: TextAlign.center,),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                            controller: discountController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              hintText: 'New Price',
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black, width: 1.5),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty){
                                if (int.parse(value.toString()) < int.parse(widget.price!)){
                                  setState((){
                                    controllerPrice = value.toString();
                                    _message = "";
                                  });
                                }
                                else {
                                  setState((){
                                    _message = "Discounted price must be lower than the original price!";
                                  });
                                }
                              }
                            }
                        ),
                        const SizedBox (height: 10),
                        Text(
                          _message,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          discountController.clear();
                          controllerPrice = null;
                        },
                        child: Text(
                          'CANCEL',
                          style: buttonText,
                        )
                    ),
                    TextButton(
                        style: (controllerPrice != null && controllerPrice!.isNotEmpty && _message.isEmpty) ? button : ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.grey.shade200),
                        ),
                        onPressed: (controllerPrice != null && controllerPrice!.isNotEmpty && _message.isEmpty) ? () {
                          if (controllerPrice != null && controllerPrice!.isNotEmpty){
                            offerDiscount(controllerPrice!).then((value) {
                              setState(() {
                                discountedPrice = controllerPrice!;
                              });
                              discountController.clear();
                              showingDiscount();
                              Navigator.pop(context);
                            });
                          }
                        } : null,
                        child: Container(
                            child: Text(
                              'OFFER',
                              style: buttonText,
                            )
                        )
                    ),
                  ],
                );
              }
            );
          }
        });
  }

  Future<void> showAlertDialogComment(String title, String message) async {
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
                    style: button,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'OK',
                      style: buttonText,
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
                    style: button,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'OK',
                      style: buttonText,
                    )
                ),
              ],
            );
          }
        });
  }

  Future deleteProduct() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    String bookDocID = currentUser!.uid + '-' + widget.ID!;
    await FirebaseFirestore.instance.collection("books").doc(bookDocID).delete().then((value) async {
      final CollectionReference collection = FirebaseFirestore.instance.collection('users');
      await collection.get().then<dynamic>((QuerySnapshot snapshot) async{
        snapshot.docs.forEach((doc) {
          String docID = doc.id;
          final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(docID);
          document.get().then<dynamic>((DocumentSnapshot snapshot2) async {
            setState(() {
              data = snapshot2.data();
              removingCart = data['cart'];
              removingBookmarks = data['bookmarks'];
            });
            removingCart.remove(widget.ID);
            removingBookmarks.remove(widget.ID);
            await FirebaseFirestore.instance.collection('users').doc(docID).update({
              "cart": removingCart,
              "bookmarks": removingBookmarks,
            });
          });
        });
      });
    });
    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get().then((DocumentSnapshot snapshot) async {
      setState(() {
        data = snapshot.data();
        removingOfferedProducts = data['offeredProducts'];
      });
      removingOfferedProducts.remove(widget.ID);
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        "offeredProducts": removingOfferedProducts,
      });
    });
  }

  Future offerDiscount(String discount) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    String bookDocID = currentUser!.uid + '-' + widget.ID!;
    await FirebaseFirestore.instance.collection('books').doc(bookDocID).update({
      "discountedPrice": discount,
    });
    final CollectionReference collection = FirebaseFirestore.instance.collection('users');
    await collection.get().then<dynamic>((QuerySnapshot snapshot) async{
      snapshot.docs.forEach((doc) {
        String docID = doc.id;
        var notificationsMap = {};
        final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(docID);
        document.get().then<dynamic>((DocumentSnapshot snapshot2) async {
          setState(() {
            data = snapshot2.data();
            discountedPriceCart = data['cart'];
            discountedPriceBookmarks = data['bookmarks'];
            notificationsMap = data['notifications'];
          });
          if (discountedPriceCart.containsKey(widget.ID)){
            discountedPriceCart[widget.ID][5] = discount;
          }
          if (discountedPriceBookmarks.containsKey(widget.ID)){
            discountedPriceBookmarks[widget.ID][9] = discount;
          }
          if (docID != widget.sellerID){
            String notiID = "${widget.ID}-";
            var rng = Random();
            for (int i = 0; i < 8; i++){
              notiID += rng.nextInt(9).toString();
            }
            String notiContent = "The seller of ${widget.title!.toUpperCase()} is offering a massive discount! Check it out!";
            Timestamp timeAndDate = Timestamp.fromDate(DateTime.now());
            var array = [notiContent, timeAndDate, widget.ID, sellerID, widget.pictureURL, notiID, false];
            notificationsMap[notiID] = array;
            await FirebaseFirestore.instance.collection('users').doc(docID).update({
              "notifications": notificationsMap,
            });
          }
          await FirebaseFirestore.instance.collection('users').doc(docID).update({
            "cart": discountedPriceCart,
            "bookmarks": discountedPriceBookmarks,
          });
        });
      });
    });
    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get().then((DocumentSnapshot snapshot) async {
      setState(() {
        data = snapshot.data();
        discountedPriceOfferedProducts = data['offeredProducts'];
      });
      if (discountedPriceOfferedProducts.containsKey(widget.ID)){
        discountedPriceOfferedProducts[widget.ID][9] = discount;
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          "offeredProducts": discountedPriceOfferedProducts,
        });
      }
    });


  }

  bool showingCartBadge() {
    if (cart.isNotEmpty){
      setState(() {
        showCartBadge = true;
      });
      return true;
    }
    else {
      setState(() {
        showCartBadge = false;
      });
      return false;
    }
  }

  bool showingDiscount() {
    if (int.parse(discountedPrice) < int.parse(widget.price!)){
      setState(() {
        discountOffered = true;
      });
      return true;
    }
    else {
      setState(() {
        discountOffered = false;
      });
      return false;
    }
  }

  Future showingNotificationsBadge() async{
    int count = 0;
    notifications.forEach((key, value) {
      if (value[6] == false){
        count++;
      }
    });
    if (count > 0){
      setState(() {
        showNotificationsBadge = true;
      });
    }
  }

  Future getComments() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get().then((DocumentSnapshot snapshot) {
      setState(() {
        data = snapshot.data();
        userProfilePictureURL = data['pictureURL'];
        username = data['username'];
      });
    });

    commentsMap.forEach((key, value) {
      int lastDash = key.toString().lastIndexOf('-');
      String firstSlice = key.toString().substring(0, lastDash);
      int secondLastDash = firstSlice.lastIndexOf('-');
      String uid = key.toString().substring(secondLastDash + 1, lastDash);
      String commentByUID = uid;
      //String commentByUID = key;
      String commentByName = value[0];
      String commentByPictureURL = value[1];
      String content = value[2];
      Timestamp dateTime = value[3];
      bool isApproved = value[4];
      String commentRating = value[5];
      String commentID = value[6];
      Comment comment = Comment(commentByName, commentByUID, commentByPictureURL, content, dateTime, isApproved, commentRating, commentID);
      setState(() {
        comments.add(comment);
      });
    });
    setState(() {
      comments = comments.reversed.toList();
    });
  }

  Future addComment() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    String ID = "";
    var rng = Random();
    for (int i = 0; i < 4; i++){
      ID += rng.nextInt(9).toString();
    }
    String commentID = DateTime.now().toString() + '-' + currentUser!.uid  + '-' + ID;
    var array = [username, userProfilePictureURL, commentContent, Timestamp.fromDate(DateTime.now()), false, commentRating, commentID];
    commentsMap[commentID] = array;
    String docID = widget.sellerID! + '-' + widget.ID!;
    //Comment comment = Comment(username, currentUser.uid, userProfilePictureURL, commentContent, Timestamp.fromDate(DateTime.now()), false);
    await FirebaseFirestore.instance.collection('books').doc(docID).update({
      "comments": commentsMap,
    });
    calculateRating();
    //update bookmarks (every user), myofferedProducts (sellerID)
    final CollectionReference collection = FirebaseFirestore.instance.collection('users');
    await collection.get().then<dynamic>((QuerySnapshot snapshot) async{
      snapshot.docs.forEach((doc) {
        String docID = doc.id;
        var bookmarksComment = {};
        var offeredProductsComment = {};
        final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(docID);
        document.get().then<dynamic>((DocumentSnapshot snapshot2) async {
          setState(() {
            data = snapshot2.data();
            offeredProductsComment = data['offeredProducts'];
            bookmarksComment = data['bookmarks'];
          });
          if (offeredProductsComment.containsKey(widget.ID)){
            offeredProductsComment[widget.ID][13] = commentsMap;
            await FirebaseFirestore.instance.collection('users').doc(docID).update({
              "offeredProducts": offeredProductsComment,
            });
          }
          if (bookmarksComment.containsKey(widget.ID)){
            bookmarksComment[widget.ID][13] = commentsMap;
            await FirebaseFirestore.instance.collection('users').doc(docID).update({
              "bookmarks": bookmarksComment,
            });
          }
        });
      });
    });
  }

  Future approveComment(Comment comment) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    String docID = currentUser!.uid + '-' + widget.ID!;
    setState(() {
      commentsMap[comment.commentID][4] = true;
    });
    await FirebaseFirestore.instance.collection('books').doc(docID).update({
      "comments": commentsMap,
    });
    final CollectionReference collection = FirebaseFirestore.instance.collection('users');
    await collection.get().then<dynamic>((QuerySnapshot snapshot) async{
      snapshot.docs.forEach((doc) {
        String docID = doc.id;
        var bookmarksComment = {};
        var offeredProductsComment = {};
        final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(docID);
        document.get().then<dynamic>((DocumentSnapshot snapshot2) async {
          setState(() {
            data = snapshot2.data();
            offeredProductsComment = data['offeredProducts'];
            bookmarksComment = data['bookmarks'];
          });
          if (offeredProductsComment.containsKey(widget.ID)){
            offeredProductsComment[widget.ID][13] = commentsMap;
            await FirebaseFirestore.instance.collection('users').doc(docID).update({
              "offeredProducts": offeredProductsComment,
            });
          }
          if (bookmarksComment.containsKey(widget.ID)){
            print(data['uid'].toString());
            bookmarksComment[widget.ID][13] = commentsMap;
            await FirebaseFirestore.instance.collection('users').doc(docID).update({
              "bookmarks": bookmarksComment,
            });
          }
        });
      });
    });

    var notificationsMap = {};
    await FirebaseFirestore.instance.collection('users').doc(comment.commentByUID).get().then((DocumentSnapshot snapshot){
      data = snapshot.data();
      notificationsMap = data['notifications'];
    });

    String notiID = "${widget.ID}-";
    var rng = Random();
    for (int i = 0; i < 8; i++){
      notiID += rng.nextInt(9).toString();
    }
    String notiContent = "Your comment on the book ${widget.title!.toUpperCase()} has been approved by the seller!";
    Timestamp timeAndDate = Timestamp.fromDate(DateTime.now());
    var array = [notiContent, timeAndDate, widget.ID, sellerID, widget.pictureURL, notiID, false];
    notificationsMap[notiID] = array;
    await FirebaseFirestore.instance.collection('users').doc(comment.commentByUID).update({
      'notifications': notificationsMap,
    });
  }

  Future deleteComment(Comment comment) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    String docID = currentUser!.uid + '-' + widget.ID!;
    setState(() {
      commentsMap.remove(comment.commentID);
    });
    await FirebaseFirestore.instance.collection('books').doc(docID).update({
      "comments": commentsMap,
    });
    final CollectionReference collection = FirebaseFirestore.instance.collection('users');
    await collection.get().then<dynamic>((QuerySnapshot snapshot) async{
      snapshot.docs.forEach((doc) {
        String docID = doc.id;
        var bookmarksComment = {};
        var offeredProductsComment = {};
        final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(docID);
        document.get().then<dynamic>((DocumentSnapshot snapshot2) async {
          setState(() {
            data = snapshot2.data();
            offeredProductsComment = data['offeredProducts'];
            bookmarksComment = data['bookmarks'];
          });
          if (offeredProductsComment.containsKey(widget.ID)){
            offeredProductsComment[widget.ID][13] = commentsMap;
            await FirebaseFirestore.instance.collection('users').doc(docID).update({
              "offeredProducts": offeredProductsComment,
            });
          }
          if (bookmarksComment.containsKey(widget.ID)){
            print(data['uid'].toString());
            bookmarksComment[widget.ID][13] = commentsMap;
            await FirebaseFirestore.instance.collection('users').doc(docID).update({
              "bookmarks": bookmarksComment,
            });
          }
        });
      });
    });
  }

  void updateComments() {
    comments.clear();
    calculateRating();
    commentsMap.forEach((key, value) {
      int lastDash = key.toString().lastIndexOf('-');
      String firstSlice = key.toString().substring(0, lastDash);
      int secondLastDash = firstSlice.lastIndexOf('-');
      String uid = key.toString().substring(secondLastDash + 1, lastDash);
      String commentByUID = uid;
      //String commentByUID = key;
      String commentByName = value[0];
      String commentByPictureURL = value[1];
      String content = value[2];
      Timestamp dateTime = value[3];
      bool isApproved = value[4];
      String commentRating = value[5];
      String commentID = value[6];
      Comment comment = Comment(commentByName, commentByUID, commentByPictureURL, content, dateTime, isApproved, commentRating, commentID);
      setState(() {
        comments.add(comment);
      });
    });
    setState(() {
      comments = comments.reversed.toList();
    });
  }

  Future calculateRating() async {
    double totalRating = 0.0;
    double commentCount = 0.0;
    commentsMap.forEach((key, value) {
      totalRating += double.parse(value[5]);
      commentCount += 1.0;
    });
    if (commentCount > 0){
      setState(() {
        initialRating = totalRating/commentCount;
      });
    }
    else{
      setState(() {
        initialRating = 0.0;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      cart = widget.cartPassed;
      notifications = widget.notificationsPassed;
      bookmarks = widget.bookmarksPassed;
      discountedPrice = widget.discountedPrice!;
      commentsMap = widget.comments;
      seller = widget.seller!;
      sellerID = widget.sellerID!;
    });
    if (cart.containsKey(widget.ID)){
      setState(() {
        alreadyAddedToCart = true;
      });
    }
    if (bookmarks.containsKey(widget.ID)){
      setState(() {
        alreadyAddedToBookmarks = true;
      });
    }
    getSellerName();
    showingCartBadge();
    showingNotificationsBadge();
    showingDiscount();
    getComments();
    calculateRating();
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
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Feed(analytics: widget.analytics, observer: widget.observer,)));
            },
          ),
          title: Text("Bookstore",
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  if (showNotificationsBadge)
                    const Positioned(
                      top: 0.0,
                      right: 0.0,
                      child: Icon(
                        Icons.brightness_1,
                        size: 10.0,
                        color: Colors.red,
                      ),
                    )
                ]
              )
            ),
            IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (showCartBadge)
                      const Positioned(
                        top: 0.0,
                        right: 0.0,
                        child: Icon(
                          Icons.brightness_1,
                          size: 10.0,
                          color: Colors.red,
                        ),
                      )
                  ]
                )
            ),
          ]
      ),
      bottomNavigationBar: Row(
            children: [
              if (alreadyAddedToBookmarks && widget.sellerID != widget.currentUID)
                Expanded(
                  flex: 2,
                  child: TextButton.icon(
                    onPressed: removeFromBookmarks,
                    icon: Icon(Icons.bookmark, size: 40, color: Colors.black),
                    label: Text(
                      'BOOKMARK',
                      style: buttonText,
                    ),
                  ),
                ),
              if (!alreadyAddedToBookmarks && widget.sellerID != widget.currentUID)
                Expanded(
                  flex: 2,
                  child: TextButton.icon(
                    onPressed: addToBookmarks,
                    icon: Icon(Icons.bookmark_outline, size: 40, color: Colors.black),
                    label: Text(
                      'BOOKMARK',
                      style: buttonText,
                    ),
                  ),
                ),
              if (alreadyAddedToCart && widget.sellerID != widget.currentUID)
                Expanded(
                  flex: 3,
                  child: TextButton.icon(
                    style: cancelProductButton,
                    onPressed:removeFromCart,
                    icon: Icon(Icons.add_shopping_cart_sharp, size: 40, color: Colors.white),
                    label: Text(
                      'REMOVE FROM CART',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (!alreadyAddedToCart && widget.sellerID != widget.currentUID)
                Expanded(
                  flex: 3,
                  child: TextButton.icon(
                    style: button,
                    onPressed: (){
                      //addToCart().then((value) {Navigator.popAndPushNamed(context, '/feed');});
                      showAlertDialogAddToCart("SELECT QUANTITY", quantity);
                    },
                    icon: Icon(Icons.add_shopping_cart_sharp, size: 40, color: Colors.white),
                    label: Text(
                      'ADD TO CART',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (widget.sellerID == widget.currentUID)
                Expanded(
                  flex: 3,
                  child: TextButton.icon(
                    onPressed: (){
                      showAlertDialogOfferDiscount("SELECT DISCOUNTED PRICE", "");
                    },
                    icon: Icon(Icons.volunteer_activism, size: 40, color: Colors.black),
                    label: Text(
                      'OFFER DISCOUNT',
                      style: buttonText,
                    ),
                  ),
                ),
              if (widget.sellerID == widget.currentUID)
                Expanded(
                  flex: 2,
                  child: TextButton.icon(
                    style: cancelProductButton,
                    onPressed: (){
                      showAlertDialogDeleteProduct("WARNING!","You are about to remove this product from the Bookstore. Do you want to permanently remove this product?");
                    },
                    icon: Icon(Icons.cancel_outlined, size: 40, color: Colors.white),
                    label: Text(
                      'DELETE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ]
          ),
      body: SingleChildScrollView(
        child: ListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InteractiveViewer(
                    maxScale: 3.0,
                    transformationController: imageController,
                    onInteractionEnd: (details) {
                      imageController.value = Matrix4.identity();
                    },
                    child: Image.network(widget.pictureURL!, width: MediaQuery. of(context). size. width - 100,),
                  )

                  /*GestureDetector(
                    child: InteractiveViewer(
                      transformationController: imageController,
                      clipBehavior: Clip.none,
                      panEnabled: false,
                      scaleEnabled: false,
                      child: Image.network(widget.pictureURL!, width: MediaQuery. of(context). size. width - 100,)
                    ),
                    onDoubleTap: (){
                      final position = tapDownDetails!.localPosition;
                      final double scale = 3;
                      final x = -position.dx * (scale - 1);
                      final y = -position.dy * (scale - 1);
                      final zoomed = Matrix4.identity()
                        ..translate(x, y)
                        ..scale(scale);
                      final value = imageController.value.isIdentity() ? zoomed : Matrix4.identity();
                      imageController.value = value;
                    },
                    onDoubleTapDown: (details) {
                      tapDownDetails = details;
                    },
                  ),*/
                ),
              ],
            ),
            if (!discountOffered)
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    initialRating != null ?
                    RatingBarIndicator(
                      itemCount: 4,
                      rating: initialRating!,
                      itemSize: 20,
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: AppColors.feedPrimary,
                      ),
                    ) : Container(),
                    SizedBox(width: MediaQuery.of(context).size.width/10),
                    Text(
                      '${widget.price!} TL',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        fontFamily: 'Open Sans',
                        color: Colors.grey.shade700,
                      ),
                    )
                  ]
              ),
            if (discountOffered)
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    initialRating != null ?
                    RatingBarIndicator(
                      itemCount: 4,
                      rating: initialRating!,
                      itemSize: 20,
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: AppColors.feedPrimary,
                      ),
                    ) : Container(),
                    SizedBox(width: MediaQuery.of(context).size.width/10),
                    Text(
                      '${widget.price!} TL',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        fontFamily: 'Open Sans',
                        color: Colors.grey.shade700,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.cancelButtonColor,
                        decorationStyle: TextDecorationStyle.wavy,
                        decorationThickness: 2,
                      ),
                    ),
                    const SizedBox(width: 10,),
                    Text(
                      '${discountedPrice} TL',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        fontFamily: 'Open Sans',
                        color: AppColors.cancelButtonColor,
                      ),
                    ),
                  ]
              ),
            const Divider(
              color: Colors.grey,
              indent: 80,
              endIndent: 80,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_left),
                Icon(Icons.arrow_right),
              ]
            ),
            CarouselSlider(
              items: [
                //1st Slider (bookTitle and author)
                SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.feedPrimary,
                      borderRadius: BorderRadius.circular(10)
                    ),
                    margin: EdgeInsets.all(4.0),
                    child: Container(
                      child: Padding(
                        padding: Dimen.regularPadding,
                        child: Column(
                          children: [
                            Text(
                              widget.title!.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 25,
                                fontFamily: 'Open Sans',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              widget.author!.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                fontFamily: 'Open Sans',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ]
                        ),
                      ),
                    ),
                  )
                ),
                //2nd Slider (bookInfo)
                SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10)
                      ),
                      margin: EdgeInsets.all(6.0),
                      child: Padding(
                        padding: Dimen.regularPadding,
                        child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        Text(
                                          'BOOK TYPE',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          widget.type!,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ]
                                    )
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        Text(
                                          'CONDITION',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          widget.category!,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ]
                                    )
                                  )
                                ],
                              ),
                              if (widget.description!.isNotEmpty)
                              const SizedBox(height: 15),
                              if (widget.description!.isNotEmpty)
                              Text(
                                'DESCRIPTION',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                              if (widget.description!.isNotEmpty)
                              const SizedBox(height: 5),
                              if (widget.description!.isNotEmpty)
                              Text(
                                widget.description!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ]
                        ),
                      ),
                    )
                ),
                //3rd Slider (comments)

                widget.sellerID != widget.currentUID ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ListView.builder(
                    itemCount: comments.length + 1,
                    itemBuilder: (context, index) => index > 0 ? CommentsListContainer(
                      comment: comments[index - 1].isApproved ? comments[index - 1] : null,
                    ) : Form(
                        key: _formKeyComments,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: TextFormField(
                                controller: commentController,
                                keyboardType: TextInputType.text,
                                enableSuggestions: false,
                                autocorrect: false,
                                maxLength: 50,
                                decoration: InputDecoration(
                                  prefixIcon: userProfilePictureURL != "" ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(userProfilePictureURL),
                                      radius: 5,
                                    ),
                                  ) : null,
                                  suffixIcon: RatingBar.builder(
                                    initialRating: 4,
                                    minRating: 1,
                                    direction: Axis.horizontal,
                                    itemPadding: EdgeInsets.all(0),
                                    itemCount: 4,
                                    itemSize: 20,
                                    itemBuilder: (context, _) => Icon(
                                      Icons.star,
                                      color: AppColors.feedPrimary,
                                    ),
                                    onRatingUpdate: (rating) {
                                      setState(() {
                                        commentRating = rating.toString();
                                      });
                                    },
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: const BorderSide(color: AppColors.feedPrimary, width: 2.0),
                                  ),
                                  floatingLabelStyle: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ) ,
                                  labelText: 'Add a comment...',
                                ),
                                validator: (value) {
                                  if (value == null){
                                    return 'Please add a comment!';
                                  } else {
                                    String trimmedValue = value.trim();
                                    if (trimmedValue.isEmpty){
                                      return 'Please add a comment!';
                                    }
                                  }
                                  return null;
                                },
                                onSaved: (value){
                                  if (value != null){
                                    setState(() {
                                      commentContent = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: Container(
                                child: IconButton(
                                  icon: Icon(Icons.add, size: 10),
                                  onPressed: (){
                                    if (_formKeyComments.currentState!.validate()){
                                      _formKeyComments.currentState!.save();
                                      addComment().then((value) {
                                        showAlertDialogComment("THANK YOU FOR YOUR FEEDBACK!",
                                            "Your comment has been sent to the book seller for approval.");
                                        commentController.clear();
                                      });
                                    }
                                  },
                                  color: Colors.black,
                                  splashRadius: 20,
                                ),
                                height: 30,
                                decoration: BoxDecoration(
                                    color: AppColors.feedPrimary,
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                            )
                          ],
                        )
                    ),
                  ),
                ) :
                //if the seller logs in
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: comments.isNotEmpty ? ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) => Row(
                      children: [
                        Expanded(
                          flex: 10,
                          child: CommentsListContainer(comment: comments[index])
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Row(
                              children: [
                                comments[index].isApproved == false ?
                                  Expanded(
                                    flex: 1,
                                    child: IconButton(
                                      icon: Icon(Icons.check_circle, size: 18, color: Colors.greenAccent.shade400),
                                      onPressed: () {
                                        approveComment(comments[index]).then((value) {updateComments();});
                                      },
                                      padding: EdgeInsets.all(0),
                                      splashRadius: 10,
                                    ),
                                  ) : Expanded(
                                  flex : 1,
                                  child: Text('')
                                ),
                                SizedBox(width: 5),
                                Expanded(
                                    flex: 1,
                                    child: IconButton(
                                      icon: Icon(Icons.cancel, size: 18, color: AppColors.cancelButtonColor),
                                      onPressed: () {
                                        deleteComment(comments[index]).then((value) {updateComments();});
                                      },
                                      padding: EdgeInsets.all(0),
                                      splashRadius: 10,
                                    ),
                                ),
                              ]
                            ),
                          )
                        )
                      ],
                    )
                  ) : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'There are no comments for this product yet. Please check again later...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        fontFamily: 'Open Sans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                //4th Slider (sellerInfo)
                SingleChildScrollView(
                    child: Container(
                      margin: EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 1,
                              child: Column(
                                  children: [
                                    Text(
                                      'SELLER',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        fontFamily: 'Open Sans',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 30),
                                    GestureDetector(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.feedPrimary,
                                          borderRadius: BorderRadius.circular(5)
                                        ),

                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Text(
                                            seller,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              fontFamily: 'Open Sans',
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => Seller(
                                          analytics: widget.analytics,
                                          observer: widget.observer,
                                          seller: seller,
                                          sellerID: sellerID,
                                        )));
                                      }
                                    )
                                  ]
                              ),
                          ),
                          const SizedBox(width: 30),
                          Expanded(
                            flex: 1,
                            child: Column(
                                children: [
                                  Text(
                                    'DELIVERY WITHIN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      fontFamily: 'Open Sans',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '${widget.deliveryWithin!} days',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      fontFamily: 'Open Sans',
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                ]
                            ),
                          ),
                        ]
                      ),
                    )
                ),
              ],

              //Slider Container properties
              options: CarouselOptions(
                height: 180.0,
                enlargeCenterPage: true,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 20),
                aspectRatio: 16 / 9,
                autoPlayCurve: Curves.fastOutSlowIn,
                enableInfiniteScroll: true,
                autoPlayAnimationDuration: Duration(milliseconds: 800),
                viewportFraction: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}