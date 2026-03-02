import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:fitment_flutter/dao/user_dao.dart';
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:fitment_flutter/config/api_config.dart';
import 'package:fitment_flutter/utils/view_util.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/components/loading_widget.dart';
import 'package:fitment_flutter/components/media_picker.dart';

class EditInfoPage extends StatefulWidget {
  const EditInfoPage({super.key});

  @override
  State<EditInfoPage> createState() => _EditInfoPageState();
}

class _EditInfoPageState extends State<EditInfoPage> {
  final TextEditingController _nicknameController = TextEditingController();
  String? _avatarUrl;
  String? _phone;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    try {
      final result = await UserDao.getUserInfo();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        final data = result['data'] as Map<String, dynamic>?;
        if (result['success'] == true && data != null) {
          _nicknameController.text = data['nickname'] ?? '';
          _avatarUrl = data['avatar'] as String?;
          _phone = data['phone'] as String?;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      showToast(context, '加载用户信息失败: $e');
    }
  }

  Future<void> _selectAvatar() async {
    final result = await MediaPicker.showPicker(
        context: context, maxCount: 1, allowVideo: false);
    if (result != null && result.isNotEmpty) {
      // 先设置选中的图片，不显示loading
      setState(() {
        _selectedImage = result.first.file;
      });
      // 然后开始上传（上传时再显示loading）
      await _uploadAvatar(result);
    }
  }

  /// 获取上传接口的完整 URL
  String _getUploadUrl() {
    final uri = ApiConfig.createUri('/upload');
    return uri.toString();
  }

  Future<void> _uploadAvatar(List<MediaFile> mediaFiles) async {
    if (mediaFiles.isEmpty) return;
    
    // 开始上传时才显示loading
    setState(() => _isUploading = true);
    
    try {
      // 获取上传 URL
      final uploadUrl = _getUploadUrl();
      
      // 获取 token 用于请求头
      final token = LoginDao.getToken();
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // 使用 MediaPicker.upload 上传
      final results = await MediaPicker.upload(
        mediaFiles: mediaFiles,
        uploadUrl: uploadUrl,
        fieldName: 'file',
        headers: headers,
        onProgress: (sent, total) {
          // 可以在这里显示上传进度
          debugPrint('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
        },
      );

      if (!mounted) return;
      
      if (results.isNotEmpty) {
        final result = results.first;
        // 使用工具函数提取 URL
        final url = MediaPicker.extractUrlFromUploadResult(result);
        
        if (url != null) {
          setState(() {
            _avatarUrl = url;
            _selectedImage = null;
            _isUploading = false;
          });
          showToast(context, '头像上传成功');
        } else {
          setState(() => _isUploading = false);
          showToast(context, result['message'] ?? '上传失败：未返回图片URL');
        }
      } else {
        setState(() => _isUploading = false);
        showToast(context, '上传失败：无返回结果');
      }
    } catch (e) {
      if (mounted) setState(() => _isUploading = false);
      showToast(context, '上传失败: $e');
    }
  }

  Future<void> _saveUserInfo() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      showToast(context, '请输入昵称');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final params = {'nickname': nickname};
      if (_avatarUrl != null) params['avatar'] = _avatarUrl!;
      final result = await UserDao.updateUserInfo(params);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        showToast(context, '保存成功');
        Navigator.pop(context, true);
      } else {
        showToast(context, result['message'] ?? '保存失败');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      showToast(context, '保存失败: $e');
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              LoginDao.logout();
              showToast(context, '已退出登录');
              NavigatorUtil.goToLogin();
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑资料'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: LoadingWidget(
        isLoading: _isLoading && _nicknameController.text.isEmpty,
        cover: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 32),
                    _buildFormSection(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _selectAvatar,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _isUploading
                        ? Container(
                            color: Colors.white,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          )
                        : (_selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar();
                                },
                              )
                            : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                                ? Image.network(
                                    _avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildDefaultAvatar();
                                    },
                                  )
                                : _buildDefaultAvatar())),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _selectAvatar,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '点击更换头像',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[100],
      child: const Icon(
        Icons.person,
        size: 50,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFormItem(
            icon: Icons.person_outline,
            iconColor: AppColors.primary,
            child: TextField(
              controller: _nicknameController,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '请输入昵称',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 48,
            color: Colors.grey[100],
          ),
          _buildFormItem(
            icon: Icons.phone_outlined,
            iconColor: Colors.grey[400]!,
            child: Text(
              _phone ?? '未绑定手机号',
              style: TextStyle(
                fontSize: 16,
                color: _phone != null ? Colors.grey[700] : Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormItem({
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              onPressed: _handleLogout,
              icon: Icons.logout,
              label: '退出登录',
              backgroundColor: Colors.red[50]!,
              foregroundColor: Colors.red[600]!,
              borderColor: Colors.red[200]!,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              onPressed: _isLoading ? null : _saveUserInfo,
              icon: Icons.check_circle_outline,
              label: '保存',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
    bool isLoading = false,
  }) {
    return Container(
      height: 50,
      decoration: borderColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            )
          : BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(foregroundColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18, color: foregroundColor),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: foregroundColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
