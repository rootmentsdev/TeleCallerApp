import 'package:flutter/material.dart';
import 'package:telecaller_app/services/auth_service.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/view/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, String?>> _loadProfile() async {
    final name = await AuthService.getUserName();
    final empId = await AuthService.getEmpId();
    return {'name': name ?? 'User', 'empId': empId ?? '--'};
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.clearAuth();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: ColorConstant.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: FutureBuilder<Map<String, String?>>(
        future: _loadProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? const {'name': 'User', 'empId': '--'};
          final name = data['name'] ?? 'User';
          final empId = data['empId'] ?? '--';

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 110),
                const CircleAvatar(
                  radius: 48,
                  backgroundImage: AssetImage(
                    'assets/images/Screenshot 2025-11-27 174648.png',
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'EMP ID: $empId',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 70),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => _logout(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
