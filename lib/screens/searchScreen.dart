import 'package:flutter/material.dart';
import 'package:flutter_uber_app/widgets/divider.dart';
import 'package:flutter_uber_app/widgets/progressDialog.dart';
import 'package:flutter_uber_app/helpingMethods/requestAssistant.dart';
import 'package:flutter_uber_app/data/appData.dart';
import 'package:flutter_uber_app/models/address.dart';
import 'package:flutter_uber_app/models/placePredictions.dart';
import 'package:flutter_uber_app/configMaps.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/src/public_ext.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController dropOffTextEditingController = TextEditingController();
  List<PlacePredictions> placePredictionsList = [];

  @override
  Widget build(BuildContext context) {
    String placeAddress =
        Provider.of<AppData>(context).pickUpLocation.placeName ?? "";
    pickUpTextEditingController.text = placeAddress;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 215.0,
              decoration: BoxDecoration(color: Colors.yellowAccent, boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 6.0,
                  spreadRadius: 0.5,
                  offset: Offset(0.7, 0.7),
                )
              ]),
              child: Padding(
                padding: EdgeInsets.only(
                    left: 25.0, top: 25.0, right: 25.0, bottom: 20.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 5.0,
                    ),
                    Stack(
                      children: [
                        GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.arrow_back)),
                        Center(
                          child: Text(
                            'set_dropOff'.tr(),
                            style: TextStyle(
                                fontSize: 18.0, fontFamily: "Brand Bold"),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                    Row(
                      children: [
                        Image.asset(
                          "images/pickicon.png",
                          height: 16.0,
                          width: 16.0,
                        ),
                        SizedBox(
                          width: 18.0,
                        ),
                        Expanded(
                            child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3.0),
                            child: TextField(
                              controller: pickUpTextEditingController,
                              decoration: InputDecoration(
                                hintText: 'pickUp_location'.tr(),
                                fillColor: Colors.grey[400],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                    left: 11.0, top: 8.0, bottom: 8.0),
                              ),
                            ),
                          ),
                        ))
                      ],
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Row(
                      children: [
                        Image.asset(
                          "images/desticon.png",
                          height: 16.0,
                          width: 16.0,
                        ),
                        SizedBox(
                          width: 18.0,
                        ),
                        Expanded(
                            child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3.0),
                            child: TextField(
                              onChanged: (val) {
                                findPlace(val);
                              },
                              controller: dropOffTextEditingController,
                              decoration: InputDecoration(
                                hintText: 'where'.tr(),
                                fillColor: Colors.grey[400],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                    left: 11.0, top: 8.0, bottom: 8.0),
                              ),
                            ),
                          ),
                        ))
                      ],
                    )
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            //predictions
            (placePredictionsList.length > 0)
                ? Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListView.separated(
                      padding: EdgeInsets.all(0.0),
                      itemBuilder: (context, index) {
                        return PredictionsTile(
                          placePredictions: placePredictionsList[index],
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          DividerWidget(),
                      itemCount: placePredictionsList.length,
                      shrinkWrap: true,
                      physics: ClampingScrollPhysics(),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      //za Srbiju promeni-countries short name-country abbreviations
      String autoCompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:rs";

      var res = await RequestAssistant.getRequest(autoCompleteUrl);

      if (res == "failed") {
        print("failed");
        return;
      }
      if (res["status"] == "OK") {
        var predictions = res["predictions"];

        var placesList = (predictions as List)
            .map((e) => PlacePredictions.fromJson(e))
            .toList();

        setState(() {
          placePredictionsList = placesList; //saving places to List
        });
      }
    }
  }
}

class PredictionsTile extends StatelessWidget {
  final PlacePredictions placePredictions;
  PredictionsTile({Key key, this.placePredictions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(padding: EdgeInsets.all(0.0)),
      onPressed: () {
        getPlaceAddressDetails(placePredictions.placeId, context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(
              width: 10.0,
            ),
            Row(
              children: [
                Icon(Icons.add_location),
                SizedBox(
                  width: 14.0,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 8.0,
                      ),
                      Text(
                        placePredictions.mainText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16.0),
                      ),
                      SizedBox(
                        height: 2.0,
                      ),
                      Text(
                        placePredictions.secondaryText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                      SizedBox(
                        height: 8.0,
                      ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(
              width: 10.0,
            ),
          ],
        ),
      ),
    );
  }

  void getPlaceAddressDetails(String placeId, context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: 'setting_dropOff'.tr(),
            ));

    String placeDetailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";
    var res = await RequestAssistant.getRequest(placeDetailsUrl);

    Navigator.pop(context);

    if (res == "failed") {
      return;
    }

    if (res["status"] == "OK") {
      Address address = Address();
      address.placeName = res["result"]["name"];
      address.placeId = placeId;
      address.latitude = res["result"]["geometry"]["location"]["lat"];
      address.longitude = res["result"]["geometry"]["location"]["lng"];

      Provider.of<AppData>(context, listen: false)
          .updateDropOffLocationAddress(address);
      print("This is Drop Off Location :: ");
      print(address.placeName);
      print(address.latitude);
      print(address.longitude);

      Navigator.pop(context, "obtainDirection");
    }
  }
}
