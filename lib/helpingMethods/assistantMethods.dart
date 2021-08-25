import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_uber_app/helpingMethods/requestAssistant.dart';
import 'package:flutter_uber_app/data/appData.dart';
import 'package:flutter_uber_app/models/address.dart';
import 'package:flutter_uber_app/models/allUsers.dart';
import 'package:flutter_uber_app/models/directionDetails.dart';
import 'package:flutter_uber_app/models/history.dart';
import 'package:flutter_uber_app/configMaps.dart';
import 'package:flutter_uber_app/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class AssistantMethods {
  static Future<String> searchCoordinateAddress(
      Position position, context) async {
    String placeAddress = "";
    String st1, st2, st3, st4;
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

    var response = await RequestAssistant.getRequest(url);

    if (response != "failed") {
      //placeAddress = response["results"][0]["formatted_address"];
      st1 = placeAddress =
          response["results"][0]["address_components"][0]["long_name"];
      st2 = placeAddress =
          response["results"][0]["address_components"][1]["long_name"];
      st3 = placeAddress =
          response["results"][0]["address_components"][2]["long_name"];
      st4 = placeAddress =
          response["results"][0]["address_components"][3]["long_name"];
      placeAddress = st1 + ", " + st2 + ", " + st3 + ", " + st4;

      Address userPickUpAddress = new Address();
      userPickUpAddress.longitude = position.longitude;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
    }

    return placeAddress;
  }

  static Future<DirectionDetails> obtainPlaceDirectionDetails(
      LatLng initialPosition, LatLng finalPosition) async {
    String directionUrl =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapKey";

    var res = await RequestAssistant.getRequest(directionUrl);

    if (res == "failed") {
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails();

    directionDetails.encodedPoints =
        res["routes"][0]["overview_polyline"]["points"];

    directionDetails.distanceText =
        res["routes"][0]["legs"][0]["distance"]["text"];
    directionDetails.distanceValue =
        res["routes"][0]["legs"][0]["distance"]["value"];

    directionDetails.durationText =
        res["routes"][0]["legs"][0]["duration"]["text"];
    directionDetails.durationValue =
        res["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetails;
  }

  static int calculateFares(DirectionDetails directionDetails) {
    //usd
    double timeTraveledFare =
        (directionDetails.durationValue / 60) * 0.20; //minutes
    double distanceTraveledFare =
        (directionDetails.distanceValue / 1000) * 0.20; //km

    double totalFare = timeTraveledFare + distanceTraveledFare;

    //1$ = 98.58 Serbian Dinar
    double total = totalFare * 98.58;
    return total.truncate();
  }

  static void getCurrentOnlineUserInfo() async {
    firebaseUser = FirebaseAuth.instance.currentUser;
    String userId = firebaseUser.uid;
    DatabaseReference reference =
        FirebaseDatabase.instance.reference().child("users").child(userId);

    reference.once().then((DataSnapshot dataSnapShot) {
      if (dataSnapShot.value != null) {
        userCurrentInfo = Users.fromSnapShot(dataSnapShot);
      }
    });
  }

  static double createRandomNumber(int num) {
    var random = Random();
    int radNumber = random.nextInt(num);
    return radNumber.toDouble();
  }

  static sendNotificationDriver(
      String token, context, String rideRequestId) async {
    var destination =
        Provider.of<AppData>(context, listen: false).dropOffLocation;
    Map<String, String> headerMap = {
      'Content-Type': 'application/json',
      'Authorization': serverToken,
    };
    Map notificationMap = {
      'body': 'DropOff Address, ${destination.placeName}',
      'title': 'New Ride Request'
    };
    Map dataMap = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': '1',
      'status': 'done',
      'ride_request_id': rideRequestId,
    };
    Map sendNotificationMap = {
      "notification": notificationMap,
      "data": dataMap,
      "priority": "high",
      "to": token,
    };

    try {
      var res = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: headerMap,
        body: jsonEncode(sendNotificationMap),
      );
    } catch (e) {
      print(e);
    }
  }

  static String formatTripDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    String formattedDate =
        "${DateFormat.MMMd().format(dateTime)}, ${DateFormat.y().format(dateTime)} - ${DateFormat.yM().format(dateTime)}"; //month, year

    return formattedDate;
  }

  static void retrieveHistoryInfo(context) {
    //retrieve and display trip history
    newRequestRef
        .orderByChild("rider_name")
        .once()
        .then((DataSnapshot dataSnapshot) {
      if (dataSnapshot.value != null) {
        //updating total number of trip counts to provider
        Map<dynamic, dynamic> keys = dataSnapshot.value;
        int tripCounter = keys.length;
        Provider.of<AppData>(context, listen: false)
            .updateTripsCounter(tripCounter);

        //updating trip keys to provider
        List<String> tripHistoryKeys = [];
        keys.forEach((key, value) {
          tripHistoryKeys.add(key);
        });

        Provider.of<AppData>(context, listen: false)
            .updateTripKeys(tripHistoryKeys);
        obtainTripRequestHistoryData(context);
      }
    });
  }

  static void obtainTripRequestHistoryData(context) {
    var keys = Provider.of<AppData>(context, listen: false).tripHistoryKeys;
    for (String key in keys) {
      newRequestRef.child(key).once().then((DataSnapshot snapshot) {
        if (snapshot.value != null) {
          newRequestRef
              .child(key)
              .child("rider_name")
              .once()
              .then((DataSnapshot dSnap) {
            String name = dSnap.value.toString();
            if (name == userCurrentInfo.name) {
              //getting keys by the name
              var history = History.fromSnapshot(snapshot);
              Provider.of<AppData>(context, listen: false)
                  .updateTripHistoryData(history);
            }
          });
        }
      });
    }
  }
}
