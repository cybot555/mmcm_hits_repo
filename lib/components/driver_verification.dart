import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DriverVerification extends StatefulWidget {
  final Function(bool bothUploaded) onVerificationChanged;

  const DriverVerification({super.key, required this.onVerificationChanged});

  @override
  State<DriverVerification> createState() => _DriverVerificationState();
}

class _DriverVerificationState extends State<DriverVerification> {
  File? licenseImage;
  File? orcrImage;

  // -------------------------------
  // PICK LICENSE IMAGE
  // -------------------------------
  Future<void> _pickLicense() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      setState(() {
        licenseImage = File(result.files.single.path!);
      });

      widget.onVerificationChanged(_bothUploaded());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver’s License selected ✅'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // -------------------------------
  // PICK OR/CR IMAGE
  // -------------------------------
  Future<void> _pickORCR() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      setState(() {
        orcrImage = File(result.files.single.path!);
      });

      widget.onVerificationChanged(_bothUploaded());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OR/CR selected ✅'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // -------------------------------
  // CHECK IF BOTH ARE "UPLOADED"
  // -------------------------------
  bool _bothUploaded() => licenseImage != null && orcrImage != null;

  // -------------------------------
  // UPLOAD BOX UI
  // -------------------------------
  Widget _buildUploadBox(String label, bool isLicense, double boxWidth) {
    final file = isLicense ? licenseImage : orcrImage;
    final isUploaded = file != null;

    return GestureDetector(
      onTap: () => isLicense ? _pickLicense() : _pickORCR(),
      child: Container(
        width: boxWidth,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isUploaded ? Colors.green : Colors.red,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUploaded ? Icons.check_circle : Icons.image_outlined,
                    size: 40,
                    color: isUploaded ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  file,
                  width: boxWidth,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  // -------------------------------
  // MAIN BUILD
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 220, 220),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            "DRIVER VERIFICATION REQUIRED",
            style: TextStyle(
              color: Color.fromARGB(255, 255, 17, 0),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),

          // ✅ FIXED: responsive sizing using LayoutBuilder + Wrap to avoid overflow
          LayoutBuilder(
            builder: (context, constraints) {
              // total horizontal padding inside this container = 12 (left) + 12 (right) from padding
              // but also consider some breathing room: we'll compute half of available width and clamp.
              final availableWidth = constraints.maxWidth;
              // spacing between the two boxes in Wrap is 10, so subtract that when splitting
              final spacing = 10.0;
              double computed = (availableWidth - spacing) / 2;

              // clamp so boxes don't become too small or too wide
              const minBoxWidth = 120.0;
              const maxBoxWidth = 220.0;
              final boxWidth = computed.clamp(minBoxWidth, maxBoxWidth);

              return Wrap(
                alignment: WrapAlignment.center,
                spacing: spacing,
                runSpacing: 10,
                children: [
                  _buildUploadBox("Driver's License", true, boxWidth),
                  _buildUploadBox("OR/CR", false, boxWidth),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}