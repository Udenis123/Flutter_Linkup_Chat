import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/GroupController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class SelectedMembers extends StatelessWidget {
  const SelectedMembers({super.key});

  @override
  Widget build(BuildContext context) {
    GroupController groupController = Get.put(GroupController());
    return Obx(
      () => Row(
        children:
            groupController.groupMembers
                .map(
                  (e) => Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.all(10),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: CachedNetworkImage(
                            imageUrl:
                                e.profileImage ?? AssetsImage.defaultImage,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => CircularProgressIndicator(),
                            errorWidget:
                                (context, url, error) => Icon(Icons.error),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 5,
                        bottom: 5,
                        child: InkWell(
                          onTap: () {
                            groupController.groupMembers.remove(e);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
      ),
    );
  }
}
