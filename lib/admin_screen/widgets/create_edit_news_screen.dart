import 'package:flutter/material.dart';
import 'package:waygo/services/news_service.dart';
import 'package:intl/intl.dart';

class CreateEditNewsScreen extends StatefulWidget {
  final Map<String, dynamic>? news; // null for create, populated for edit

  const CreateEditNewsScreen({super.key, this.news});

  @override
  State<CreateEditNewsScreen> createState() => _CreateEditNewsScreenState();
}

class _CreateEditNewsScreenState extends State<CreateEditNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final NewsService _newsService = NewsService();

  String _selectedType = 'Info';
  String _selectedStatus = 'Published'; // Default to Published so it appears to passengers
  DateTime? _publishDate;
  DateTime? _expiryDate;
  bool _isLoading = false;

  final List<String> _types = ['Info', 'Warning', 'Offer'];
  final List<String> _statuses = ['Draft', 'Published', 'Active'];

  @override
  void initState() {
    super.initState();
    if (widget.news != null) {
      _titleController.text = widget.news!['title'] ?? '';
      _descriptionController.text = widget.news!['description'] ?? '';
      _imageUrlController.text = widget.news!['imageUrl'] ?? '';
      _selectedType = widget.news!['type'] ?? 'Info';
      _selectedStatus = widget.news!['status'] ?? 'Draft';
      
      if (widget.news!['publishDate'] != null) {
        if (widget.news!['publishDate'] is String) {
          _publishDate = DateTime.tryParse(widget.news!['publishDate']);
        }
      }
      if (widget.news!['expiryDate'] != null) {
        if (widget.news!['expiryDate'] is String) {
          _expiryDate = DateTime.tryParse(widget.news!['expiryDate']);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isPublishDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isPublishDate ? (_publishDate ?? DateTime.now()) : (_expiryDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isPublishDate) {
          _publishDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.news != null) {
        // Update
        await _newsService.updateNews(
          id: widget.news!['_id'],
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty 
              ? null 
              : _imageUrlController.text.trim(),
          type: _selectedType,
          status: _selectedStatus,
          publishDate: _publishDate?.toIso8601String(),
          expiryDate: _expiryDate?.toIso8601String(),
        );
      } else {
        // Create
        await _newsService.createNews(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty 
              ? null 
              : _imageUrlController.text.trim(),
          type: _selectedType,
          status: _selectedStatus, // Include status when creating
          publishDate: _publishDate?.toIso8601String(),
          expiryDate: _expiryDate?.toIso8601String(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.news != null 
                ? 'News updated successfully' 
                : 'News created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.news != null ? 'Edit News' : 'Create News'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: _types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              // Status dropdown - show for both create and edit
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(_publishDate == null 
                          ? 'Publish Date (optional)' 
                          : 'Publish: ${DateFormat('dd/MM/yyyy').format(_publishDate!)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _pickDate(context, true),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(_expiryDate == null 
                          ? 'Expiry Date (optional)' 
                          : 'Expiry: ${DateFormat('dd/MM/yyyy').format(_expiryDate!)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.event_busy),
                        onPressed: () => _pickDate(context, false),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.news != null ? 'Update News' : 'Create News'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

