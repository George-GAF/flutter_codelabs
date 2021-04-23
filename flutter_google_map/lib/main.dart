import 'package:flutter/material.dart';
import 'package:flutter_google_map/service/get_location_permtion.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GoogleMapController mapController;
  late LatLng _center; //= const LatLng(45.521563, -122.677433);
  final Map<String, Marker> _markers = {};
  Position? position;
  bool isLoading = true;
  bool isLocationOrWifiEnabled = false;

  @override
  void initState() {
    super.initState();
    getPermissionToLocation();
  }

  void getPermissionToLocation() async {
    final gpsState = await Geolocator.isLocationServiceEnabled();
    setState(() {
      isLocationOrWifiEnabled = gpsState;
    });
    if (!isLocationOrWifiEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'please enable your gps',
            style: TextStyle(fontSize: 14),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 10,
            right: 10,
            bottom: MediaQuery.of(context).size.height * .45,
          ),
        ),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }
    try {
      position = await GetPermission.instance.determinePosition();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: TextStyle(fontSize: 14),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 10,
            right: 10,
            bottom: MediaQuery.of(context).size.height * .45,
          ),
        ),
      );
    }
    setState(() {
      if (position != null) {
        _center = LatLng(position!.latitude, position!.longitude);
        final location = Marker(
          markerId: MarkerId('current-location'),
          position: LatLng(position!.latitude, position!.longitude),
          infoWindow: InfoWindow(
            title: 'My Location',
          ),
        );
        _markers['current-location'] = location;
        isLoading = false;
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maps'),
      ),
      body: Stack(
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : !isLocationOrWifiEnabled
                  ? Center(
                      child: Text(
                        "can't show maps without gps service",
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black.withOpacity(.7),
                        ),
                      ),
                    )
                  : GoogleMap(
                      onTap: (lat) {
                        final marker = Marker(
                          markerId: MarkerId(lat.latitude.toString()),
                          position: LatLng(lat.latitude, lat.longitude),
                          infoWindow: InfoWindow(
                            title: 'Tapped',
                            snippet: lat.latitude.toString(),
                          ),
                        );
                        _markers.clear();
                        setState(() {
                          _markers[lat.latitude.toString()] = marker;
                        });
                      },
                      markers: _markers.values.toSet(),
                      myLocationButtonEnabled: true,
                      myLocationEnabled: true,
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: 11,
                      ),
                    ),
        ],
      ),
    );
  }
}
