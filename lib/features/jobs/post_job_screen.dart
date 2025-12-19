import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/section_title.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();

  String _category = "Plumber";

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post a job")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle(
            title: "Create a job",
            subtitle: "UI demo form — backend later",
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                AppTextField(
                  controller: _title,
                  label: "Title",
                  hint: "e.g. Need AC repair",
                  prefixIcon: const Icon(Icons.title),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _location,
                  label: "Location",
                  hint: "e.g. DHA Phase 4, Karachi",
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _category,
                      items: const [
                        DropdownMenuItem(value: "Plumber", child: Text("Plumber")),
                        DropdownMenuItem(value: "Electrician", child: Text("Electrician")),
                        DropdownMenuItem(value: "AC/HVAC", child: Text("AC/HVAC")),
                        DropdownMenuItem(value: "Pest Control", child: Text("Pest Control")),
                        DropdownMenuItem(value: "Flooring", child: Text("Flooring")),
                        DropdownMenuItem(value: "Mechanic", child: Text("Mechanic")),
                      ],
                      onChanged: (v) => setState(() => _category = v ?? "Plumber"),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    hintText: "Explain the problem clearly...",
                  ),
                ),

                const SizedBox(height: 14),
                PrimaryButton(
                  text: "Post Job (UI)",
                  icon: Icons.rocket_launch_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Job posted (UI demo). Backend baad mein ✅")),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
