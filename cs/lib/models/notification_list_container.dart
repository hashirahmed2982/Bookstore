// ignore_for_file: prefer_const_constructors

import 'package:cs/classes/usernotification.dart';
import 'package:flutter/material.dart';
import 'package:cs/utils/colors.dart';

class NotificationsListContainer extends StatelessWidget {
  const NotificationsListContainer({
    Key? key,
    required this.notification,
  }) : super(key: key);
  final UserNotification notification;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      leading: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Image.network(notification.pictureURL),
      ),
      title: Text(
        notification.content,
        style: notification.isDismissed == false ? TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ) : TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            notification.timeAndDate.toDate().hour.toString() + ':' + notification.timeAndDate.toDate().minute.toString() +
            ' on ' + notification.timeAndDate.toDate().day.toString() + '-' + notification.timeAndDate.toDate().month.toString() + '-' + notification.timeAndDate.toDate().year.toString(),

            style: notification.isDismissed == false ? TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ) : TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
          ),
          /*Text(
            notification.timeAndDate.toDate().day.toString() + '-' + notification.timeAndDate.toDate().month.toString() + '-' + notification.timeAndDate.toDate().year.toString(),
            style: TextStyle(
              fontSize: 13,
            ),
          ),*/
        ],
      ),
      isThreeLine: true,
      /*trailing: Column(
        children: [
          Text(
            notification.timeAndDate.toDate().hour.toString() + ':' + notification.timeAndDate.toDate().minute.toString(),
            style: TextStyle(
              fontSize: 13,
            ),
          ),
          Text(
            notification.timeAndDate.toDate().day.toString() + '-' + notification.timeAndDate.toDate().month.toString() + '-' + notification.timeAndDate.toDate().year.toString(),
            style: TextStyle(
              fontSize: 13,
            ),
          ),
        ],
      ),*/
    );
  }
}
