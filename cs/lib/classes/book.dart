import 'package:cs/classes/comment.dart';

class Book {
  String bookID;
  String bookTitle;
  String author;
  String bookType;
  String bookCategory;
  String description;
  String deliveryWithin;
  String seller;
  String sellerID;
  String price;
  String discountedPrice;
  String inventory;
  String sold;
  String pictureURL;
  var comments;

  Book({
    required this.bookID,
    required this.bookTitle,
    required this.author,
    required this.bookType,
    required this.bookCategory,
    required this.description,
    required this.deliveryWithin,
    required this.seller,
    required this.sellerID,
    required this.price,
    required this.discountedPrice,
    required this.inventory,
    required this.sold,
    required this.pictureURL,
    required this.comments,
  });

  void addComment() {
    //TODO: add comments to the comments list
  }

  void alterPrice() {
    //TODO: change the price of the book
  }

  void delete() {
    //TODO
  }
}