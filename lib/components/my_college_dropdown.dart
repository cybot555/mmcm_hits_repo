import 'package:flutter/material.dart';
import 'package:mmcm_hits/components/college.dart';

class MyCollegeDropdown extends StatefulWidget {
  final Function(String?, String?) onChanged;

  const MyCollegeDropdown({
    super.key,
    required this.onChanged,
    required List colleges,
  });

  @override
  State<MyCollegeDropdown> createState() => _MyCollegeDropdownState();
}

class _MyCollegeDropdownState extends State<MyCollegeDropdown> {
  String? selectedCollege;
  String? selectedProgram;

  //  Colleges and program
  final List<College> colleges = [
    College(
      name: "Alfonso T. Yuchengco College of Business",
      programs: [
        "BS Entrepreneurship",
        "BS Management Accounting",
        "BS Real Estate Management",
        "BS Tourism Management",
        "BS Accountancy",
        "BS Accounting Information System",
      ],
    ),
    College(
      name: "College of Arts and Sciences",
      programs: ["BA Communication", "Bachelor of Multimedia Arts"],
    ),
    College(
      name: "Computer and Information Science",
      programs: [
        "BS Computer Science",
        "BS Entertainment and Multimedia Computing",
        "BS Information Systems",
      ],
    ),
    College(
      name: "College of Engineering and Architecture",
      programs: [
        "BS Architecture",
        "BS Chemical Engineering",
        "BS Civil Engineering",
        "BS Computer Engineering",
        "BS Electrical Engineering",
        "BS Electronics Engineering",
        "BS Industrial Engineering",
        "BS Mechanical Engineering",
      ],
    ),
    College(
      name: "College of Health Sciences",
      programs: [
        "BS Biology",
        "BS Pharmacy",
        "BS Psychology",
        "BS Physical Therapy",
        "BS Medical Laboratory Science",
      ],
    ),
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
          initialValue: selectedProgram,
          decoration: const InputDecoration(
            labelText: "Select Program",
            border: OutlineInputBorder(),
          ),
          isExpanded: true,
          items:
              (selectedCollege == null
                      ? <String>[]
                      : colleges
                            .firstWhere((c) => c.name == selectedCollege)
                            .programs)
                  .map((program) {
                    return DropdownMenuItem(
                      value: program,
                      child: Text(program),
                    );
                  })
                  .toList(),
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
