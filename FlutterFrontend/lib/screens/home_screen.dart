import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/feature_card.dart';
import '../widgets/xp_progress.dart';
import '../providers/auth_provider.dart';

// Main home screen after login
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh user data when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).refreshUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      body: SafeArea(
        child: user == null
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF61DAFB)),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF192734),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Profile picture
                            GestureDetector(
                              onTap: () {
                                // Navigate to profile page (not implemented yet)
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF61DAFB), width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    color: const Color(0xFF252836),
                                    child: const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Color(0xFF61DAFB),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // User info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, ${user.username}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2A6F97),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.school,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              user.role,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[700],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${user.points} Points',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.notifications,
                                color: Color(0xFF61DAFB),
                                size: 28,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // XP Progress Bar
                        XPProgress(
                          currentXP: user.xp,
                          maxXP: user.level * 1000, // Example formula
                          level: user.level,
                        ),
                      ],
                    ),
                  ),
                  // Main Content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Daily challenge banner
                        Container(
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2A6F97), Color(0xFF61DAFB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2A6F97).withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.pushNamed(context, '/quiz');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.bolt,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Daily Challenge',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Complete for 50XP & special rewards',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Section Title
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Learning Hub',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Feature Grid
                        GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: [
                            FeatureCard(
                              title: 'Daily Quiz',
                              icon: Icons.quiz,
                              color: const Color(0xFF61DAFB),
                              onTap: () =>
                                  Navigator.pushNamed(context, '/quiz'),
                              hasNew: true,
                            ),
                            FeatureCard(
                              title: 'Leaderboard',
                              icon: Icons.leaderboard,
                              color: Colors.amber,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/leaderboard'),
                            ),
                            FeatureCard(
                              title: 'Classrooms',
                              icon: Icons.class_outlined,
                              color: Colors.deepPurple,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/classrooms'),
                              showBadge: true,
                            ),
                            FeatureCard(
                              title: 'Store',
                              icon: Icons.store,
                              color: Colors.green,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/store'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // AI Chatbot Section
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252836),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(4, 4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                offset: const Offset(-4, -4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () =>
                                  Navigator.pushNamed(context, '/chatbot'),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF61DAFB)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Icon(
                                        Icons.smart_toy,
                                        size: 32,
                                        color: Color(0xFF61DAFB),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AI Learning Assistant',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Get help with your studies',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Color(0xFF61DAFB),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF192734),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF192734),
            selectedItemColor: const Color(0xFF61DAFB),
            unselectedItemColor: Colors.white54,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.class_),
                label: 'Classes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.smart_toy),
                label: 'AI Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: 0,
            onTap: (index) {
              switch (index) {
                case 0:
                  // Already on home
                  break;
                case 1:
                  Navigator.pushNamed(context, '/classrooms');
                  break;
                case 2:
                  Navigator.pushNamed(context, '/chatbot');
                  break;
                case 3:
                  // Profile options
                  _showProfileOptions(context);
                  break;
              }
            },
          ),
        ),
      ),
    );
  }

  void _showProfileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252836),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const ListTile(
              leading: Icon(Icons.person, color: Color(0xFF61DAFB)),
              title: Text(
                'View Profile',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.settings, color: Color(0xFF61DAFB)),
              title: Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF61DAFB)),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // First close the bottom sheet
                Navigator.pop(context);

                // Use a separate method for sign out to avoid context issues
                _handleSignOut(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // Create a separate method for sign out to ensure proper context handling
  Future<void> _handleSignOut(BuildContext context) async {
    // Store local reference to context (safer than using mounted)
    final BuildContext signOutContext = context;

    try {
      // Show loading dialog during sign out
      showDialog(
        context: signOutContext,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF61DAFB)),
          ),
        ),
      );

      // Get auth provider without listening to avoid rebuild during sign out
      final authProvider =
          Provider.of<AuthProvider>(signOutContext, listen: false);

      // Execute the sign out
      await authProvider.signOut();

      // Check if we can still use the context before navigating
      if (Navigator.canPop(signOutContext)) {
        Navigator.pop(signOutContext); // Close loading dialog
      }

      // Navigate to login screen using a new context to avoid "defunct" context issues
      Future.microtask(() {
        Navigator.of(signOutContext).pushNamedAndRemoveUntil(
          '/login',
          (_) => false, // Clear all routes in the stack
        );
      });
    } catch (e) {
      print('Error during sign out: $e');

      // Try to dismiss the loading dialog if still showing
      if (Navigator.canPop(signOutContext)) {
        Navigator.pop(signOutContext); // Close loading dialog
      }

      // Show error using ScaffoldMessenger (safer with context issues)
      ScaffoldMessenger.of(signOutContext).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
