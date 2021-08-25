import 'package:flutter/material.dart';
import 'package:easy_localization/src/public_ext.dart';

class CollectFareScreen extends StatefulWidget {
  CollectFareScreen({this.fareAmount});

  final fareAmount;

  @override
  State<CollectFareScreen> createState() => _CollectFareScreenState();
}

class _CollectFareScreenState extends State<CollectFareScreen> {
  String dropdownValue = 'cash'.tr();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
        backgroundColor: Colors.yellowAccent,
        child: Container(
          margin: EdgeInsets.all(15.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 22.0,
              ),
              Text(
                'trip_fare'.tr(),
                style: TextStyle(color: Colors.yellowAccent),
              ),
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
              Text(
                "RSD ${widget.fareAmount}",
                style: TextStyle(
                    fontSize: 55.0,
                    fontFamily: "Brand Bold",
                    color: Colors.yellowAccent),
              ),
              SizedBox(
                height: 16.0,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'trip_amount'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.yellowAccent,
                  ),
                ),
              ),
              SizedBox(
                height: 30.0,
              ),
              Padding(
                padding: EdgeInsets.all(17.0),
                child: Container(
                  padding: EdgeInsets.only(left: 18.0),
                  color: Colors.yellowAccent,
                  child: DropdownButton<String>(
                    value: dropdownValue,
                    dropdownColor: Colors.yellowAccent,
                    focusColor: Colors.black,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black,
                    ),
                    iconSize: 40,
                    elevation: 16,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 30.0,
                        fontFamily: "Brand Bold"),
                    underline: Container(
                      height: 3,
                      color: Colors.yellowAccent,
                    ),
                    onChanged: (String newValue) {
                      setState(() {
                        dropdownValue = newValue;
                      });
                      Navigator.pop(context, ["close", dropdownValue]);
                    },
                    items: <String>['cash'.tr(), 'card'.tr()]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Container(
                          color: Colors.yellowAccent,
                          child: Text(
                            value,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 20.0,
                                fontFamily: "Brand Bold"),
                          ),
                          width: 150.0,
                        ),
                      );
                    }).toList(),
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
