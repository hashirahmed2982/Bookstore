// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_key_in_widget_constructors

/*import 'dart:ffi';

import 'package:cs/models/product_list_container.dart';
import 'package:cs/models/products.dart';
import 'package:cs/utils/colors.dart';
import 'package:flutter/material.dart';
import 'banner.dart';

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedBanner(size: size),
          SizedBox(height: 20),
          Row(
            children: [
              Text('Best Sellers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Expanded(
              child: GridView.builder(
                  itemCount: books.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.60,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20),
                  itemBuilder: (context, index) => ProductsListContainer(
                        book: books[index],
                        press: () {},
                      )))
        ],
      ),
    );
  }
}
*/