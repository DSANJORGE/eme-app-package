import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transparent_image/transparent_image.dart';
import '../models/workspace.dart';
import '../services/auth_service.dart';
import '../services/workspace_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(String) onLoginSuccess;
  final VoidCallback? onWorkspaceChanged;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.onWorkspaceChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  late Workspace _selectedWorkspace;
  bool _isRegistrationStage = false;
  bool _isOtpStage = false;
  bool _rememberMe = true;
  bool _isLoading = false;
  int _timerSeconds = 0;
  Timer? _resendTimer;
  String? _otpError;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedWorkspace = WorkspaceService.activeWorkspace;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _otpFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _fadeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _timerSeconds = 30;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0) {
            _timerSeconds--;
          } else {
            _resendTimer?.cancel();
          }
        });
      }
    });
  }

  void _sendOtp({bool isResend = false}) async {
    if (!_isOtpStage && !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      final response = await AuthService.sendUserCode(
        email: _emailController.text.trim(),
        firstName: _isRegistrationStage
            ? _firstNameController.text.trim()
            : null,
        lastName: _isRegistrationStage ? _lastNameController.text.trim() : null,
      );

      if (!mounted) return;

      final status = response['status']?.toString();

      if (status == 'ok') {
        setState(() {
          _isLoading = false;
          _isOtpStage = true;
          _isRegistrationStage = false;
          _otpController.clear();
        });

        _startResendTimer();

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.mark_email_read_rounded,
                  color: Color(0xFF38B6FF),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isResend
                        ? 'Verification code resent to your email!'
                        : 'Verification code sent to your email!',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF161C24),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: const Color(0xFF38B6FF).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_otpFocusNode.canRequestFocus) {
            _otpFocusNode.requestFocus();
          }
        });
      } else if (status == 'nouser') {
        final allowGuest = response['allowguestregistration'] == true;
        if (allowGuest) {
          setState(() {
            _isLoading = false;
            _isRegistrationStage = true;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User does not exist.'),
              backgroundColor: Color(0xFFF50057),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        final msg = response['message']?.toString() ?? 'Failed to send code';
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFFF50057),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFF50057),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _verifyOtp() async {
    if (_otpController.text.length < 6) {
      setState(() {
        _otpError = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      final success = await AuthService.loginWithOtp(
        _emailController.text.trim(),
        _otpController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        widget.onLoginSuccess(_emailController.text.trim());
      } else {
        setState(() {
          _isLoading = false;
          _otpError = 'Invalid verification code. Please try again.';
          _otpController.clear();
        });
        _otpFocusNode.requestFocus();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpError = e.toString().replaceAll('Exception: ', '');
        _otpController.clear();
      });
      _otpFocusNode.requestFocus();
    }
  }

  void _submit() {
    if (_isOtpStage) {
      _verifyOtp();
    } else {
      _sendOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F13), Color(0xFF141923), Color(0xFF0F1319)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative glowing elements
            Positioned(
              top: -size.height * 0.2,
              right: -size.width * 0.1,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF38B6FF).withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.2,
              left: -size.width * 0.1,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8A2387).withValues(alpha: 0.06),
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 450 : double.infinity,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF161C24,
                              ).withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 40,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Logo Container
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child:
                                          _selectedWorkspace.iconAsset != null
                                          ? ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth: 200,
                                                maxHeight: 100,
                                              ),
                                              child: FadeInImage.memoryNetwork(
                                                placeholder: kTransparentImage,
                                                image: _selectedWorkspace
                                                    .iconAsset!,
                                                fit: BoxFit.contain,
                                              ),
                                            )
                                          : Text(
                                              _selectedWorkspace.name,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: -0.5,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  if (_isRegistrationStage) ...[
                                    // Guest Registration Form Stage
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isRegistrationStage = false;
                                              _firstNameController.clear();
                                              _lastNameController.clear();
                                            });
                                          },
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: Color(0xFF38B6FF),
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Edit Email',
                                                style: TextStyle(
                                                  color: Color(0xFF38B6FF),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'No account found for ${_emailController.text}. Please enter your details to register.',
                                      style: const TextStyle(
                                        color: Color(0xFF90A4AE),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    const Text(
                                      'First Name',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInputField(
                                      controller: _firstNameController,
                                      hintText: 'Enter your first name',
                                      prefixIcon: Icons.person_outline,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Please enter your first name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    const Text(
                                      'Last Name',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInputField(
                                      controller: _lastNameController,
                                      hintText: 'Enter your last name',
                                      prefixIcon: Icons.person_outline,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Please enter your last name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ] else if (!_isOtpStage) ...[
                                    // Workspace Selection Menu
                                    const Text(
                                      'Workspace',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildWorkspaceDropdown(),
                                    const SizedBox(height: 20),

                                    // Email Address Input
                                    const Text(
                                      'Email Address',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInputField(
                                      controller: _emailController,
                                      hintText: 'Enter your email',
                                      prefixIcon: Icons.email_outlined,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!val.contains('@')) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                activeColor: const Color(
                                                  0xFF38B6FF,
                                                ),
                                                checkColor: Colors.black,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                side: BorderSide(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.2),
                                                ),
                                                onChanged: (val) {
                                                  setState(() {
                                                    _rememberMe = val ?? false;
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Remember session',
                                              style: TextStyle(
                                                color: Color(0xFF90A4AE),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    // OTP Input Stage
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Verification Code',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isOtpStage = false;
                                              _isRegistrationStage = false;
                                              _otpController.clear();
                                              _otpError = null;
                                              _resendTimer?.cancel();
                                              _timerSeconds = 0;
                                            });
                                          },
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: Color(0xFF38B6FF),
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Edit Email',
                                                style: TextStyle(
                                                  color: Color(0xFF38B6FF),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sent to ${_emailController.text}',
                                      style: const TextStyle(
                                        color: Color(0xFF90A4AE),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.hub_rounded,
                                          size: 12,
                                          color: Color(0xFF38B6FF),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Workspace: ${_selectedWorkspace.name}',
                                          style: const TextStyle(
                                            color: Color(0xFF38B6FF),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildOtpInput(),
                                    if (_otpError != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          _otpError!,
                                          style: const TextStyle(
                                            color: Color(0xFFF50057),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _timerSeconds > 0
                                              ? 'Resend code in ${_timerSeconds}s'
                                              : "Didn't receive the code? ",
                                          style: const TextStyle(
                                            color: Color(0xFF90A4AE),
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (_timerSeconds == 0)
                                          GestureDetector(
                                            onTap: () =>
                                                _sendOtp(isResend: true),
                                            child: const Text(
                                              'Resend Code',
                                              style: TextStyle(
                                                color: Color(0xFF38B6FF),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 28),

                                  // Submit Button
                                  _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF38B6FF),
                                                ),
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF38B6FF),
                                                Color(0xFF8A2387),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF38B6FF,
                                                ).withValues(alpha: 0.25),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _submit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: Text(
                                              _isRegistrationStage
                                                  ? 'Register & Send Code'
                                                  : _isOtpStage
                                                  ? 'Verify & Sign In'
                                                  : 'Send Verification Code',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),

                                  const SizedBox(height: 24),
                                  Text(
                                    textAlign: TextAlign.center,
                                    'Powered by eMe.world',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Stack(
      children: [
        // Hidden text field to capture inputs
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 50,
            child: TextField(
              controller: _otpController,
              focusNode: _otpFocusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _otpError = null;
                });
                if (value.length == 6) {
                  _verifyOtp();
                }
              },
            ),
          ),
        ),
        // Visual representation of 6 digits
        GestureDetector(
          onTap: () {
            if (!_otpFocusNode.hasFocus) {
              _otpFocusNode.requestFocus();
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              String char = '';
              if (_otpController.text.length > index) {
                char = _otpController.text[index];
              }

              final isFocused =
                  _otpFocusNode.hasFocus &&
                  (_otpController.text.length == index ||
                      (index == 5 && _otpController.text.length == 6));

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 6,
                    right: index == 5 ? 0 : 6,
                  ),
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1319),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFocused
                          ? const Color(0xFF38B6FF)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isFocused ? 2.0 : 1.0,
                    ),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF38B6FF,
                              ).withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    char,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1319),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 20),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 20,
          ),
          suffixIcon: suffixIcon,
          errorStyle: const TextStyle(color: Color(0xFFF50057), fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildWorkspaceDropdown() {
    final currentWorkspace = WorkspaceService.workspaces.firstWhere(
      (w) => w.id.toLowerCase() == _selectedWorkspace.id.toLowerCase(),
      orElse: () => WorkspaceService.activeWorkspace,
    );

    final color = currentWorkspace.id == 'minsur'
        ? const Color(0xFF0072FF)
        : currentWorkspace.id == 'eme'
        ? const Color(0xFF00C853)
        : const Color(0xFF8A2387);

    return InkWell(
      onTap: () => _showWorkspaceModalSheet(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1319),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(Icons.hub_rounded, size: 14, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentWorkspace.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currentWorkspace.mediaDBRoot,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkspaceModalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final workspaces = WorkspaceService.workspaces;
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF161C24),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Workspace',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _showAddWorkspaceDialog(context);
                        },
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 16,
                          color: Color(0xFF38B6FF),
                        ),
                        label: const Text(
                          'Add New',
                          style: TextStyle(
                            color: Color(0xFF38B6FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: workspaces.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final ws = workspaces[index];
                        final isSelected = ws.id == _selectedWorkspace.id;
                        final color = ws.id == 'minsur'
                            ? const Color(0xFF0072FF)
                            : ws.id == 'eme'
                            ? const Color(0xFF00C853)
                            : const Color(0xFF8A2387);
                        final canDelete = WorkspaceService.canDeleteWorkspace(
                          ws,
                        );

                        return Material(
                          color: isSelected
                              ? const Color(0xFF1E2638)
                              : const Color(0xFF0F1319),
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(
                                        0xFF38B6FF,
                                      ).withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: ListTile(
                              onTap: () async {
                                Navigator.pop(sheetContext);
                                final isLoggedIn =
                                    await AuthService.switchWorkspace(ws);
                                if (isLoggedIn) {
                                  widget.onLoginSuccess(
                                    AuthService.currentUser?.email ??
                                        AuthService.userId ??
                                        '',
                                  );
                                } else {
                                  setState(() {
                                    _selectedWorkspace = ws;
                                    _isOtpStage = false;
                                    _otpController.clear();
                                    _otpError = null;
                                  });
                                  widget.onWorkspaceChanged?.call();
                                }
                              },
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withValues(alpha: 0.15),
                                  border: Border.all(color: color, width: 1.5),
                                ),
                                child: Icon(
                                  Icons.hub_rounded,
                                  size: 16,
                                  color: color,
                                ),
                              ),
                              title: Text(
                                ws.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF38B6FF)
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                ws.mediaDBRoot,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: canDelete
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFF50057),
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        final confirmed =
                                            await _showConfirmDeleteDialog(
                                              context,
                                              ws,
                                            );
                                        if (confirmed) {
                                          await WorkspaceService.removeWorkspace(
                                            ws,
                                          );
                                          await AuthService.loadSessionForActiveWorkspace();
                                          if (mounted) {
                                            setState(() {
                                              _selectedWorkspace =
                                                  WorkspaceService
                                                      .activeWorkspace;
                                            });
                                            widget.onWorkspaceChanged?.call();
                                          }
                                          setSheetState(() {});
                                        }
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _showConfirmDeleteDialog(
    BuildContext context,
    Workspace ws,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161C24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFF50057)),
              SizedBox(width: 8),
              Text(
                'Delete Workspace',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete workspace "${ws.name}" (${ws.mediaDBRoot})?',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF50057),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _showAddWorkspaceDialog(BuildContext context) async {
    final urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161C24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_link_rounded, color: Color(0xFF38B6FF)),
              SizedBox(width: 8),
              Text(
                'Add Custom Workspace',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter the MediaDB Root URL for your workspace:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'https://minsur.genailabs.tech/site/mediadb',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F1319),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a MediaDB Root URL';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newWs =
                      WorkspaceService.getOrCreateWorkspaceFromMediaDBRoot(
                        urlController.text.trim(),
                      );
                  await AuthService.switchWorkspace(newWs);
                  if (mounted) {
                    setState(() {
                      _selectedWorkspace = newWs;
                      _isOtpStage = false;
                    });
                    widget.onWorkspaceChanged?.call();
                  }
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38B6FF),
              ),
              child: const Text(
                'Add & Select',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
