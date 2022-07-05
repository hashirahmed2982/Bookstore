//FINAL PROJECT
import 'package:cs/routes/address.dart';
import 'package:cs/routes/checkout.dart';
import 'package:cs/routes/mybookmarks.dart';
import 'package:cs/routes/cart.dart';
import 'package:cs/routes/myofferedproducts.dart';
import 'package:cs/routes/notifications.dart';
import 'package:cs/routes/product.dart';
import 'package:cs/routes/resetpass.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:cs/routes/welcome.dart';
import 'package:cs/routes/register.dart';
import 'package:cs/routes/login.dart';
import 'package:cs/routes/walkthrough.dart';
import 'package:cs/routes/editprofile.dart';
import 'package:cs/routes/feed.dart';
import 'package:cs/routes/profile.dart';
import 'package:cs/routes/mycomments.dart';
import 'package:cs/routes/search.dart';
import 'package:cs/routes/orderhistory.dart';
import 'package:cs/utils/colors.dart';
import 'package:cs/utils/sharedpreferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  runApp(MyFirebaseApp());
}

class MyFirebaseApp extends StatefulWidget {
  const MyFirebaseApp({Key? key}) : super(key: key);

  @override
  _MyFirebaseAppState createState() => _MyFirebaseAppState();
}

class _MyFirebaseAppState extends State<MyFirebaseApp> {

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text("No Firebase Connection ${snapshot.error}"),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }

        return MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.feedPrimary,
              )
            )
          )
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {

  bool isFirstTimeOpen = false;
  bool isLoggedIn = false;

  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  MyAppState() {
    MySharedPreferences.instance
      .getBooleanValue("firstTimeOpen")
      .then((value) => setState(() {
        isFirstTimeOpen = value;
    }));
    MySharedPreferences.instance
      .getBooleanValue("isLoggedIn")
      .then((value) => setState(() {
        isLoggedIn = value;
    }));
  }

  @override
  /*Widget build(BuildContext context) {
    //print("IsFirstTimeOpen $isFirstTimeOpen");
    return MaterialApp(
      navigatorObservers: <NavigatorObserver>[observer],
      routes: {
        '/': (context) => isFirstTimeOpen ? Welcome(analytics: analytics, observer: observer,) : WalkThrough(analytics: analytics, observer: observer,) ,
        '/welcome': (context) => Welcome(analytics: analytics, observer: observer,),
        '/register': (context) => Register(analytics: analytics, observer: observer,),
        '/login': (context) => Login(analytics: analytics, observer: observer,),
        '/resetpass' : (context) => ResetPass(analytics: analytics, observer: observer),
        '/addbooks' : (context) => Feed(analytics: analytics, observer: observer),
      },
    );
  }*/
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: AppColors.feedPrimary,
        appBarTheme: AppBarTheme(
            iconTheme: IconThemeData(
              color: Colors.black,
            )),
      ),
      navigatorObservers: <NavigatorObserver>[observer],
      routes: {
        '/': (context) => isFirstTimeOpen ? Welcome(
          analytics: analytics,
          observer: observer,
        )
            : WalkThrough(
          analytics: analytics,
          observer: observer,
        ),
        '/welcome': (context) => Welcome(
          analytics: analytics,
          observer: observer,
        ),
        '/register': (context) => Register(
          analytics: analytics,
          observer: observer,
        ),
        '/login': (context) => Login(
          analytics: analytics,
          observer: observer,
        ),
        '/resetpass': (context) => ResetPass(
          analytics: analytics,
          observer: observer
        ),
        '/feed': (context) => Feed(
          analytics: analytics,
          observer: observer
        ),
        '/profile': (context) => Profile(
          analytics: analytics,
          observer: observer
        ),
        '/mycomments': (context) => MyComments(
          analytics: analytics,
          observer: observer
        ),
        '/editprofile': (context) => EditProfile(
          analytics: analytics,
          observer: observer
        ),
        /*'/search': (context) => Search(
          analytics: analytics,
          observer: observer,
        ),*/
        '/notifications' : (context) => Notifications(
          analytics: analytics,
          observer: observer,
        ),
        '/orderhistory' : (context) => OrderHistory(
          analytics: analytics,
          observer: observer,
        ),
        '/cart' : (context) => Cart(
          analytics: analytics,
          observer: observer,
        ),
        '/product' : (context) => Product(
          analytics: analytics,
          observer: observer,
        ),
        '/mybookmarks' : (context) => MyBookmarks(
          analytics: analytics,
          observer: observer,
        ),
        '/myofferedproducts' : (context) => MyOfferedProducts(
          analytics: analytics,
          observer: observer,
        ),
        '/mycomments' : (context) => MyComments(
          analytics: analytics,
          observer: observer,
        ),
        '/checkout' : (context) => Checkout(
          analytics: analytics,
          observer: observer
        ),
        '/address' : (context) => Address(
          analytics: analytics,
          observer: observer,
        )
      },
    );
  }
}

