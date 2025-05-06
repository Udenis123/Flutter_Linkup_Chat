import 'package:flutter/material.dart';

MyTabBar(TabController tabController, BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: TabBar(
      controller: tabController,
      labelStyle: Theme.of(context).textTheme.bodyLarge,
      indicatorWeight: 5,
      indicatorSize: TabBarIndicatorSize.label,

      unselectedLabelStyle: Theme.of(context).textTheme.labelLarge,
      tabs: [Tab(text: 'Chats'), Tab(text: 'Groups'), Tab(text: 'Calls')],
    ),
  );
}
