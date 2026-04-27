import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:news_app/core/utils/image_processor.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_app/features/auth/presentation/cubit/profile_cubit.dart';
import 'package:news_app/features/auth/presentation/cubit/profile_state.dart';
import 'package:news_app/features/news/presentation/cubit/category_cubit.dart';
import 'package:news_app/injection_container.dart';


class EditProfileBottomSheet extends StatefulWidget {
  const EditProfileBottomSheet({super.key});

  /// Helper to show this bottom sheet globally
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<ProfileCubit>()),
          BlocProvider(create: (_) => sl<CategoryCubit>()..load()),
        ],
        child: const EditProfileBottomSheet(),
      ),
    );
  }

  @override
  State<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  
  Set<String> _selectedPreferences = {};
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    
    // Parse 'technology,sports' into a Set
    if (user != null && user.preferences.isNotEmpty && user.preferences != '{}') {
      _selectedPreferences = user.preferences.split(',').map((e) => e.trim()).toSet();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Flag untuk nampilin loading saat Isolate bekerja
  bool _isProcessingImage = false;

  Future<void> _pickImage() async {
    // UI cuma tahu: ambil file dari galeri, lalu minta tolong ke Helper.
    // UI tidak tahu dan tidak peduli bagaimana cara crop/compress dilakukan.
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      // Tanpa batasan ukuran: biarkan user pilih foto resolusi penuh.
    );

    if (pickedFile != null) {
      setState(() => _isProcessingImage = true);

      // Delegasikan semua kerja berat ke ImageProcessorHelper.
      // Di balik layar, Helper akan menjalankan ini di Worker Isolate.
      final String? processedPath = await ImageProcessorHelper.compressAndCropSquare(
        originalPath: pickedFile.path,
      );

      setState(() {
        _isProcessingImage = false;
        // Fallback: jika Helper gagal, gunakan file asli agar app tidak crash.
        _selectedImage = File(processedPath ?? pickedFile.path);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final user = context.read<AuthBloc>().state.user;
      if (user == null) return;

      context.read<ProfileCubit>().saveProfile(
        currentUser: user,
        newName: _nameController.text.trim(),
        newBio: _bioController.text.trim(),
        newPhone: _phoneController.text.trim(),
        newPreferences: _selectedPreferences.join(','), // Combine back to DB format
        newAvatarFile: _selectedImage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // We need to shift up the bottom sheet if the keyboard appears
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state.status == ProfileStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Update failed'),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else if (state.status == ProfileStatus.success) {
          // Tell AuthBloc about the newly updated data!
          if (state.updatedUser != null) {
            context.read<AuthBloc>().add(AuthUserUpdated(state.updatedUser!));
          }
          
          // Use rootNavigator: true to correctly pop the modal bottom sheet,
          // avoiding 'nothing to pop' GoRouter conflict.
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully! ✨'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == ProfileStatus.loading;
        final user = context.read<AuthBloc>().state.user;
        final currentAvatarUrl = user?.avatarUrl;

        return Container(
          margin: EdgeInsets.only(top: 60, bottom: keyboardHeight),
          decoration: const BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              
              // Scrollable Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar Picker
                        Center(
                          child: GestureDetector(
                            onTap: isLoading ? null : _pickImage,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!) as ImageProvider
                                      : (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty
                                          // Append timestamp for cache busting so the new
                                          // avatar shows immediately after upload.
                                          ? CachedNetworkImageProvider(
                                              '$currentAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch ~/ 10000}',
                                            )
                                          : null),
                                  child: (_selectedImage == null && (currentAvatarUrl == null || currentAvatarUrl.isEmpty))
                                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                      : null,
                                ),
                                // Tampilkan Loading Spinner kalau Isolate sedang bekerja
                                if (_isProcessingImage)
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    width: 100,
                                    height: 100,
                                    child: const Center(
                                      child: CircularProgressIndicator(color: Colors.white),
                                    ),
                                  ),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        const Text(
                          'Personal Info',
                          style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        
                        TextFormField(
                          controller: _nameController,
                          enabled: !isLoading,
                          decoration: _inputDecoration('Full Name', Icons.person_outline),
                          validator: (val) => (val == null || val.isEmpty) ? 'Name required' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _bioController,
                          enabled: !isLoading,
                          maxLines: 3,
                          decoration: _inputDecoration('Bio / About me', Icons.info_outline),
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _phoneController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
                        ),
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Topics of Interest',
                          style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        
                        // Category Chips for Preferences
                        BlocBuilder<CategoryCubit, CategoryState>(
                          builder: (context, catState) {
                            if (catState is CategoryLoading) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (catState is CategoryLoaded) {
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: catState.categories.map((cat) {
                                  final isSelected = _selectedPreferences.contains(cat.slug);
                                  return FilterChip(
                                    label: Text(
                                      cat.name,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: AppTheme.primaryColor,
                                    backgroundColor: AppTheme.surfaceElevated,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedPreferences.add(cat.slug);
                                        } else {
                                          _selectedPreferences.remove(cat.slug);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              );
                            }
                            return const Text('Failed to load categories', style: TextStyle(color: Colors.red));
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Submit Button
                        ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Profile',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.textMuted),
      filled: true,
      fillColor: AppTheme.surfaceElevated,
      labelStyle: const TextStyle(color: AppTheme.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }
}
