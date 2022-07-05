import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentID, commentByName, commentByUID, commentByPictureURL, content, commentRating;
  final Timestamp timeAndDate;
  bool isApproved = false;

  Comment(this.commentByName, this.commentByUID, this.commentByPictureURL, this.content, this.timeAndDate, this.isApproved, this.commentRating, this.commentID);
}