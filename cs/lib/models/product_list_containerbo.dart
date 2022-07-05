// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cs/utils/colors.dart';
import 'package:cs/classes/book.dart';

class ProductsListContainerBO extends StatelessWidget {
  const ProductsListContainerBO({
    Key? key,
    required this.book,
  }) : super(key: key);
  final Book? book;

  @override
  Widget build(BuildContext context) {
    return book != null ? Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        children: [
          Stack(
              children: [
                Container(
                  child: Image.network(book!.pictureURL, height: 215),
                ),
              ]
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(book!.bookTitle.length <= 25 ? book!.bookTitle.toUpperCase() : '${book!.bookTitle.substring(0, 22).toUpperCase()}...' ,
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
              if (book!.bookCategory == "Old")
                Chip(
                  label: Text(book!.bookCategory.toUpperCase()),
                  backgroundColor: Colors.grey.shade200,
                  elevation: 2,
                  shadowColor: Colors.grey[60],
                  //padding: EdgeInsets.all(8),
                  labelPadding: EdgeInsets.all(2),
                ),
              if (book!.bookCategory == "New")
                Chip(
                  label: Text(book!.bookCategory.toUpperCase()),
                  backgroundColor: Colors.blue.shade200,
                  elevation: 2,
                  shadowColor: Colors.grey[60],
                  //padding: EdgeInsets.all(8),
                  labelPadding: EdgeInsets.all(2),
                ),
              if (int.parse(book!.discountedPrice) >= int.parse(book!.price))
                Text('${book!.price} TL',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Open Sans',
                      color: Colors.grey.shade700
                  ),
                  textAlign: TextAlign.center,
                ),
              if (int.parse(book!.discountedPrice) < int.parse(book!.price))
                Text('${book!.discountedPrice} TL',
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
    ) : Container();
  }
}
