import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_uber_app/configMaps.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:easy_localization/src/public_ext.dart';

class RatingScreen extends StatefulWidget {
  final String driverId;

  RatingScreen({this.driverId});

  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.all(5.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 22.0,
              ),
              Text('rate_driver'.tr(),
                  style: TextStyle(
                      fontSize: 40.0,
                      fontFamily: "Brand Bold",
                      color: Colors.black)),
              SizedBox(
                height: 22.0,
              ),
              Divider(
                height: 2.0,
                thickness: 2.0,
              ),
              SizedBox(
                height: 16.0,
              ),
              SmoothStarRating(
                rating: starCounter,
                color: Colors.yellowAccent,
                allowHalfRating: false,
                starCount: 5,
                size: 45,
                onRated: (value) {
                  starCounter = value;
                  if (starCounter == 1) {
                    setState(() {
                      title = 'very_bad'.tr();
                    });
                  }
                  if (starCounter == 2) {
                    setState(() {
                      title = 'bad'.tr();
                    });
                  }
                  if (starCounter == 3) {
                    setState(() {
                      title = 'good'.tr();
                    });
                  }
                  if (starCounter == 4) {
                    setState(() {
                      title = 'very_good'.tr();
                    });
                  }
                  if (starCounter == 5) {
                    setState(() {
                      title = 'excellent'.tr();
                    });
                  }
                },
              ),
              SizedBox(
                height: 14.0,
              ),
              Text(title,
                  style: TextStyle(
                      fontSize: 55.0,
                      fontFamily: "Signatra",
                      color: Colors.yellowAccent)),
              SizedBox(
                height: 16.0,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    DatabaseReference driverRatingRef = FirebaseDatabase
                        .instance
                        .reference()
                        .child("drivers")
                        .child(widget.driverId)
                        .child("ratings");
                    driverRatingRef.once().then((DataSnapshot snap) {
                      if (snap.value != null) {
                        double oldRatings = double.parse(snap.value.toString());
                        double addRatings = oldRatings + starCounter;
                        double averageRatings = addRatings / 2;
                        driverRatingRef.set(averageRatings.toString());
                      } else {
                        driverRatingRef.set(
                            starCounter.toString()); //ukoliko je prva ocena
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'submit'.tr(),
                          style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 30.0,
              )
            ],
          ),
        ),
      ),
    );
  }
}
