import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DriverVerification extends StatefulWidget {
  const DriverVerification({super.key});

  @override
  State<DriverVerification> createState() => _DriverVerificationState();
}

class _DriverVerificationState extends State<DriverVerification> {
  String? licenseFile;
  String? orcrFile;

  // Function to pick file
  Future<void> _pickFile(bool isLicense) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      setState(() {
        if (isLicense) {
          licenseFile = result.files.single.name;
        } else {
          orcrFile = result.files.single.name;
        }
      });
    }
  }

  Widget _buildUploadBox(String label, bool isLicense) {
    return GestureDetector(
      onTap: () => _pickFile(isLicense),
      child: Container(
        width: 140,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              isLicense ? "Upload Driver's License" : "Upload OR/CR",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),
            if ((isLicense ? licenseFile : orcrFile) != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isLicense ? licenseFile! : orcrFile!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.green),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadBox("Driver's License", true),
                _buildUploadBox("OR/CR", false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
