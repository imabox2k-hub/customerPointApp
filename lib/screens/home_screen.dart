import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'new_customer_screen.dart';
import 'existing_customer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDF6F0), Color(0xFFFCE8E8), Color(0xFFF5E6F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo / Header
                Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('💅', style: TextStyle(fontSize: 40)),
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 20),

                    Text(
                      'Welcome',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                    const SizedBox(height: 8),

                    Text(
                      'Are you a new or returning client?',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: AppTheme.textGrey,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 350.ms),
                  ],
                ),

                const Spacer(flex: 2),

                // New Customer Button
                _HomeButton(
                  label: 'New Customer',
                  subtitle: 'First time here? Welcome! 🌸',
                  icon: '✨',
                  gradient: AppTheme.primaryGradient,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewCustomerScreen()),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

                const SizedBox(height: 16),

                // Existing Customer Button
                _HomeButton(
                  label: 'Existing Customer',
                  subtitle: 'Check points & redeem rewards 💖',
                  icon: '👑',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFB85C8A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExistingCustomerScreen()),
                  ),
                ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.3),

                const Spacer(flex: 3),

                Text(
                  'Powered by Nail Studio ✨',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ).animate().fadeIn(delay: 800.ms),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatefulWidget {
  final String label;
  final String subtitle;
  final String icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _HomeButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.last.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
