import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

successMessage(String message) {
  return Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.CENTER,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.green,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

errorMessage(String message) {
  return Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.CENTER,
    timeInSecForIosWeb: 1,
    backgroundColor: const Color.fromARGB(255, 241, 84, 73),
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

warningMessage(String message) {
  return Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.CENTER,
    timeInSecForIosWeb: 1,
    backgroundColor: const Color.fromARGB(255, 194, 143, 4),
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
