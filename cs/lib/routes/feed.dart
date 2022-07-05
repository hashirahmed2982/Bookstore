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
import 'package:cs/utils/sharedpreferences.dart';
import 'package:flutter/material.dart';
import '../utils/dimensions.dart';
import '../utils/colors.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cs/models/sell.dart';
import 'package:cs/models/buy.dart';
import 'package:cs/classes/book.dart';
import 'package:search_page/search_page.dart';
import 'package:cs/models/product_list_container.dart';
import 'package:cs/routes/product.dart';

class Feed extends StatefulWidget {
  const Feed({Key? key, required this.analytics, required this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _FeedState createState() => _FeedState();
}

class _FeedState extends State<Feed> {

  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);
  Future<void> _setLogEvent(n) async {
    await analytics.logEvent(
        name: n,
        parameters: <String, dynamic> {
          "bool" : true,
        }
    );
  }

  FirebaseAuth auth = FirebaseAuth.instance;

  dynamic data;
  String username = "";
  String mail = "";
  String uid = "";
  String pictureURL = "";
  var cart = {};
  var bookmarks = {};
  var notifications = {};
  List<Book> books = [];
  List<Book> oldBooks = [];
  bool showNotificationsBadge = false;

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
        mail = data['email'];
        uid = currentUser.uid;
        cart = data['cart'];
        pictureURL = data['pictureURL'];
        bookmarks = data['bookmarks'];
        notifications = data['notifications'];
      });
    });
  }

  Future getBooks() async {
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
          setState(() {
            books.add(book);
          });
        });
      });
    });
  }

  Future showingNotificationsBadge() async {
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

  _FeedState() {
    _setLogEvent("Feed_page_reached");
    getData().then((value) {
      showingNotificationsBadge();
    });
    getBooks();
  }

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    if (username != "ANONYMOUS USER"){
      return FutureBuilder(
          future: _initialization,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return DefaultTabController(
                length: 2,
                child: Scaffold(
                  backgroundColor: AppColors.bgColor,
                  appBar: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
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
                                  if (cart.isNotEmpty)
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
                  bottomNavigationBar: TabBar(
                      indicatorColor: AppColors.feedPrimary,
                      indicatorSize: TabBarIndicatorSize.tab,

                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        color: AppColors.feedPrimary,
                      ),
                      //indicatorWeight: 8,
                      tabs: [
                        Tab(
                            child: Text(
                              'BUY',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            )
                        ),
                        Tab(
                            child: Text(
                              'SELL',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            )
                        ),
                      ]
                  ),
                  body: TabBarView(
                    children: [
                      Buy(analytics: analytics, observer: observer, userName: username, books: books, uid: uid, cart: cart, bookmarks: bookmarks, notifications: notifications,),
                      Sell(analytics: analytics, observer: observer, userName: username),
                    ],
                  ),
                  drawer: Drawer(
                      child: ListView(children: [
                        UserAccountsDrawerHeader(
                          accountName: Text('$username'),
                          accountEmail: Text('$mail'),
                          currentAccountPicture: CircleAvatar(
                            backgroundImage: NetworkImage(
                                pictureURL),
                          ),
                          currentAccountPictureSize: const Size.square(80),
                        ),
                        MenuList(press: () {
                          Navigator.pop(context);
                          Navigator.popAndPushNamed(context, '/feed');
                        },
                            title: 'Home',
                            icon: Icons.home),
                        MenuList(
                            press: () {
                              Navigator.popAndPushNamed(context, "/profile");
                            },
                            title: 'Profile',
                            icon: Icons.account_circle),
                        MenuList(
                            press: () {
                              Navigator.popAndPushNamed(context, "/cart");
                            },
                            title: 'Cart',
                            icon: Icons.shopping_cart),
                        Divider(color: AppColors.feedPrimary),
                        MenuList(
                          title: 'Search',
                          icon: Icons.search_rounded,
                          press: () => showSearch(
                              context: context,
                              delegate: SearchPage<Book>(
                                  barTheme: ThemeData(
                                    appBarTheme: AppBarTheme(
                                      backgroundColor: AppColors.feedPrimary,
                                    ),
                                    textSelectionTheme: TextSelectionThemeData(
                                      cursorColor: Colors.black,
                                    ),
                                    inputDecorationTheme: InputDecorationTheme(
                                      fillColor: Colors.grey.shade200,
                                      filled: true,
                                      focusedBorder: InputBorder.none,
                                    ),

                                  ),
                                  items: books,
                                  searchLabel: 'Search...',
                                  suggestion: Center(
                                    child: Text(
                                      'Enter name, author, price or condition...',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  failure: Center(
                                    child: Text('No such book found :(',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  filter: (book) => [
                                    book.bookTitle,
                                    int.parse(book.discountedPrice) < int.parse(book.price) ? book.discountedPrice : book.price,
                                    book.bookCategory,
                                    book.author,
                                  ],
                                  builder: (book) => Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: GestureDetector(
                                        child: ProductsListContainer(
                                          book: book,
                                          uid: uid,
                                          cart: cart,
                                          bookmarks: bookmarks,
                                        ),
                                        onTap: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                                            analytics: widget.analytics,
                                            observer: widget.observer,
                                            ID: book.bookID,
                                            title: book.bookTitle,
                                            author: book.author,
                                            type: book.bookType,
                                            category: book.bookCategory,
                                            description: book.description,
                                            deliveryWithin: book.deliveryWithin,
                                            seller: book.seller,
                                            sellerID: book.sellerID,
                                            price: book.price,
                                            discountedPrice: book.discountedPrice,
                                            inventory: book.inventory,
                                            pictureURL: book.pictureURL,
                                            comments: book.comments,
                                            currentUID: uid,
                                            cartPassed: cart,
                                            bookmarksPassed: bookmarks,
                                            notificationsPassed: notifications,
                                          ),
                                          )
                                          );
                                        }
                                    ),
                                  )
                              )
                          ),
                        ),
                      ])
                  ),
                ),
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
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return DefaultTabController(
              length: 1,
              child: Scaffold(
                backgroundColor: AppColors.bgColor,
                appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
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
                                if (cart.isNotEmpty)
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
                bottomNavigationBar: TabBar(
                    indicatorColor: AppColors.feedPrimary,
                    indicatorSize: TabBarIndicatorSize.tab,

                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      color: AppColors.feedPrimary,
                    ),
                    //indicatorWeight: 8,
                    tabs: [
                      Tab(
                          child: Text(
                            'BUY',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          )
                      ),
                    ]
                ),
                body: TabBarView(
                  children: [
                    Buy(analytics: analytics, observer: observer, userName: username, books: books, uid: uid, cart: cart, bookmarks: bookmarks, notifications: notifications,),
                  ],
                ),
                drawer: Drawer(
                    child: ListView(children: [
                      UserAccountsDrawerHeader(
                        accountName: Text('$username'),
                        accountEmail: Text('$mail'),
                        currentAccountPicture: CircleAvatar(
                          backgroundImage: NetworkImage(
                              pictureURL),
                        ),
                        currentAccountPictureSize: const Size.square(80),
                      ),
                      MenuList(press: () {
                        Navigator.pop(context);
                        Navigator.popAndPushNamed(context, '/feed');
                      },
                          title: 'Home',
                          icon: Icons.home),
                      MenuList(
                          press: () {
                            Navigator.popAndPushNamed(context, "/cart");
                          },
                          title: 'Cart',
                          icon: Icons.shopping_cart),
                      MenuList(
                        title: 'Search',
                        icon: Icons.search_rounded,
                        press: () => showSearch(
                            context: context,
                            delegate: SearchPage<Book>(
                                barTheme: ThemeData(
                                  appBarTheme: AppBarTheme(
                                    backgroundColor: AppColors.feedPrimary,
                                  ),
                                  textSelectionTheme: TextSelectionThemeData(
                                    cursorColor: Colors.black,
                                  ),
                                  inputDecorationTheme: InputDecorationTheme(
                                    fillColor: Colors.grey.shade200,
                                    filled: true,
                                    focusedBorder: InputBorder.none,
                                  ),

                                ),
                                items: books,
                                searchLabel: 'Search...',
                                suggestion: Center(
                                  child: Text(
                                    'Enter name, author, price or condition...',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                failure: Center(
                                  child: Text('No such book found :(',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                filter: (book) => [
                                  book.bookTitle,
                                  int.parse(book.discountedPrice) < int.parse(book.price) ? book.discountedPrice : book.price,
                                  book.bookCategory,
                                  book.author,
                                ],
                                builder: (book) => Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: GestureDetector(
                                      child: ProductsListContainer(
                                        book: book,
                                        uid: uid,
                                        cart: cart,
                                        bookmarks: bookmarks,
                                      ),
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
                                          analytics: widget.analytics,
                                          observer: widget.observer,
                                          ID: book.bookID,
                                          title: book.bookTitle,
                                          author: book.author,
                                          type: book.bookType,
                                          category: book.bookCategory,
                                          description: book.description,
                                          deliveryWithin: book.deliveryWithin,
                                          seller: book.seller,
                                          sellerID: book.sellerID,
                                          price: book.price,
                                          discountedPrice: book.discountedPrice,
                                          inventory: book.inventory,
                                          pictureURL: book.pictureURL,
                                          comments: book.comments,
                                          currentUID: uid,
                                          cartPassed: cart,
                                          bookmarksPassed: bookmarks,
                                          notificationsPassed: notifications,
                                        ),
                                        )
                                        );
                                      }
                                  ),
                                )
                            )
                        ),
                      ),
                      Divider(color: AppColors.feedPrimary),
                      MenuList(
                          press: () async {
                            User? currentUser = await auth.currentUser;
                            if (currentUser != null) {
                              await currentUser.reload();
                            }
                            await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).delete();
                            await auth.currentUser!.delete();
                            auth.signOut();
                            MySharedPreferences.instance.setBooleanValue("isLoggedIn", false);
                            Navigator.popUntil(context, (route) => route.isFirst);
                            Navigator.pushNamed(context, '/welcome');
                          },
                          title: 'Sign Out',
                          icon: Icons.account_circle),
                    ])
                ),
              ),
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

class MenuList extends StatelessWidget {
  const MenuList({
    Key? key,
    required this.title,
    required this.press,
    required this.icon,
  }) : super(key: key);
  final String title;
  final void Function() press;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        press();
      },
      child: ListTile(
        title: Text(title),
        leading: Icon(icon, color: Colors.grey),
      ),
    );
  }
}

