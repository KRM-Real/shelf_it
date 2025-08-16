import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../profile_page.dart';
import '../analytics.dart';
import '../transaction.dart';
import '../company_details_page.dart';
import '../login_screen.dart';

class ModernDrawer extends StatelessWidget {
  final String? userMode;
  final String? companyName;

  const ModernDrawer({super.key, this.userMode, this.companyName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Modern Profile Header
          _buildProfileHeader(context),

          // Navigation Menu Items
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // Profile Section
                  _buildDrawerSection(
                    title: "Profile",
                    items: [
                      _buildDrawerItem(
                        icon: Icons.person_outline,
                        title: "User Profile",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProfilePage(),
                            ),
                          );
                        },
                      ),
                      if (userMode == 'organization')
                        _buildDrawerItem(
                          icon: Icons.business_outlined,
                          title: "Company Details",
                          onTap: () {
                            Navigator.pop(context);
                            if (companyName != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => companydetailsPage(
                                    companyName: companyName!,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Company name not available'),
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Analytics Section
                  _buildDrawerSection(
                    title: "Analytics",
                    items: [
                      _buildDrawerItem(
                        icon: Icons.receipt_long_outlined,
                        title: "Transactions",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const TransactionPage(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.analytics_outlined,
                        title: "Inventory Analytics",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AnalyticsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // App Section
                  _buildDrawerSection(
                    title: "App",
                    items: [
                      _buildDrawerItem(
                        icon: Icons.info_outline,
                        title: "About",
                        onTap: () {
                          Navigator.pop(context);
                          _showAboutDialog(context);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.contact_support_outlined,
                        title: "Contact Us",
                        onTap: () {
                          Navigator.pop(context);
                          _showContactDialog(context);
                        },
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Logout
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildDrawerItem(
                      icon: Icons.logout,
                      title: "Logout",
                      isDestructive: true,
                      onTap: () async {
                        Navigator.pop(context);
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
              ),
            ),
            width: double.infinity,
            height: 180,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
              ),
            ),
            width: double.infinity,
            height: 180,
            child: const Center(
              child: Text(
                'Error loading profile',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final profileImageURL = data?['profileImage'] ?? "";
        final profileName = data?['name'] ?? "Profile Name";
        final email = data?['email'] ?? "";

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            ),
          ),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: (profileImageURL.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: profileImageURL,
                          imageBuilder: (context, imageProvider) =>
                              CircleAvatar(
                                radius: 35,
                                backgroundImage: imageProvider,
                              ),
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(strokeWidth: 2),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            size: 35,
                            color: Color(0xFF1565C0),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 35,
                          color: Color(0xFF1565C0),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profileName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDestructive ? Colors.red : const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'About Shelf It',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Shelf It is a comprehensive inventory management system designed to help businesses track, manage, and optimize their inventory efficiently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Contact Us',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('For general inquiries, contact us at:'),
              SizedBox(height: 16),
              Text(
                'Team Members',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Mark Real'),
              Text('• Raven Moral'),
              Text('• Jahred Vapor'),
              Text('• Tristan Faicol'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
