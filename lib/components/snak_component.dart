import 'package:flutter/material.dart';

void SnackComponent({required BuildContext context, required Color type,required String text}) {
  var snackBar = SnackBar(
      elevation: 6.0,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.symmetric(vertical: 80,horizontal: 20),
      backgroundColor: type,
      content: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme  
            .bodyMedium
            ?.copyWith(color: Colors.white),
      ));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //  Fluttertoast.showToast(
  //                                   msg: text,
  //                                   toastLength: Toast.LENGTH_SHORT,
  //                                   gravity: ToastGravity.BOTTOM,
  //                                   timeInSecForIosWeb: 1,
  //                                   backgroundColor: type,
  //                                   textColor: Colors.white,
  //                                   fontSize: 16.0);
}

class SnackbarTypeColor {
  static Color danger = Colors.red;
  static Color warning = Colors.yellow;
  static Color success = Colors.green;
}
