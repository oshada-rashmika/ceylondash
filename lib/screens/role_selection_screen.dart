import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.cyan),
        elevation: 0,
        title: const Text(
          'Join Ceylon Dash',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 72, color: Colors.cyan),
              const SizedBox(height: 16),
              const Text(
                'How would you like to use Ceylon Dash?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your role to get started',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 40),

              _RoleCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Customer',
                subtitle: 'Order and track deliveries',
                onTap: () => Navigator.pushNamed(context, '/register/customer'),
              ),
              const SizedBox(height: 16),

              _RoleCard(
                icon: Icons.store_outlined,
                title: 'Seller',
                subtitle: 'List your business and manage orders',
                onTap: () => Navigator.pushNamed(context, '/register/seller'),
              ),
              const SizedBox(height: 16),

              _RoleCard(
                icon: Icons.two_wheeler_outlined,
                title: 'Rider',
                subtitle: 'Deliver orders and earn',
                onTap: () => Navigator.pushNamed(context, '/register/rider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.cyan),
          borderRadius: BorderRadius.circular(14),
          color: Colors.black,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.cyan, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.cyan, size: 18),
          ],
        ),
      ),
    );
  }
}
