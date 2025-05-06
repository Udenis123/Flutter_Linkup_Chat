import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Config/Strings.dart';
import 'package:chat_app/Controller/ContactController.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Controller/StatusController.dart';
import 'package:chat_app/Groups/GroupPage.dart';
import 'package:chat_app/Pages/CallList.dart/CallList.dart';
import 'package:chat_app/Pages/HomePage/Widget/ChatsList.dart';
import 'package:chat_app/Pages/HomePage/Widget/TabBar.dart';
import 'package:chat_app/Pages/ProfilePage.dart/ProfilePage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with TickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    int initialTab = 0;
    if (Get.arguments != null && Get.arguments['tabIndex'] != null) {
      initialTab = Get.arguments['tabIndex'];
    }
    tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    ProfileController profileController = Get.put(ProfileController());
    Get.put(StatusController(), permanent: true);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(
          AppString.appName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        leading: Image.asset(AssetsImage.appIcon, width: 10),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
          IconButton(
            onPressed: () async {
              await profileController.getUserDetails();
              Get.to(() => Profilepage());
            },
            icon: Icon(Icons.more_vert),
          ),
        ],
        bottom: MyTabBar(tabController, context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed("/contactPage");
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          FontAwesomeIcons.pen,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),

      body: TabBarView(
        controller: tabController,
        children: [ChatsList(), GroupPage(), CallListPage()],
      ),
    );
  }
}
