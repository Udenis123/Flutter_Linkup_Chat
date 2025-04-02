import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Config/Strings.dart';
import 'package:flutter/material.dart';

class WelcomeBody extends StatelessWidget {
  const WelcomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AssetsImage.boyPic, height: 100, width: 100),
            Image.asset(AssetsImage.connetSvG, height: 40, width: 40),
            Image.asset(AssetsImage.girlPic, height: 100, width: 100),
          ],
        ),
        SizedBox(height: 20),
        Text(
          AppString.nowYourAre,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          AppString.connected,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        Text(
          AppString.discription,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}
