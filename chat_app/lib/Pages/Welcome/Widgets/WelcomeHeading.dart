import 'package:chat_app/Config/Images.dart' show AssetsImage;
import 'package:chat_app/Config/Strings.dart';
import 'package:flutter/material.dart';

class Welcomeheading extends StatelessWidget {
  const Welcomeheading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Image.asset(AssetsImage.appIcon, height: 70, width: 80)],
        ),
        Text(
          AppString.appName,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
