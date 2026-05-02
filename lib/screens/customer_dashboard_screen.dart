import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/customer_model.dart';
import '../models/coupon_model.dart';
import '../services/firebase_service.dart';

class CustomerDashboardScreen extends StatefulWidget {
  final Customer customer;
  final bool isNewCustomer;

  const CustomerDashboardScreen({
    super.key,
    required this.customer,
    this.isNewCustomer = false,
  });

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen>
    with TickerProviderStateMixin {
  final _service = FirebaseService();
  late Customer _customer;
  late ConfettiController _confetti;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  bool _pointAdded = false;
  bool _promoLoading = false;
  final _promoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;

    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    // Auto add point on login (only for existing customers)
    if (!widget.isNewCustomer) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _addVisitPoint());
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _shakeCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _addVisitPoint() async {
    final result = await _service.addVisitPoint(_customer);
    final newPoints = result['points'] as int;
    final newCoupon = result['newCoupon'] as Coupon?;

    setState(() {
      _customer = _customer.copyWith(points: newPoints);
      _pointAdded = true;
    });

    if (newCoupon != null) {
      _confetti.play();
      _showCelebrationDialog(newCoupon);
    }
  }

  void _showCelebrationDialog(Coupon coupon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouncing emojis
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['💅', '🎉', '💖']
                  .asMap()
                  .entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(e.value, style: const TextStyle(fontSize: 40))
                            .animate(delay: Duration(milliseconds: e.key * 120))
                            .scale(duration: 500.ms, curve: Curves.elasticOut)
                            .then()
                            .moveY(begin: 0, end: -8, duration: 600.ms)
                            .then()
                            .moveY(begin: -8, end: 0, duration: 600.ms),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text(
              '🎊 You earned a reward!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 10),
            Text(
              '${coupon.discount} is now available\nfor your next visit 💖',
              style: GoogleFonts.dmSans(
                color: AppTheme.textGrey, fontSize: 15, height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Yay! Let\'s Go 🎊',
                  style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600)),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _redeemCoupon(Coupon coupon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Redeem Coupon?',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        content: Text('Use ${coupon.discount} on your visit today?',
          style: GoogleFonts.dmSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Redeem')),
        ],
      ),
    );

    if (confirm != true) return;

