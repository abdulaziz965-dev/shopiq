import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../services/wishlist_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _priceDropAlerts = true;
  bool _lightMode = true;
  bool _reviewShield = true;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistService>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(wishlist.count),
              _buildSection('ALERTS', [
                _Row(
                  Icons.notifications_rounded,
                  'Price Drop Alerts',
                  trailing: Switch.adaptive(
                    value: _priceDropAlerts,
                    onChanged: (value) => setState(() => _priceDropAlerts = value),
                    activeThumbColor: AppColors.accent,
                    activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
                  ),
                  onTap: () => setState(() => _priceDropAlerts = !_priceDropAlerts),
                ),
                _Row(
                  Icons.show_chart_rounded,
                  'Price History',
                  onTap: () => _showInfo('Price history will open from Search results and product cards.'),
                ),
              ], context),
              _buildSection('PREFERENCES', [
                _Row(
                  Icons.light_mode_rounded,
                  'Light Mode',
                  trailing: Switch.adaptive(
                    value: _lightMode,
                    onChanged: (value) => setState(() => _lightMode = value),
                    activeThumbColor: AppColors.accent,
                    activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
                  ),
                  onTap: () => setState(() => _lightMode = !_lightMode),
                ),
                _Row(
                  Icons.shield_rounded,
                  'Review Shield™',
                  trailing: Switch.adaptive(
                    value: _reviewShield,
                    onChanged: (value) => setState(() => _reviewShield = value),
                    activeThumbColor: AppColors.accent,
                    activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
                  ),
                  onTap: () => setState(() => _reviewShield = !_reviewShield),
                ),
                _Row(
                  Icons.link_rounded,
                  'Affiliate Links',
                  onTap: () => _showInfo('Affiliate links are enabled on product cards.'),
                ),
              ], context),
              _buildSection('ACCOUNT', [
                _Row(
                  Icons.person_rounded,
                  'Edit Profile',
                  onTap: () => _showInfo('Profile editing UI can be connected to your backend next.'),
                ),
                _Row(
                  Icons.lock_rounded,
                  'Privacy & Security',
                  onTap: () => _showInfo('Security settings page is currently in progress.'),
                ),
                _Row(
                  Icons.help_rounded,
                  'Help & Support',
                  onTap: () => _showInfo('Support: support@shopiq.app'),
                ),
              ], context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int savedCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.bg3, AppColors.bg], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border(bottom: BorderSide(color: AppColors.border2, width: 0.7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(child: Text('👤', style: TextStyle(fontSize: 32))),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Smart Shopper', style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700)),
                  Text('shopper@shopiq.app', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const _StatBox(value: '₹8.2K', label: 'Saved'),
              const SizedBox(width: 8),
              _StatBox(value: '$savedCount', label: 'Wishlisted'),
              const SizedBox(width: 8),
              const _StatBox(value: '23', label: 'Compared'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_Row> rows, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          ...rows.map((row) => InkWell(
            onTap: row.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border2, width: 0.7),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0B1324),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(row.icon, color: AppColors.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(row.label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500))),
                if (row.trailing != null)
                  row.trailing!
                else
                  const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
          )),
        ],
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _Row {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  _Row(this.icon, this.label, {this.trailing, this.onTap});
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border2, width: 0.7),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accent)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
