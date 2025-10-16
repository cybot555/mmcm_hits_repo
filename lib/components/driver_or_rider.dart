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
        // -------------------------------
        // DRIVER OR HITCHER RADIO BUTTONS
        // -------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.start, // ✅ stays side by side (not centered)
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text(
                  "Driver",
                  overflow: TextOverflow.ellipsis, // ✅ prevents text cutoff
                  softWrap: false,
                ),
                value: "Driver", // ✅ saves as Driver
                groupValue: selectedRole,
                onChanged: onChanged,
                contentPadding: EdgeInsets.zero, // ✅ keep it tighter
                dense: true, // ✅ more compact look
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text(
                  "Hitcher",
                  overflow: TextOverflow.ellipsis, // ✅ fixes text cutting
                  softWrap: false,
                ),
                value: "Hitcher", // ✅ saves as Passenger
                groupValue: selectedRole,
                onChanged: onChanged,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}