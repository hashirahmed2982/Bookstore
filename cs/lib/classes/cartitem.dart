class CartItem {
  String bookID;
  String bookTitle;
  String bookType;
  String deliveryWithin;
  String seller;
  String sellerID;
  String price;
  String quantity;
  String pictureURL;

  CartItem({
    required this.bookID,
    required this.bookTitle,
    required this.bookType,
    required this.deliveryWithin,
    required this.seller,
    required this.sellerID,
    required this.price,
    required this.quantity,
    required this.pictureURL,
  });
}