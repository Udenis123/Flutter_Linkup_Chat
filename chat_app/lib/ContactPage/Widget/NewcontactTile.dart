
import 'package:flutter/material.dart';

class NewContantTile extends StatelessWidget {
      final String btnName;
    final IconData icon;
    final VoidCallback ontap;
  const NewContantTile({super.key, required this.btnName, required this.icon, required this.ontap});

  @override
  Widget build(BuildContext context) {

    

    return InkWell(
      onTap: (){

      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20)
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              child: Icon(icon,size: 30,),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(100),
              ),     
            ),
            SizedBox(width: 20,),
            Text(btnName,style: Theme.of(context).textTheme.bodyLarge,),
            
            
          ],
        ),
      ),
    );
  }
}