import 'package:flutter/material.dart';
import 'package:search_page/search_page.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cs/utils/colors.dart';
import '../utils/dimensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cs/classes/book.dart';
import 'package:cs/routes/product.dart';
import 'package:cs/models/product_list_container.dart';

/*class Search extends StatefulWidget {
  const Search({Key? key, required this.analytics, required this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _SearchState createState() => _SearchState();
}
class _SearchState extends State<Search> {

  Future<void> _setLogEvent(n) async {
    await widget.analytics.logEvent(
        name: n,
        parameters: <String, dynamic>{
          "bool": true,
        }
    );
  }

  dynamic data;
  String username = "";
  String mail = "";
  String uid = "";
  var cart = {};
  List<Book> books = [];

  FirebaseAuth auth = FirebaseAuth.instance;

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
      });
    });
  }
  Future getBooks() async {
    User? currentUser = await auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
    }
    setState(() {
      uid = currentUser!.uid;
    });

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
  _SearchState() {
    _setLogEvent("Feed_page_reached");
    getBooks();
  }

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
        backgroundColor: AppColors.feedPrimary,
      ),
      body: GridView.builder(
          itemCount: books.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.52,
            crossAxisSpacing: 20,
          ),
          itemBuilder: (context, index) => GestureDetector(
            child: ProductsListContainer(
              book: books[index],
              uid: uid,
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Product(
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
                currentUID: uid,
                cartPassed: cart,
                ),
              )
            );
          }
        )
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Search books',
        onPressed: () => showSearch(
          context: context,
          delegate: SearchPage<Book>(
            barTheme: ThemeData(
                appBarTheme: AppBarTheme(
                  backgroundColor: AppColors.feedPrimary,
                )
            ),
            onQueryUpdate: (s) => print(s),
            items: books,
            searchLabel: 'Search books',
            suggestion: Center(
              child: Text('Filter books by name or price'),
            ),
            failure: Center(
              child: Text('No such book found :('),
            ),
            filter: (book) => [
              book.bookTitle,
              book.price.toString(),
              book.bookCategory,
            ],
            builder: (book) => ListTile(
              title: Text(book.bookTitle),
              trailing: Text(book.price),
            ),
          ),
        ),
        child: Icon(Icons.search),
        backgroundColor: AppColors.feedPrimary,
      ),
    );
  }
}*/