class Order {
  final String bookName, bookID, pictureURL, address, status;
  final String price;
  final String id;
  final String buyerID, sellerID, quantity, bookType, bookCategory;

  Order(this.id, this.buyerID, this.sellerID, this.price, this.address, this.bookID, this.bookName, this.quantity, this.bookType, this.bookCategory, this.pictureURL, this.status);
}