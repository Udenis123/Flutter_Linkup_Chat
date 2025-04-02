import 'package:chat_app/Config/Colors.dart';
import 'package:flutter/material.dart';

var lightTheme = ThemeData();
var darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,

  appBarTheme: AppBarTheme(backgroundColor: dContainerColor),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: dBackgroundColor,
    hintStyle: TextStyle(color: donContainerColor, fontSize: 15),
    border: UnderlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(10),
    ),
  ),

  colorScheme: ColorScheme.dark(
    primary: dPrimarColor,
    onPrimary: dOnBackgroundColor,
    surface: dBackgroundColor,
    onSurface: dOnBackgroundColor,
    primaryContainer: dContainerColor,
    onPrimaryContainer: donContainerColor,
  ),
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      color: dPrimarColor,
      fontSize: 32,
      fontFamily: "Poppins",
      fontWeight: FontWeight.w800,
    ),
    headlineMedium: TextStyle(
      color: dOnBackgroundColor,
      fontSize: 30,
      fontFamily: "Poppins",
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      color: dOnBackgroundColor,
      fontSize: 20,
      fontFamily: "Poppins",
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      color: dOnBackgroundColor,
      fontSize: 18,
      fontFamily: "Poppins",
      fontWeight: FontWeight.w500,
    ),
    bodyMedium: TextStyle(
      color: dOnBackgroundColor,
      fontSize: 12,
      fontFamily: "Poppins",
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      color: donContainerColor,
      fontSize: 15,
      fontFamily: "Poppins",
      fontWeight: FontWeight.w400,
    ),
    labelSmall: TextStyle(
      color: donContainerColor,
      fontSize: 10,
      fontFamily: "Poppins",
      fontWeight: FontWeight.w300,
    ),
    labelMedium: TextStyle(
      color: donContainerColor,
      fontSize: 12,
      fontFamily: "Poppins",
      fontWeight: FontWeight.w400,
    ),
  ),
);
