import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import 'customer_dashboard_screen.dart';

class NewCustomerScreen extends StatefulWidget {
  const NewCustomerScreen({super.key});

  @override
  State<NewCustomerScreen> createState() => _NewCustomerScreenState();
}

class _NewCustomerScreenState extends State<NewCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirebaseService();

  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _referralCtrl = TextEditingController();

  DateTime? _birthday;
  String _howFound = 'Google';
  bool _loading = false;

  static const List<Map<String, String>> _sources = [
    {'label': 'Google',    'icon': '🔍'},
    {'label': 'Instagram', 'icon': '📸'},
    {'label': 'Facebook',  'icon': '👥'},
    {'label': 'TikTok',    'icon': '🎵'},
    {'label': 'Friend',    'icon': '💬'},
    {'label': 'Walk-in',   'icon': '🚶'},
    {'label': 'Other',     'icon': '✨'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final customer = await _service.createCustomer(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        birthday: _birthday,
        referredBy: _referralCtrl.text.trim().isEmpty ? null : _referralCtrl.text.trim(),
        howFound: _howFound,
      );

      if (!mounted) return;
      // Navigate to their dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerDashboardScreen(customer: customer, isNewCustomer: true),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDF6F0), Color(0xFFF5E6F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Your Info'),

                        // Name
                        _buildField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 12),

                        // Phone
                        _buildField(
                          controller: _phoneCtrl,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.length < 10 ? 'Enter a valid phone number' : null,
                        ),
                        const SizedBox(height: 12),

                        // Email (optional)
                        _buildField(
                          controller: _emailCtrl,
                          label: 'Email Address (optional)',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          isOptional: true,
                        ),
                        const SizedBox(height: 12),

                        // Birthday
                        GestureDetector(
                          onTap: _pickBirthday,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF0DCE8)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake_outlined, color: AppTheme.textGrey, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  _birthday != null
                                      ? DateFormat('MMMM d, yyyy').format(_birthday!)
                                      : 'Birthday (optional)',
                                  style: GoogleFonts.dmSans(
                                    color: _birthday != null ? AppTheme.textDark : AppTheme.textGrey,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right, color: AppTheme.textGrey),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        _sectionLabel('How did you find us?'),

                        // How Found — chip selector
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _sources.map((s) {
                            final selected = _howFound == s['label'];
                            return GestureDetector(
                              onTap: () => setState(() => _howFound = s['label']!),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected ? AppTheme.primary : const Color(0xFFF0DCE8),
                                  ),
                                  boxShadow: selected ? [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ] : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(s['icon']!, style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text(
                                      s['label']!,
                                      style: GoogleFonts.dmSans(
                                        color: selected ? Colors.white : AppTheme.textDark,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),
                        _sectionLabel('Were you referred by someone?'),

                        _buildField(
                          controller: _referralCtrl,
                          label: 'Referral name (optional)',
                          icon: Icons.favorite_outline,
                          isOptional: true,
                        ),

                        const SizedBox(height: 32),

                        // Submit
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: AppTheme.primary,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Welcome to the Family 🌸',
                                    style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC96E6E), Color(0xFFB85C8A)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Customer',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
                )),
              Text('Fill in your details below',
                style: GoogleFonts.dmSans(
                  fontSize: 12, color: Colors.white70,
                )),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.textGrey,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: isOptional ? null : validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textGrey, size: 20),
      ),
    );
  }
}
