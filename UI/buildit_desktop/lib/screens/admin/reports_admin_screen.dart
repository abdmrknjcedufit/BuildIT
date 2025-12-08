import 'package:flutter/material.dart';
import 'package:buildit_desktop/app_colors.dart';

class ReportsAdminScreen extends StatefulWidget {
  const ReportsAdminScreen({super.key});

  @override
  State<ReportsAdminScreen> createState() => _ReportsAdminScreenState();
}

class _ReportsAdminScreenState extends State<ReportsAdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Izvještaji',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.5,
              children: [
                _buildReportCard(
                  icon: Icons.people,
                  title: 'Izvještaj o korisnicima',
                  description: 'Pregled svih korisnika i njihove aktivnosti',
                  onTap: () {
                    // TODO: Navigate to users report
                  },
                ),
                _buildReportCard(
                  icon: Icons.shopping_bag,
                  title: 'Izvještaj o oglasima',
                  description: 'Pregled svih oglasa i njihovih performansi',
                  onTap: () {
                    // TODO: Navigate to listings report
                  },
                ),
                _buildReportCard(
                  icon: Icons.star,
                  title: 'Izvještaj o recenzijama',
                  description: 'Pregled svih recenzija i ocjena',
                  onTap: () {
                    // TODO: Navigate to reviews report
                  },
                ),
                _buildReportCard(
                  icon: Icons.trending_up,
                  title: 'Izvještaj o poslovanju',
                  description: 'Sveobuhvatni izvještaj o poslovanju korisnika',
                  onTap: () {
                    // TODO: Navigate to business report
                  },
                ),
                _buildReportCard(
                  icon: Icons.history,
                  title: 'Historija oglasa',
                  description: 'Pregled historije svih oglasa',
                  onTap: () {
                    // TODO: Navigate to listings history
                  },
                ),
                _buildReportCard(
                  icon: Icons.assessment,
                  title: 'Statistika',
                  description: 'Opća statistika aplikacije',
                  onTap: () {
                    // TODO: Navigate to statistics
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 48,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

