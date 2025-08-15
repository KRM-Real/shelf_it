// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedIndex = 2;

  File? _selectedImage; // Variable to hold the selected image
  String? _uploadedImageUrl; // Variable to hold the Cloudinary image URL
  String? _scannedBarcode; // Variable to hold the scanned barcode
  final bool _isUploading = false; // To track the upload status

  Future<void> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan(); // Start the barcode scanning
      if (!mounted) return;
      setState(() {
        _scannedBarcode = result.rawContent; // Store the scanned barcode
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barcode Scanned: $_scannedBarcode')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan barcode: $e')),
      );
    }
  }

  Future<void> addItem() async {
    //Function for Adding Products
    String name = _nameController.text.trim();
    int quantity = int.tryParse(_quantityController.text) ?? 0;
    String price = _priceController.text;
    String description = _descriptionController.text;

    if (name.isEmpty || quantity <= 0 || price.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      // Retrieve the current user ID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Get the user data to retrieve the mode and company name
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userSnapshot.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found')),
        );
        return;
      }

      // Get the mode (personal or organization) and company name
      String mode = userSnapshot['mode'] ?? 'personal';
      String? companyName =
          mode == 'organization' ? userSnapshot['company_name'] : null;

      // Reference to the Product collection
      final collectionRef = FirebaseFirestore.instance.collection('Product');

      // Check if the barcode is provided and needs validation
      if (_scannedBarcode != null && _scannedBarcode!.isNotEmpty) {
        // Check if the barcode is already used
        final barcodeQuery = await collectionRef
            .where('barcode', isEqualTo: _scannedBarcode)
            .get();

        if (barcodeQuery.docs.isNotEmpty) {
          // Barcode already exists
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Barcode already in use, scan another')),
          );
          return;
        }
      }

      // Check if an item with the same name, mode, and company_name already exists
      final querySnapshot = await collectionRef
          .where('name', isEqualTo: name)
          .where('mode', isEqualTo: mode)
          .where('company_name', isEqualTo: companyName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Item already exists, update the quantity and `updatedAt`
        final existingDoc = querySnapshot.docs.first;
        final existingQuantity = existingDoc['quantity'] ?? 0;

        await existingDoc.reference.update({
          'quantity': existingQuantity + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item quantity updated successfully')),
        );
      } else {
        // Item does not exist, add a new item with `addedAt` and `updatedAt`
        await collectionRef.add({
          'name': name,
          'quantity': quantity,
          'price': price,
          'description': description,
          'barcode': _scannedBarcode ?? '', // Add barcode only if present
          'imageUrl': _uploadedImageUrl ?? '',
          'addedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'mode': mode,
          'userId': userId,
          'company_name': companyName,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully')),
        );
      }

      // Clear the text fields after adding or updating
      _nameController.clear();
      _quantityController.clear();
      _priceController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
        _uploadedImageUrl = null;
        _scannedBarcode = null;
      });
    } catch (e) {
      // Error handling
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add or update item: $e')),
      );
    }
  }

  Future<void> uploadImageToCloudinary(File image) async {
    final cloudName = 'dmkfftvi9';
    final uploadPreset = 'ml_default';

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    try {
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData.body);
        if (!mounted) return;
        setState(() {
          _uploadedImageUrl = jsonResponse['secure_url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to upload image: ${responseData.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> pickImage() async {
    // Function for Adding Image
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);

                  if (pickedFile != null) {
                    if (!mounted) return;
                    setState(() {
                      _selectedImage = File(pickedFile.path);
                    });

                    await uploadImageToCloudinary(_selectedImage!);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedFile =
                      await picker.pickImage(source: ImageSource.camera);

                  if (pickedFile != null) {
                    if (!mounted) return;
                    setState(() {
                      _selectedImage = File(pickedFile.path);
                    });

                    await uploadImageToCloudinary(_selectedImage!);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    //Bottom Navigation Mapping
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });

      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/dashboard');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/product');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/add');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/stocklevels');
          break;
        case 4:
          Navigator.pushReplacementNamed(context, '/orders');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF213A57),
        title: const Text("Add Item", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Color(0xFFE6F2F0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black54),
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_outlined,
                                size: 50, color: Colors.black54),
                            SizedBox(height: 10),
                            Text(
                              "Add Photo",
                              style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
              if (_isUploading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              buildInputField("Item Name", "Enter item name", _nameController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: buildInputField("Quantity", "0", _quantityController,
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildInputField("Price", "0.00", _priceController,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              buildInputField(
                  "Description", "Enter description", _descriptionController,
                  maxLines: 3, isOptional: true),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: scanBarcode,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                ),
                icon: const Icon(Icons.qr_code, color: Colors.black54),
                label: const Text("Scan Barcode"),
              ),
              if (_scannedBarcode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Scanned Barcode: $_scannedBarcode',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00b140),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0B6477),
        selectedItemColor: const Color(0xFF45DFB1),
        unselectedItemColor: Colors.black,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory), label: "Products"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add"),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_outlined), label: "Stock Levels"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Order"),
        ],
      ),
    );
  }

  Widget buildInputField(
      String label, String hint, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      int maxLines = 1,
      bool isOptional = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (!isOptional)
              const Text(
                '*',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black54),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black54),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
