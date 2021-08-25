import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_uber_app/screens/changePassword.dart';
import 'package:flutter_uber_app/screens/collectFareScreen.dart';
import 'package:flutter_uber_app/screens/historyScreen.dart';
import 'package:flutter_uber_app/screens/loginScreen.dart';
import 'package:flutter_uber_app/screens/profileScreen.dart';
import 'package:flutter_uber_app/screens/ratingScreen.dart';
import 'package:flutter_uber_app/screens/searchScreen.dart';
import 'package:flutter_uber_app/screens/updateInfo.dart';
import 'package:flutter_uber_app/widgets/divider.dart';
import 'package:flutter_uber_app/widgets/drawerGestureDetector.dart';
import 'package:flutter_uber_app/widgets/driverInfoMarkerOnClicked.dart';
import 'package:flutter_uber_app/widgets/driverListContainer.dart';
import 'package:flutter_uber_app/widgets/noDriverDialog.dart';
import 'package:flutter_uber_app/widgets/progressDialog.dart';
import 'package:flutter_uber_app/helpingMethods/assistantMethods.dart';
import 'package:flutter_uber_app/helpingMethods/geofireAssistant.dart';
import 'package:flutter_uber_app/data/appData.dart';
import 'package:flutter_uber_app/models/directionDetails.dart';
import 'package:flutter_uber_app/models/nearbyAvailableDrivers.dart';
import 'package:flutter_uber_app/configMaps.dart';
import 'package:flutter_uber_app/constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/src/public_ext.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "mainScreen";

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DirectionDetails tripDirectionDetails;

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double requestRideDetailsContainerHeight = 0;
  double searchContainerHeight = 250.0;
  double driverDetailsContainerHeight = 0;
  double markerDriverHeight = 0;

  bool drawerOpen = true;
  bool nearbyAvailableDriverKeysLoaded = false;

  DatabaseReference rideRequestRef;

  BitmapDescriptor nearbyIcon;

  List<NearbyAvailableDrivers> availableDrivers;

  String state = "normal";
  String paymentMethod;

  StreamSubscription<Event> rideStreamSubscription;

  bool isRequestingPositionDetails = false;
  BitmapDescriptor pinDestinationIcon;

  Future<void> currentOnlineUser() async {
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  @override
  void initState() {
    super.initState();
    currentOnlineUser();
  }

  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.reference().child("Ride Requests").push();

    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocMap = {
      "latitude": pickUp.latitude.toString(),
      "longitude": pickUp.longitude.toString(),
    };

    Map dropOffLocMap = {
      "latitude": dropOff.latitude.toString(),
      "longitude": dropOff.longitude.toString(),
    };

    Map rideInfoMap = {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpLocMap,
      "dropoff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_id": userCurrentInfo.id,
      "rider_name": userCurrentInfo.name,
      "rider_phone": userCurrentInfo.phone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName,
    };

    rideRequestRef.set(rideInfoMap);

    rideStreamSubscription = rideRequestRef.onValue.listen((event) async {
      if (event.snapshot.value == null) {
        return;
      }
      if (event.snapshot.value["car_details"] != null) {
        setState(() {
          carDetails = event.snapshot.value["car_details"].toString();
        });
      }
      if (event.snapshot.value["driver_name"] != null) {
        setState(() {
          driverName = event.snapshot.value["driver_name"].toString();
        });
      }
      if (event.snapshot.value["driver_phone"] != null) {
        setState(() {
          driverPhone = event.snapshot.value["driver_phone"].toString();
        });
      }
      if (event.snapshot.value["driver_location"] != null) {
        double driverLat = double.parse(
            event.snapshot.value["driver_location"]["latitude"].toString());
        double driverLng = double.parse(
            event.snapshot.value["driver_location"]["longitude"].toString());
        LatLng driverCurrentLocation = LatLng(driverLat, driverLng);
        if (statusRide == "accepted") {
          updateRideTimeToPickUpLocation(driverCurrentLocation);
        } else if (statusRide == "onride") {
          updateRideTimeToDropOffLocation(driverCurrentLocation);
        } else if (statusRide == "arrived") {
          setState(() {
            rideStatus = 'driver_arrived'.tr();
          });
        }
      }

      if (event.snapshot.value["status"] != null) {
        statusRide = event.snapshot.value["status"].toString();
      }
      if (statusRide == "accepted") {
        displayDriverDetailsContainer();
        Geofire.stopListener();
        deleteGeofireMarkers();
      }

      if (statusRide == "ended") {
        if (event.snapshot.value["fares"] != null) {
          int fare = int.parse(event.snapshot.value["fares"].toString());
          var res = await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => CollectFareScreen(fareAmount: fare)));
          // var res = await showDialog(
          //   context: context,
          //   barrierDismissible: false,
          //   builder: (BuildContext context) => CollectFareDialog(
          //     paymentMethod: "cash",
          //     fareAmount: fare,
          //   ),
          // );
          String driverId = "";
          if (res[1] != null) {
            rideRequestRef.child("payment_method").set(res[1]);
          }
          if (res[0] == "close") {
            if (event.snapshot.value["driver_id"] != null) {
              driverId = event.snapshot.value["driver_id"].toString();
            }
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => RatingScreen(driverId: driverId)));

            rideRequestRef.onDisconnect();
            rideRequestRef.remove();
            rideRequestRef = null;
            rideStreamSubscription.cancel();
            rideStreamSubscription = null;
            resetApp();
          }
        }
      }
    });
  }

  void deleteGeofireMarkers() {
    setState(() {
      markersSet
          .removeWhere((element) => element.markerId.value.contains("driver"));
    });
  }

  void updateRideTimeToPickUpLocation(LatLng driverCurrentLocation) async {
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails = true;

      var positionUserLatLng =
          LatLng(currentPosition.latitude, currentPosition.longitude);
      var details = await AssistantMethods.obtainPlaceDirectionDetails(
          driverCurrentLocation, positionUserLatLng);
      if (details == null) {
        return;
      }
      setState(() {
        rideStatus = 'driver_coming_in'.tr() + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }

  void updateRideTimeToDropOffLocation(LatLng driverCurrentLocation) async {
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails = true;

      var dropOff =
          Provider.of<AppData>(context, listen: false).dropOffLocation;
      var dropOffLatLng = LatLng(dropOff.latitude, dropOff.longitude);

      var details = await AssistantMethods.obtainPlaceDirectionDetails(
          driverCurrentLocation, dropOffLatLng);
      if (details == null) {
        return;
      }
      setState(() {
        rideStatus = 'going_destination'.tr() + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }

  void cancelRideRequest() {
    rideRequestRef.remove();

    setState(() {
      state = "normal";
    });
  }

  void displayDriverDetailsContainer() {
    setState(() {
      requestRideDetailsContainerHeight = 0.0;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingOfMap = 290.0;
      driverDetailsContainerHeight = 310.0;
    });
  }

  void displayRequestContainer() {
    setState(() {
      markerDriverHeight = 0;
      requestRideDetailsContainerHeight = 250.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 250.0;
      drawerOpen = true;
    });

    saveRideRequest();
  }

  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 250.0;
      rideDetailsContainerHeight = 0;
      requestRideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 250.0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();

      statusRide = "";
      driverName = "";
      driverPhone = "";
      carDetails = "";
      rideStatus = 'driver_coming'.tr();
      driverDetailsContainerHeight = 0.0;
    });

    locatePosition();
  }

  void displayRideDetailsContainer() async {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 250.0;
      markerDriverHeight = 300.0;
      bottomPaddingOfMap = 250.0;
      drawerOpen = false;
    });
  }

  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
        new CameraPosition(target: latLngPosition, zoom: 14.0);
    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address =
        await AssistantMethods.searchCoordinateAddress(position, context);
    print("This is your Address:: " + address);

    initGeoFireListener();
    //nedostaje deo

    AssistantMethods.retrieveHistoryInfo(context);
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        color: Colors.black87,
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165.0,
                color: Colors.black87,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.black87),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.yellowAccent,
                        child: CircleAvatar(
                          radius: 39,
                          backgroundImage: userCurrentInfo != null
                              ? NetworkImage(userCurrentInfo.imageUrl)
                              : AssetImage('images/user_icon.png'),
                        ),
                      ),
                      SizedBox(
                        width: 16.0,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userCurrentInfo != null
                                ? userCurrentInfo.name
                                : 'name'.tr(),
                            style: TextStyle(
                                fontSize: 16.0,
                                fontFamily: "Brand Bold",
                                color: Colors.yellowAccent),
                          ),
                          SizedBox(
                            height: 6.0,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              DividerWidget(),
              SizedBox(
                height: 12.0,
              ),

              //Drawer Body Controllers
              DrawerGestureDetector(
                icon: Icons.history,
                text: 'history'.tr(),
                function: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => HistoryScreen()));
                },
              ),
              DrawerGestureDetector(
                icon: Icons.person,
                text: 'visit_profile'.tr(),
                function: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProfileTabPage()));
                },
              ),
              DrawerGestureDetector(
                icon: Icons.update,
                text: 'update_info'.tr(),
                function: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => UpdateInfo()));
                },
              ),
              DrawerGestureDetector(
                icon: Icons.password_outlined,
                text: "Change password",
                function: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChangePassword()));
                },
              ),
              DrawerGestureDetector(
                icon: Icons.logout,
                text: 'sign_out'.tr(),
                function: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              locatePosition();
              setState(() {
                bottomPaddingOfMap = 300.0;
              });
            },
          ),

          //HamburgerButton for Drawer
          Positioned(
            top: 38.0,
            left: 22.0,
            child: GestureDetector(
              onTap: () {
                if (drawerOpen) {
                  scaffoldKey.currentState.openDrawer();
                } else {
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6.0,
                      spreadRadius: 0.5,
                      offset: Offset(
                        0.7,
                        0.7,
                      ),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  child: Icon(
                    (drawerOpen) ? Icons.menu : Icons.close,
                    color: Colors.yellowAccent,
                  ),
                  radius: 20.0,
                ),
              ),
            ),
          ),

          //Search UI
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellowAccent,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.0),
                      Text(
                        'hi'.tr(),
                        style: TextStyle(
                            fontSize: 12.0, color: Colors.yellowAccent),
                      ),
                      Text(
                        'where'.tr(),
                        style: TextStyle(
                            fontSize: 20.0,
                            fontFamily: "Brand Bold",
                            color: Colors.yellowAccent),
                      ),
                      SizedBox(height: 20.0),
                      GestureDetector(
                        onTap: () async {
                          var res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchScreen()));

                          if (res == "obtainDirection") {
                            displayRideDetailsContainer();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.yellowAccent,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.black,
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                Text(
                                  'search_dropOff'.tr(),
                                  style: TextStyle(color: Colors.black),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24.0,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.yellowAccent,
                            size: 30.0,
                          ),
                          SizedBox(
                            width: 12.0,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Provider.of<AppData>(context)
                                              .pickUpLocation !=
                                          null
                                      ? Provider.of<AppData>(context)
                                          .pickUpLocation
                                          .placeName
                                      : 'add_location'.tr(),
                                  style: TextStyle(
                                    color: Colors.yellowAccent,
                                  ),
                                ),
                                SizedBox(
                                  height: 4.0,
                                ),
                                Text(
                                  'your_location'.tr(),
                                  style: TextStyle(
                                      color: Colors.yellowAccent,
                                      fontSize: 12.0),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      DividerWidget(),
                      SizedBox(
                        height: 16.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //list of available drivers 3
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: markerDriverHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellowAccent,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount:
                      GeoFireAssistant.nearbyAvailableDriversList.length <= 3
                          ? GeoFireAssistant.nearbyAvailableDriversList.length
                          : 3,
                  itemBuilder: (BuildContext context, int index) {
                    return DriverListContainer(
                      tripDirectionDetails: tripDirectionDetails,
                      driverCurrentInfo: GeoFireAssistant
                          .nearbyAvailableDriversList[index].key,
                      function: () => driverInfo(
                          GeoFireAssistant.nearbyAvailableDriversList[index]),
                      // function: () => callingDriver(
                      //     GeoFireAssistant.nearbyAvailableDriversList[index]),
                    );
                  },
                ),
              ),
            ),
          ),

          //Ride Details
          // Positioned(
          //   bottom: 0.0,
          //   left: 0.0,
          //   right: 0.0,
          //   child: AnimatedSize(
          //     curve: Curves.bounceIn,
          //     duration: new Duration(milliseconds: 160),
          //     child: Container(
          //       height: 0,
          //       decoration: BoxDecoration(
          //           color: Colors.black,
          //           borderRadius: BorderRadius.only(
          //               topLeft: Radius.circular(16.0),
          //               topRight: Radius.circular(16.0)),
          //           boxShadow: [
          //             BoxShadow(
          //               color: Colors.black,
          //               blurRadius: 16.0,
          //               spreadRadius: 0.5,
          //               offset: Offset(0.7, 0.7),
          //             ),
          //           ]),
          //       child: Padding(
          //         padding: const EdgeInsets.symmetric(vertical: 17.0),
          //         child: Column(
          //           children: [
          //             Container(
          //               width: double.infinity,
          //               color: Colors.yellowAccent,
          //               child: Padding(
          //                 padding: EdgeInsets.symmetric(horizontal: 16.0),
          //                 child: Row(
          //                   children: [
          //                     Image.asset(
          //                       "images/taxi.png",
          //                       height: 70.0,
          //                       width: 80.0,
          //                     ),
          //                     SizedBox(
          //                       width: 16.0,
          //                     ),
          //                     Column(
          //                       crossAxisAlignment: CrossAxisAlignment.start,
          //                       children: [
          //                         Text(
          //                           'car'.tr(),
          //                           style: TextStyle(
          //                               fontSize: 18.0,
          //                               fontFamily: "Brand Bold",
          //                               color: Colors.black),
          //                         ),
          //                         Text(
          //                           ((tripDirectionDetails != null)
          //                               ? tripDirectionDetails.distanceText
          //                               : ''),
          //                           style: TextStyle(
          //                               fontSize: 16.0, color: Colors.black),
          //                         ),
          //                       ],
          //                     ),
          //                     Expanded(child: Container()),
          //                     Text(
          //                       ((tripDirectionDetails != null)
          //                           ? '\RS: ${AssistantMethods.calculateFares(tripDirectionDetails)}'
          //                           : ''),
          //                       style: TextStyle(
          //                           fontFamily: "Brand Bold",
          //                           fontSize: 16.0,
          //                           color: Colors.black),
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //             ),
          //             SizedBox(
          //               height: 20.0,
          //             ),
          //             Padding(
          //               padding: EdgeInsets.symmetric(horizontal: 20.0),
          //               child: Row(
          //                 children: [
          //                   Icon(
          //                     FontAwesomeIcons.moneyCheckAlt,
          //                     size: 18.0,
          //                     color: Colors.yellowAccent,
          //                   ),
          //                   SizedBox(
          //                     width: 16.0,
          //                   ),
          //                   Text(
          //                     'cash'.tr(),
          //                     style: TextStyle(color: Colors.yellowAccent),
          //                   ),
          //                   SizedBox(
          //                     width: 6.0,
          //                   ),
          //                   Icon(
          //                     Icons.keyboard_arrow_down,
          //                     color: Colors.yellowAccent,
          //                     size: 16.0,
          //                   ),
          //                 ],
          //               ),
          //             ),
          //             Padding(padding: EdgeInsets.only(bottom: 15.0)),
          //             SizedBox(
          //               width: 20.0,
          //             ),
          //             Padding(
          //               padding: EdgeInsets.symmetric(horizontal: 16.0),
          //               child: ElevatedButton(
          //                 style: ElevatedButton.styleFrom(
          //                   padding: EdgeInsets.all(10.0),
          //                   primary: Colors.yellowAccent,
          //                   textStyle: TextStyle(
          //                       fontSize: 18.0,
          //                       fontFamily: "Brand Bold",
          //                       color: Theme.of(context).accentColor),
          //                 ),
          //                 onPressed: () {
          //                   setState(() {
          //                     state = "requesting";
          //                   });
          //                   displayRequestContainer();
          //                   availableDrivers = GeoFireAssistant
          //                       .nearbyAvailableDriversList; //sending notification to the nearest driver
          //                   //searchNearestDriver();
          //                 },
          //                 child: Padding(
          //                   padding: EdgeInsets.all(17.0),
          //                   child: Row(
          //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //                     children: [
          //                       Text(
          //                         "Request",
          //                         style: TextStyle(
          //                             fontSize: 20.0,
          //                             fontWeight: FontWeight.bold,
          //                             color: Colors.black),
          //                       ),
          //                       Icon(
          //                         FontAwesomeIcons.taxi,
          //                         color: Colors.black,
          //                         size: 26.0,
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          //request or cancel ui
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0)),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                      spreadRadius: 0.5,
                      blurRadius: 16.0,
                      color: Colors.yellowAccent,
                      offset: Offset(0.7, 0.7))
                ],
              ),
              height: requestRideDetailsContainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 12.0,
                    ),
                    DefaultTextStyle(
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 25.0,
                        fontWeight: FontWeight.w900,
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'waiting_response'.tr(),
                          ),
                          TypewriterAnimatedText(
                            'please_wait'.tr(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    GestureDetector(
                      onTap: () {
                        cancelRideRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26.0),
                          border:
                              Border.all(width: 2.0, color: Colors.grey[300]),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 26.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Container(
                      width: double.infinity,
                      child: Text(
                        'cancel_ride'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          //display assigned driver info
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0)),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      spreadRadius: 0.5,
                      blurRadius: 16.0,
                      color: Colors.black54,
                      offset: Offset(0.7, 0.7))
                ],
              ),
              height: driverDetailsContainerHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 6.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          rideStatus,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20.0, fontFamily: "Brand Bold"),
                        ),
                      ],
                    ),
                    // SizedBox(
                    //   height: 22.0,
                    // ),
                    // Divider(
                    //   height: 2.0,
                    //   thickness: 2.0,
                    // ),
                    // Text(carDetails,
                    //     style: TextStyle(
                    //       color: Colors.grey,
                    //     )),
                    // Text(driverName,
                    //     style: TextStyle(
                    //       color: Colors.grey,
                    //     )),
                    // Divider(
                    //   height: 2.0,
                    //   thickness: 2.0,
                    // ),
                    SizedBox(
                      height: 22.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(10.0),
                              primary: Colors.pink,
                              textStyle: TextStyle(
                                  fontSize: 18.0,
                                  fontFamily: "Brand Bold",
                                  color: Theme.of(context).accentColor),
                            ),
                            onPressed: () async {
                              //calling driver
                              launch(('tel://$driverPhone}'));
                            },
                            child: Padding(
                              padding: EdgeInsets.all(17.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    'call_driver'.tr(),
                                    style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Icon(
                                    Icons.call,
                                    color: Colors.white,
                                    size: 26.0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BitmapDescriptor dropOffIcon;
  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: 'please_wait'.tr(),
            ));

    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLatLng, dropOffLatLng);

    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.pop(context);

    print("This is Encoded Points ::");
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult =
        polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();

    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.black,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow:
          InfoWindow(title: initialPos.placeName, snippet: "my location"),
      position: pickUpLatLng,
      markerId: MarkerId("pickUpId"),
    );

    // Marker dropOffLocMarker = Marker(
    //   icon: await BitmapDescriptor.fromAssetImage(
    //       createLocalImageConfiguration(context), 'images/destination.png'),
    //   infoWindow: InfoWindow(title: finalPos.placeName, snippet: "dropOff"),
    //   position: dropOffLatLng,
    //   markerId: MarkerId("dropOffId"),
    // );

    await BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(32, 32)), 'images/destination.png')
        .then((onValue) {
      setState(() {
        dropOffIcon = onValue;
      });
    });

    Marker dropOffLocMarker = Marker(
      icon: dropOffIcon,
      infoWindow: InfoWindow(title: finalPos.placeName, snippet: "dropOff"),
      position: dropOffLatLng,
      markerId: MarkerId("dropOffId"),
    );

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
      fillColor: Colors.blueAccent,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.blueAccent,
      circleId: CircleId("pickUpId"),
    );

    Circle dropOffLocCircle = Circle(
      fillColor: Colors.deepPurple,
      center: dropOffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.purple,
      circleId: CircleId("dropOffId"),
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  void initGeoFireListener() {
    Geofire.initialize("availableDrivers");

    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 10)
        .listen((map) {
      //distance 5km
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered: //when driver becomes online
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.nearbyAvailableDriversList
                .add(nearbyAvailableDrivers);
            if (nearbyAvailableDriverKeysLoaded == true) {
              updateAvailableDriversOnMap();
            }
            break;

          case Geofire.onKeyExited: //when driver becomes offline
            GeoFireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.updateDriverNearbyLocation(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();
            // Update your key's location
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            // All Intial Data is loaded
            break;
        }
      }
    });
  }

  void updateAvailableDriversOnMap() {
    if (this.mounted) {
      setState(() {
        markersSet.clear();
      });
    }
    Set<Marker> tMarkers = Set<Marker>();
    for (NearbyAvailableDrivers driver
        in GeoFireAssistant.nearbyAvailableDriversList) {
      LatLng driverAvailablePosition =
          LatLng(driver.latitude, driver.longitude);

      Marker marker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverAvailablePosition,
        icon: nearbyIcon,
        rotation: AssistantMethods.createRandomNumber(360),
        onTap: () => driverInfo(driver),
      );

      tMarkers.add(marker);
    }
    if (this.mounted) {
      setState(() {
        markersSet = tMarkers;
      });
    }
  }

  Future<void> driverInfo(NearbyAvailableDrivers driver) async {
    print(driver.key);
    String name;

    String phone;

    String carModel;

    String carColor;

    String carNumber;

    String ratings;

    String imageUrl;

    await driversRef.child(driver.key).once().then((DataSnapshot snapshot) {
      setState(() {
        if (snapshot.value != null) {
          name = snapshot.value['name'];
          phone = snapshot.value['phone'];
          ratings = snapshot.value['ratings'];
          carModel = snapshot.value['car_details']['car_model'];
          carColor = snapshot.value['car_details']['car_color'];
          carNumber = snapshot.value['car_details']['car_number'];
          imageUrl = snapshot.value['driverImageUrl'];
        }
      });
    });

    showDialog(
      context: context,
      builder: (context) {
        return DriverMarkerClickedDialog(
          name: name,
          phone: phone,
          ratings: ratings,
          carModel: carModel,
          carColor: carColor,
          carNumber: carNumber,
          function: () => callingDriver(driver),
          imageUrl: imageUrl,
        );
      },
    );
  }

  void createIconMarker() {
    if (nearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, "images/car_android.png")
          .then((value) {
        nearbyIcon = value;
      });
    }
  }

  void noDriverFound() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => NoDriverAvailable());
  }

  void searchNearestDriver() {
    if (availableDrivers.isEmpty) {
      cancelRideRequest();
      resetApp();
      noDriverFound();
      return;
    }
    if (availableDrivers[0] != null) {
      var driver = availableDrivers[0]; //list is sorted so we get the first one
      notifyDriver(driver);
      availableDrivers.removeAt(0);
    }
  }

  void callingDriver(NearbyAvailableDrivers driver) {
    setState(() {
      state = "requesting";
    });
    Navigator.pop(context);
    displayRequestContainer();

    availableDrivers = GeoFireAssistant.nearbyAvailableDriversList;

    // if (availableDrivers.isEmpty) {
    //   cancelRideRequest();
    //   resetApp();
    //   noDriverFound();
    //   return;
    // }
    if (driver != null) {
      //var driver = availableDrivers[0]; //list is sorted so we get the first one
      notifyDriver(driver);
      availableDrivers.remove(driver);
    }
  }

  void notifyDriver(NearbyAvailableDrivers driver) {
    driversRef.child(driver.key).child("newRide").set(rideRequestRef.key);
    //each driver carry his own token
    driversRef
        .child(driver.key)
        .child("token")
        .once()
        .then((DataSnapshot dataSnapshot) {
      if (dataSnapshot != null) {
        String token = dataSnapshot.value.toString();
        AssistantMethods.sendNotificationDriver(
            token, context, rideRequestRef.key);
      } else {
        return;
      }
      const oneSecondPassed = Duration(
          seconds: 1); //when one second is passed we update driverRequestTime
      var timer = Timer.periodic(oneSecondPassed, (timer) {
        if (state != "requesting") {
          driversRef.child(driver.key).child("newRide").set("cancelled");
          driversRef.child(driver.key).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();

          //searchNearestDriver();
        }
        driverRequestTimeOut = driverRequestTimeOut - 1;

        driversRef.child(driver.key).child("newRide").onValue.listen((event) {
          if (event.snapshot.value.toString() == "accepted") {
            driversRef.child(driver.key).child("newRide").onDisconnect();
            driverRequestTimeOut = 40;
          }
        });
        if (driverRequestTimeOut == 0) {
          driversRef.child(driver.key).child("newRide").set("timeout");
          driversRef.child(driver.key).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();

          //searchNearestDriver();
        }
      });
    });
  }
}
