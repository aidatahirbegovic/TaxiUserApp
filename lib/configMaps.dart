import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_uber_app/models/allUsers.dart';
import 'package:easy_localization/src/public_ext.dart';

String mapKey = "AIzaSyAX0e4XXlkniZfsxvSzCJCividSUlxRw_U";

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
    "key=AAAAtxMbMeA:APA91bGd7RBIknbv4NCSv9xMd6AJ-ti0Rr_jd6dxrTyHONlXvf299S4E9IPRvcRgTl5GkzzB2JWyS2utCB60fc_rT3Znft9PsJMTPUzftQRBVQA9ImVTL7iUxcGLBt09-dSu5EWhsZ3W";
