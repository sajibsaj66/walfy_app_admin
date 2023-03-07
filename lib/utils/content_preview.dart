import 'package:flutter/material.dart';




showContentPreview(context,imageUrl) {
  showDialog(
    context: context,
    builder: (BuildContext context){
      return Dialog(
        child: Stack(
          children: <Widget>[
            Image(
              image: NetworkImage(imageUrl),
              fit: BoxFit.contain,
            ),

            Positioned(
              top: 20,
              right: 20,
              child: InkWell(
                  child: const CircleAvatar(
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.close, color: Colors.white,),
                ),
                onTap: (){
                  Navigator.pop(context);
                },
              ),
            )
          ],
        ),
      );
    }
  );
}