    await _service.redeemCoupon(coupon.id);
    _confetti.play();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 ${coupon.discount} applied! Enjoy your visit!',
          style: GoogleFonts.dmSans()),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _giveCouponToFriend(Coupon coupon) async {
    final phoneCtrl = TextEditingController();

    final friend = await showDialog<Customer?>(
      context: context,
      builder: (_) => _GiveFriendDialog(service: _service),
    );

    phoneCtrl.dispose();
    if (friend == null) return;

    await _service.giveCouponToFriend(coupon: coupon, friend: friend);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💖 Coupon sent to ${friend.name}!', style: GoogleFonts.dmSans()),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _redeemPromoCode() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() => _promoLoading = true);
    final promo = await _service.validatePromoCode(code);

    if (promo == null) {
      setState(() => _promoLoading = false);
      _shakeCtrl.forward(from: 0);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Invalid or expired code. Try again!', style: GoogleFonts.dmSans()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    await _service.redeemPromoCode(customer: _customer, promo: promo);
    _promoCtrl.clear();
    setState(() => _promoLoading = false);
    _confetti.play();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 ${promo.discount} promo applied! — ${promo.description}',
          style: GoogleFonts.dmSans()),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = _customer.points;
    final pointsToNext = 5 - points;  // since we reset to 0 after every 5

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFDF6F0), Color(0xFFF5E6F0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                AppTheme.primary, AppTheme.gold, Colors.pink,
                Colors.purple, AppTheme.success,
              ],
              numberOfParticles: 40,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Points card
                        _buildPointsCard(points, pointsToNext),
                        const SizedBox(height: 16),

                        // Promo code section
                        _buildPromoSection(),
                        const SizedBox(height: 20),

                        // Coupons
                        _buildCouponsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${_customer.name.split(' ').first}! 👋',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                ),
                if (_pointAdded && !widget.isNewCustomer)
                  Text('+1 point added for today\'s visit ✨',
                    style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildPointsCard(int points, int pointsToNext) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFB85C8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('⭐', style: const TextStyle(fontSize: 28))
                  .animate(onPlay: (c) => c.repeat())
                  .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2),
                    duration: 800.ms, curve: Curves.easeInOut)
                  .then()
                  .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1),
                    duration: 800.ms),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Points',
                    style: GoogleFonts.dmSans(
                      color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w300,
                    )),
                  Text('$points pts',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w600,
                    )).animate().fadeIn(delay: 200.ms),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pointsToNext to reward',
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress bar — 5 dots, filled = visits this cycle
          Row(
            children: List.generate(5, (i) {
              final filled = i < points;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                  height: 10,
                  decoration: BoxDecoration(
                    color: filled ? AppTheme.gold : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: filled ? [
                      BoxShadow(color: AppTheme.gold.withOpacity(0.6), blurRadius: 6),
                    ] : [],
                  ),
                ).animate(delay: Duration(milliseconds: i * 100)).scaleX(
                  begin: 0, end: 1, curve: Curves.elasticOut,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            pointsToNext == 1
              ? '1 more visit to earn your reward! 🎁'
              : '$pointsToNext more visits to earn your reward! 🎁',
            style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2);
  }

  Widget _buildPromoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0DCE8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📱', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('Redeem SMS or Flyer Code',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Got a special code from us? Enter it below!',
            style: GoogleFonts.dmSans(color: AppTheme.textGrey, fontSize: 12)),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(8 * (0.5 - _shakeAnim.value).abs() * 4, 0),
              child: child,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _promoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'e.g. VDAY25',
                      hintStyle: GoogleFonts.dmSans(color: AppTheme.textGrey),
                      prefixIcon: const Icon(Icons.confirmation_number_outlined,
                        color: AppTheme.primary, size: 20),
                      filled: true,
                      fillColor: AppTheme.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF0DCE8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF0DCE8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _promoLoading ? null : _redeemPromoCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _promoLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Apply', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildCouponsSection() {
    return StreamBuilder<List<Coupon>>(
      stream: _service.streamCustomerCoupons(_customer.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error details if stream fails
        if (snap.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.error.withOpacity(0.3)),
            ),
            child: Text(
              'Error loading rewards:\n${snap.error}',
              style: GoogleFonts.dmSans(color: AppTheme.error, fontSize: 12),
            ),
          );
        }

        final allCoupons = snap.data ?? [];
        final active   = allCoupons.where((c) => c.status == CouponStatus.active).toList();
        final history  = allCoupons.where((c) => c.status != CouponStatus.active).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active coupons
            _sectionTitle('🎁 Your Rewards', count: active.length),
            const SizedBox(height: 10),

            if (active.isEmpty)
              _emptyState('No rewards yet.\nKeep visiting to earn points! 💅')
            else
              ...active.asMap().entries.map((e) => _activeCouponCard(e.value, e.key)),

            const SizedBox(height: 24),

            // History
            _sectionTitle('📋 Already Redeemed', count: history.length),
            const SizedBox(height: 10),

            if (history.isEmpty)
              _emptyState('No history yet')
            else
              ...history.map((c) => _historyCard(c)),
          ],
        );
      },
    );
  }

  Widget _activeCouponCard(Coupon coupon, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F7), Color(0xFFF8F0FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎟️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coupon.discount,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.primary,
                    )),
                  if (coupon.givenByName != null)
                    Text(coupon.givenByName!,
                      style: GoogleFonts.dmSans(color: AppTheme.textGrey, fontSize: 12)),
                  Text('Tap below to redeem 💅',
                    style: GoogleFonts.dmSans(color: AppTheme.textGrey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _redeemCoupon(coupon),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text('Redeem', style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.success,
                    side: BorderSide(color: AppTheme.success.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _giveCouponToFriend(coupon),
                  icon: const Icon(Icons.favorite_outline, size: 18),
                  label: Text('Give Friend', style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 100)).fadeIn().slideX(begin: 0.1);
  }

  Widget _historyCard(Coupon coupon) {
    final isGiven = coupon.status == CouponStatus.given;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0DCE8)),
      ),
      child: Row(
        children: [
          Text(isGiven ? '💝' : '✅', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coupon.discount,
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                Text(
                  coupon.notes ?? coupon.statusLabel,
                  style: GoogleFonts.dmSans(color: AppTheme.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isGiven
                  ? AppTheme.primary.withOpacity(0.1)
                  : AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isGiven ? 'Given' : 'Used',
              style: GoogleFonts.dmSans(
                color: isGiven ? AppTheme.primary : AppTheme.success,
                fontSize: 12, fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {int count = 0}) => Row(
    children: [
      Text(title, style: GoogleFonts.playfairDisplay(
        fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textDark,
      )),
      if (count > 0) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary, borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    ],
  );

  Widget _emptyState(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0DCE8)),
    ),
    child: Text(msg,
      textAlign: TextAlign.center,
      style: GoogleFonts.dmSans(color: AppTheme.textGrey, fontSize: 14, height: 1.6)),
  );
}

// Dialog to search for a friend to give coupon to
class _GiveFriendDialog extends StatefulWidget {
  final FirebaseService service;
  const _GiveFriendDialog({required this.service});

  @override
  State<_GiveFriendDialog> createState() => _GiveFriendDialogState();
}

class _GiveFriendDialogState extends State<_GiveFriendDialog> {
  final _searchCtrl = TextEditingController();
  List<Customer> _results = [];
  bool _searching = false;

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    final results = await widget.service.searchCustomersByName(q);
    setState(() { _results = results; _searching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Find Your Friend 💖',
        style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 18)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      hintStyle: GoogleFonts.dmSans(color: AppTheme.textGrey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searching ? null : _search,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _searching
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search, size: 20),
                ),
              ],
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._results.map((c) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accent,
                  child: Text(c.name[0], style: GoogleFonts.playfairDisplay(color: AppTheme.primary)),
                ),
                title: Text(c.name, style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
                subtitle: Text(c.phone, style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textGrey)),
                onTap: () => Navigator.pop(context, c),
              )),
            ],
            if (_results.isEmpty && !_searching && _searchCtrl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('No clients found. Make sure your friend is signed up!',
                  style: GoogleFonts.dmSans(color: AppTheme.textGrey, fontSize: 13),
                  textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.dmSans()),
        ),
      ],
    );
  }
}
