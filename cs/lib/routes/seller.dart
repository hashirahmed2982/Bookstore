import 'package:cs/models/product_list_containerbo.dart';
import 'package:cs/routes/productsellerprofile.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:cs/utils/colors.dart';
import 'package:cs/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs/classes/book.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';


class Seller extends StatefulWidget {
  const Seller({Key? key, required this.analytics, required this.observer, required this.sellerID, required this.seller}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  final String sellerID, seller;

  @override
  _SellerState createState() => _SellerState();
}

class _SellerState extends State<Seller> {

  FirebaseAuth auth = FirebaseAuth.instance;
  dynamic data;
  var offeredProductsMap = {};
  var discountProductsMap = {};
  List<Book> offeredProducts = [];
  List<Book> discountProducts = [];
  int offeredCount = -1;
  int discountCount = -1;
  double originalRating = 0.0;
  String pictureURL = "";
  String username = "";

  String uid = "";
  var bookmarks = {};
  var cart = {};
  var notifications = {};

  void calculateSellerRating() {
    double totalRating = 0.0;
    double commentCount = 0.0;
    offeredProductsMap.forEach((key, value) {
      var commentsMap = value[13];
      commentsMap.forEach((key2, value2) {
        totalRating += double.parse(value2[5]);
        commentCount += 1.0;
      });
    });

    setState(() {
      if (commentCount > 0){
        originalRating = totalRating/commentCount;
      }
      else{
        originalRating = 0;
      }
    });
    //return double.parse((totalRating/commentCount).toStringAsFixed(0) + '0');
  }

  Future getOfferedBooks() async {
    final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(widget.sellerID);
    await document.get().then<dynamic>((DocumentSnapshot snapshot) async{
      setState(() {
        data = snapshot.data();
        offeredProductsMap = data['offeredProducts'];
        pictureURL = data['pictureURL'];
        username = data['username'];
      });
    });
    offeredProductsMap.forEach((key, value) {
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
      offeredProducts.add(book);
      if (int.parse(book.discountedPrice) < int.parse(book.price)){
        discountProductsMap[key] = [value[0], value[1], value[2], value[3], value[4], value[5], value[6], value[7], value[8], value[9], value[10], value[11], value[12], value[13]];
        discountProducts.add(book);
      }
    });
  }

  Future getData() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    final DocumentReference document = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    await document.get().then<dynamic>((DocumentSnapshot snapshot) async{
      setState(() {
        data = snapshot.data();
        cart = data['cart'];
        uid = data['uid'];
        bookmarks = data['bookmarks'];
        notifications = data['notifications'];
      });
    });
  }

  _SellerState(){

  }

