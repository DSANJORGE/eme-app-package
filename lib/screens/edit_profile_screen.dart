import 'dart:io';
import 'package:flutter/material.dart';
import 'package:eme_app_package/l10n/app_localizations.dart';
import 'package:eme_app_package/utils/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'ImagePicker failed in EditProfileScreen',
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppErrorHandler.showUserError(context, l10n.failedToSelectImage);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final mediaDbRoot = AuthService.mediaDBRoot;
      final targetUrl =
          '$mediaDbRoot/services/authentication/usersave.json?'
          'save=true&'
          'userid=${AuthService.userId}&'
          'username=${AuthService.userId}&'
          'field=firstName&firstName.value=${Uri.encodeComponent(_firstNameController.text)}&'
          'field=lastName&lastName.value=${Uri.encodeComponent(_lastNameController.text)}&'
          'field=email&email.value=${Uri.encodeComponent(_emailController.text)}'
          '${_imageFile != null ? '&field=assetportrait' : ''}';

      final formData = FormData();
      if (_imageFile != null) {
        formData.files.add(
          MapEntry(
            'file.assetportrait',
            await MultipartFile.fromFile(_imageFile!.path),
          ),
        );
      }

      final response = await DioUtil.dio.post(
        targetUrl,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer ${AuthService.token}'},
        ),
      );

      if (response.statusCode == 200) {
        // Refresh user data
        await AuthService.fetchUser();
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          AppErrorHandler.showUserSuccess(
            context,
            l10n.profileUpdatedSuccessfully,
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          AppErrorHandler.showUserError(context, l10n.failedToUpdateProfile);
        }
      }
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'EditProfileScreen _saveProfile failed',
      );
      if (mounted) {
        AppErrorHandler.showUserError(
          context,
          'Error: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        backgroundColor: const Color(0xFF141923),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F13), Color(0xFF141923), Color(0xFF0F1319)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: OverflowBox(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : (AuthService
                                              .currentUser
                                              ?.assetPortrait
                                              .isNotEmpty ==
                                          true
                                      ? Image.network(
                                          AuthService
                                              .currentUser!
                                              .assetPortrait,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.white54,
                                        )),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF38B6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  context: context,
                  controller: _firstNameController,
                  label: l10n.firstName,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context: context,
                  controller: _lastNameController,
                  label: l10n.lastName,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context: context,
                  controller: _emailController,
                  label: l10n.email,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38B6FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.saveChanges,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF38B6FF)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.fieldIsRequired(label);
        }
        return null;
      },
    );
  }
}
