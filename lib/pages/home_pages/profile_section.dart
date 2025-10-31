import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mmcm_hits/repositories/storage_repository.dart';
import 'package:mmcm_hits/repositories/user_repository.dart';
import 'package:mmcm_hits/viewmodels/profile_viewmodel.dart';
import 'package:provider/provider.dart';

class ProfileSection extends StatefulWidget {
  final String uid;
  final String role;
  final Future<void> Function() onLogout;

  const ProfileSection({
    super.key,
    required this.uid,
    required this.role,
    required this.onLogout,
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

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _profileImageUrl;
  String? _selectedBrand;

  bool _isEditing = false;
  bool _initialised = false;

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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    _modelController.dispose();
    _otherBrandController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(ProfileViewModel viewModel) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      setState(() => _selectedImage = file);

      final url = await viewModel.uploadProfilePhoto(file);
      if (!mounted) return;

      if (url != null) {
        setState(() => _profileImageUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile picture updated!')),
        );
      } else if (viewModel.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(viewModel.errorMessage!)));
        viewModel.resetError();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error uploading image: $e')));
    }
  }

  Future<void> _saveProfile(ProfileViewModel viewModel) async {
    await viewModel.saveProfile({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'plateNumber': _plateController.text,
      'carBrand': _selectedBrand,
      'otherBrand': _selectedBrand == 'Others'
          ? _otherBrandController.text
          : '',
      'carModel': _modelController.text,
    });

    if (!mounted) return;

    if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(viewModel.errorMessage!)));
      viewModel.resetError();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _isEditing = false);
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE1E6EB)),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2933),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFF4F8AFF), width: 1.6),
      ),
      disabledBorder: baseBorder.copyWith(
        borderSide: const BorderSide(color: Color(0xFFD5DAE0)),
      ),
    );
  }

  Widget _buildDisplayField({
    required String label,
    required String value,
    IconData? icon,
    double? width,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();

    final field = InputDecorator(
      decoration: _buildInputDecoration(
        label,
      ).copyWith(floatingLabelBehavior: FloatingLabelBehavior.always),
      isEmpty: value.isEmpty,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: const Color(0xFF5B6B7C)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1F2933),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }

    return field;
  }

  @override
  Widget build(BuildContext context) {
    final userRepository = context.read<UserRepository>();
    final storageRepository = context.read<StorageRepository>();

    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(
        userRepository: userRepository,
        storageRepository: storageRepository,
        uid: widget.uid,
      )
            ..initialise(),
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, _) {
          final data = viewModel.userData;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_initialised) {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _plateController.text = data['plateNumber'] ?? '';
            _modelController.text = data['carModel'] ?? '';
            _selectedBrand = data['carBrand'] ?? '';
            _otherBrandController.text = data['otherBrand'] ?? '';
            _profileImageUrl = data['profileImage'];
            _initialised = true;
          } else {
            final remoteImage = data['profileImage'] as String?;
            if (!_isEditing &&
                _selectedImage == null &&
                remoteImage != null &&
                remoteImage.isNotEmpty &&
                remoteImage != _profileImageUrl) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _profileImageUrl = remoteImage);
              });
            }
          }

          final role = (data['role'] as String?) ?? widget.role;
          final isDriver = role == 'Driver';
          final college = (data['college'] as String?) ?? '';
          final program = (data['program'] as String?) ?? '';
          final email = (data['email'] as String?) ?? '';
          if (viewModel.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(viewModel.errorMessage!)));
              viewModel.resetError();
            });
          }

          ImageProvider<Object>? imageProvider;
          if (_selectedImage != null) {
            imageProvider = FileImage(_selectedImage!) as ImageProvider<Object>;
          } else if (_profileImageUrl != null) {
            imageProvider =
                NetworkImage(_profileImageUrl!) as ImageProvider<Object>;
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              const double padding = 20;
              double fieldWidth = constraints.maxWidth - padding * 2;
              if (fieldWidth <= 0) {
                fieldWidth = constraints.maxWidth;
              }

              final infoFields = <Widget>[];
              if (email.isNotEmpty) {
                infoFields.add(
                  _buildDisplayField(
                    label: 'Email Address',
                    value: email,
                    icon: Icons.email_outlined,
                    width: fieldWidth,
                  ),
                );
              }
              if (college.isNotEmpty) {
                infoFields.add(
                  _buildDisplayField(
                    label: 'College',
                    value: college,
                    icon: Icons.school,
                    width: fieldWidth,
                  ),
                );
              }
              if (program.isNotEmpty) {
                infoFields.add(
                  _buildDisplayField(
                    label: 'Program',
                    value: program,
                    icon: Icons.menu_book_rounded,
                    width: fieldWidth,
                  ),
                );
              }
              infoFields.add(
                _buildDisplayField(
                  label: 'Role',
                  value: role,
                  icon: isDriver
                      ? Icons.directions_car_filled
                      : Icons.person_pin_circle,
                  width: fieldWidth,
                ),
              );

              // -------------- SCROLLABLE WRAP --------------
              return SafeArea(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    padding,
                    padding,
                    padding + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _isEditing
                                  ? () => _pickAndUploadImage(viewModel)
                                  : null,
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: imageProvider,
                                child: (imageProvider == null)
                                    ? const Icon(Icons.person, size: 45)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _nameController,
                                builder: (context, value, _) {
                                  final name = value.text.trim().isEmpty
                                      ? 'Edit name'
                                      : value.text.trim();

                                  return Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(_isEditing ? Icons.close : Icons.edit),
                              onPressed: () {
                                setState(() => _isEditing = !_isEditing);
                                if (!_isEditing) _selectedImage = null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        if (infoFields.isNotEmpty) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < infoFields.length; i++) ...[
                                infoFields[i],
                                if (i != infoFields.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        SizedBox(
                          width: fieldWidth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Color(0xFFE1E6EB)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: _nameController,
                                  readOnly: !_isEditing,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: _buildInputDecoration(
                                    'Full Name',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _phoneController,
                                  readOnly: !_isEditing,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: _buildInputDecoration(
                                    'Phone Number',
                                  ),
                                ),
                                if (isDriver) ...[
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _plateController,
                                    readOnly: !_isEditing,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                    decoration: _buildInputDecoration(
                                      'Plate Number',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedBrand?.isEmpty == true
                                        ? null
                                        : _selectedBrand,
                                    decoration: _buildInputDecoration(
                                      'Car Brand',
                                    ),
                                    items: _sortedBrands.map((brand) {
                                      return DropdownMenuItem(
                                        value: brand,
                                        child: Text(brand),
                                      );
                                    }).toList(),
                                    onChanged: _isEditing
                                        ? (value) {
                                            setState(() {
                                              _selectedBrand = value;
                                            });
                                          }
                                        : null,
                                  ),
                                  if (_selectedBrand == 'Others') ...[
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _otherBrandController,
                                      readOnly: !_isEditing,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                      decoration: _buildInputDecoration(
                                        'Specify Other Brand',
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _modelController,
                                    readOnly: !_isEditing,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                    decoration: _buildInputDecoration(
                                      'Car Model',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            if (_isEditing)
                              ElevatedButton.icon(
                                onPressed: !viewModel.isSaving
                                    ? () => _saveProfile(viewModel)
                                    : null,
                                icon: viewModel.isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: const Text('Save'),
                              ),
                            if (_isEditing) const SizedBox(width: 12),
                            if (_isEditing)
                              TextButton(
                                onPressed: () => setState(() {
                                  _isEditing = false;
                                  _selectedImage = null;
                                }),
                                child: const Text('Cancel'),
                              ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async => await widget.onLogout(),
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
