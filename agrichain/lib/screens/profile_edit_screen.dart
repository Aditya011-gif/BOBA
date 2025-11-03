import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/firestore_models.dart';
import '../services/profile_service.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const ProfileEditScreen({
    Key? key,
    this.profileData,
  }) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  
  // Form controllers
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _farmSizeController = TextEditingController();
  final TextEditingController _businessTypeController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  String? _selectedState;
  List<String> _selectedCrops = [];
  List<String> _selectedServices = [];
  
  // Static data
  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
  ];
  
  final List<String> _cropOptions = [
    'Wheat', 'Rice', 'Maize', 'Barley', 'Sugarcane', 'Cotton', 'Jute',
    'Tea', 'Coffee', 'Rubber', 'Coconut', 'Groundnut', 'Mustard', 'Sunflower',
    'Soybean', 'Potato', 'Onion', 'Tomato', 'Chili', 'Turmeric', 'Ginger',
    'Garlic', 'Banana', 'Mango', 'Apple', 'Orange', 'Grapes', 'Pomegranate'
  ];
  
  final List<String> _serviceOptions = [
    'Wholesale Trading', 'Retail Distribution', 'Export Services',
    'Processing & Packaging', 'Cold Storage', 'Transportation',
    'Quality Testing', 'Market Analysis', 'Financial Services',
    'Agricultural Consulting', 'Equipment Rental', 'Seed Supply'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.profileData != null) {
      final data = widget.profileData!;
      
      _addressController.text = data['address'] ?? '';
      _cityController.text = data['city'] ?? '';
      _pincodeController.text = data['pincode'] ?? '';
      _bioController.text = data['bio'] ?? '';
      _experienceController.text = data['experience']?.toString() ?? '';
      _selectedState = data['state'];
      
      // User type specific data
        final currentUser = Provider.of<AppState>(context, listen: false).currentUser;
        if (currentUser?.userType == UserType.farmer) {
        _farmSizeController.text = data['farmSize'] ?? '';
        
        // Parse crops
        if (data['crops'] != null) {
          if (data['crops'] is String) {
            try {
              final cropsData = jsonDecode(data['crops']);
              if (cropsData is List) {
                _selectedCrops = cropsData.cast<String>();
              }
            } catch (e) {
              _selectedCrops = [data['crops']];
            }
          } else if (data['crops'] is List) {
            _selectedCrops = data['crops'].cast<String>();
          }
        }
      } else if (currentUser?.userType == UserType.buyer) {
        _businessTypeController.text = data['businessType'] ?? '';
        _gstController.text = data['gstNumber'] ?? '';
        
        // Parse services
        if (data['services'] != null) {
          if (data['services'] is String) {
            try {
              final servicesData = jsonDecode(data['services']);
              if (servicesData is List) {
                _selectedServices = servicesData.cast<String>();
              }
            } catch (e) {
              _selectedServices = [data['services']];
            }
          } else if (data['services'] is List) {
            _selectedServices = data['services'].cast<String>();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _farmSizeController.dispose();
    _businessTypeController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 16),
              _buildPersonalInfoSection(),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Location Details'),
              const SizedBox(height: 16),
              _buildLocationSection(),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Professional Information'),
              const SizedBox(height: 16),
              _buildProfessionalSection(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Tell us about yourself...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
          maxLines: 3,
          maxLength: 500,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bio is required';
            }
            if (value.trim().length < 10) {
              return 'Bio must be at least 10 characters long';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _experienceController,
          decoration: const InputDecoration(
            labelText: 'Years of Experience',
            hintText: 'Enter your experience in years',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work_outline),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Experience is required';
            }
            final experience = int.tryParse(value);
            if (experience == null || experience < 0 || experience > 50) {
              return 'Please enter a valid experience (0-50 years)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            hintText: 'Enter your full address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home_outlined),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Address is required';
            }
            if (value.trim().length < 10) {
              return 'Please enter a complete address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                items: _indianStates.map((state) {
                  return DropdownMenuItem(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedState = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'State is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pincodeController,
          decoration: const InputDecoration(
            labelText: 'Pincode',
            hintText: 'Enter 6-digit pincode',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.pin_drop),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Pincode is required';
            }
            if (value.length != 6) {
              return 'Pincode must be 6 digits';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfessionalSection() {
    final currentUser = Provider.of<AppState>(context, listen: false).currentUser;
    if (currentUser?.userType == UserType.farmer) {
      return _buildFarmerSection();
    } else if (currentUser?.userType == UserType.buyer) {
      return _buildBuyerSection();
    }
    return const SizedBox.shrink();
  }

  Widget _buildFarmerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _farmSizeController,
          decoration: const InputDecoration(
            labelText: 'Farm Size',
            hintText: 'e.g., 5 acres, 2 hectares',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.landscape),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Farm size is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Crops Grown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildMultiSelectChips(
          options: _cropOptions,
          selectedItems: _selectedCrops,
          onSelectionChanged: (selected) {
            setState(() {
              _selectedCrops = selected;
            });
          },
        ),
        if (_selectedCrops.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one crop',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBuyerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _businessTypeController,
          decoration: const InputDecoration(
            labelText: 'Business Type',
            hintText: 'e.g., Wholesale Distributor, Retailer',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Business type is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _gstController,
          decoration: const InputDecoration(
            labelText: 'GST Number',
            hintText: 'Enter 15-digit GST number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.receipt_long),
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(15),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'GST number is required';
            }
            if (value.length != 15) {
              return 'GST number must be 15 characters';
            }
            // Basic GST format validation
            final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
            if (!gstRegex.hasMatch(value)) {
              return 'Please enter a valid GST number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Services Offered',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildMultiSelectChips(
          options: _serviceOptions,
          selectedItems: _selectedServices,
          onSelectionChanged: (selected) {
            setState(() {
              _selectedServices = selected;
            });
          },
        ),
        if (_selectedServices.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one service',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMultiSelectChips({
    required List<String> options,
    required List<String> selectedItems,
    required Function(List<String>) onSelectionChanged,
  }) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: options.map((option) {
        final isSelected = selectedItems.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            final newSelection = List<String>.from(selectedItems);
            if (selected) {
              newSelection.add(option);
            } else {
              newSelection.remove(option);
            }
            onSelectionChanged(newSelection);
          },
          selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
          checkmarkColor: AppTheme.primaryGreen,
        );
      }).toList(),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate user type specific requirements
    final currentUser = Provider.of<AppState>(context, listen: false).currentUser;
    if (currentUser?.userType == UserType.farmer && _selectedCrops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one crop'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentUser?.userType == UserType.buyer && _selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Prepare profile data
      final profileData = {
        'userId': currentUser.id,
        'userType': currentUser.userType.name,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _selectedState!,
        'pincode': _pincodeController.text.trim(),
        'bio': _bioController.text.trim(),
        'experience': int.parse(_experienceController.text.trim()),
      };

      // Add user type specific data
      if (currentUser.userType == UserType.farmer) {
        profileData['farmSize'] = _farmSizeController.text.trim();
        profileData['crops'] = jsonEncode(_selectedCrops);
      } else if (currentUser.userType == UserType.buyer) {
        profileData['businessType'] = _businessTypeController.text.trim();
        profileData['gstNumber'] = _gstController.text.trim();
        profileData['services'] = jsonEncode(_selectedServices);
      }

      // Update profile
      await _profileService.updateProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
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
}