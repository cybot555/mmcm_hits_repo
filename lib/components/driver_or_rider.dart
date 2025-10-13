import 'package:flutter/material.dart';

class DriverOrRider extends StatelessWidget {
  final String? selectedRole;
  final ValueChanged<String?> onChanged;

  const DriverOrRider({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text("Driver"),
                value: "Driver", // ✅ saves as Driver
                groupValue: selectedRole,
                onChanged: onChanged,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text("Hitcher"), // 👀 shows Hitcher in UI
                value: "Hitcher", // ✅ saves as Passenger
                groupValue: selectedRole,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
