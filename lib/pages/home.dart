import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      setState(() {
        _userData = doc.data();
        _role = doc['role'];
      });
    }
  }

  /// ---------------------------
  /// AppBar Helpers
  /// ---------------------------
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

  /// ---------------------------
  /// Pages
  /// ---------------------------
  List<Widget> _pages() {
    return [
      _buildProfilePage(),
      if (_role == "Passenger")
        _buildPassengerRidesPage()
      else
        _buildDriverRequestsPage(),
      if (_role == "Driver") _buildCreateRidePage(),
    ];
  }

  /// Profile Page
  Widget _buildProfilePage() {
    if (_userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDriver = _role == "Driver";

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 55, color: Colors.white),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData!['college'] ?? "",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _userData!['program'] ?? "",
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_transportation,
                          size: 20,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDriver ? "Driver" : "Hitcher",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Email row
          Row(
            children: [
              const Icon(Icons.email, size: 24),
              const SizedBox(width: 10),
              Text(
                _userData!['email'] ?? "",
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),

          const Spacer(),

          // Logout button
          Center(
            child: ElevatedButton.icon(
              onPressed: loginUserOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Logout",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Passenger Rides Page
  Widget _buildPassengerRidesPage() {
    return const Center(
      child: Text("Available Rides UI here 🚘", style: TextStyle(fontSize: 20)),
    );
  }

  /// Driver Requests Page
  Widget _buildDriverRequestsPage() {
    return const Center(
      child: Text("Ride Requests UI here 📝", style: TextStyle(fontSize: 20)),
    );
  }

  /// Create Ride Page (Driver only)
  Widget _buildCreateRidePage() {
    return const Center(
      child: Text("Create Ride UI here ➕", style: TextStyle(fontSize: 20)),
    );
  }

  /// ---------------------------
  /// Build
  /// ---------------------------
  @override
  Widget build(BuildContext context) {
    if (_role == null || _userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDriver = _role == "Driver";
    final themeColor = isDriver
        ? const Color.fromARGB(255, 195, 255, 198) // pastel green
        : const Color.fromARGB(255, 192, 237, 255); // pastel blue
    final pages = _pages();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        toolbarHeight: 85, // uniform AppBar height
        title: Padding(
          padding: const EdgeInsets.only(top: 10), // ✅ bring down a bit
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end, // ✅ align bottom
            children: [
              // Left side: Title + Subtitle
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
              // Right side: Role label
              Padding(
                padding: const EdgeInsets.only(bottom: 6), // ✅ lower Hitcher
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
