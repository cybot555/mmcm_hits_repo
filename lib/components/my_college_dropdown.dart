import 'package:flutter/material.dart';
import 'package:mmcm_hits/components/college.dart';


class MyCollegeDropdown extends StatefulWidget {
  final Function(String?, String?) onChanged;

  const MyCollegeDropdown({super.key, required this.onChanged, required List colleges});

  @override
  State<MyCollegeDropdown> createState() => _MyCollegeDropdownState();
}

class _MyCollegeDropdownState extends State<MyCollegeDropdown> {
  String? selectedCollege;
  String? selectedProgram;

  //  Colleges and program
  final List<College> colleges = [
    College(name: "Business", programs: [
      "Entrepreneurship",
      "Management Accounting",
      "Real Estate Management",
      "Tourism Management",
      "Accountancy",
      "Accounting Information System",
    ]),
    College(name: "Arts and Science", programs: [
      "Arts in Communication",
      "Multimedia Arts",
    ]),
    College(name: "Computer and Information Science", programs: [
      "Computer Science",
      "Entertainment and Multimedia Computing",
      "Information Systems",
    ]),
    College(name: "Engineering and Architecture", programs: [
      "Architecture",
      "Chemical Engineering",
      "Civil Engineering",
      "Computer Engineering",
    ]),
    College(name: "Health Sciences", programs: [
      "Medical Biology",
      "Pharmacy",
      "Psychology",
      "Physical Therapy",
      "Medical Technology / Medical Laboratory Science",
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // College dropdown
        DropdownButtonFormField<String>(
          value: selectedCollege,
          decoration: const InputDecoration(
            labelText: "Select College",
            border: OutlineInputBorder(),
          ),
          isExpanded: true,
          items: colleges.map((college) {
            return DropdownMenuItem(
              value: college.name,
              child: Text(college.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedCollege = value;
              selectedProgram = null; // reset program after picking college
            });
            widget.onChanged(selectedCollege, selectedProgram);
          },
        ),

        const SizedBox(height: 15),

        // Program dropdown
        DropdownButtonFormField<String>(
          value: selectedProgram,
          decoration: const InputDecoration(
            labelText: "Select Program",
            border: OutlineInputBorder(),
          ),
          isExpanded: true,
          items: (selectedCollege == null
                  ? <String>[]
                  : colleges
                      .firstWhere((c) => c.name == selectedCollege)
                      .programs)
              .map((program) {
            return DropdownMenuItem(
              value: program,
              child: Text(program),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedProgram = value;
            });
            widget.onChanged(selectedCollege, selectedProgram);
          },
        ),
      ],
    );
  }
}
