import 'package:chat_app/Pages/Auth/AuthPage.dart';
import 'package:chat_app/Pages/Chat/ChatPage.dart';
import 'package:chat_app/Pages/HomePage/HomePage.dart';
import 'package:chat_app/Pages/Welcome/WelcomePage.dart';
import 'package:chat_app/Profile/ProfilePage.dart';
import 'package:chat_app/Profile/UpdateProfile.dart';
import 'package:get/route_manager.dart';

var pagePath = [
  GetPage(
    name: "/authPage",
    page: () => Authpage(),
    transition: Transition.zoom,
    transitionDuration: const Duration(milliseconds: 1000),
  ),
  GetPage(
    name: "/homePage",
    page: () => const Homepage(),
    transition: Transition.rightToLeft,
    transitionDuration: const Duration(milliseconds: 1000),
  ),
  GetPage(
    name: "/chatPage",
    page: () => const ChatPage(),
    transition: Transition.downToUp,
    transitionDuration: const Duration(milliseconds: 500),
  ),
  GetPage(
    name: "/welcomePage",
    page: () => const Welcomepage(),
    transition: Transition.downToUp,
    transitionDuration: const Duration(milliseconds: 500),
  ),
  GetPage(
    name: "/profilePage",
    page: () => const Profilepage(),
    transition: Transition.rightToLeft,
    transitionDuration: const Duration(milliseconds: 500),
  ),
  GetPage(
    name: "/updateProfile",
    page: () => const UpdateProfile(),
    transition: Transition.rightToLeft,
    transitionDuration: const Duration(milliseconds: 500),
  ),
];
