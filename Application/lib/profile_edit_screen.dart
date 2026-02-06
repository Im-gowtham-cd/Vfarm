import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:vfarm/firebase_service.dart';
import 'package:vfarm/models/user_profile_model.dart';
import 'package:vfarm/l10n/app_localizations.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserProfileModel? userProfile;
  final bool fromTutorial;

  const ProfileEditScreen({
    super.key,
    this.userProfile,
    this.fromTutorial = false,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmLocationController = TextEditingController();
  final _farmSizeController = TextEditingController();

  List<String> _selectedCrops = [];
  String _profileImageUrl = '';
  bool _isLoading = false;

  final List<String> _cropOptions = [
    'Rice',
    'Wheat',
    'Corn',
    'Sugarcane',
    'Cotton',
    'Tomato',
    'Potato',
    'Onion',
    'Cabbage',
    'Carrot',
    'Beans',
    'Peas',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.userProfile != null) {
      _nameController.text = widget.userProfile!.name;
      _phoneController.text = widget.userProfile!.phone ?? '';
      _farmLocationController.text = widget.userProfile!.farmLocation ?? '';
      _farmSizeController.text = widget.userProfile!.farmSize?.toString() ?? '';
      _selectedCrops = List.from(widget.userProfile!.cropTypes);
      _profileImageUrl = widget.userProfile!.profileImageUrl ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.fromTutorial,
      onPopInvoked: (didPop) async {
        if (!didPop && widget.fromTutorial) {
          _showExitWarningDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A9D88),
          foregroundColor: Colors.white,
          title: Text(
            widget.fromTutorial
                ? AppLocalizations.of(context)!.completeYourProfile
                : AppLocalizations.of(context)!.editProfile,
          ),
          automaticallyImplyLeading: !widget.fromTutorial,
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: Text(
                AppLocalizations.of(context)!.save,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Image
              Center(
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        _profileImageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(_profileImageUrl)
                            : null,
                    child:
                        _profileImageUrl.isEmpty
                            ? const Icon(
                              Icons.camera_alt,
                              size: 30,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  AppLocalizations.of(context)!.tapToChangeProfilePicture,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 30),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.name,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterYourName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.phoneNumber,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                      context,
                    )!.pleaseEnterYourPhoneNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Farm Location
              TextFormField(
                controller: _farmLocationController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.farmLocation,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                      context,
                    )!.pleaseEnterYourFarmLocation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Farm Size
              TextFormField(
                controller: _farmSizeController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.farmSizeAcres,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.landscape),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                      context,
                    )!.pleaseEnterYourFarmSize;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Crop Types
              Text(
                AppLocalizations.of(context)!.cropTypes,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _cropOptions.map((crop) {
                      final isSelected = _selectedCrops.contains(crop);
                      return FilterChip(
                        label: Text(crop),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCrops.add(crop);
                            } else {
                              _selectedCrops.remove(crop);
                            }
                          });
                        },
                        selectedColor: const Color(0xFF0A9D88).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF0A9D88),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A9D88),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            AppLocalizations.of(context)!.saveProfile,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final imageUrl = await FirebaseService.uploadProfileImage(
          File(image.path),
        );
        setState(() {
          _profileImageUrl = imageUrl;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorUploadingImage}: ${e.toString()}',
            ),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID (String)
      final userId = FirebaseService.getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      // Get current user profile to preserve email and other data
      final currentProfile = FirebaseService.getCurrentUserProfile();
      final email = currentProfile?.email ?? widget.userProfile?.email ?? '';

      final profile = UserProfileModel(
        uid: userId, // userId is already a String
        name: _nameController.text.trim(),
        email: email, // Use preserved email
        phone: _phoneController.text.trim(),
        farmLocation: _farmLocationController.text.trim(),
        farmSize: double.tryParse(_farmSizeController.text.trim()),
        cropTypes: _selectedCrops,
        profileImageUrl: _profileImageUrl,
        createdAt: widget.userProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseService.createOrUpdateProfile(profile);

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.profileUpdatedSuccessfully,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.errorSavingProfile}: ${e.toString()}',
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showExitWarningDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.completeYourProfile),
            content: Text(
              AppLocalizations.of(context)!.profileCompletionMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.continueEditing),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _farmLocationController.dispose();
    _farmSizeController.dispose();
    super.dispose();
  }
}
