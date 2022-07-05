import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs/classes/order.dart';
import 'package:cs/models/order_list_container.dart';
import 'package:cs/routes/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:cs/utils/styles.dart';
import '../utils/colors.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({Key? key, required this.analytics, required this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {

  FirebaseAuth auth = FirebaseAuth.instance;
  dynamic data;
  var ordersPlacedMap = {};
  var ordersReceivedMap = {};
  List<Order> ordersBuyer = [];
  List<Order> ordersSeller = [];

  Future getOrders() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get().then((DocumentSnapshot snapshot) {
      setState((){
        data = snapshot.data();
        ordersPlacedMap = data['ordersPlaced'];
        ordersReceivedMap = data['ordersReceived'];
      });

      ordersPlacedMap.forEach((key, value) {
        String id = key;
        String buyerID = value[0];
        String sellerID = value[1];
        String price = value[2];
        String address = value[3];
        String bookID = value[4];
        String bookName = value[5];
        String quantity = value[6];
        String bookType = value[7];
        String bookCategory = value[8];
        String pictureURL = value[9];
        String status = value[10];
        Order order = Order(id, buyerID, sellerID, price, address, bookID, bookName, quantity, bookType, bookCategory, pictureURL, status);
        ordersBuyer.add(order);
      });

      ordersReceivedMap.forEach((key, value) {
        String id = key;
        String buyerID = value[0];
        String sellerID = value[1];
        String price = value[2];
        String address = value[3];
        String bookID = value[4];
        String bookName = value[5];
        String quantity = value[6];
        String bookType = value[7];
        String bookCategory = value[8];
        String pictureURL = value[9];
        String status = value[10];
        Order order = Order(id, buyerID, sellerID, price, address, bookID, bookName, quantity, bookType, bookCategory, pictureURL, status);
        ordersSeller.add(order);
      });
    });
  }

  Future confirmOrder(Order order) async{
    if (order.status == "Placed" && order.status != "Cancelled by Buyer"){
      User? currentUser = await auth.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
      }
      String buyerID = order.buyerID;
      String orderID = order.id;
      ordersReceivedMap[orderID][10] = "Confirmed";
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'ordersReceived': ordersReceivedMap,
      });

      var ordersPlacedTemp = {};
      var notifications = {};
      await FirebaseFirestore.instance.collection('users').doc(buyerID).get().then((DocumentSnapshot snapshot){
        data = snapshot.data();
        ordersPlacedTemp = data['ordersPlaced'];
        ordersPlacedTemp[orderID][10] = "Confirmed";
        notifications = data['notifications'];
        String notiID = "${order.bookID}-";
        var rng = Random();
        for (int i = 0; i < 8; i++){
          notiID += rng.nextInt(9).toString();
        }

        String notiContent = "Your order for ${order.bookName.toUpperCase()} has been confirmed!";
        Timestamp timeAndDate = Timestamp.fromDate(DateTime.now());
        var array = [notiContent, timeAndDate, order.bookID, order.sellerID, order.pictureURL, notiID, false];
        notifications[notiID] = array;
      });

      await FirebaseFirestore.instance.collection('users').doc(buyerID).update({
        'ordersPlaced': ordersPlacedTemp,
        'notifications': notifications,
      });
      updateLists();
    }
  }

  Future<void> showAlertDialogConfirmOrder(String title, String message, Order order) async {
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
                      Navigator.pop(context);
                    },
                    child: Text(
                      'NO',
                      style: buttonText,
                    )
                ),
                TextButton(
                    style: button,
                    onPressed: () {
                      confirmOrder(order).then((value) {
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                      'CONFIRM',
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'NO',
                      style: buttonText,
                    )
                ),
                TextButton(
                    style: button,
                    onPressed: () {
                      confirmOrder(order).then((value) {
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                      'CONFIRM',
                      style: buttonText,
                    )
                ),
              ],
            );
          }
        });
  }

  Future dispatchOrder(Order order) async{
    if (order.status == "Confirmed" && order.status != "Cancelled by Buyer"){
      User? currentUser = await auth.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
      }
      String buyerID = order.buyerID;
      String orderID = order.id;
      ordersReceivedMap[orderID][10] = "Dispatched";
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'ordersReceived': ordersReceivedMap,
      });

      var ordersPlacedTemp = {};
      var notifications = {};
      await FirebaseFirestore.instance.collection('users').doc(buyerID).get().then((DocumentSnapshot snapshot){
        data = snapshot.data();
        ordersPlacedTemp = data['ordersPlaced'];
        ordersPlacedTemp[orderID][10] = "Dispatched";
        notifications = data['notifications'];
        String notiID = "${order.bookID}-";
        var rng = Random();
        for (int i = 0; i < 8; i++){
          notiID += rng.nextInt(9).toString();
        }

        String notiContent = "Your order for ${order.bookName.toUpperCase()} has been dispatched!";
        Timestamp timeAndDate = Timestamp.fromDate(DateTime.now());
        var array = [notiContent, timeAndDate, order.bookID, order.sellerID, order.pictureURL, notiID, false];
        notifications[notiID] = array;
      });

      await FirebaseFirestore.instance.collection('users').doc(buyerID).update({
        'ordersPlaced': ordersPlacedTemp,
        'notifications': notifications,
      });
      updateLists();
    }
  }

  Future<void> showAlertDialogDispatchOrder(String title, String message, Order order) async {
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
                      Navigator.pop(context);
                    },
                    child: Text(
                      'NO',
                      style: buttonText,
                    )
                ),
                TextButton(
                    style: button,
                    onPressed: () {
                      dispatchOrder(order).then((value) {
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                      'DISPATCH',
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'NO',
                      style: buttonText,
                    )
                ),
                TextButton(
                    style: button,
                    onPressed: () {
                      dispatchOrder(order).then((value) {
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                      'DISPATCH',
                      style: buttonText,
                    )
                ),
              ],
            );
          }
        });
  }

  Future deliverOrder(Order order) async{
    if (order.status == "Dispatched" && order.status != "Cancelled by Buyer"){
      User? currentUser = await auth.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
      }
      String buyerID = order.buyerID;
      String orderID = order.id;
      ordersReceivedMap[orderID][10] = "Delivered";
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'ordersReceived': ordersReceivedMap,
      });

      var ordersPlacedTemp = {};
      var notifications = {};
      await FirebaseFirestore.instance.collection('users').doc(buyerID).get().then((DocumentSnapshot snapshot){
        data = snapshot.data();
        ordersPlacedTemp = data['ordersPlaced'];
        ordersPlacedTemp[orderID][10] = "Delivered";
        notifications = data['notifications'];
        String notiID = "${order.bookID}-";
        var rng = Random();
        for (int i = 0; i < 8; i++){
          notiID += rng.nextInt(9).toString();
        }

        String notiContent = "Your order for ${order.bookName.toUpperCase()} has been delivered to you!";
        Timestamp timeAndDate = Timestamp.fromDate(DateTime.now());
        var array = [notiContent, timeAndDate, order.bookID, order.sellerID, order.pictureURL, notiID, false];
        notifications[notiID] = array;
      });

      await FirebaseFirestore.instance.collection('users').doc(buyerID).update({
        'ordersPlaced': ordersPlacedTemp,
        'notifications': notifications,
      });
      updateLists();
    }
  }

  Future<void> showAlertDialogDeliverOrder(String title, String message, Order order) async {
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
                      Navigator.pop(context);
                    },
                    child: Text(
                      'NO',
                      style: buttonText,
                    )
                ),
                TextButton(
                    style: button,
                    onPressed: () {
                      deliverOrder(order).then((value) {
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                      'CONFIRM DELIVERY',
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'NO',
                      style: buttonText,
                    )
                ),
                TextButton(
                    style: button,
                    onPressed: () {
                      deliverOrder(order).then((value) {
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                      'CONFIRM DELIVERY',
                      style: buttonText,
                    )
                ),
              ],
            );
          }
        });
  }

  Future cancelOrderBuyer(Order order) async{
    if ((order.status == "Placed" || order.status == "Confirmed") && order.status != "Cancelled by Seller") {
      print("I WAS HERE");
      User? currentUser = await auth.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
      }
      String buyerID = order.buyerID;
      String orderID = order.id;
      String sellerID = order.sellerID;
      ordersPlacedMap[orderID][10] = "Cancelled by Buyer";
      await FirebaseFirestore.instance.collection('users')
          .doc(currentUser!.uid)
          .update({
        'ordersPlaced': ordersPlacedMap,
      });

      var ordersReceivedTemp = {};
      var notifications = {};
      await FirebaseFirestore.instance.collection('users').doc(sellerID)
          .get()
          .then((DocumentSnapshot snapshot) {
        data = snapshot.data();
        ordersReceivedTemp = data['ordersReceived'];
        ordersReceivedTemp[orderID][10] = "Cancelled by Buyer";
        notifications = data['notifications'];
        String notiID = "${order.bookID}-";
        var rng = Random();
        for (int i = 0; i < 8; i++){
          notiID += rng.nextInt(9).toString();
        }

        String notiContent = "The order you received for ${order.bookName.toUpperCase()} has been cancelled by the buyer!";
        Timestamp timeAndDate = Timestamp.fromDate(DateTime.now());
        var array = [notiContent, timeAndDate, order.bookID, order.sellerID, order.pictureURL, notiID, false];
        notifications[notiID] = array;
      });

      await FirebaseFirestore.instance.collection('users').doc(sellerID).update({
        'ordersReceived': ordersReceivedTemp,
        'notifications': notifications,
      });
      updateLists();
    }
  }

  Future<void> showAlertDialogCancelOrderBuyer(String title, String message, Order order) async {
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
                      cancelOrderBuyer(order).then((value) {
                        Navigator.pop(context);
                      });
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
              title: Text(title, textAlign: TextAlign.center,),
              content: SingleChildScrollView(
                child: Text(message, textAlign: TextAlign.center),
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
                      cancelOrderBuyer(order).then((value) {
                        Navigator.pop(context);
                      });
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

  Future cancelOrderSeller(Order order) async{
    if (order.status != "Delivered"){
      User? currentUser = await auth.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
      }
      String buyerID = order.buyerID;
      String orderID = order.id;
      ordersReceivedMap[orderID][10] = "Cancelled by Seller";
      await FirebaseFirestore.instance.collection('users')
          .doc(currentUser!.uid)
          .update({
        'ordersReceived': ordersReceivedMap,
      });

      var ordersPlacedTemp = {};
      var notifications = {};
      await FirebaseFirestore.instance.collection('users').doc(buyerID)
          .get()
          .then((DocumentSnapshot snapshot) {
        data = snapshot.data();
        ordersPlacedTemp = data['ordersPlaced'];
        ordersPlacedTemp[orderID][10] = "Cancelled by Seller";
        notifications = data['notifications'];
        String notiID = "${order.bookID}-";
        var rng = Random();
        for (int i = 0; i < 8; i++){
          notiID += rng.nextInt(9).toString();
        }

        String notiContent = "Your order for ${order.bookName.toUpperCase()} has been cancelled by the seller!";
        Timestamp timeAndDate = Timestamp.fromDate(DateTime.now());
        var array = [notiContent, timeAndDate, order.bookID, order.sellerID, order.pictureURL, notiID, false];
        notifications[notiID] = array;
      });

      await FirebaseFirestore.instance.collection('users').doc(buyerID).update({
        'ordersPlaced': ordersPlacedTemp,
        'notifications': notifications,
      });
      updateLists();
    }
  }

  Future<void> showAlertDialogCancelOrderSeller(String title, String message, Order order) async {
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
                      cancelOrderSeller(order).then((value) {
                        Navigator.pop(context);
                      });
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
              title: Text(title, textAlign: TextAlign.center,),
              content: SingleChildScrollView(
                child: Text(message, textAlign: TextAlign.center),
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
                      cancelOrderSeller(order).then((value) {
                        Navigator.pop(context);
                      });
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

  void updateLists() {
    ordersBuyer.clear();
    ordersSeller.clear();
    ordersPlacedMap.forEach((key, value) {
      String id = key;
      String buyerID = value[0];
      String sellerID = value[1];
      String price = value[2];
      String address = value[3];
      String bookID = value[4];
      String bookName = value[5];
      String quantity = value[6];
      String bookType = value[7];
      String bookCategory = value[8];
      String pictureURL = value[9];
      String status = value[10];
      Order order = Order(id, buyerID, sellerID, price, address, bookID, bookName, quantity, bookType, bookCategory, pictureURL, status);
      setState(() {
        ordersBuyer.add(order);
      });
    });

    ordersReceivedMap.forEach((key, value) {
      String id = key;
      String buyerID = value[0];
      String sellerID = value[1];
      String price = value[2];
      String address = value[3];
      String bookID = value[4];
      String bookName = value[5];
      String quantity = value[6];
      String bookType = value[7];
      String bookCategory = value[8];
      String pictureURL = value[9];
      String status = value[10];
      Order order = Order(id, buyerID, sellerID, price, address, bookID, bookName, quantity, bookType, bookCategory, pictureURL, status);
      setState(() {
        ordersSeller.add(order);
      });
    });
  }

  _OrderHistoryState(){
    getOrders();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_outlined),
            onPressed: (){
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Profile(analytics: widget.analytics, observer: widget.observer,)));
            },
          ),
          title: Text(
            'Orders',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
          ),
          bottom: TabBar(
            //labelColor: Colors.transparent,
            //unselectedLabelColor: AppColors.feedPrimary,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              color: AppColors.feedPrimary,
            ),
            tabs: [
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Text("PLACED (BUYER)")
                )
              ),
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Text("RECEIVED (SELLER)"),
                )
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: TabBarView(
          children: [
            placed(),
            received(),
          ],
        ),
      ),
    );
  }

  Widget placed(){
    return Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
        child: ListView.builder(
            itemCount: ordersBuyer.length,
            itemBuilder: (context, index) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        flex: 10,
                        child: OrdersListContainer(order: ordersBuyer[index])
                    ),
                    Expanded(
                        flex: 2,
                        child: Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Column(
                                children: [
                                  Row(
                                      children: [
                                        Icon(
                                          Icons.check_box,
                                          color: ordersBuyer[index].status == "Confirmed" ? AppColors.feedPrimary : Colors.black,
                                        ),
                                        Icon(
                                          Icons.airport_shuttle,
                                          color: ordersBuyer[index].status == "Dispatched" ? AppColors.feedPrimary : Colors.black,
                                        )
                                      ]
                                  ),
                                  Row(
                                      children: [
                                        Icon(
                                          Icons.water_damage_sharp,
                                          color: ordersBuyer[index].status == "Delivered" ? AppColors.feedPrimary : Colors.black,
                                        ),
                                        GestureDetector(
                                          child: Icon(
                                            Icons.cancel,
                                            color: ordersBuyer[index].status == "Cancelled by Seller" || ordersBuyer[index].status == "Cancelled by Buyer"  ?
                                            AppColors.cancelButtonColor : Colors.black,
                                          ),
                                          onTap: (){
                                            ordersBuyer[index].status == "Cancelled by Seller" || ordersBuyer[index].status == "Cancelled by Buyer" ||
                                            ordersBuyer[index].status == "Dispatched" || ordersBuyer[index].status == "Delivered" ? null :
                                            showAlertDialogCancelOrderBuyer("WARNING!", "You are about to cancel this order. If you do so, you will have to replace the order!", ordersBuyer[index]);                                          }
                                        )
                                      ]
                                  ),
                                  if (ordersBuyer[index].status == "Cancelled by Seller")
                                    Text(
                                      'Cancelled by seller.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.cancelButtonColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  if (ordersBuyer[index].status == "Cancelled by Buyer")
                                    Text(
                                      'Cancelled by you.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.cancelButtonColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                ]
                            )
                        )
                    ),
                  ],
                ),
                Divider(
                  color: Colors.grey,
                ),
              ],
            )
        )
    );
  }

  Widget received(){
    return Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
        child: ListView.builder(
            itemCount: ordersSeller.length,
            itemBuilder: (context, index) => Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        flex: 10,
                        child: OrdersListContainer(order: ordersSeller[index])
                    ),
                    Expanded(
                        flex: 3,
                        child: Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Column(
                                children: [
                                  Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: GestureDetector(
                                            child: Icon(
                                              Icons.check_box,
                                              color: ordersSeller[index].status == "Confirmed" ? AppColors.feedPrimary : Colors.black,
                                            ),
                                            onTap: () {
                                              ordersSeller[index].status == "Placed" ?
                                              showAlertDialogConfirmOrder("CONFIRM ORDER?", "You are about to confirm this order.", ordersSeller[index]) :
                                              null;
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: GestureDetector(
                                            child: Icon(
                                              Icons.airport_shuttle,
                                              color: ordersSeller[index].status == "Dispatched" ? AppColors.feedPrimary : Colors.black,
                                            ),
                                            onTap: (){
                                              ordersSeller[index].status == "Confirmed" ?
                                              showAlertDialogDispatchOrder("DISPATCH ORDER?", "You are about to dispatch this order.", ordersSeller[index]) :
                                              null;
                                            },
                                          ),
                                        )
                                      ]
                                  ),
                                  Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: GestureDetector(
                                            child: Icon(
                                              Icons.water_damage_sharp,
                                              color: ordersSeller[index].status == "Delivered" ? AppColors.feedPrimary : Colors.black,
                                            ),
                                            onTap: () {
                                              ordersSeller[index].status == "Dispatched" ?
                                              showAlertDialogDeliverOrder("HAS THIS ORDER BEEN DELIVERED?",
                                                  "You are about to mark this order as delivered. If it has not been delivered, you would be flagged by the Bookstore.",
                                                  ordersSeller[index]) :
                                              null;
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: GestureDetector(
                                            child: Icon(
                                              Icons.cancel,
                                              color: ordersSeller[index].status == "Cancelled by Seller" || ordersSeller[index].status == "Cancelled by Buyer"  ?
                                              AppColors.cancelButtonColor : Colors.black,
                                            ),
                                            onTap: (){
                                              ordersSeller[index].status != "Cancelled by Buyer" && ordersSeller[index].status != "Delivered" ?
                                              showAlertDialogCancelOrderSeller("WARNING!", "You are about to cancel this order!", ordersSeller[index]) :
                                              null;
                                            },
                                          ),
                                        )
                                      ]
                                  ),
                                  if (ordersSeller[index].status == "Cancelled by Seller")
                                    Text(
                                      'Cancelled by you.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.cancelButtonColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  if (ordersSeller[index].status == "Cancelled by Buyer")
                                    Text(
                                      'Cancelled by buyer.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.cancelButtonColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                ]
                            )
                        )
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(
                  color: Colors.grey,
                ),
              ],
            )
        )
    );
  }




}




