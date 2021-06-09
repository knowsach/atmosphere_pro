import 'package:atsign_atmosphere_pro/desktop_routes/desktop_route_names.dart';
import 'package:atsign_atmosphere_pro/desktop_routes/desktop_routes.dart';
import 'package:atsign_atmosphere_pro/screens/common_widgets/custom_button.dart';
import 'package:atsign_atmosphere_pro/utils/colors.dart';
import 'package:atsign_atmosphere_pro/utils/images.dart';
import 'package:atsign_atmosphere_pro/utils/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:atsign_atmosphere_pro/services/size_config.dart';
import 'package:atsign_atmosphere_pro/utils/text_strings.dart'
    as pro_text_strings;

class DesktopEmptySender extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
                color: Color(0xffFCF9F9),
                borderRadius: BorderRadius.circular(80.toHeight)),
            height: 160.toHeight,
            width: 160.toHeight,
            child: Image.asset(ImageConstants.emptyTrustedSenders),
          ),
        ),
        SizedBox(height: 20.toHeight),
        Text(
          pro_text_strings.TextStrings().noTrustedSenders,
          style: CustomTextStyles.primaryBold18,
        ),
        SizedBox(height: 10.toHeight),
        Text(
          pro_text_strings.TextStrings().addTrustedSender,
          style: CustomTextStyles.secondaryRegular16,
        ),
        SizedBox(
          height: 25.toHeight,
        ),
        TextButton(
          onPressed: () {
            DesktopSetupRoutes.nested_push(
                DesktopRoutes.DESKTOP_TRUSTED_SENDER);
          },
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              return ColorConstants.orangeColor;
            },
          ), fixedSize: MaterialStateProperty.resolveWith<Size>(
            (Set<MaterialState> states) {
              return Size(160, 40);
            },
          )),
          child: Text(
            'Add',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
    ));
  }
}
