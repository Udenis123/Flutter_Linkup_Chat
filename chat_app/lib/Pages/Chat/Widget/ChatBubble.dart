import 'package:flutter/material.dart';

class Chatbubble extends StatelessWidget {
  final String message;
  final bool isComming;
  final String time;
  final String status;
  final String imageUrl;

  const Chatbubble({
    super.key,
    required this.message,
    required this.isComming,
    required this.time,
    required this.status,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isComming ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.all(13),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width / 1.3,
            ),
            decoration: BoxDecoration(
              color: isComming?
                  Theme.of(context).colorScheme.primaryContainer
                  : Color(const Color.fromARGB(255, 9, 89, 155).value),
              borderRadius:
                  isComming
                      ? BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(20),
                      )
                      : BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(0),
                      ),
            ),
            child:
                imageUrl == ""
                    ? Text(message,style: TextStyle(fontSize: 17,fontFamily:"Poppins"),)
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network(imageUrl),
                        ),
                        Text(message),
                      ],
                    ),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment:
                isComming ? MainAxisAlignment.start : MainAxisAlignment.end,

            children: [
              isComming
                  ? Text(time, style: Theme.of(context).textTheme.labelMedium)
                  : Row(
                    children: [
                      Text(
                        time,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.done_all, color: Colors.grey, size: 15),
                    ],
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
