import 'package:cs/classes/order.dart';
import 'package:flutter/material.dart';

class OrdersListContainer extends StatelessWidget {
  const OrdersListContainer({
    Key? key,
    required this.order,
  }) : super(key: key);
  final Order order;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Padding(
        padding: const EdgeInsets.only(right: 3.0),
        child: Image.network(order.pictureURL),
      ),
      title: Text(
        order.bookName.length <= 16 ? order.bookName.toUpperCase() : order.bookName.toUpperCase().substring(0,13) + '...',
      ),
      trailing: Text(
        order.price.toString() + ' TL',
        style: TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              order.quantity + '  |  ' + order.price + ' TL each',
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              order.bookType,
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              order.bookCategory,
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              'Address: ' + order.address,
            ),
          ),
        ],
      ),
    );
  }
}
