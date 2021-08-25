import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_uber_app/constants.dart';
import 'package:easy_localization/src/public_ext.dart';

class DriverListContainer extends StatefulWidget {
  DriverListContainer(
      {this.driverCurrentInfo, this.tripDirectionDetails, this.function});

  final driverCurrentInfo;
  final tripDirectionDetails;
  final function;

  @override
  State<DriverListContainer> createState() => _DriverListContainerState();
}

class _DriverListContainerState extends State<DriverListContainer> {
  String name;

  String carModel;

  Future<void> getInfo() async {
    await driversRef
        .child(widget.driverCurrentInfo)
        .once()
        .then((DataSnapshot snapshot) {
      name = snapshot.value['name'];
      carModel = snapshot.value['car_details']['car_model'];
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.yellowAccent,
          borderRadius: BorderRadius.all(Radius.circular(18.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 16.0,
              spreadRadius: 0.5,
              offset: Offset(0.7, 0.7),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: CircleAvatar(
                  radius: 39,
                  backgroundColor: Colors.yellowAccent,
                  child: CircleAvatar(
                    radius: 33,
                    backgroundImage: AssetImage('images/user_icon.png'),
                    // backgroundImage: userCurrentInfo != null
                    //     ? NetworkImage(userCurrentInfo.imageUrl)
                    //     : AssetImage('images/user_icon.png'),
                  ),
                ),
              ),
              Flexible(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null ? 'name'.tr() : name,
                      style: TextStyle(
                          fontSize: 18.0,
                          fontFamily: "Brand Bold",
                          color: Colors.black),
                    ),
                    Text(
                      carModel == null ? 'car model' : carModel,
                      style: TextStyle(fontSize: 16.0, color: Colors.black),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      'distance'.tr(),
                      style: TextStyle(fontSize: 16.0, color: Colors.black),
                    ),
                    Text(
                      ((widget.tripDirectionDetails != null)
                          ? widget.tripDirectionDetails.distanceText
                          : ''),
                      style: TextStyle(fontSize: 16.0, color: Colors.black),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: TextButton(
                  onPressed: widget.function,
                  child: Icon(
                    Icons.phone,
                    color: Colors.yellowAccent,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(5.0),
                    primary: Colors.black,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
