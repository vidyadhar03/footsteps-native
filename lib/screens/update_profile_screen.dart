import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class UpdateProfileScreen extends StatefulWidget {
  final bool isFromOnboarding;
  final UserProfile? existingProfile;

  const UpdateProfileScreen({
    super.key,
    this.isFromOnboarding = false,
    this.existingProfile,
  });

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _totalKmController = TextEditingController();
  final _totalCountriesController = TextEditingController();
  
  File? _selectedImage;
  String? _selectedCountry;
  List<String> _selectedTravelStyles = [];
  bool _isLoading = false;

  // Predefined travel style options
  final List<String> _travelStyleOptions = [
    'Raw Adventure',
    'Backpackers', 
    'Travel Filmmaking',
    'Mountaineering',
    'Slow Travel',
    'Eco Travel',
    'Bikepacking',
    'Road Trips',
  ];

  @override
  void initState() {
    super.initState();
    _initializeWithExistingProfile();
  }

  void _initializeWithExistingProfile() {
    if (widget.existingProfile != null) {
      final profile = widget.existingProfile!;
      _nameController.text = profile.name;
      _bioController.text = profile.bio ?? '';
      _selectedCountry = profile.origin;
      _selectedTravelStyles = List.from(profile.styleTags);
      _totalKmController.text = profile.totalKm.toString();
      _totalCountriesController.text = profile.totalCountries.toString();
    } else {
      // Initialize with auth service data for new users
      final authService = Provider.of<AuthService>(context, listen: false);
      _nameController.text = authService.userDisplayName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _totalKmController.dispose();
    _totalCountriesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
        });
      },
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Theme.of(context).colorScheme.surface,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.7,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
    );
  }

  void _toggleTravelStyle(String style) {
    setState(() {
      if (_selectedTravelStyles.contains(style)) {
        _selectedTravelStyles.remove(style);
      } else {
        _selectedTravelStyles.add(style);
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Create profile with form data
      final profile = UserProfile(
        name: _nameController.text.trim().isNotEmpty 
            ? _nameController.text.trim() 
            : authService.userDisplayName,
        email: authService.userEmail,
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        origin: _selectedCountry,
        styleTags: _selectedTravelStyles,
        totalKm: double.tryParse(_totalKmController.text) ?? 0.0,
        totalCountries: int.tryParse(_totalCountriesController.text) ?? 0,
        avatarUrl: null, // TODO: Implement avatar upload to storage
        timezone: 'Asia/Kolkata',
      );

      final success = await authService.createOrUpdateProfile(profile);
      
      if (success && mounted) {
        if (widget.isFromOnboarding) {
          // Navigate to main app
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Go back to profile screen
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSkipOrCancel() async {
    if (widget.isFromOnboarding) {
      // For onboarding, create empty profile
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        
        // Create minimal profile
        final profile = UserProfile(
          name: authService.userDisplayName,
          email: authService.userEmail,
          timezone: 'Asia/Kolkata',
        );

        final success = await authService.createOrUpdateProfile(profile);
        
        if (success && mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      // For edit mode, just go back
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : _handleSkipOrCancel,
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSkipOrCancel,
            child: Text(
              widget.isFromOnboarding ? 'Skip' : 'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar Section
                  _buildAvatarSection(authService),
                  const SizedBox(height: 32),

                  // Name Field
                  _buildNameField(),
                  const SizedBox(height: 20),

                  // Bio Field
                  _buildBioField(),
                  const SizedBox(height: 20),

                  // Origin Country
                  _buildCountryField(),
                  const SizedBox(height: 20),

                  // Travel Style Tags
                  _buildTravelStyleSection(),
                  const SizedBox(height: 20),

                  // Travel Stats
                  _buildTravelStats(),
                  const SizedBox(height: 40),

                  // Submit Button
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildAvatarSection(AuthService authService) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
            child: _selectedImage != null
                ? ClipOval(
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    ),
                  )
                : authService.userAvatarUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          authService.userAvatarUrl,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) => _buildAvatarPlaceholder(),
                        ),
                      )
                    : _buildAvatarPlaceholder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to change photo',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Icon(
      Icons.person,
      size: 60,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Name is required';
        }
        return null;
      },
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      controller: _bioController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Bio (Optional)',
        hintText: 'Tell us about yourself...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.edit_outlined),
      ),
    );
  }

  Widget _buildCountryField() {
    return GestureDetector(
      onTap: _selectCountry,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedCountry ?? 'Select Origin Country (Optional)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _selectedCountry != null 
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel Style (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _travelStyleOptions.map((style) {
            final isSelected = _selectedTravelStyles.contains(style);
            return FilterChip(
              label: Text(style),
              selected: isSelected,
              onSelected: (_) => _toggleTravelStyle(style),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTravelStats() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _totalKmController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total KM (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions_walk_outlined),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (double.tryParse(value) == null) {
                  return 'Enter valid number';
                }
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _totalCountriesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Countries (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.public_outlined),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (int.tryParse(value) == null) {
                  return 'Enter valid number';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.isFromOnboarding ? 'Complete Setup' : 'Update Profile',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
} 