import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/mekong_illustration.dart';

class LoginScreen extends StatefulWidget {
  final Function(UserProfile user) onLoginSuccess;

  const LoginScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isStaffMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = _isStaffMode
          ? 'Please enter your university email or staff code'
          : 'Please enter your invite code');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await ApiService.login(code);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      widget.onLoginSuccess(user);
    } else {
      setState(() => _errorMessage = 'Invalid invite code or email. Check with your exchange coordinator.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MekongColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Banner with Exchange Tag and Artwork
              Stack(
                children: [
                  const MekongIllustration(height: 220),
                  Positioned(
                    top: 16,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: MekongColors.card.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'SorSU × CTU exchange',
                        style: TextStyle(
                          color: MekongColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Curved white sheet
              Container(
                transform: Matrix4.translationValues(0, -20, 0),
                decoration: const BoxDecoration(
                  color: MekongColors.paper,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xin chào, welcome',
                      style: TextStyle(
                        fontFamily: 'Nunito Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MekongColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your Can Tho\nprogram, in one place',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: MekongColors.ink,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your schedule, the map and notes on the places you will visit.',
                      style: TextStyle(
                        fontSize: 15,
                        color: MekongColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Invite code field
                    Text(
                      _isStaffMode ? 'University email or staff code' : 'Invite code',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: MekongColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeController,
                      onSubmitted: (_) => _handleContinue(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MekongColors.ink,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: MekongColors.card,
                        hintText: _isStaffMode
                            ? 'Enter university email or coordinator code'
                            : 'Enter code from your coordinator (e.g. SORSU-STU-01)',
                        hintStyle: TextStyle(color: MekongColors.muted.withOpacity(0.7)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: MekongColors.divider, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: MekongColors.divider, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: MekongColors.riverGreen, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your invite also sets your role: student, professor or admin.',
                      style: TextStyle(
                        fontSize: 13,
                        color: MekongColors.muted,
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: MekongColors.clay, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MekongColors.riverGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Staff link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isStaffMode = !_isStaffMode;
                            _errorMessage = null;
                          });
                        },
                        child: Text(
                          _isStaffMode
                              ? 'Sign in with student invite code instead'
                              : "I'm staff: sign in with my university email",
                          style: const TextStyle(
                            color: MekongColors.deltaBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Privacy notice
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_outline, size: 16, color: MekongColors.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'We keep your name, email and role. Questions you type are saved without your name.',
                            style: TextStyle(
                              fontSize: 12,
                              color: MekongColors.muted.withOpacity(0.9),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
