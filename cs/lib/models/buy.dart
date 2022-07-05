import 'package:carousel_slider/carousel_slider.dart';
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

class Buy extends StatefulWidget {
  const Buy({Key? key, required this.analytics, required this.observer, required this.userName, required this.books, required this.uid, this.cart, this.bookmarks, this.notifications}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  final String userName;
  final String uid;
  final List<Book> books;
  final dynamic cart, bookmarks, notifications;

  @override
  _BuyState createState() => _BuyState();
}

class _BuyState extends State<Buy> {

  FirebaseAuth auth = FirebaseAuth.instance;
  dynamic data;

  var currentSelectedValue;
  final bookCategories = ["All", "Discounted", "New", "Old"];
  List<Book> oldBooks = [];
  List<Book> newBooks = [];
  List<Book> discountBooks = [];
  List<Book> paperbackBooks = [];
  List<Book> hardcoverBooks = [];
  List<Book> recommendedBooks = [];

  Book? hardcoverBook;
  Book? paperbackBook;
  Book? newBook;
  Book? oldBook;

  Future getCategoryBooks() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    final CollectionReference collection = FirebaseFirestore.instance.collection('books');
    await collection.get().then<dynamic>((QuerySnapshot snapshot) async{
      snapshot.docs.forEach((doc) {
        String docID = doc.id;
        final DocumentReference document = FirebaseFirestore.instance.collection('books').doc(docID);
        document.get().then<dynamic>((DocumentSnapshot snapshot2) async{
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
            comments: comments,
          );
          if (bookCategory == "Old"){
            setState(() {
              oldBooks.add(book);
            });
            if (int.parse(book.discountedPrice) < int.parse(book.price)){
              setState(() {
                discountBooks.add(book);
              });
            }
            if (bookType == "Paperback"){
              paperbackBooks.add(book);
            }
            else{
              hardcoverBooks.add(book);
            }
          }
          else{
            setState(() {
              newBooks.add(book);
            });
            if (int.parse(book.discountedPrice) < int.parse(book.price)){
              setState(() {
                discountBooks.add(book);
              });
            }
            if (bookType == "Paperback"){
              paperbackBooks.add(book);
            }
            else{
              hardcoverBooks.add(book);
            }
          }
        });
      });
    });
  }

  Future getRecommendations() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    int paperbackCount = 0;
    int hardcoverCount = 0;
    int oldCount = 0;
    int newCount = 0;
    var cart = {};
    var bookmarks = {};
    var offeredProducts = {};
    var orders = {};
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get().then((DocumentSnapshot snapshot){
      data = snapshot.data();
      cart = data['cart'];
      bookmarks = data['bookmarks'];
      offeredProducts = data['offeredProducts'];
      orders = data['ordersPlaced'];
    });
    cart.forEach((key, value) {
      if (value[8] == "Old"){
        oldCount++;
      }
      else if (value[8] == "New"){
        newCount++;
      }
      if (value[1] == "Paperback"){
        paperbackCount++;
      }
      else if (value[1] == "Hardcover"){
        hardcoverCount++;
      }
    });
    bookmarks.forEach((key, value) {
      if (value[3] == "Old"){
        oldCount++;
      }
      else if (value[3] == "New"){
        newCount++;
      }
      if (value[2] == "Paperback"){
        paperbackCount++;
      }
      else if (value[2] == "Hardcover"){
        hardcoverCount++;
      }
    });
    offeredProducts.forEach((key, value) {
      if (value[3] == "Old"){
        oldCount++;
      }
      else if (value[3] == "New"){
        newCount++;
      }
      if (value[2] == "Paperback"){
        paperbackCount++;
      }
      else if (value[2] == "Hardcover"){
        hardcoverCount++;
      }
    });
    orders.forEach((key, value) {
      if (value[6] == "Old"){
        oldCount++;
      }
      else if (value[6] == "New"){
        newCount++;
      }
      if (value[7] == "Paperback"){
        paperbackCount++;
      }
      else if (value[7] == "Hardcover"){
        hardcoverCount++;
      }
    });

    if (oldCount > newCount){
      var rng = Random();
      var rndIndex = rng.nextInt(oldBooks.length);
      recommendedBooks.add(oldBooks[rndIndex]);

    }
    else{
      var rng = Random();
      var rndIndex = rng.nextInt(newBooks.length);
      recommendedBooks.add(newBooks[rndIndex]);
    }

    if(paperbackCount > hardcoverCount){
      var rng = Random();
      var rndIndex = rng.nextInt(paperbackBooks.length);
      recommendedBooks.add(paperbackBooks[rndIndex]);

    }
    else{
      var rng = Random();
      var rndIndex = rng.nextInt(hardcoverBooks.length);
      recommendedBooks.add(hardcoverBooks[rndIndex]);
    }
  }

  _BuyState(){
    getCategoryBooks().then((value){
      getRecommendations();
    });
  }

  @override
  void initState(){
    super.initState();

  }

  /*Future<void> showAlertDialogRecommendations(String title, List<Book> rBooks) async {
    bool isiOS = Platform.isIOS;

    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if(isiOS) {
            return CupertinoAlertDialog(
              title: Container(
                color: AppColors.feedPrimary,
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
              content: CarouselSlider(
                items:[
                  if (rBooks.length >= 1)
                  GestureDetector(
                    child: ProductsListContainer(
                      book: rBooks[0],
                      uid: widget.uid,
                      cart: widget.cart,
                      bookmarks: widget.bookmarks,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: rBooks[0].bookID,
                        title: rBooks[0].bookTitle,
                        author: rBooks[0].author,
                        type: rBooks[0].bookType,
                        category: rBooks[0].bookCategory,
                        description: rBooks[0].description,
                        deliveryWithin: rBooks[0].deliveryWithin,
                        seller: rBooks[0].seller,
                        sellerID: rBooks[0].sellerID,
                        price: rBooks[0].price,
                        discountedPrice: rBooks[0].discountedPrice,
                        inventory: rBooks[0].inventory,
                        sold: rBooks[0].sold,
                        pictureURL: rBooks[0].pictureURL,
                        comments: rBooks[0].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                      )));
                    }
                  ),
                  if (rBooks.length >= 2)
                  GestureDetector(
                      child: ProductsListContainer(
                        book: rBooks[1],
                        uid: widget.uid,
                        cart: widget.cart,
                        bookmarks: widget.bookmarks,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                          analytics: widget.analytics,
                          observer: widget.observer,
                          ID: rBooks[1].bookID,
                          title: rBooks[1].bookTitle,
                          author: rBooks[1].author,
                          type: rBooks[1].bookType,
                          category: rBooks[1].bookCategory,
                          description: rBooks[1].description,
                          deliveryWithin: rBooks[1].deliveryWithin,
                          seller: rBooks[1].seller,
                          sellerID: rBooks[1].sellerID,
                          price: rBooks[1].price,
                          discountedPrice: rBooks[1].discountedPrice,
                          inventory: rBooks[1].inventory,
                          sold: rBooks[1].sold,
                          pictureURL: rBooks[1].pictureURL,
                          comments: rBooks[1].comments,
                          currentUID: widget.uid,
                          cartPassed: widget.cart,
                          bookmarksPassed: widget.bookmarks,
                        )));
                      }
                  ),
                ],
                options: CarouselOptions(
                  height: 365.0,
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
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'CLOSE',
                      style: buttonText,
                    )
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Container(
                color: AppColors.feedPrimary,
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
              content: CarouselSlider(
                items:[
                  if (rBooks.length >= 1)
                    GestureDetector(
                        child: ProductsListContainer(
                          book: rBooks[0],
                          uid: widget.uid,
                          cart: widget.cart,
                          bookmarks: widget.bookmarks,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                            analytics: widget.analytics,
                            observer: widget.observer,
                            ID: rBooks[0].bookID,
                            title: rBooks[0].bookTitle,
                            author: rBooks[0].author,
                            type: rBooks[0].bookType,
                            category: rBooks[0].bookCategory,
                            description: rBooks[0].description,
                            deliveryWithin: rBooks[0].deliveryWithin,
                            seller: rBooks[0].seller,
                            sellerID: rBooks[0].sellerID,
                            price: rBooks[0].price,
                            discountedPrice: rBooks[0].discountedPrice,
                            inventory: rBooks[0].inventory,
                            sold: rBooks[0].sold,
                            pictureURL: rBooks[0].pictureURL,
                            comments: rBooks[0].comments,
                            currentUID: widget.uid,
                            cartPassed: widget.cart,
                            bookmarksPassed: widget.bookmarks,
                          )));
                        }
                    ),
                  if (rBooks.length >= 2)
                    GestureDetector(
                        child: ProductsListContainer(
                          book: rBooks[1],
                          uid: widget.uid,
                          cart: widget.cart,
                          bookmarks: widget.bookmarks,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                            analytics: widget.analytics,
                            observer: widget.observer,
                            ID: rBooks[1].bookID,
                            title: rBooks[1].bookTitle,
                            author: rBooks[1].author,
                            type: rBooks[1].bookType,
                            category: rBooks[1].bookCategory,
                            description: rBooks[1].description,
                            deliveryWithin: rBooks[1].deliveryWithin,
                            seller: rBooks[1].seller,
                            sellerID: rBooks[1].sellerID,
                            price: rBooks[1].price,
                            discountedPrice: rBooks[1].discountedPrice,
                            inventory: rBooks[1].inventory,
                            sold: rBooks[1].sold,
                            pictureURL: rBooks[1].pictureURL,
                            comments: rBooks[1].comments,
                            currentUID: widget.uid,
                            cartPassed: widget.cart,
                            bookmarksPassed: widget.bookmarks,
                          )));
                        }
                    ),
                ],
                options: CarouselOptions(
                  height: 365.0,
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
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'CLOSE',
                      style: buttonText,
                    )
                ),
              ],
            );
          }
        });
  }*/
  /*Future<void> showAlertDialog(String title) async {
    bool isiOS = Platform.isIOS;
    var rng = Random();
    var rndIndex = rng.nextInt(widget.books.length);
    //while (widget.books[rndIndex].sellerID == widget.uid){
      //rndIndex = rng.nextInt(widget.books.length);
    //}
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if(isiOS) {
            return CupertinoAlertDialog(
              title: Container(
                color: AppColors.feedPrimary,
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
              content: SingleChildScrollView(
                child: GestureDetector(
                    child: ProductsListContainer(
                      book: widget.books[rndIndex],
                      uid: widget.uid,
                      cart: widget.cart,
                      bookmarks: widget.bookmarks,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: widget.books[rndIndex].bookID,
                        title: widget.books[rndIndex].bookTitle,
                        author: widget.books[rndIndex].author,
                        type: widget.books[rndIndex].bookType,
                        category: widget.books[rndIndex].bookCategory,
                        description: widget.books[rndIndex].description,
                        deliveryWithin: widget.books[rndIndex].deliveryWithin,
                        seller: widget.books[rndIndex].seller,
                        sellerID: widget.books[rndIndex].sellerID,
                        price: widget.books[rndIndex].price,
                        discountedPrice: widget.books[rndIndex].discountedPrice,
                        inventory: widget.books[rndIndex].inventory,
                        sold: widget.books[rndIndex].sold,
                        pictureURL: widget.books[rndIndex].pictureURL,
                        comments: widget.books[rndIndex].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                      )));
                    }
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'CLOSE',
                      style: buttonText,
                    )
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Container(
                color: AppColors.feedPrimary,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                  ),
              ),
              content: SingleChildScrollView(
                child: GestureDetector(
                    child: ProductsListContainer(
                      book: widget.books[rndIndex],
                      uid: widget.uid,
                      cart: widget.cart,
                      bookmarks: widget.bookmarks,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: widget.books[rndIndex].bookID,
                        title: widget.books[rndIndex].bookTitle,
                        author: widget.books[rndIndex].author,
                        type: widget.books[rndIndex].bookType,
                        category: widget.books[rndIndex].bookCategory,
                        description: widget.books[rndIndex].description,
                        deliveryWithin: widget.books[rndIndex].deliveryWithin,
                        seller: widget.books[rndIndex].seller,
                        sellerID: widget.books[rndIndex].sellerID,
                        price: widget.books[rndIndex].price,
                        discountedPrice: widget.books[rndIndex].discountedPrice,
                        inventory: widget.books[rndIndex].inventory,
                        sold: widget.books[rndIndex].sold,
                        pictureURL: widget.books[rndIndex].pictureURL,
                        comments: widget.books[rndIndex].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                      )));
                    }
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                      'CLOSE',
                      style: buttonText,
                    )
                ),
              ],
            );
          }
        });
  }

  Future<void> showAlertDialogOld(String title) async {
    bool isiOS = Platform.isIOS;
    var rng = Random();
    var rndIndex = rng.nextInt(oldBooks.length);
    //while (oldBooks[rndIndex].sellerID == widget.uid){
      //rndIndex = rng.nextInt(oldBooks.length);
    //}
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if(isiOS) {
            return CupertinoAlertDialog(
              title: Container(
                color: AppColors.feedPrimary,
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
              content: SingleChildScrollView(
                child: GestureDetector(
                    child: ProductsListContainer(
                      book: oldBooks[rndIndex],
                      uid: widget.uid,
                      cart: widget.cart,
                      bookmarks: widget.bookmarks,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: oldBooks[rndIndex].bookID,
                        title: oldBooks[rndIndex].bookTitle,
                        author: oldBooks[rndIndex].author,
                        type: oldBooks[rndIndex].bookType,
                        category: oldBooks[rndIndex].bookCategory,
                        description: oldBooks[rndIndex].description,
                        deliveryWithin: oldBooks[rndIndex].deliveryWithin,
                        seller: oldBooks[rndIndex].seller,
                        sellerID: oldBooks[rndIndex].sellerID,
                        price: oldBooks[rndIndex].price,
                        discountedPrice: oldBooks[rndIndex].discountedPrice,
                        inventory: oldBooks[rndIndex].inventory,
                        sold: oldBooks[rndIndex].sold,
                        pictureURL: oldBooks[rndIndex].pictureURL,
                        comments: oldBooks[rndIndex].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                      )));
                    }
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'CLOSE',
                      style: buttonText,
                    )
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Container(
                color: AppColors.feedPrimary,
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
              content: SingleChildScrollView(
                child: GestureDetector(
                    child: ProductsListContainer(
                      book: oldBooks[rndIndex],
                      uid: widget.uid,
                      cart: widget.cart,
                      bookmarks: widget.bookmarks,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: oldBooks[rndIndex].bookID,
                        title: oldBooks[rndIndex].bookTitle,
                        author: oldBooks[rndIndex].author,
                        type: oldBooks[rndIndex].bookType,
                        category: oldBooks[rndIndex].bookCategory,
                        description: oldBooks[rndIndex].description,
                        deliveryWithin: oldBooks[rndIndex].deliveryWithin,
                        seller: oldBooks[rndIndex].seller,
                        sellerID: oldBooks[rndIndex].sellerID,
                        price: oldBooks[rndIndex].price,
                        discountedPrice: oldBooks[rndIndex].discountedPrice,
                        inventory: oldBooks[rndIndex].inventory,
                        sold: oldBooks[rndIndex].sold,
                        pictureURL: oldBooks[rndIndex].pictureURL,
                        comments: oldBooks[rndIndex].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                      )));
                    }
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                      'CLOSE',
                      style: buttonText,
                    )
                ),
              ],
            );
          }
        });
  }

  Future<void> showAlertDialogNew(String title) async {
    bool isiOS = Platform.isIOS;
    var rng = Random();
    var rndIndex = rng.nextInt(newBooks.length);
    //while (newBooks[rndIndex].sellerID == widget.uid){
      //rndIndex = rng.nextInt(newBooks.length);
    //}
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if(isiOS) {
            return CupertinoAlertDialog(
              title: Container(
                color: AppColors.feedPrimary,
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
              content: SingleChildScrollView(
                child: GestureDetector(
                    child: ProductsListContainer(
                      book: newBooks[rndIndex],
                      uid: widget.uid,
                      cart: widget.cart,
                      bookmarks: widget.bookmarks,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: newBooks[rndIndex].bookID,
                        title: newBooks[rndIndex].bookTitle,
                        author: newBooks[rndIndex].author,
                        type: newBooks[rndIndex].bookType,
                        category: newBooks[rndIndex].bookCategory,
                        description: newBooks[rndIndex].description,
                        deliveryWithin: newBooks[rndIndex].deliveryWithin,
                        seller: newBooks[rndIndex].seller,
                        sellerID: newBooks[rndIndex].sellerID,
                        price: newBooks[rndIndex].price,
                        discountedPrice: newBooks[rndIndex].discountedPrice,
                        inventory: newBooks[rndIndex].inventory,
                        sold: newBooks[rndIndex].sold,
                        pictureURL: newBooks[rndIndex].pictureURL,
                        comments: newBooks[rndIndex].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                      )));
                    }
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'CLOSE',
                      style: buttonText,
                    )
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Container(
                color: AppColors.feedPrimary,
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
              content: SingleChildScrollView(
                child: GestureDetector(
                    child: ProductsListContainer(
                      book: newBooks[rndIndex],
                      uid: widget.uid,
                      cart: widget.cart,
                      bookmarks: widget.bookmarks,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: newBooks[rndIndex].bookID,
                        title: newBooks[rndIndex].bookTitle,
                        author: newBooks[rndIndex].author,
                        type: newBooks[rndIndex].bookType,
                        category: newBooks[rndIndex].bookCategory,
                        description: newBooks[rndIndex].description,
                        deliveryWithin: newBooks[rndIndex].deliveryWithin,
                        seller: newBooks[rndIndex].seller,
                        sellerID: newBooks[rndIndex].sellerID,
                        price: newBooks[rndIndex].price,
                        discountedPrice: newBooks[rndIndex].discountedPrice,
                        inventory: newBooks[rndIndex].inventory,
                        sold: newBooks[rndIndex].sold,
                        pictureURL: newBooks[rndIndex].pictureURL,
                        comments: newBooks[rndIndex].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                      )));
                    }
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                      'CLOSE',
                      style: buttonText,
                    )
                ),
              ],
            );
          }
        });
  }

  Future<void> showAlertDialogDiscount(String title) async {
    bool isiOS = Platform.isIOS;
    var rng = Random();
    var rndIndex = rng.nextInt(newBooks.length);
    //while (newBooks[rndIndex].sellerID == widget.uid){
    //rndIndex = rng.nextInt(newBooks.length);
    //}
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if(isiOS) {
            return CupertinoAlertDialog(
              title: Container(
                color: AppColors.feedPrimary,
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
              content: SingleChildScrollView(
                child: GestureDetector(
                    child: ProductsListContainer(
                      book: discountBooks[rndIndex],
                      uid: widget.uid,
                      cart: widget.cart,
                      bookmarks: widget.bookmarks,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: discountBooks[rndIndex].bookID,
                        title: discountBooks[rndIndex].bookTitle,
                        author: discountBooks[rndIndex].author,
                        type: discountBooks[rndIndex].bookType,
                        category: discountBooks[rndIndex].bookCategory,
                        description: discountBooks[rndIndex].description,
                        deliveryWithin: discountBooks[rndIndex].deliveryWithin,
                        seller: discountBooks[rndIndex].seller,
                        sellerID: discountBooks[rndIndex].sellerID,
                        price: discountBooks[rndIndex].price,
                        discountedPrice: discountBooks[rndIndex].discountedPrice,
                        inventory: discountBooks[rndIndex].inventory,
                        sold: discountBooks[rndIndex].sold,
                        pictureURL: discountBooks[rndIndex].pictureURL,
                        comments: discountBooks[rndIndex].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                      )));
                    }
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'CLOSE',
                      style: buttonText,
                    )
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Container(
                color: AppColors.feedPrimary,
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
              content: SingleChildScrollView(
                child: GestureDetector(
                    child: ProductsListContainer(
                      book: discountBooks[rndIndex],
                      uid: widget.uid,
                      cart: widget.cart,
                      bookmarks: widget.bookmarks,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: discountBooks[rndIndex].bookID,
                        title: discountBooks[rndIndex].bookTitle,
                        author: discountBooks[rndIndex].author,
                        type: discountBooks[rndIndex].bookType,
                        category: discountBooks[rndIndex].bookCategory,
                        description: discountBooks[rndIndex].description,
                        deliveryWithin: discountBooks[rndIndex].deliveryWithin,
                        seller: discountBooks[rndIndex].seller,
                        sellerID: discountBooks[rndIndex].sellerID,
                        price: discountBooks[rndIndex].price,
                        discountedPrice: discountBooks[rndIndex].discountedPrice,
                        inventory: discountBooks[rndIndex].inventory,
                        sold: discountBooks[rndIndex].sold,
                        pictureURL: discountBooks[rndIndex].pictureURL,
                        comments: discountBooks[rndIndex].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                      )));
                    }
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        Navigator.pop(context);
                      });
                    },
                    child: Text(
                      'CLOSE',
                      style: buttonText,
                    )
                ),
              ],
            );
          }
        });
  }*/

  Future<void> showAlertDialogRecommendations(String title, List<Book> rBooks) async {
    bool isiOS = Platform.isIOS;

    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          if(isiOS) {
            return CupertinoAlertDialog(
              title: Container(
                color: AppColors.feedPrimary,
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
              content: CarouselSlider(
                items:[
                  if (rBooks.length >= 1)
                    GestureDetector(
                        child: ProductsListContainer(
                          book: rBooks[0],
                          uid: widget.uid,
                          cart: widget.cart,
                          bookmarks: widget.bookmarks,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                            analytics: widget.analytics,
                            observer: widget.observer,
                            ID: rBooks[0].bookID,
                            title: rBooks[0].bookTitle,
                            author: rBooks[0].author,
                            type: rBooks[0].bookType,
                            category: rBooks[0].bookCategory,
                            description: rBooks[0].description,
                            deliveryWithin: rBooks[0].deliveryWithin,
                            seller: rBooks[0].seller,
                            sellerID: rBooks[0].sellerID,
                            price: rBooks[0].price,
                            discountedPrice: rBooks[0].discountedPrice,
                            inventory: rBooks[0].inventory,
                            sold: rBooks[0].sold,
                            pictureURL: rBooks[0].pictureURL,
                            comments: rBooks[0].comments,
                            currentUID: widget.uid,
                            cartPassed: widget.cart,
                            bookmarksPassed: widget.bookmarks,
                            notificationsPassed: widget.notifications,
                          )));
                        }
                    ),
                  if (rBooks.length >= 2)
                    GestureDetector(
                        child: ProductsListContainer(
                          book: rBooks[1],
                          uid: widget.uid,
                          cart: widget.cart,
                          bookmarks: widget.bookmarks,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                            analytics: widget.analytics,
                            observer: widget.observer,
                            ID: rBooks[1].bookID,
                            title: rBooks[1].bookTitle,
                            author: rBooks[1].author,
                            type: rBooks[1].bookType,
                            category: rBooks[1].bookCategory,
                            description: rBooks[1].description,
                            deliveryWithin: rBooks[1].deliveryWithin,
                            seller: rBooks[1].seller,
                            sellerID: rBooks[1].sellerID,
                            price: rBooks[1].price,
                            discountedPrice: rBooks[1].discountedPrice,
                            inventory: rBooks[1].inventory,
                            sold: rBooks[1].sold,
                            pictureURL: rBooks[1].pictureURL,
                            comments: rBooks[1].comments,
                            currentUID: widget.uid,
                            cartPassed: widget.cart,
                            bookmarksPassed: widget.bookmarks,
                            notificationsPassed: widget.notifications,
                          )));
                        }
                    ),
                ],
                options: CarouselOptions(
                  height: 365.0,
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
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'CLOSE',
                      style: buttonText,
                    )
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Container(
                color: AppColors.feedPrimary,
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                        child: ProductsListContainer(
                          book: rBooks[0],
                          uid: widget.uid,
                          cart: widget.cart,
                          bookmarks: widget.bookmarks,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                            analytics: widget.analytics,
                            observer: widget.observer,
                            ID: rBooks[0].bookID,
                            title: rBooks[0].bookTitle,
                            author: rBooks[0].author,
                            type: rBooks[0].bookType,
                            category: rBooks[0].bookCategory,
                            description: rBooks[0].description,
                            deliveryWithin: rBooks[0].deliveryWithin,
                            seller: rBooks[0].seller,
                            sellerID: rBooks[0].sellerID,
                            price: rBooks[0].price,
                            discountedPrice: rBooks[0].discountedPrice,
                            inventory: rBooks[0].inventory,
                            sold: rBooks[0].sold,
                            pictureURL: rBooks[0].pictureURL,
                            comments: rBooks[0].comments,
                            currentUID: widget.uid,
                            cartPassed: widget.cart,
                            bookmarksPassed: widget.bookmarks,
                            notificationsPassed: widget.notifications,
                          )));
                        }
                    ),
                    if (rBooks.length >= 2)
                      GestureDetector(
                          child: ProductsListContainer(
                            book: rBooks[1],
                            uid: widget.uid,
                            cart: widget.cart,
                            bookmarks: widget.bookmarks,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                              analytics: widget.analytics,
                              observer: widget.observer,
                              ID: rBooks[1].bookID,
                              title: rBooks[1].bookTitle,
                              author: rBooks[1].author,
                              type: rBooks[1].bookType,
                              category: rBooks[1].bookCategory,
                              description: rBooks[1].description,
                              deliveryWithin: rBooks[1].deliveryWithin,
                              seller: rBooks[1].seller,
                              sellerID: rBooks[1].sellerID,
                              price: rBooks[1].price,
                              discountedPrice: rBooks[1].discountedPrice,
                              inventory: rBooks[1].inventory,
                              sold: rBooks[1].sold,
                              pictureURL: rBooks[1].pictureURL,
                              comments: rBooks[1].comments,
                              currentUID: widget.uid,
                              cartPassed: widget.cart,
                              bookmarksPassed: widget.bookmarks,
                              notificationsPassed: widget.notifications,
                            )));
                          }
                      ),
                  ]
                )
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'CLOSE',
                      style: buttonText,
                    )
                ),
              ],
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            indent: 100,
            endIndent: 100,
            color: Colors.grey,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: DropdownButtonFormField<String>(
                    hint: Text("Select Category..."),
                    value: currentSelectedValue,
                    isDense: true,
                    onChanged: (newValue) {
                      setState(() {
                        currentSelectedValue = newValue;
                      });
                    },
                    items: bookCategories.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: TextButton.icon(
                  onPressed: (){
                    /*if (currentSelectedValue == "All" || currentSelectedValue == null){
                      showAlertDialog("RECOMMENDED");
                    }
                    else if (currentSelectedValue == "New"){
                      showAlertDialogNew("RECOMMENDED");
                    }
                    else if (currentSelectedValue == "Discounted") {
                      showAlertDialogDiscount("RECOMMENDED");
                    }
                    else{
                      showAlertDialogOld("RECOMMENDED");
                    }*/

                    if (recommendedBooks.isNotEmpty){
                      showAlertDialogRecommendations("RECOMMENDED", recommendedBooks);
                    }
                  },
                  icon: Icon(Icons.star, size: 20, color: Colors.black),
                  label: Text(
                    'RECOMMENDED',
                    style: buttonText,
                  ),
                  style: button,
                ),
              )
            ]
          ),
          Row(
            children: [
              SizedBox(width: MediaQuery.of(context).size.width/3),

              SizedBox(height: 1, width: MediaQuery.of(context).size.width/3),
            ]
          ),
          SizedBox(height: 20),
          Expanded(
              child: GridView.builder(
                  itemCount: (currentSelectedValue == "All" || currentSelectedValue == null) ? widget.books.length : (currentSelectedValue == "Discounted" ? discountBooks.length : (currentSelectedValue == "New" ? newBooks.length : oldBooks.length)),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.52,
                      crossAxisSpacing: 20,
                  ),
                  itemBuilder: (context, index) => GestureDetector(
                    child: ProductsListContainer(
                      book: (currentSelectedValue == "All" || currentSelectedValue == null) ? widget.books[index] : (currentSelectedValue == "Discounted" ? discountBooks[index] : (currentSelectedValue == "New" ? newBooks[index]: oldBooks[index])),
                      uid: widget.uid,
                      cart: widget.cart,
                      bookmarks: widget.bookmarks,
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => (currentSelectedValue == "All" ||currentSelectedValue == null ) ? Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: widget.books[index].bookID,
                        title: widget.books[index].bookTitle,
                        author: widget.books[index].author,
                        type: widget.books[index].bookType,
                        category: widget.books[index].bookCategory,
                        description: widget.books[index].description,
                        deliveryWithin: widget.books[index].deliveryWithin,
                        seller: widget.books[index].seller,
                        sellerID: widget.books[index].sellerID,
                        price: widget.books[index].price,
                        discountedPrice: widget.books[index].discountedPrice,
                        sold: widget.books[index].sold,
                        inventory: widget.books[index].inventory,
                        pictureURL: widget.books[index].pictureURL,
                        comments: widget.books[index].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                        notificationsPassed: widget.notifications,
                      ) : (currentSelectedValue == "Discounted" ? Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: discountBooks[index].bookID,
                        title: discountBooks[index].bookTitle,
                        author: discountBooks[index].author,
                        type: discountBooks[index].bookType,
                        category: discountBooks[index].bookCategory,
                        description: discountBooks[index].description,
                        deliveryWithin: discountBooks[index].deliveryWithin,
                        seller: discountBooks[index].seller,
                        sellerID: discountBooks[index].sellerID,
                        price: discountBooks[index].price,
                        discountedPrice: discountBooks[index].discountedPrice,
                        sold: discountBooks[index].sold,
                        inventory: discountBooks[index].inventory,
                        pictureURL: discountBooks[index].pictureURL,
                        comments: discountBooks[index].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                        notificationsPassed: widget.notifications,
                      ) : (currentSelectedValue == "New") ? Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: newBooks[index].bookID,
                        title: newBooks[index].bookTitle,
                        author: newBooks[index].author,
                        type: newBooks[index].bookType,
                        category: newBooks[index].bookCategory,
                        description: newBooks[index].description,
                        deliveryWithin: newBooks[index].deliveryWithin,
                        seller: newBooks[index].seller,
                        sellerID: newBooks[index].sellerID,
                        price: newBooks[index].price,
                        discountedPrice: newBooks[index].discountedPrice,
                        inventory: newBooks[index].inventory,
                        sold: newBooks[index].sold,
                        pictureURL: newBooks[index].pictureURL,
                        comments: newBooks[index].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                        notificationsPassed: widget.notifications,
                      ) : Product(
                        analytics: widget.analytics,
                        observer: widget.observer,
                        ID: oldBooks[index].bookID,
                        title: oldBooks[index].bookTitle,
                        author: oldBooks[index].author,
                        type: oldBooks[index].bookType,
                        category: oldBooks[index].bookCategory,
                        description: oldBooks[index].description,
                        deliveryWithin: oldBooks[index].deliveryWithin,
                        seller: oldBooks[index].seller,
                        sellerID: oldBooks[index].sellerID,
                        price: oldBooks[index].price,
                        discountedPrice: oldBooks[index].discountedPrice,
                        inventory: oldBooks[index].inventory,
                        sold: oldBooks[index].sold,
                        pictureURL: oldBooks[index].pictureURL,
                        comments: oldBooks[index].comments,
                        currentUID: widget.uid,
                        cartPassed: widget.cart,
                        bookmarksPassed: widget.bookmarks,
                        notificationsPassed: widget.notifications,
                      )),
                      )
                      );
                    }
                  )
              )
          )
        ],
      ),
    );
  }
}
