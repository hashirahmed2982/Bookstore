// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cs/models/products.dart';
import 'package:cs/utils/colors.dart';
import 'package:cs/classes/comment.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class CommentsListContainer extends StatelessWidget {
  const CommentsListContainer({
    Key? key,
    this.comment,
  }) : super(key: key);
  final Comment? comment;

  @override
  Widget build(BuildContext context) {

    return comment != null ? ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(comment!.commentByPictureURL),
        radius: 15,
      ),
      title: Text(
        comment!.commentByName.length <= 8 ? comment!.commentByName : comment!.commentByName.substring(0, 5) + '...',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      subtitle: Text(
        comment!.content,
        style: TextStyle(
          fontSize: 13,
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
        ],
      ),
    ) : Container();
  }
}
