import 'package:cs/classes/book.dart';
import 'package:cs/classes/comment.dart';
import 'package:cs/models/mycomment_list_container.dart';
import 'package:cs/routes/productcomments.dart';
import 'package:cs/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyComments extends StatefulWidget {
  const MyComments({Key? key, required this.analytics, required this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _MyCommentsState createState() => _MyCommentsState();
}

class _MyCommentsState extends State<MyComments> {

  FirebaseAuth auth = FirebaseAuth.instance;
  dynamic data;
  List<Comment> comments = [];
  List<Book> books = [];
  Future<bool>? _isData;
  String uid = "";
  var cart = {};
  var bookmarks = {};
  var notifications = {};

  Future getData() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    await document.get().then<dynamic>((DocumentSnapshot snapshot) async{
      setState(() {
        data = snapshot.data();
        uid = currentUser.uid;
        cart = data['cart'];
        bookmarks = data['bookmarks'];
        notifications = data['notifications'];
      });
    });
  }

  Future<bool> getComments() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    final CollectionReference collection = FirebaseFirestore.instance.collection('books');
    await collection.get().then<dynamic>((QuerySnapshot snapshot) async{
      snapshot.docs.forEach((doc) async {
        String docID = doc.id;
        var commentsMap = {};
        final DocumentReference document = FirebaseFirestore.instance.collection('books').doc(docID);
        await document.get().then<dynamic>((DocumentSnapshot snapshot2) async {
          setState(() {
            data = snapshot2.data();
            commentsMap = data['comments'];
          });
          commentsMap.forEach((key, value) {
            int lastDash = key.toString().lastIndexOf('-');
            String firstSlice = key.toString().substring(0, lastDash);
            int secondLastDash = firstSlice.lastIndexOf('-');
            String uid = key.toString().substring(secondLastDash + 1, lastDash);
            if (uid == currentUser!.uid){
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
              var comments2 = data['comments'];
              Book book = Book(
                bookID: bookID,
                bookTitle: bookTitle,
                author: author,
                bookType: bookType,
                bookCategory: bookCategory,
                description: description,
                deliveryWithin: deliveryWithin,
                seller: seller,
                sellerID: sellerID,
                price: price,
                discountedPrice: discountedPrice,
                inventory: inventory,
                sold: sold,
                pictureURL: pictureURL,
                comments: comments2,
              );
              String commentByUID = key;
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
                books.add(book);
              });
            }
          });
        });
      });
    });
    return true;
  }

  _MyCommentsState(){
    getData();
    _isData = getComments();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: false,
      future: _isData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            backgroundColor: AppColors.bgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text("My Comments",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            body: comments.isEmpty ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.feedPrimary,
                )
            ) : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) => GestureDetector(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 10,
                          child: MyCommentsListContainer(comment: comments[index], book: books[index]),
                        ),
                      ],
                    ),
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ProductComments(
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
                        inventory: books[index].inventory,
                        pictureURL: books[index].pictureURL,
                        comments: books[index].comments,
                        currentUID: uid,
                        cartPassed: cart,
                        bookmarksPassed: bookmarks,
                        notificationsPassed: notifications,
                      )));
                    },
                  )
              ),
            )

          );
        }
        return Scaffold(
        );
      }
    );
  }
}