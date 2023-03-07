import 'package:admin/utils/styles.dart';
import 'package:flutter/material.dart';

void openDialog(context, title, message) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          contentPadding: const EdgeInsets.all(50),
          elevation: 0,
          children: <Widget>[
            Text(title,
                
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(
              height: 10,
            ),
            Text(message,
                
                style: TextStyle(
                    color: Colors.grey[900],
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(
              height: 30,
            ),
            Center(
              child: TextButton(
                style: buttonStyle(Colors.deepPurpleAccent),
                child: const Text(
                  'Okay',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            )
          ],
        );
      });
}
