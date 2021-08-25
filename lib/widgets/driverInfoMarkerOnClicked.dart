import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:easy_localization/src/public_ext.dart';

import '../constants.dart';

class DriverMarkerClickedDialog extends StatelessWidget {
  DriverMarkerClickedDialog(
      {this.name,
      this.phone,
      this.ratings,
      this.carModel,
      this.carColor,
      this.carNumber,
      this.function,
      this.imageUrl});

  final name;
  final phone;
  final carModel;
  final carNumber;
  final carColor;
  final ratings;
  final function;
  final imageUrl;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      insetPadding: EdgeInsets.only(bottom: 120.0, top: 50.0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            'driver_info'.tr(),
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Colors.yellowAccent),
          ),
          SizedBox(
            width: 30.0,
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Icon(
              Icons.cancel,
              color: Colors.yellowAccent,
              size: 40.0,
            ),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.yellowAccent,
                child: CircleAvatar(
                  radius: 39,
                  //backgroundImage: AssetImage('images/user_icon.png'),
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : AssetImage('images/user_icon.png'),
                ),
              ),
              SizedBox(
                width: 15.0,
              ),
              SmoothStarRating(
                rating: ratings == null ? 0 : double.parse(ratings),
                color: Colors.yellowAccent,
                allowHalfRating: false,
                starCount: 5,
                size: 25,
              ),
            ],
          ),
          SizedBox(
            height: 18.0,
          ),
          Text(
            name == null ? 'name'.tr() : name,
            style: TextStyle(
                fontSize: 18.0,
                fontFamily: "Brand Bold",
                color: Colors.yellowAccent),
          ),
          SizedBox(
            height: 18.0,
          ),
          Text(
            phone == null ? 'phone'.tr() : phone,
            style: TextStyle(
                fontSize: 18.0,
                fontFamily: "Brand Bold",
                color: Colors.yellowAccent),
          ),
          SizedBox(
            height: 18.0,
          ),
          Text(
            carModel == null ? 'car model' : carModel,
            style: TextStyle(fontSize: 16.0, color: Colors.yellowAccent),
          ),
          SizedBox(
            height: 18.0,
          ),
          Text(
            carNumber == null ? 'car number' : carNumber,
            style: TextStyle(fontSize: 16.0, color: Colors.yellowAccent),
          ),
          SizedBox(
            height: 18.0,
          ),
          Text(
            carColor == null ? 'car color' : carColor + ' boja',
            style: TextStyle(fontSize: 16.0, color: Colors.yellowAccent),
          ),
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            child: Text('call'.tr()),
            onPressed: function,
            style: ElevatedButton.styleFrom(
              primary: Colors.yellowAccent,
              textStyle: TextStyle(
                  fontSize: 15.0,
                  fontFamily: "Brand Bold",
                  color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}
