import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GeonogatorService(),
    );
  }
}

class GeonogatorService extends StatefulWidget {
  @override
  _GeonogatorServiceState createState() => _GeonogatorServiceState();
}

class _GeonogatorServiceState extends State<GeonogatorService> {
  String location = 'Unknown location';
  String status = 'Idle';
  Position? myPosition;
  List<String> savedLocations = [];
  List<String> fetchedLocations = [];

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  // Function to request permissions
  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      return result == PermissionStatus.granted;
    }
  }

  Future<void> getAddresses(double latitude, double longitude) async {
    try {
      List<Placemark> addresses =
          await placemarkFromCoordinates(latitude, longitude);

      if (addresses.isNotEmpty) {
        setState(() {
          fetchedLocations = addresses.map((address) {
            return '${address.name}, ${address.locality}, ${address.administrativeArea},${address.postalCode}, ${address.country}, ';
          }).toList();

          status = 'Addresses fetched';
          location = fetchedLocations.first; // Show the first location
        });
      } else {
        setState(() {
          location = 'No addresses found';
          fetchedLocations.clear();  // Reset if no addresses found
        });
      }
    } catch (e) {
      setState(() {
        location = 'Error fetching addresses: $e';
      });
    }
  }

  Future<void> getCurrentLocation() async {
    if (await _requestPermission(Permission.location)) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          myPosition = position;
          status = 'Fetching address...';
          getAddresses(position.latitude, position.longitude); // To geocoding
        });
      } catch (e) {
        setState(() {
          status = 'Error getting location: $e';
        });
      }
    } else {
      setState(() {
        status = 'Permission denied';
        return;
      });
    }
  }

  Future<void> _loadSavedLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? locations = prefs.getStringList('savedLocations');
    if (locations != null && locations.isNotEmpty) {
      setState(() {
        savedLocations = locations;
      });
    }
  }


  Future<void> _saveLocation(String locationToSave) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!savedLocations.contains(locationToSave)) {
      savedLocations.add(locationToSave);
      await prefs.setStringList('savedLocations', savedLocations);

      setState(() {
        status = 'Location saved!';
      });
    } else {
      setState(() {
        status = 'Location already saved!';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Location Service',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.red[700],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                color: Colors.red[700],
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4.0, vertical: 20),
                  child: Text(
                    'Current Location:\n $location',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '$status',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent, // Button color
                  foregroundColor: Colors.black, // Text color
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Get Landmarks',
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: Column(
                  children: [
                    Text('Fetched Locations:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: fetchedLocations.length,
                        itemBuilder: (context, index) {
                          return Card(
                            color: Colors.lightBlueAccent,
                            child: ListTile(
                              leading: Icon(Icons.location_on, color: Colors.red[700]),
                              title: Text(fetchedLocations[index]),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  _saveLocation(fetchedLocations[index]);
                                },
                                child: Text("Save"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[100],
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Saved Locations:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: savedLocations.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              leading: Icon(Icons.check, color: Colors.green[700]),
                              title: Text(savedLocations[index]),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.red,
          child: Icon(Icons.clear),
          onPressed: ()async{
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();  // This clears all stored preferences.
        setState(() {
          savedLocations.clear();  // Also clear the savedLocations list in the UI.
        });
      }),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: GeonogatorService(),
//     );
//   }
// }
//
// class GeonogatorService extends StatefulWidget {
//   @override
//   _GeonogatorServiceState createState() => _GeonogatorServiceState();
// }
//
// class _GeonogatorServiceState extends State<GeonogatorService> {
//   String location = 'Unknown location';
//   String status = 'Idle';
//   List<String> savedLocations = [];
//   List<String> fetchedLocations = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadSavedLocations();
//   }
//
//   Future<bool> _requestPermission(Permission permission) async {
//     if (await permission.isGranted) {
//       return true;
//     } else {
//       var result = await permission.request();
//       return result == PermissionStatus.granted;
//     }
//   }
//
//   Future<void> getAddresses(double latitude, double longitude) async {
//     try {
//       List<Placemark> addresses =
//       await placemarkFromCoordinates(latitude, longitude);
//
//       if (addresses.isNotEmpty) {
//         setState(() {
//           fetchedLocations = addresses.map((address) {
//             return '${address.name}, ${address.locality}, ${address.administrativeArea},${address.postalCode}, ${address.country}';
//           }).toList();
//           location = fetchedLocations.first;
//           status = 'Addresses fetched';
//         });
//       } else {
//         setState(() {
//           location = 'No addresses found';
//           fetchedLocations.clear();
//         });
//       }
//     } catch (e) {
//       setState(() {
//         location = 'Error fetching addresses: $e';
//       });
//     }
//   }
//
//   Future<void> getCurrentLocation() async {
//     if (await _requestPermission(Permission.location)) {
//       try {
//         Position position = await Geolocator.getCurrentPosition(
//             desiredAccuracy: LocationAccuracy.high);
//         setState(() {
//           status = 'Fetching address...';
//           getAddresses(position.latitude, position.longitude);
//         });
//       } catch (e) {
//         setState(() {
//           status = 'Error getting location: $e';
//         });
//       }
//     } else {
//       setState(() {
//         status = 'Permission denied';
//       });
//     }
//   }
//
//   Future<void> _loadSavedLocations() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String>? locations = prefs.getStringList('savedLocations');
//     if (locations != null && locations.isNotEmpty) {
//       setState(() {
//         savedLocations = locations;
//       });
//     }
//   }
//
//   Future<void> _saveLocation(String locationToSave) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     if (!savedLocations.contains(locationToSave)) {
//       savedLocations.add(locationToSave);
//       await prefs.setStringList('savedLocations', savedLocations);
//       setState(() {
//         status = 'Location saved!';
//       });
//     } else {
//       setState(() {
//         status = 'Location already saved!';
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Location Service'),
//         centerTitle: true,
//         backgroundColor: Colors.teal[800],
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(10.0),
//           child: Column(
//             children: [
//               Card(
//                 color: Colors.teal[300],
//                 child: Padding(
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
//                   child: Text(
//                     'Current Location:\n $location',
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 status,
//                 style: const TextStyle(fontSize: 16, color: Colors.grey),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: getCurrentLocation,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.teal[600],
//                   foregroundColor: Colors.white,
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//                 child: const Text('Get Landmarks'),
//               ),
//               const SizedBox(height: 20),
//               const Text('Fetched Locations:'),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: fetchedLocations.length,
//                   itemBuilder: (context, index) {
//                     return Card(
//                       color: Colors.teal[100],
//                       child: ListTile(
//                         leading: const Icon(
//                           Icons.location_on,
//                           color: Colors.blueGrey,
//                         ),
//                         title: Text(fetchedLocations[index]),
//                         trailing: ElevatedButton(
//                           onPressed: () {
//                             _saveLocation(fetchedLocations[index]);
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.teal[200],
//                             foregroundColor: Colors.black,
//                           ),
//                           child: const Text("Save"),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => SavedLocationsPage(
//                           savedLocations: savedLocations,
//                         )),
//                   );
//                 },
//                 child: const Text("View Saved Locations"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class SavedLocationsPage extends StatelessWidget {
//   final List<String> savedLocations;
//
//   const SavedLocationsPage({Key? key, required this.savedLocations})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Saved Locations"),
//         backgroundColor: Colors.teal[800],
//       ),
//       body: ListView.builder(
//         itemCount: savedLocations.length,
//         itemBuilder: (context, index) {
//           return Card(
//             child: ListTile(
//               leading: const Icon(
//                 Icons.check,
//                 color: Colors.green,
//               ),
//               title: Text(savedLocations[index]),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
