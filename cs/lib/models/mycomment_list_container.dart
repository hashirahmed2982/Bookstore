import 'package:cs/classes/book.dart';
import 'package:flutter/material.dart';
import 'package:cs/utils/colors.dart';
import 'package:cs/classes/comment.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MyCommentsListContainer extends StatelessWidget {
  const MyCommentsListContainer({
    Key? key,
    this.comment,
    this.book,
  }) : super(key: key);
  final Comment? comment;
  final Book? book;

  @override
  Widget build(BuildContext context) {
    return comment != null ? ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      leading: ClipRect(
        child: Image.network(book!.pictureURL),
      ),
      title: Text(
        book!.bookTitle.length <= 13 ? book!.bookTitle.toUpperCase() : book!.bookTitle.toUpperCase().substring(0, 11) + '...',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      subtitle: Text(
        comment!.content,
        style: TextStyle(
          fontSize: 15,
        ),
      ),
      isThreeLine: true,
      trailing: Column(
        children: [
          Text(
            comment!.timeAndDate.toDate().day.toString() + '-' + comment!.timeAndDate.toDate().month.toString() + '-' + comment!.timeAndDate.toDate().year.toString(),
            style: TextStyle(
              fontSize: 13,
            ),
          ),
          RatingBarIndicator(
            itemCount: 4,
            rating: double.parse(comment!.commentRating),
            itemSize: 20,
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: AppColors.feedPrimary,
            ),
          ),
          comment!.isApproved ? Text(
            '  APPROVED  ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.greenAccent.shade400,
              fontWeight: FontWeight.w600,
            ),
          ) : Text(
            'UNAPPROVED',
            style: TextStyle(
              fontSize: 13,
              color: Colors.red.shade400,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    ) : Container();
  }
}
