import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_pages/create_ride_section.dart';
import 'home_pages/driver_requests_section.dart';
import 'home_pages/passenger_rides_section.dart';
import 'home_pages/profile_section.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser!;
  int _selectedIndex = 0;
  String? _role;
  Map<String, dynamic>? _userData;

  void loginUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await db.collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        _userData = doc.data();
        _role = doc['role'];
      });
    }
  }

  String _getAppBarTitle() {
    if (_selectedIndex == 0) return "Profile";
    if (_selectedIndex == 1 && _role == "Passenger") return "Available Rides";
    if (_selectedIndex == 1 && _role == "Driver") return "Ride Requests";
    if (_selectedIndex == 2 && _role == "Driver") return "Create Ride";
    return "";
  }

  String _getAppBarSubtitle() {
    if (_selectedIndex == 0) return "";
    if (_selectedIndex == 1 && _role == "Passenger") {
      return "Find available rides going along your destination.";
    }
    if (_selectedIndex == 1 && _role == "Driver") {
      return "See requests on posted shared ride!";
    }
    if (_selectedIndex == 2 && _role == "Driver") {
      return "Post a ride for others to join.";
    }
    return "";
  }

  List<Widget> _pages() {
    return [
      ProfileSection(
        userData: _userData,
        onLogout: loginUserOut,
        role: _role ?? "",
      ),
      if (_role == "Passenger")
        const PassengerRidesSection()
      else
        const DriverRequestsSection(),
      if (_role == "Driver") const CreateRideSection(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_role == null || _userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDriver = _role == "Driver";
    final themeColor = isDriver
        ? const Color.fromARGB(255, 195, 255, 198)
        : const Color.fromARGB(255, 192, 237, 255);

    final pages = _pages();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        toolbarHeight: 85,
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _getAppBarTitle(),
                    style: TextStyle(
                      fontSize: _selectedIndex == 0 ? 36 : 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (_getAppBarSubtitle().isNotEmpty)
                    Text(
                      _getAppBarSubtitle(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "(${_role == "Passenger" ? "Hitcher" : _role})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color.fromARGB(255, 99, 98, 98),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: themeColor,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
          if (_role == "Passenger")
            const BottomNavigationBarItem(
              icon: Icon(Icons.directions_car),
              label: "Rides",
            )
          else
            const BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: "Requests",
            ),
          if (_role == "Driver")
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: "Create Ride",
            ),
        ],
      ),
    );
  }
}
