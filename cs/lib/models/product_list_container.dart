// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cs/models/products.dart';
import 'package:cs/utils/colors.dart';
import 'package:cs/classes/book.dart';

class ProductsListContainer extends StatelessWidget {
  const ProductsListContainer({
    Key? key,
    required this.book,
    required this.uid,
    required this.bookmarks,
    required this.cart,
  }) : super(key: key);
  final Book book;
  final String uid;
  final dynamic cart, bookmarks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                child: Image.network(book.pictureURL, height: 215),
              ),
              if (cart.containsKey(book.bookID))
                Positioned(
                  top: 15, right: 15, //give the values according to your requirement
                  child: Container(
                    color: AppColors.feedPrimary,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.shopping_cart, color: Colors.black,),
                    )
                  ),
                ),
              if (bookmarks.containsKey(book.bookID))
                Positioned(
                  top: 15, left: 15, //give the values according to your requirement
                  child: Container(
                    color: AppColors.feedPrimary,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.bookmark, color: Colors.black,),
                    )
                  ),
                ),
              if (book.sellerID == uid && !cart.containsKey(book.bookID) && !bookmarks.containsKey(book.bookID))
                Positioned(
                  bottom: 15, right: 15, //give the values according to your requirement
                  child: Chip(
                    label: Text('YOU'),
                    backgroundColor: AppColors.feedPrimary,
                    elevation: 2,
                    shadowColor: Colors.grey[60],
                    //padding: EdgeInsets.all(8),
                    labelPadding: EdgeInsets.all(2),
                  ),
                ),
            ]
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(book.bookTitle.length <= 25 ? book.bookTitle.toUpperCase() : '${book.bookTitle.substring(0, 22).toUpperCase()}...' ,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Open Sans',
                ),
                textAlign: TextAlign.center,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (book.bookCategory == "Old")
                Chip(
                  label: Text(book.bookCategory.toUpperCase()),
                  backgroundColor: Colors.grey.shade200,
                  elevation: 2,
                  shadowColor: Colors.grey[60],
                  //padding: EdgeInsets.all(8),
                  labelPadding: EdgeInsets.all(2),
                ),
              if (book.bookCategory == "New")
                Chip(
                  label: Text(book.bookCategory.toUpperCase()),
                  backgroundColor: Colors.blue.shade200,
                  elevation: 2,
                  shadowColor: Colors.grey[60],
                  //padding: EdgeInsets.all(8),
                  labelPadding: EdgeInsets.all(2),
                ),
              if (int.parse(book.discountedPrice) >= int.parse(book.price))
                Text('${book.price} TL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Open Sans',
                    color: Colors.grey.shade700
                  ),
                  textAlign: TextAlign.center,
                ),
              if (int.parse(book.discountedPrice) < int.parse(book.price))
                Text('${book.discountedPrice} TL',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Open Sans',
                      color: AppColors.cancelButtonColor,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
