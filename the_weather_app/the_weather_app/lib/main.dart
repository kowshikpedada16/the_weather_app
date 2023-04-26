import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';

void main() {
  runApp(TheWeatherApp());
}

class TheWeatherApp extends StatelessWidget {
  const TheWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color primaryColor = const Color(0xFF4B77BE);

  var isLoading = true;
  var result = "24° Celcius";
  var city = "Visakhapatnam";
  var cityTextFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchLocation().then((location) {
      placemarkFromCoordinates(location.latitude, location.longitude)
          .then((List<Placemark> placemarks) {
        city = placemarks
                .where((placemark) =>
                    placemark.locality != null &&
                    placemark.locality!.isNotEmpty)
                .first
                .locality ??
            "Visakhapatnam";
        get(
          Uri.parse(
              'https://api.openweathermap.org/data/2.5/weather?lat=${location.latitude}&lon=${location.longitude}&units=metric&appid=d43894f3d1447287554f7dd5ceab9537'),
        ).then((response) {
          result = "${jsonDecode(response.body)["main"]["temp"]}° Celcius";
          setState(() {
            isLoading = false;
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isDesktop = constraints.maxWidth > 840;
      return Scaffold(
        body: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFADD8E6), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 60 : 16, vertical: 48),
            child: isDesktop
                ? SizedBox(
                    height: double.infinity,
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                topContainer(
                                    isDesktop, isLoading, result, city),
                                SizedBox(
                                  height: 16,
                                ),
                                getWeathCard(isDesktop),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 110,
                          ),
                          Flexible(
                            child: SvgPicture.asset("weather-illustration.svg",
                                height: double.infinity),
                          ),
                        ]),
                  )
                : Column(
                    children: [
                      topContainer(isDesktop, isLoading, result, city),
                      const SizedBox(
                        height: 16,
                      ),
                      getWeathCard(isDesktop),
                      const SizedBox(
                        height: 48,
                      ),
                      SvgPicture.asset("assets/weather-illustration.svg"),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  topContainer(bool isDesktop, bool isLoading, String result, String city) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                "The Weather App",
                style: GoogleFonts.poppins(
                    color: primaryColor,
                    fontSize: isDesktop ? 36 : 24,
                    fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  result,
                  style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 48 : 36,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                city,
                style: GoogleFonts.poppins(
                    color: primaryColor,
                    fontSize: isDesktop ? 36 : 24,
                    fontWeight: FontWeight.bold),
              ),
            ]),
    );
  }

  getWeathCard(bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
            child: TextField(
          controller: cityTextFieldController,
          decoration: InputDecoration(
            hintText: "Enter city",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
          ),
        )),
        SizedBox(
          width: 16,
        ),
        MaterialButton(
          onPressed: () {
            setState(() {
              isLoading = true;
            });
            var url =
                "https://api.openweathermap.org/data/2.5/weather?q=${cityTextFieldController.value.text}&units=metric&appid=d43894f3d1447287554f7dd5ceab9537";
            print(cityTextFieldController.text);
            get(
              Uri.parse(url),
            ).then((response) {
              if (jsonDecode(response.body)["cod"].toString() == "404") {
                city = "N/A";
                result = "N/A";
                setState(() {
                  isLoading = false;
                });
              } else {
                result =
                    "${jsonDecode(response.body)["main"]["temp"]}° Celcius";
                city = cityTextFieldController.text;
                setState(() {
                  isLoading = false;
                });
              }
            });
          },
          padding: EdgeInsets.symmetric(
              vertical: isDesktop ? 16 : 20, horizontal: isDesktop ? 32 : 28),
          color: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          child: Text(
            "Get Weather",
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isDesktop ? 21 : 16,
                fontWeight: FontWeight.bold),
          ),
        ),
      ]),
    );
  }

  Future<Position> fetchLocation() async {
    if (kIsWeb) {
      return Geolocator.getCurrentPosition();
    }

    bool serviceEnabled;
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    var lastKnownLocation = await Geolocator.getLastKnownPosition();
    if (lastKnownLocation != null) {
      return lastKnownLocation;
    }

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
