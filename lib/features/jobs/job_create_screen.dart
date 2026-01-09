import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart'; // Ensure you have record: ^5.0.0 or compatible
import 'package:intl/intl.dart' as intl;

import '../../core/app_colors.dart';
import 'job_model.dart';
import 'jobs_api.dart';
import 'job_detail_screen.dart';

class JobCreateScreen extends StatefulWidget {
  final JobModel? jobToEdit; // ✅ Optional parameter for Edit Mode

  const JobCreateScreen({super.key, this.jobToEdit});

  @override
  State<JobCreateScreen> createState() => _JobCreateScreenState();
}

class _JobCreateScreenState extends State<JobCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _location = TextEditingController();
  final _address = TextEditingController();

  DateTime? _selectedDeadline;
  bool _loading = false;

  // ✅ Helper to check if we are editing
  bool get _isEditMode => widget.jobToEdit != null;

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

  // Media Logic
  final _picker = ImagePicker();
  final List<XFile> _media = [];
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  String? _audioDataUrl;
  String? _audioMime;

  @override
  void initState() {
    super.initState();
    // ✅ Pre-fill form if editing
    if (_isEditMode) {
      final j = widget.jobToEdit!;
      _title.text = j.title;
      _desc.text = j.description;
      _price.text = j.budget.toString(); 
      _location.text = j.city; 
      
      // ✅ FIXED: Changed j.location to j.area (matches your JobModel)
      _address.text = j.area; 
      
      // Category matching
      if (_categories.contains(j.category)) {
        _category = j.category;
      } else {
        _category = null; 
      }
      
      // ✅ FIXED: j.deadline is already DateTime, just assign it directly
      _selectedDeadline = j.deadline;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _location.dispose();
    _address.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _clearAudio() {
    setState(() {
      _audioDataUrl = null;
      _audioMime = null;
      _recording = false;
    });
  }

  int _extractCreatedJobId(Map<String, dynamic> res) {
    if (res["job_id"] != null) return int.parse(res["job_id"].toString());
    if (res["data"] != null && res["data"]["id"] != null) {
      return int.parse(res["data"]["id"].toString());
    }
    return 0;
  }

  bool _isImage(XFile f) {
    final mt = (f.mimeType ?? "").toLowerCase();
    if (mt.startsWith("image/")) return true;
    final name = f.name.toLowerCase();
    return name.endsWith(".jpg") || name.endsWith(".jpeg") || name.endsWith(".png") || name.endsWith(".webp") || name.endsWith(".gif");
  }

  String _mediaKind(XFile f) {
    if (_isImage(f)) return "image";
    final mt = (f.mimeType ?? "").toLowerCase();
    if (mt.startsWith("video/")) return "video";
    final name = f.name.toLowerCase();
    if (name.endsWith(".mp4") || name.endsWith(".mov") || name.endsWith(".mkv") || name.endsWith(".avi") || name.endsWith(".webm")) {
      return "video";
    }
    return "file";
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() => _media.addAll(files));
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _media.add(file));
  }

  void _removeMediaAt(int i) => setState(() => _media.removeAt(i));

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(), 
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path == null || path.isEmpty) return;
      final bytes = await XFile(path).readAsBytes();
      final lower = path.toLowerCase();
      String mime = "audio/webm";
      if (lower.endsWith(".m4a")) mime = "audio/mp4";
      if (lower.endsWith(".aac")) mime = "audio/aac";
      if (lower.endsWith(".wav")) mime = "audio/wav";
      if (lower.endsWith(".mp3")) mime = "audio/mpeg";
      final b64 = base64Encode(bytes);
      setState(() {
        _audioMime = mime;
        _audioDataUrl = "data:$mime;base64,$b64";
      });
      return;
    }
    final ok = await _recorder.hasPermission();
    if (!ok) return;
    final config = kIsWeb ? const RecordConfig(encoder: AudioEncoder.opus) : const RecordConfig(encoder: AudioEncoder.aacLc);
    await _recorder.start(config, path: kIsWeb ? "voice.webm" : "voice.m4a");
    setState(() => _recording = true);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deadline required")));
      return;
    }

    setState(() => _loading = true);

    try {
      final formattedDate = intl.DateFormat('yyyy-MM-dd').format(_selectedDeadline!);
      final mediaKinds = _media.map(_mediaKind).toList();

      if (_isEditMode) {
        // ✅ CALL UPDATE API
        final data = {
          "title": _title.text.trim(),
          "description": _desc.text.trim(),
          "category": _category,
          "budget": _price.text.trim(),
          "deadline": formattedDate,
          "location": _address.text.trim(), // Maps to Detailed Address
        };

        final ok = await JobsApi.updateJob(widget.jobToEdit!.id, data);
        
        if (ok && mounted) {
           Navigator.pop(context, true); // Return true to trigger list refresh
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job updated successfully")));
        } else {
           throw Exception("Update failed");
        }
      } else {
        // ✅ CALL CREATE API
        final res = await JobsApi.create(
          category: _category!,
          title: _title.text.trim(),
          description: _desc.text.trim(),
          price: int.tryParse(_price.text.trim()) ?? 0,
          location: _address.text.trim(), // Assuming address maps to location in create
          deadline: formattedDate,
          mediaFiles: _media,
          mediaKinds: mediaKinds,
          audioBase64: _audioDataUrl,
          audioMime: _audioMime,
        );
        final newId = _extractCreatedJobId(res);
        if (newId <= 0) throw Exception("Job creation failed");
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: newId)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(_isEditMode ? "Edit Job Post" : "Post a Job")), // ✅ Dynamic Title
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
                    value: _category,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _category = v),
                    validator: (v) => v == null ? "Required" : null,
                    decoration: const InputDecoration(labelText: "Category"),
                  ),
                  const SizedBox(height: 12),
                  _field(_title, "Title", "e.g. Plumber needed"),
                  const SizedBox(height: 12),
                  _field(_desc, "Description", "Details...", maxLines: 4),
                  const SizedBox(height: 12),
                  _field(_price, "Budget (Pkr)", "0", keyboard: TextInputType.number),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_location, "Location", "City/Area")),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: _selectDeadline,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              _selectedDeadline == null ? "Deadline" : intl.DateFormat('MMM dd').format(_selectedDeadline!),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(_address, "Detailed Address", "Street details"),
                  const SizedBox(height: 16),
                  
                  // ✅ Hides Media upload when editing (as per your request logic)
                  if (!_isEditMode) ...[ 
                    _attachmentsCard(),
                    const SizedBox(height: 16),
                  ],
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isEditMode ? "Update Post" : "Post Job"), // ✅ Dynamic Button Text
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

  Widget _attachmentsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(onPressed: _pickImages, icon: const Icon(Icons.image)),
              IconButton(
                  onPressed: _pickVideo, icon: const Icon(Icons.videocam)),
              IconButton(
                onPressed: _toggleRecord,
                icon: Icon(_recording ? Icons.stop : Icons.mic,
                    color: _recording ? Colors.red : null),
              ),
            ],
          ),
          if (_media.isNotEmpty) const SizedBox(height: 10),
          if (_media.isNotEmpty)
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _mediaThumb(_media[i], i),
              ),
            ),
          if ((_audioDataUrl ?? "").isNotEmpty) ...[
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.audiotrack, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Voice note attached",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                IconButton(
                    onPressed: _clearAudio,
                    icon: const Icon(Icons.close, size: 18))
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _mediaThumb(XFile f, int index) {
    return Stack(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            color: AppColors.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _isImage(f)
                ? FutureBuilder<Uint8List>(
                    future: f.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Center(child: Icon(Icons.error, size: 20));
                      }
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  )
                : const Center(
                    child: Icon(Icons.play_circle_outline, size: 34)),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => _removeMediaAt(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
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