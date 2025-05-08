import 'package:chat_app/ContactPage/ContactPage.dart';
import 'package:chat_app/Pages/Auth/AuthPage.dart';
import 'package:chat_app/Pages/Chat/ChatPage.dart';
import 'package:chat_app/Pages/HomePage/HomePage.dart';
import 'package:chat_app/Pages/Welcome/WelcomePage.dart';
import 'package:chat_app/UserProfile/ProfilePage.dart';
import 'package:chat_app/UserProfile/UpdateProfile.dart';
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
    transition: Transition.noTransition,
    transitionDuration: const Duration(milliseconds: 1000),
  ),
  // GetPage(
  //   name: "/chatPage",
  //   page: () => const ChatPage(),
  //   transition: Transition.downToUp,
  //   transitionDuration: const Duration(milliseconds: 500),
  // ),
  GetPage(
    name: "/welcomePage",
    page: () => const Welcomepage(),
    transition: Transition.downToUp,
    transitionDuration: const Duration(milliseconds: 500),
  ),
  // GetPage(
  //   name: "/profilePage",
  //   page: () => const UserProfilepage(),
  //   transition: Transition.rightToLeft,
  //   transitionDuration: const Duration(milliseconds: 500),
  // ),
  GetPage(
    name: "/contactPage",
    page: () => const Contactpage(),
    transition: Transition.downToUp,
    transitionDuration: const Duration(milliseconds: 500),
  ),
];
