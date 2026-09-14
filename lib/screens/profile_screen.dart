import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  UserProfile? _profile;
  bool _loading = true;
  bool _uploadingPhoto = false;
  bool _editingName = false;
  bool _editingMobile = false;
  bool _otpSent = false;
  String? _verificationId;
  String? _pendingMobile;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await UserProfileService.instance.getProfile(_uid);
    setState(() {
      _profile = profile;
      _nameCtrl.text = profile?.name ?? '';
      _mobileCtrl.text = profile?.mobileNumber ?? '';
      _loading = false;
    });
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await UserProfileService.instance.updateName(_uid, name);
    setState(() => _editingName = false);
    _load();
  }

  Future<void> _sendOtp() async {
    final mobile = _mobileCtrl.text.trim();
    if (mobile.isEmpty) return;
    _pendingMobile = mobile;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: mobile,
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Verification failed')),
        );
      },
      codeSent: (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _confirmOtp() async {
    if (_verificationId == null || _pendingMobile == null) return;
    final code = _otpCtrl.text.trim();
    if (code.isEmpty) return;

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: code,
    );

    try {
      // Linking actually asks Firebase to check the code against this
      // verification session — this is what really confirms the OTP.
      await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
      await UserProfileService.instance
          .updateMobileNumber(_uid, _pendingMobile!);
      setState(() {
        _editingMobile = false;
        _otpSent = false;
        _otpCtrl.clear();
      });
      _load();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'provider-already-linked') {
        await UserProfileService.instance
            .updateMobileNumber(_uid, _pendingMobile!);
        setState(() {
          _editingMobile = false;
          _otpSent = false;
          _otpCtrl.clear();
        });
        _load();
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Invalid code')),
        );
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final ref =
          FirebaseStorage.instance.ref().child('profile_photos/$_uid.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await UserProfileService.instance.updatePhotoUrl(_uid, url);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundImage: _profile?.photoUrl != null
                            ? NetworkImage(_profile!.photoUrl!)
                            : null,
                        child: _profile?.photoUrl == null
                            ? const Icon(Icons.person, size: 48)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: _uploadingPhoto
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt,
                                    size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Name
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: _editingName
                        ? TextField(
                            controller: _nameCtrl,
                            autofocus: true,
                            decoration:
                                const InputDecoration(labelText: 'Name'),
                          )
                        : Text(_profile?.name?.isNotEmpty == true
                            ? _profile!.name!
                            : 'Add your name'),
                    trailing: _editingName
                        ? IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: _saveName,
                          )
                        : IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                setState(() => _editingName = true),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Mobile number
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: _editingMobile
                            ? TextField(
                                controller: _mobileCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile number',
                                  hintText: '+91XXXXXXXXXX',
                                ),
                              )
                            : Text(_profile?.mobileNumber?.isNotEmpty == true
                                ? _profile!.mobileNumber!
                                : 'Add mobile number'),
                        trailing: _editingMobile
                            ? IconButton(
                                icon: const Icon(Icons.sms_outlined),
                                onPressed: _otpSent ? null : _sendOtp,
                              )
                            : IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    setState(() => _editingMobile = true),
                              ),
                      ),
                      if (_otpSent)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _otpCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter OTP',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _confirmOtp,
                                child: const Text('Verify'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Email (read-only)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: Text(email ?? 'No email'),
                    subtitle: const Text('Email cannot be changed here'),
                  ),
                ),
              ],
            ),
    );
  }
}
