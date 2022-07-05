import 'package:cs/models/product_list_containerbo.dart';
import 'package:cs/routes/productbookmarks.dart';
import 'package:cs/routes/profile.dart';
import 'package:cs/utils/colors.dart';
import 'package:cs/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:cs/models/product_list_container.dart';
import 'package:cs/classes/book.dart';
import 'package:cs/routes/product.dart';
import 'dart:math';

class MyBookmarks extends StatefulWidget {
  const MyBookmarks({Key? key, required this.analytics, required this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _MyBookmarksState createState() => _MyBookmarksState();
}

class _MyBookmarksState extends State<MyBookmarks> {

  FirebaseAuth auth = FirebaseAuth.instance;
  dynamic data;
  var bookmarks = {};
  var cart = {};
  var notifications = {};
  String uid = "";
  List<Book> books = [];

  Future getData() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    await document.get().then<dynamic>((DocumentSnapshot snapshot) async{
      setState(() {
        data = snapshot.data();
        bookmarks = data['bookmarks'];
        cart = data['cart'];
        uid = data['uid'];
        notifications = data['notifications'];
      });
    });
    bookmarks.forEach((key, value) {
      Book book = Book(
        bookID: key,
        bookTitle: value[0],
        author: value[1],
        bookType: value[2],
        bookCategory: value[3],
        description: value[4],
        deliveryWithin: value[5],
        seller: value[6],
        sellerID: value[7],
        price: value[8],
        discountedPrice: value[9],
        inventory: value[10],
        sold: value[11],
        pictureURL: value[12],
        comments: value[13],
      );
      books.add(book);
    });
  }

  _MyBookmarksState(){
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_outlined),
          onPressed: (){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Profile(analytics: widget.analytics, observer: widget.observer,)));
          },
        ),
        title: Text("My Bookmarks",
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(
              indent: 100,
              endIndent: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Expanded(
                child: GridView.builder(
                    itemCount: books.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.52,
                      crossAxisSpacing: 20,
                    ),
                    itemBuilder: (context, index) => GestureDetector(
                        child: ProductsListContainerBO(
                          book: books[index],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) =>  ProductBookmarks(
                            analytics: widget.analytics,
                            observer: widget.observer,
                            ID: books[index].bookID,
                            title: books[index].bookTitle,
                            author: books[index].author,
                            type: books[index].bookType,
                            category: books[index].bookCategory,
                            description: books[index].description,
                            deliveryWithin: books[index].deliveryWithin,
                            seller: books[index].seller,
                            sellerID: books[index].sellerID,
                            price: books[index].price,
                            discountedPrice: books[index].discountedPrice,
                            sold: books[index].sold,
                            inventory: books[index].inventory,
                            pictureURL: books[index].pictureURL,
                            comments: books[index].comments,
                            currentUID: uid,
                            cartPassed: cart,
                            bookmarksPassed: bookmarks,
                            notificationsPassed: notifications,
                          )));
                        }
                    )
                )
            )
          ],
        ),
      ),
    );;
  }
}
