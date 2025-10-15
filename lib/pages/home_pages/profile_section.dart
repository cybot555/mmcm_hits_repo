import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSection extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onLogout;
  final String role;
  final String uid; // Firestore UID

  ProfileSection({
    super.key,
    required this.userData,
    required this.onLogout,
    required this.role,
    required this.uid,
  });

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _otherBrandController = TextEditingController();

  String? _selectedBrand;
  bool _isEditing = false;

  final List<String> _brands = [
    'Audi','BMW','BYD','Changan','Chery','Chevrolet','Dongfeng','Foton',
    'Ford','GAC','Geely','Great Wall','Honda','Hyundai','Isuzu','JAC','Jeep',
    'Kia','Lexus','Mazda','Mercedes-Benz','MG','Mini','Mitsubishi','Nissan',
    'Peugeot','Subaru','Suzuki','Tesla','Toyota','Volkswagen','Volvo',
  ];

  List<String> get _sortedBrands {
    final sorted = List<String>.from(_brands)..sort((a, b) => a.compareTo(b));
    sorted.add('Others'); // ensure 'Others' always last
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (widget.userData != null) {
      _nameController.text = widget.userData!['name'] ?? '';
      _phoneController.text = widget.userData!['phone'] ?? '';
      _plateController.text = widget.userData!['plateNumber'] ?? '';
      _modelController.text = widget.userData!['carModel'] ?? '';
      _selectedBrand = widget.userData!['carBrand'] ?? '';
      _otherBrandController.text = widget.userData!['otherBrand'] ?? '';
    }
  }

  Future<void> _saveProfileToFirestore() async {
    try {
      final dataToUpdate = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'plateNumber': _plateController.text,
        'carBrand': _selectedBrand,
        'otherBrand': _otherBrandController.text,
        'carModel': _modelController.text,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update(dataToUpdate);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _loadUserData(); // reload original data
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = widget.role == "Driver";

    if (widget.userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Profile Header
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
                      _nameController.text.isEmpty
                          ? (widget.userData!['college'] ?? "")
                          : _nameController.text,
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.userData!['program'] ?? "",
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.emoji_transportation,
                            size: 20, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          isDriver ? "Driver" : "Hitcher",
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (_isEditing)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      tooltip: 'Cancel',
                      onPressed: _cancelEdit,
                    ),
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.check : Icons.edit,
                      color: _isEditing ? Colors.green : Colors.blueAccent,
                    ),
                    tooltip: _isEditing ? 'Save' : 'Edit',
                    onPressed: () async {
                      if (_isEditing) await _saveProfileToFirestore();
                      setState(() => _isEditing = !_isEditing);
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 25),

          // --- Fields
          _buildTextField("Name", _nameController),
          _buildTextField("Phone Number", _phoneController),
          if (isDriver) ...[
            _buildTextField("Plate Number", _plateController),
            _buildBrandDropdown(),
            if (_selectedBrand == 'Others')
              _buildTextField("Specify Brand", _otherBrandController),
            _buildTextField("Car Model", _modelController),
          ],

          const SizedBox(height: 25),

          // --- Email
          Row(
            children: [
              const Icon(Icons.email, size: 24),
              const SizedBox(width: 10),
              Text(
                widget.userData!['email'] ?? "",
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // --- Logout Button
          Center(
            child: ElevatedButton.icon(
              onPressed: widget.onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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

  // --- Helpers
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildBrandDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DropdownButtonFormField<String>(
        value: _selectedBrand?.isNotEmpty == true ? _selectedBrand : null,
        decoration: const InputDecoration(
          labelText: 'Car Brand',
          border: OutlineInputBorder(),
        ),
        items: _sortedBrands
            .map((brand) => DropdownMenuItem(
                  value: brand,
                  child: Text(brand),
                ))
            .toList(),
        onChanged: _isEditing
            ? (value) {
                setState(() => _selectedBrand = value);
              }
            : null,
      ),
    );
  }
}