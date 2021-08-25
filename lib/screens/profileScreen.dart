import 'package:flutter/material.dart';
import 'package:flutter_uber_app/screens/mainscreen.dart';
import 'package:flutter_uber_app/configMaps.dart';
import 'package:easy_localization/src/public_ext.dart';

class ProfileTabPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userCurrentInfo.name,
              style: TextStyle(
                fontSize: 65.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Signatra',
              ),
            ),

            SizedBox(
              height: 20,
              width: 200,
              child: Divider(
                color: Colors.white,
              ),
            ),

            SizedBox(
              height: 40.0,
            ),

            InfoCard(
              text: userCurrentInfo.phone,
              icon: Icons.phone,
              onPressed: () async {
                print("this is phone.");
              },
            ),

            InfoCard(
              text: userCurrentInfo.email,
              icon: Icons.email,
              onPressed: () async {
                print("this is email.");
              },
            ),

            //go back button
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, MainScreen.idScreen, (route) => false);
              },
              style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(10.0),
              )),
              child: Text(
                'go_back'.tr(),
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final Function onPressed;

  InfoCard({
    this.text,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        color: Colors.white,
        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
        child: ListTile(
          leading: Icon(
            icon,
            color: Colors.black87,
          ),
          title: Text(
            text,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16.0,
              fontFamily: 'Brand Bold',
            ),
          ),
        ),
      ),
    );
  }
}
