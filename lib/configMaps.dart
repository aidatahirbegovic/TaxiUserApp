import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_uber_app/models/allUsers.dart';
import 'package:easy_localization/src/public_ext.dart';

String mapKey = "";

User firebaseUser;

Users userCurrentInfo;

int driverRequestTimeOut = 40; //if driver doesnt respond in 40 seconds
String statusRide = "";
String rideStatus = 'driver_coming'.tr();
String carDetails = "";
String driverName = "";
String driverPhone = "";

double starCounter = 0.0;
String title = "";

String serverToken =
    "";