  void initState(){
    super.initState();
    getData().then((value) {
      getOfferedBooks().then((value){
        calculateSellerRating();
      });
    });

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
            Navigator.pop(context);
          },
        ),
        title: Text("$username",
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20)
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4,
                      child: CircleAvatar(
                        backgroundImage: pictureURL.isNotEmpty ? NetworkImage(pictureURL) : null,
                        radius: 80,
                      )
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Text(
                            'SELLER RATING',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 20,
                              fontFamily: 'Open Sans',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Divider(
                            color: Colors.grey,
                            indent: 20,
                            endIndent: 20,
                          ),
                          RatingBarIndicator(
                            itemCount: 4,
                            rating: originalRating,
                            itemSize: 20,
                            itemBuilder: (context, _) => Icon(
                              Icons.star,
                              color: AppColors.feedPrimary,
                            ),
                          ),
                        ],
                      )
                    ),
                  ]
                ),
              ),
              const SizedBox(height: 20),
              const Divider(
                color: Colors.grey,
                indent: 80,
                endIndent: 80,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Text(
                  'DISCOUNTED PRODUCTS',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                    fontFamily: 'Open Sans',
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 80),
              CarouselSlider(
                items: discountProductsMap.entries.map((entry) {
                  discountCount++;
                  return Container(
                    child: discountProducts.length > 0 ? GestureDetector(
                      child: ProductsListContainerBO(
                        book: discountCount < discountProducts.length ? discountProducts[discountCount] : null,
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductSellerProfile(
                          analytics: widget.analytics,
                          observer: widget.observer,
                          ID: discountProducts[discountCount].bookID,
                          title: discountProducts[discountCount].bookTitle,
                          author: discountProducts[discountCount].author,
                          type: discountProducts[discountCount].bookType,
                          category: discountProducts[discountCount].bookCategory,
                          description: discountProducts[discountCount].description,
                          deliveryWithin: discountProducts[discountCount].deliveryWithin,
                          seller: discountProducts[discountCount].seller,
                          sellerID: discountProducts[discountCount].sellerID,
                          price: discountProducts[discountCount].price,
                          discountedPrice: discountProducts[discountCount].discountedPrice,
                          sold: discountProducts[discountCount].sold,
                          inventory: discountProducts[discountCount].inventory,
                          pictureURL: discountProducts[discountCount].pictureURL,
                          comments: discountProducts[discountCount].comments,
                          currentUID: uid,
                          cartPassed: cart,
                          bookmarksPassed: bookmarks,
                          notificationsPassed: notifications,
                        )));
                      }
                    ) : Text(
                      'THERE ARE NO PRODUCTS BEING OFFERED AT A DISCOUNT BY THIS SELLER!',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 10,
                        fontFamily: 'Open Sans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
                //Slider Container properties
                options: CarouselOptions(
                  height: 365.0,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 20),
                  aspectRatio: 16 / 9,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enableInfiniteScroll: discountProducts.length > 1 ? true : false,
                  autoPlayAnimationDuration: Duration(milliseconds: 800),
                  viewportFraction: 0.8,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(
                color: Colors.grey,
                indent: 80,
                endIndent: 80,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    color: AppColors.feedPrimary,
                    borderRadius: BorderRadius.circular(10)
                ),
                child: Text(
                  'ALL PRODUCTS',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                    fontFamily: 'Open Sans',
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 80),
              CarouselSlider(
                items: offeredProductsMap.entries.map((entry) {
                  offeredCount++;
                  return Container(
                    child: offeredProducts.length > 0 ? GestureDetector(
                      child: ProductsListContainerBO(
                        book: offeredCount < offeredProducts.length ? offeredProducts[offeredCount] : null,
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductSellerProfile(
                          analytics: widget.analytics,
                          observer: widget.observer,
                          ID: offeredProducts[offeredCount].bookID,
                          title: offeredProducts[offeredCount].bookTitle,
                          author: offeredProducts[offeredCount].author,
                          type: offeredProducts[offeredCount].bookType,
                          category: offeredProducts[offeredCount].bookCategory,
                          description: offeredProducts[offeredCount].description,
                          deliveryWithin: offeredProducts[offeredCount].deliveryWithin,
                          seller: offeredProducts[offeredCount].seller,
                          sellerID: offeredProducts[offeredCount].sellerID,
                          price: offeredProducts[offeredCount].price,
                          discountedPrice: offeredProducts[offeredCount].discountedPrice,
                          sold: offeredProducts[offeredCount].sold,
                          inventory: offeredProducts[offeredCount].inventory,
                          pictureURL: offeredProducts[offeredCount].pictureURL,
                          comments: offeredProducts[offeredCount].comments,
                          currentUID: uid,
                          cartPassed: cart,
                          bookmarksPassed: bookmarks,
                        )));
                      },
                    ) : Text(
                      'THERE ARE NO PRODUCTS BEING OFFERED BY THIS SELLER!',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 10,
                        fontFamily: 'Open Sans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
                //Slider Container properties
                options: CarouselOptions(
                  height: 365.0,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 20),
                  aspectRatio: 16 / 9,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enableInfiniteScroll: offeredProducts.length > 1 ? true : false,
                  autoPlayAnimationDuration: Duration(milliseconds: 800),
                  viewportFraction: 0.8,
                ),
              ),
            ]
          ),
        ),
      )
    );
  }
}
