import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSection extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onLogout;
  final String role;
  final String uid;

  const ProfileSection({
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
  bool _initialized = false;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _profileImageUrl;

  final List<String> _brands = [
    'Audi',
    'BMW',
    'BYD',
    'Changan',
    'Chery',
    'Chevrolet',
    'Dongfeng',
    'Foton',
    'Ford',
    'GAC',
    'Geely',
    'Great Wall',
    'Honda',
    'Hyundai',
    'Isuzu',
    'JAC',
    'Jeep',
    'Kia',
    'Lexus',
    'Mazda',
    'Mercedes-Benz',
    'MG',
    'Mini',
    'Mitsubishi',
    'Nissan',
    'Peugeot',
    'Subaru',
    'Suzuki',
    'Tesla',
    'Toyota',
    'Volkswagen',
    'Volvo',
  ];

  List<String> get _sortedBrands {
    final sorted = List<String>.from(_brands)..sort((a, b) => a.compareTo(b));
    sorted.add('Others');
    return sorted;
  }

  /// 🖼️ Pick and upload profile picture
  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;

      setState(() => _selectedImage = File(pickedFile.path));

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${widget.uid}.jpg');

      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'profileImage': downloadUrl});

      setState(() => _profileImageUrl = downloadUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile picture updated!')),
      );
    } catch (e) {
      if (e is FirebaseException) {
        print('Firebase Storage Error: ${e.code} - ${e.message}');
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error uploading image: $e')));
    }
  }

  /// 💾 Save other profile info
  Future<void> _saveProfileToFirestore() async {
    try {
      final dataToUpdate = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'plateNumber': _plateController.text,
        'carBrand': _selectedBrand,
        'otherBrand': _selectedBrand == 'Others'
            ? _otherBrandController.text
            : '',
        'carModel': _modelController.text,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update(dataToUpdate);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  void _cancelEdit() => setState(() => _isEditing = false);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("User data not found"));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final isDriver = userData['role'] == "Driver";

        if (!_initialized) {
          _nameController.text = userData['name'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _plateController.text = userData['plateNumber'] ?? '';
          _modelController.text = userData['carModel'] ?? '';
          _selectedBrand = userData['carBrand'] ?? '';
          _otherBrandController.text = userData['otherBrand'] ?? '';
          _profileImageUrl = userData['profileImage'];
          _initialized = true;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🧑 Profile Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _pickAndUploadImage : null,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null),
                      child:
                          (_selectedImage == null && _profileImageUrl == null)
                          ? const Icon(
                              Icons.person,
                              size: 55,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Editable Name
                        _isEditing
                            ? TextField(
                                controller: _nameController,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: UnderlineInputBorder(),
                                  labelText: "Name",
                                ),
                              )
                            : Text(
                                _nameController.text.isEmpty
                                    ? "Set name"
                                    : _nameController.text,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),

                        // 🔹 College and Program
                        Text(
                          userData['college'] ?? "",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          userData['program'] ?? "",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDriver
                                      ? Colors.green
                                      : Colors.blueGrey,
                                  thickness: 1,
                                  endIndent: 8,
                                ),
                              ),
                              Text(
                                isDriver ? "Driver" : "Hitcher",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  color: isDriver
                                      ? Colors.green[800]
                                      : Colors.blueGrey[700],
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDriver
                                      ? Colors.green
                                      : Colors.blueGrey,
                                  thickness: 1,
                                  indent: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                          ),
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

              // 📞 Contact + Vehicle Info
              const Text(
                "Personal Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              _buildTextField("Phone Number", _phoneController),
              if (isDriver) ...[
                _buildTextField("Plate Number", _plateController),
                _buildBrandDropdown(),
                if (_selectedBrand == 'Others')
                  _buildTextField("Specify Brand", _otherBrandController),
                _buildTextField("Car Model", _modelController),
              ],

              const SizedBox(height: 25),

              // 📧 Email
              Row(
                children: [
                  const Icon(Icons.email, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      userData['email'] ?? "",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 🚪 Logout
              Center(
                child: ElevatedButton.icon(
                  onPressed: widget.onLogout,
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
      },
    );
  }

  // 🧩 Helpers
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
      child: IgnorePointer(
        ignoring: !_isEditing,
        child: DropdownButtonFormField<String>(
          value: _selectedBrand?.isNotEmpty == true ? _selectedBrand : null,
          decoration: const InputDecoration(
            labelText: 'Car Brand',
            border: OutlineInputBorder(),
          ),
          dropdownColor: Colors.white,
          items: _sortedBrands
              .map(
                (brand) => DropdownMenuItem(value: brand, child: Text(brand)),
              )
              .toList(),
          onChanged: (value) {
            if (_isEditing) setState(() => _selectedBrand = value);
          },
        ),
      ),
    );
  }
}
