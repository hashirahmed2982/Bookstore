import 'package:cs/classes/usernotification.dart';
import 'package:cs/models/notification_list_container.dart';
import 'package:cs/routes/product.dart';
import 'package:cs/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:cs/utils/styles.dart';
import 'package:cs/utils/dimensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:cs/classes/comment.dart';
import 'dart:math';
import 'package:cs/models/comment_list_container.dart';
import 'package:cs/routes/feed.dart';
import 'package:cs/classes/book.dart';

class Notifications extends StatefulWidget {
  const Notifications({Key? key, required this.analytics, required this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {

  FirebaseAuth auth = FirebaseAuth.instance;
  dynamic data;
  var notificationsMap = {};
  List<UserNotification> notifications = [];
  var cart = {};
  var bookmarks = {};
  String uid = "";

  Future getNotifications() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get().then((DocumentSnapshot snapshot) {
      setState(() {
        data = snapshot.data();
        notificationsMap = data['notifications'];
        cart = data['cart'];
        bookmarks = data['bookmarks'];
        uid = data['uid'];
      });
    });

    notificationsMap.forEach((key, value) {
      int dash = key.toString().indexOf('-');
      String bookID = key.toString().substring(0, dash);
      String notiID = key.toString().substring(dash + 1);
      String content = value[0];
      Timestamp timeAndDate = value[1];
      String sellerID = value[3];
      String pictureURL = value[4];
      bool isDismissed = value[6];
      UserNotification notification = UserNotification(key, content, timeAndDate, bookID, sellerID, pictureURL, isDismissed);

      setState(() {
        notifications.add(notification);
      });

    });
  }

  Future dismissNotification(UserNotification n) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    setState(() {
      notificationsMap[n.ID][6] = true;
    });
    updateNotifications();
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      "notifications": notificationsMap,
    });

  }

  Future deleteNotification(UserNotification n) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    setState(() {
      notificationsMap.remove(n.ID);
    });
    updateNotifications();
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      "notifications": notificationsMap,
    });
  }

  void updateNotifications() {
    notifications.clear();
    notificationsMap.forEach((key, value) {
      int dash = key.toString().indexOf('-');
      String bookID = key.toString().substring(0, dash);
      String notiID = key.toString().substring(dash + 1);
      String content = value[0];
      Timestamp timeAndDate = value[1];
      String sellerID = value[3];
      String pictureURL = value[4];
      bool isDismissed = value[6];
      UserNotification notification = UserNotification(key, content, timeAndDate, bookID, sellerID, pictureURL, isDismissed);

      setState(() {
        notifications.add(notification);
      });

    });
  }

  Future navigateToBook(UserNotification n) async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    if (n.sellerID != "noSeller"){
      final CollectionReference collection = FirebaseFirestore.instance.collection('books');
      await collection.get().then<dynamic>((QuerySnapshot snapshot) async{
        snapshot.docs.forEach((doc) {
          String docID = doc.id;
          if (docID.substring(docID.indexOf('-') + 1) == n.bookID){
            final DocumentReference document = FirebaseFirestore.instance.collection('books').doc(docID);
            document.get().then<dynamic>((DocumentSnapshot snapshot2) async {
              setState(() {
                data = snapshot2.data();
              });
              String bookID = data['bookID'];
              String bookTitle = data['bookTitle'];
              String author = data['author'];
              String bookType = data['bookType'];
              String bookCategory = data['bookCategory'];
              String description = data['description'];
              String deliveryWithin = data['deliveryWithin'];
              String seller = data['seller'];
              String sellerID = data['sellerID'];
              String price = data['price'];
              String discountedPrice = data['discountedPrice'];
              String inventory = data['inventory'];
              String sold = data['sold'];
              String pictureURL = data['pictureURL'];
              var comments = data['comments'];
              Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                analytics: widget.analytics,
                observer: widget.observer,
                ID: bookID,
                title: bookTitle,
                author: author,
                type: bookType,
                category: bookCategory,
                description: description,
                deliveryWithin: deliveryWithin,
                seller: seller,
                sellerID: sellerID,
                price: price,
                discountedPrice: discountedPrice,
                inventory: inventory,
                sold: sold,
                pictureURL: pictureURL,
                comments: comments,
                currentUID: uid,
                cartPassed: cart,
                bookmarksPassed: bookmarks,
              )));
            });
          }
        });
      });
    }
  }

  _NotificationsState(){
    getNotifications();
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
        title: Text("Notifications",
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: notifications.isNotEmpty ? ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) =>  Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        flex: 10,
                        child: GestureDetector(
                          child: NotificationsListContainer(notification: notifications[index]),
                          onTap: () {
                            navigateToBook(notifications[index]);
                          }
                        )
                    ),
                    Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: Row(
                              children: [
                                if (notifications[index].isDismissed == false)
                                Expanded(
                                  flex: 1,
                                  child: IconButton(
                                    icon: Icon(Icons.mark_chat_read, size: 18, color: AppColors.feedPrimary),
                                    onPressed: () {
                                      dismissNotification(notifications[index]);
                                    },
                                    padding: EdgeInsets.all(0),
                                    splashRadius: 10,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Expanded(
                                  flex: 1,
                                  child: IconButton(
                                    icon: Icon(Icons.delete, size: 18, color: AppColors.cancelButtonColor),
                                    onPressed: () {
                                      deleteNotification(notifications[index]);
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
                ),
                Divider(
                  color: Colors.grey,
                )
              ],
            ),
        ) : Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'You have no new notifications. Please check again later...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              fontFamily: 'Open Sans',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
