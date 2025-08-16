// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, prefer_final_fields, use_build_context_synchronously, sort_child_properties_last, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductPage extends StatefulWidget {
  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int _selectedIndex = 1;
  String? _userMode;
  String? _companyName;
  String? _userId;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserMode();
  }

  Future<void> _fetchUserMode() async {
    try {
      // Get the current user ID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch the user data from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          _userMode = userSnapshot['mode'];
          _companyName = userSnapshot['mode'] == 'organization'
              ? userSnapshot['company_name']
              : null;
          _userId = userId; // Save the user's ID for filtering in personal mode
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching user data: $e')));
    }
  }

  Future<void> _scanQrCode() async {
    try {
      var result = await BarcodeScanner.scan();

      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        String barcode = result.rawContent.trim(); // Normalize input
        // Debug: Scanned Barcode: $barcode

        // Create a base query
        Query query = FirebaseFirestore.instance
            .collection('Product')
            .where('barcode', isEqualTo: barcode);

        // Apply additional filtering based on user mode
        if (_userMode == 'organization') {
          query = query.where('company_name', isEqualTo: _companyName);
        } else {
          query = query.where('userId', isEqualTo: _userId);
        }

        // Execute the query
        QuerySnapshot productSnapshot = await query.get();

        if (productSnapshot.docs.isNotEmpty) {
          // Assuming one product per barcode
          _showProductDialog(context, productSnapshot.docs.first);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product not found or access denied')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error scanning QR Code: $e')));
    }
  }

  Stream<QuerySnapshot> _getProductsStream() {
    Query query = FirebaseFirestore.instance.collection('Product');

    if (_userMode == 'organization') {
      query = query.where('company_name', isEqualTo: _companyName);
    } else {
      query = query.where('userId', isEqualTo: _userId);
    }

    if (_searchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThanOrEqualTo: '$_searchQuery\uf8ff');
    }

    return query.snapshots();
  }

  void _onItemTapped(int index) {
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

  void _showProductDialog(BuildContext context, DocumentSnapshot product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          titlePadding: const EdgeInsets.all(0), // Remove default padding
          title: Stack(
            alignment: Alignment.center, // Keeps the title centered
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.black,
                  tooltip: 'Go Back',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Text(
                product['name'] ?? 'No Title',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: product['imageUrl'] != null
                      ? Image.network(
                          product['imageUrl'],
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 80),
                        )
                      : const Icon(Icons.broken_image, size: 80),
                ),
                const SizedBox(height: 10.0),
                Text('Name:', style: _dialogFieldTitleStyle),
                Text(product['name'] ?? 'No Name'),
                const SizedBox(height: 8.0),
                Text('Price:', style: _dialogFieldTitleStyle),
                Text('\$${product['price']?.toString() ?? 'N/A'}'),
                const SizedBox(height: 8.0),
                Text('Quantity:', style: _dialogFieldTitleStyle),
                Text(product['quantity']?.toString() ?? 'N/A'),
                const SizedBox(height: 8.0),
                Text('Description:', style: _dialogFieldTitleStyle),
                Text(product['description'] ?? 'No Description'),
                const SizedBox(height: 8.0),
                Text('Added At:', style: _dialogFieldTitleStyle),
                Text(
                  product['addedAt'] != null
                      ? (product['addedAt'] as Timestamp).toDate().toString()
                      : 'Unknown',
                ),
                const SizedBox(height: 8.0),
                Text('Barcode:', style: _dialogFieldTitleStyle),
                Text(product['barcode'] ?? 'No Barcode Available'),
              ],
            ),
          ),
          actions: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Removal'),
                            content: const Text(
                              'Are you sure you want to remove this product?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(), // Close dialog
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pop(); // Close confirmation dialog
                                  Navigator.of(
                                    context,
                                  ).pop(); // Close product dialog
                                  _deleteProduct(
                                    product.id,
                                  ); // Remove the product
                                },
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Remove',
                      style: TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProductPage(
                            product: {
                              ...product.data() as Map<String, dynamic>,
                              'id': product.id, // Include the document ID
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 16.0, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF0B6477,
                      ), // Consistent theme
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper style for field titles
  TextStyle _dialogFieldTitleStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14.0,
  );

  Future<void> _deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Product')
          .doc(productId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing product: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF0F2F5), // Soft light gray
              const Color(0xFFE8F4FD), // Muted light blue
              const Color(0xFFECEFF1), // Warm light gray
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header Card
              Container(
                margin: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shadowColor: Theme.of(
                    context,
                  ).colorScheme.shadow.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            '/dashboard',
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  'Products',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Manage Inventory',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _scanQrCode,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Search Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim();
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        hintText: 'Search products...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _userMode == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder(
                        stream: _getProductsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text('No products available.'),
                            );
                          }

                          var products = snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              var product = products[index];
                              return GestureDetector(
                                onTap: () =>
                                    _showProductDialog(context, product),
                                child: ProductTile(
                                  name: product['name'] ?? 'No Name',
                                  description:
                                      product['description'] ??
                                      'No Description',
                                  imageUrl:
                                      product['imageUrl'] ??
                                      'https://via.placeholder.com/150',
                                  price: product['price'].toString(),
                                  quantity: product['quantity'].toString(),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: "Products",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add"),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_outlined),
            label: "Stock Levels",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Order"),
        ],
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  final String name;
  final String description;
  final String imageUrl;
  final String price;
  final String quantity;

  const ProductTile({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), // Shadow color
            spreadRadius: 2, // How much the shadow spreads
            blurRadius: 5, // The blur intensity
            offset: const Offset(0, 3), // Offset in x and y direction
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                imageUrl,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  size: 80,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 15.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Color(0xFF0B6477),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Price: \$${price}',
                    style: const TextStyle(color: Colors.green),
                  ),
                  Text(
                    'Quantity: $quantity',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> product; // Pass product details as a Map

  const EditProductPage({required this.product});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String description;
  late String price;
  late String quantity;
  String? imageUrl; // Current image URL
  File? _newImage; // New image file
  bool _isUploading = false; // To track upload state

  @override
  void initState() {
    super.initState();
    name = widget.product['name'];
    description = widget.product['description'];
    price = widget.product['price'].toString();
    quantity = widget.product['quantity'].toString();
    imageUrl = widget.product['imageUrl']; // Existing image URL
  }

  Future<void> pickImage() async {
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
                  Navigator.of(context).pop(); // Close the modal
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (pickedFile != null) {
                    setState(() {
                      _newImage = File(pickedFile.path);
                      _isUploading = true; // Start upload indicator
                    });

                    try {
                      await _uploadImageToCloudinary(_newImage!);
                    } finally {
                      setState(() {
                        _isUploading = false; // Stop upload indicator
                      });
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop(); // Close the modal
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                  );

                  if (pickedFile != null) {
                    setState(() {
                      _newImage = File(pickedFile.path);
                      _isUploading = true; // Start upload indicator
                    });

                    try {
                      await _uploadImageToCloudinary(_newImage!);
                    } finally {
                      setState(() {
                        _isUploading = false; // Stop upload indicator
                      });
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadImageToCloudinary(File image) async {
    final cloudName = 'dmkfftvi9'; // Replace with your Cloud Name
    final uploadPreset = 'ml_default'; // Replace with your Upload Preset
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);
        return data['secure_url']; // Return the secure URL of the uploaded image
      } else {
        throw Exception('Failed to upload image to Cloudinary');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        // Upload new image if selected
        String? newImageUrl;
        if (_newImage != null) {
          newImageUrl = await _uploadImageToCloudinary(_newImage!);
        }

        // Update product data in Firestore or database
        await FirebaseFirestore.instance
            .collection('Product')
            .doc(widget.product['id'])
            .update({
              'name': name,
              'description': description,
              'price': double.parse(price),
              'quantity': int.parse(quantity),
              'imageUrl':
                  newImageUrl ?? imageUrl, // Use existing URL if no new image
              'updatedAt': FieldValue.serverTimestamp(),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating product: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Product',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF213A57),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFE6F2F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: _isUploading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(), // Loading spinner
                          const SizedBox(height: 10),
                          const Text(
                            "Uploading image...",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      )
                    : _newImage != null
                    ? Image.file(
                        _newImage!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      )
                    : imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 80),
                      )
                    : const Icon(Icons.broken_image, size: 80),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: pickImage, // Call the pickImage method
                  child: const Text('Change Image'),
                ),
              ),
              const SizedBox(height: 20),
              _buildInputBox(
                label: "Name",
                initialValue: name,
                onSaved: (value) => name = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Name cannot be empty' : null,
              ),
              _buildInputBox(
                label: "Description",
                initialValue: description,
                onSaved: (value) => description = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Description cannot be empty' : null,
              ),
              _buildInputBox(
                label: "Price",
                initialValue: price,
                keyboardType: TextInputType.number,
                onSaved: (value) => price = value!,
                validator: (value) =>
                    value!.isEmpty || double.tryParse(value) == null
                    ? 'Enter a valid price'
                    : null,
              ),
              _buildInputBox(
                label: "Quantity",
                initialValue: quantity,
                keyboardType: TextInputType.number,
                onSaved: (value) => quantity = value!,
                validator: (value) =>
                    value!.isEmpty || int.tryParse(value) == null
                    ? 'Enter a valid quantity'
                    : null,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _updateProduct,
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBox({
    required String label,
    required String initialValue,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        keyboardType: keyboardType,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}
