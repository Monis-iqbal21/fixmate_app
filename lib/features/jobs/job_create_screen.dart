import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'jobs_api.dart';

class JobCreateScreen extends StatefulWidget {
  const JobCreateScreen({super.key});

  @override
  State<JobCreateScreen> createState() => _JobCreateScreenState();
}

class _JobCreateScreenState extends State<JobCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _budget = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();

  // ✅ NEW: Address
  final _address = TextEditingController();

  bool _loading = false;

  final List<String> _categories = const [
    "Electrician",
    "Plumber",
    "AC / HVAC",
    "Carpenter",
    "Painter",
    "Cleaning",
    "Appliance Repair",
    "General Handyman",
  ];
  String? _category;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _budget.dispose();
    _city.dispose();
    _area.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final res = await JobsApi.create(
        category: _category!,            // required
        title: _title.text,
        description: _desc.text,
        budget: _budget.text,
        city: _city.text,
        areaName: _area.text,            // (agar tumhare API me area_name hai)
        address: _address.text,          // ✅ required
      );

      final ok = (res["status"] ?? "").toString().toLowerCase() == "ok";
      if (!ok) throw Exception((res["msg"] ?? "Create failed").toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job posted ✅")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text("Post a Job")),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? "Category required" : null,
                    decoration: InputDecoration(
                      labelText: "Category",
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  _field(_title, "Title", "Electrician needed"),
                  const SizedBox(height: 12),
                  _field(_desc, "Description", "Explain your issue...", maxLines: 4),
                  const SizedBox(height: 12),
                  _field(_budget, "Budget (Rs)", "5000",
                      keyboard: TextInputType.number),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_city, "City", "Karachi")),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_area, "Area", "Gulshan")),
                    ],
                  ),

                  const SizedBox(height: 12),
                  // ✅ Address field
                  _field(_address, "Address", "House/Street/Block, etc", maxLines: 2),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_loading ? "Posting..." : "Post Job"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    String hint, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? "$label required" : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
