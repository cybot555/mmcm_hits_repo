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

  // sign user out
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

  List<Widget> _pages() {
    return [
      // Profile Page
      _buildProfilePage(),

      // Second Tab: depends on role
      if (_role == "Passenger")
        _buildPassengerRidesPage()
      else
        _buildDriverRequestsPage(),

      // Third Tab: only for drivers
      if (_role == "Driver") _buildCreateRidePage(),
    ];
  }

  Widget _buildProfilePage() {
    if (_userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: _role == "Driver" ? Colors.green[100] : Colors.blue[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.black54),
            Text(
              "Name: ${_userData!['email']}",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "College: ${_userData!['college']}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Program: ${_userData!['program']}",
              style: const TextStyle(fontSize: 16),
            ),
            Text("Role: $_role", style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerRidesPage() {
    return Container(
      color: Colors.blue[50],
      child: const Center(
        child: Text(
          "Available Rides UI here 🚘",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildDriverRequestsPage() {
    return Container(
      color: Colors.green[50],
      child: const Center(
        child: Text("Ride Requests UI here 📝", style: TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildCreateRidePage() {
    return Container(
      color: Colors.green[50],
      child: const Center(
        child: Text("Create Ride UI here ➕", style: TextStyle(fontSize: 20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = _pages();

    return Scaffold(
      appBar: AppBar(
        title: Text("HITS ($_role)"),
        actions: [
          IconButton(onPressed: loginUserOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
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
