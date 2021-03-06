import 'package:flutter/material.dart';
import 'package:fluttergooglemap/GoogeMapDirection/DirectionsRepository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// import 'package:location/location.dart';
import 'direction_model/Directions.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: GoogleMapScreen(),
    );
  }
}

class GoogleMapScreen extends StatefulWidget {
  const GoogleMapScreen({Key? key}) : super(key: key);

  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late dynamic positionNow;
  late dynamic positionLast;
  LatLng? currentLatLng;

  void getUserCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((currLocation) {
      currentLatLng = new LatLng(currLocation.latitude, currLocation.longitude);
      print(currentLatLng);
      print(
          'Current Position: ${currentLatLng!.latitude} :: ${currentLatLng!.longitude} ');
    }).catchError((onError) {
      print("onError: $onError");
    });

    positionLast = await Geolocator.getLastKnownPosition();

    print(
        "Last Position: ${positionLast.latitude} :: ${positionLast.longitude}");

    setState(() {
      // print(
      //     "Position lat: ${positionNow.latitude}:: lng: ${positionNow.longitude}");
    });
  }

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(37.773972, -122.431297), //LatLng(37.773972, -122.431297)
    zoom: 11.5,
    tilt: 50.0,
  );

  late GoogleMapController _googleMapController;
  Marker? _origin;
  Marker? _destination;
  Directions? _info;

  @override
  void initState() {
    getUserCurrentLocation();

    Geolocator.getCurrentPosition().then((currLocation) {
      setState(() {
        currentLatLng =
            new LatLng(currLocation.latitude, currLocation.longitude);
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    setState(() {});
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text("Google Map"),
        actions: [
          if (_origin != null)
            TextButton(
                onPressed: () => _googleMapController.animateCamera(
                        CameraUpdate.newCameraPosition(CameraPosition(
                      target: _origin!.position,
                      zoom: 14.5,
                      tilt: 50.0,
                    ))),
                style: TextButton.styleFrom(
                    primary: Colors.green,
                    textStyle: TextStyle(fontWeight: FontWeight.w600)),
                child: Text("Origin")),
          TextButton(
              onPressed: () => _googleMapController.animateCamera(
                      CameraUpdate.newCameraPosition(CameraPosition(
                    target: _destination!.position,
                    zoom: 14.5,
                    tilt: 50.0,
                  ))),
              style: TextButton.styleFrom(
                primary: Colors.blue,
                textStyle: TextStyle(fontWeight: FontWeight.w600),
              ),
              child: Text("Dest"))
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) => _googleMapController = controller,
            markers: {
              if (_origin != null) _origin!,
              if (_destination != null) _destination!
            },
            polylines: {
              if (_info != null)
                Polyline(
                  polylineId: const PolylineId('overview_polyline'),
                  color: Colors.red,
                  width: 5,
                  points: _info!.polylinePoints
                      .map((e) => LatLng(e.latitude, e.longitude))
                      .toList(),
                ),
            },
            onLongPress: _addMarker,
          ),
          if (_info != null)
            Positioned(
              top: 20.0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                decoration: BoxDecoration(
                    color: Colors.yellowAccent,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 6.0)
                    ]),
                child: Text(
                  '${_info!.totalDistance}, ${_info!.totalDuration}',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.black,
        onPressed: () {
          _googleMapController.animateCamera(_info != null
              ? CameraUpdate.newLatLngBounds(_info!.bounds, 100.0)
              : CameraUpdate.newCameraPosition(_initialCameraPosition));

          getUserCurrentLocation();
        },
        child: Icon(Icons.center_focus_strong),
      ),
    );
  }

  void _addMarker(LatLng pos) async {
    if (_origin == null || (_origin != null && _destination != null)) {
      //  Origin is not set OR Origin/Destination are both set.

      //  Set Origin
      setState(() {
        _origin = Marker(
          markerId: const MarkerId('origin'),
          infoWindow: const InfoWindow(title: 'Origin'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: pos,
        );

        //  reset Destination
        _destination = null;
        // reset Info
        _info = null;
      });
    } else {
      //  Origin is already set
      //  Set Destination
      setState(() {
        _destination = Marker(
          markerId: const MarkerId('destination'),
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: pos,
        );
      });

      //  Get Directions
      final directions = await DirectionsRepository().getDirections(
          origin: _origin!.position, destination: _destination!.position);
      setState(() => _info = directions!);
    }
  }
}
