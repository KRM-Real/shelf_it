import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  File? _profileImage;
  String? _profileImageUrl;

  // Cloudinary API credentials
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/dmkfftvi9/image/upload";
  final String cloudinaryPreset = "ml_default";

  // Gender options
  final List<String> _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load existing user data from Firestore
  void _loadUserData() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _genderController.text = data['gender'] ?? '';
          _dobController.text = data['dob'] ?? '';
          _profileImageUrl = data['profileImage'] ?? '';
        });
      }
    }
  }

  // Save user data to Firestore
  void _saveUserData() async {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _genderController.text.trim(),
        'dob': _dobController.text.trim(),
        'profileImage': _profileImageUrl,
      };

      await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .set(updatedData, SetOptions(merge: true));

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  // Upload image to Cloudinary
  Future<void> _uploadToCloudinary(File imageFile) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      request.fields['upload_preset'] = cloudinaryPreset;

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var jsonResponse = jsonDecode(responseData.body);

        setState(() {
          _profileImageUrl = jsonResponse['secure_url'];
        });

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Profile image uploaded successfully!')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image. Please try again.'),
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Select a profile picture
  Future<void> _selectProfilePicture() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      if (_profileImage != null && _profileImage!.existsSync()) {
        await _uploadToCloudinary(_profileImage!);
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Invalid image file. Please try again.'),
          ),
        );
      }
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Image selection canceled.')),
      );
    }
  }

  // Open Date Picker
  Future<void> _selectDateOfBirth() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text =
            "${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'User Profile',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8F4FD)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1565C0),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[100],
                                child:
                                    (_profileImageUrl != null &&
                                        _profileImageUrl!.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: _profileImageUrl!,
                                        imageBuilder:
                                            (context, imageProvider) =>
                                                CircleAvatar(
                                                  radius: 50,
                                                  backgroundImage:
                                                      imageProvider,
                                                ),
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Color(0xFF1565C0),
                                            ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Color(0xFF1565C0),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _selectProfilePicture,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1565C0),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Profile Picture',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the camera icon to update your profile picture',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Profile Information Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Color(0xFF1565C0),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Profile Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Name Field
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Phone Field
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Gender Dropdown
                        _buildDropdownField(
                          value: _genderController.text.isEmpty
                              ? null
                              : _genderController.text,
                          label: 'Gender',
                          icon: Icons.wc_outlined,
                          items: _genders,
                          onChanged: (value) {
                            setState(() {
                              _genderController.text = value ?? '';
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // Date of Birth Field
                        _buildTextField(
                          controller: _dobController,
                          label: 'Date of Birth',
                          icon: Icons.calendar_today_outlined,
                          readOnly: true,
                          onTap: _selectDateOfBirth,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select your date of birth';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
    );
  }
}
