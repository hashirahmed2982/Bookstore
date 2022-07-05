import 'package:cloud_firestore/cloud_firestore.dart';

class UserNotification {
  final String ID, content, bookID, sellerID, pictureURL;
  final Timestamp timeAndDate;
  bool isDismissed = false;

  UserNotification(this.ID, this.content, this.timeAndDate, this.bookID, this.sellerID, this.pictureURL, this.isDismissed);
}