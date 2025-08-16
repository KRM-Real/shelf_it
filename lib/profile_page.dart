import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_currentUser.uid).get();

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
        'profileImage': _profileImageUrl, // Save profile image URL
      };

      await _firestore.collection('users').doc(_currentUser.uid).set(
            updatedData,
            SetOptions(merge: true),
          );

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  // Upload image to Cloudinary
  Future<void> _uploadToCloudinary(File imageFile) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(cloudinaryUrl),
      );
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));
      request.fields['upload_preset'] = cloudinaryPreset;

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var jsonResponse = jsonDecode(responseData.body);

        setState(() {
          _profileImageUrl = jsonResponse['secure_url'];
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Profile image uploaded successfully!')),
        );
      } else {
        // Debug: Upload failed - could not get error details  
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to upload image. Please try again.')),
        );
      }
    } catch (e) {
      // Debug: Exception: $e
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Select a profile picture
  Future<void> _selectProfilePicture() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      // Upload image to Cloudinary
      if (_profileImage != null && _profileImage!.existsSync()) {
        await _uploadToCloudinary(_profileImage!);
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Invalid image file. Please try again.')),
        );
      }
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Image selection canceled.')),
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
        // Format the date as mm-dd-yyyy
        _dobController.text =
            "${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF213A57),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Color(0xFFE6F2F0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: (_profileImageUrl != null &&
                              _profileImageUrl!.isNotEmpty)
                          ? NetworkImage(_profileImageUrl!) as ImageProvider
                          : AssetImage('assets/default_profile.png'),
                      onBackgroundImageError: (exception, stackTrace) {
                        // Debug: Failed to load image
                      },
                      child: (_profileImageUrl == null ||
                              _profileImageUrl!.isEmpty)
                          ? const Icon(Icons.account_circle,
                              size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _selectProfilePicture,
                        child: CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 15,
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Divider(),
              Center(
                child: Text(
                  'Profile Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              Divider(),
// Name Text Field
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100], // Light grey color
                      ),
                      textAlign: TextAlign.start, // Adjust text alignment here
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your name' : null,
                    ),
                  ],
                ),
              ),
              // Phone Text Field
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    SizedBox(height: 16), // Add space above the TextFormField
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100], // Light grey color
                      ),
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.start, // Align text to the left
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your phone number' : null,
                    ),
                  ],
                ),
              ),

              // Gender selection with icons
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                        height:
                            16), // Add space above the DropdownButtonFormField
                    DropdownButtonFormField<String>(
                      initialValue: _genderController.text.isEmpty
                          ? null
                          : _genderController.text,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100], // Light grey color
                      ),
                      items: _genders.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Row(
                            children: [
                              gender == 'Male'
                                  ? Icon(Icons.male, color: Colors.grey[900])
                                  : Icon(Icons.female, color: Colors.grey[900]),
                              SizedBox(width: 8),
                              Text(gender),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _genderController.text = newValue!;
                        });
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Select your gender'
                          : null,
                    ),
                  ],
                ),
              ),

              // Date of Birth Text Field
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    SizedBox(height: 16), // Add space above the TextFormField
                    TextFormField(
                      controller: _dobController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        prefixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: _selectDateOfBirth,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      readOnly: true,
                      textAlign: TextAlign.start, // Adjust text alignment here
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your date of birth' : null,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveUserData, //add color to the button
                style: ElevatedButton.styleFrom(
                  //add shadow to the button
                  elevation: 5,
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black, // foreground color
                ),
                child: Text('Save',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
