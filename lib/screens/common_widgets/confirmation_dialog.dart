import 'package:at_common_flutter/services/size_config.dart';
import 'package:flutter/material.dart';

class ConfirmationDialog extends StatefulWidget {
  final String title;
  final Function onConfirmation;
  ConfirmationDialog(this.title, this.onConfirmation);

  @override
  _ConfirmationDialogState createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300.toWidth,
      padding: EdgeInsets.all(15.toFont),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            SizedBox(
              height: 10.toHeight,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await widget.onConfirmation();
                    },
                    child: Text('Yes', style: TextStyle(fontSize: 16.toFont))),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child:
                        Text('Cancel', style: TextStyle(fontSize: 16.toFont)))
              ],
            )
          ],
        ),
      ),
    );
  }
}
