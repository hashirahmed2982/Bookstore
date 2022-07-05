// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors
import 'package:cs/utils/colors.dart';
import 'package:flutter/material.dart';

class FeedBanner extends StatelessWidget {
  const FeedBanner({
    Key? key,
    required this.size,
  }) : super(key: key);

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
          height: size.height * 0.25,
          decoration: BoxDecoration(
              color: AppColors.feedPrimary,
              borderRadius: BorderRadius.circular(30)),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10, left: 12),
                child: Image.asset('assets/images/alchemist.jpeg'),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(children: [
                    Text(
                      "Editor's Choice",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Text(
                      "The Alchemist by Paulo Coelho continues to change the lives of its readers forever. The Alchemist has established itself as a modern classic, universally admired.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ]),
                ),
              )
            ],
          )),
    );
  }
}
