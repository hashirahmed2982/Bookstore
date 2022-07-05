import 'package:cs/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cs/utils/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cs/utils/sharedpreferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

class WalkThrough extends StatefulWidget {
  const WalkThrough({Key? key, required this.analytics, required this.observer}) : super(key: key);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _WalkThroughState createState() => _WalkThroughState();

}

class _WalkThroughState extends State<WalkThrough> {

  int currentPage = 0;
  int lastPage = 3;

  Future<void> _setLogEvent(n) async {
    await widget.analytics.logEvent(
        name: n,
        parameters: <String, dynamic> {
          "bool" : true,
        }
    );
  }

  _WalkThroughState() {
    _setLogEvent("WalkThrough_page_reached");
  }

  List<String> headings = [
    'Welcome',
    'Shop',
    'Sell',
    'You Are All Good To Go!'
  ];
  List<String> captions = [
    'sell and buy products in one platform',
    'shop wide range of books for every age',
    'sell books that you don’t use anymore',
    'click next to start your experience'
  ];

  List<String> images = [
    'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/Emojione_BW_1F44B.svg/768px-Emojione_BW_1F44B.svg.png',
    'https://cdn3.iconfinder.com/data/icons/e-commerce-2-2/380/1-512.png',
    'https://cdn.icon-icons.com/icons2/2582/PNG/512/sale_icon_153984.png',
    'https://www.nicepng.com/png/full/11-116475_green-thumbs-up-png-black-and-white-stock.png',
  ];

  void nextPage() {
    if(currentPage < lastPage) {
      setState(() {
        currentPage += 1;
      });
    }
    else{
      Navigator.pushNamed(context, '/welcome');
    }
  }

  void prevPage() {
    if(currentPage > 0) {
      setState(() {
        currentPage -= 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.walkthroughbackground,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  headings[currentPage],
                  style: headingtitle,
                ),
              ),
            ),


            Container(
              height: 280,
              child: CircleAvatar(
                backgroundImage: NetworkImage(images[currentPage]),
                radius: 140,
                backgroundColor: AppColors.buttonColor,
              ),
            ),

            Center(
              child: Text(
                captions[currentPage],
                textAlign: TextAlign.center,
                style: captiontitle,
              ),
            ),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 80,
                child: Row(
                  children: [
                    currentPage != 0 ? (
                        OutlinedButton(
                          onPressed: prevPage,
                          child: Text(
                            'Prev',
                            style: TextStyle(
                              color: AppColors.buttonColor,
                            ),
                          ),
                        )
                    ) : (
                      OutlinedButton(
                        onPressed: () {},
                        child: Text(
                          ''
                        ),
                        style: ButtonStyle(
                          // TODO: NEED TO REMOVE CLICK BEHAVIOR

                        ),
                      )
                    ),


                    Spacer(),


                    Text(
                      '${currentPage+1}/${lastPage+1}',
                      style: TextStyle(
                        color: AppColors.buttonColor,
                      ),
                      textAlign: TextAlign.center,
                    ),


                    Spacer(),


                    OutlinedButton(
                      onPressed: nextPage,
                      child: Text(
                        'Next',
                        style: TextStyle(
                          color: AppColors.buttonColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
