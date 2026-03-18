import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/conversation_model.dart';
import '../../models/elon_model.dart';
import '../../services/chat_service.dart';
import '../../services/elonlar_service.dart';
import '../../services/favorite_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../services/analytics_service.dart';
import '../../services/moderation_service.dart';
import '../../widgets/full_screen_image_viewer.dart';
import '../../widgets/report_bottom_sheet.dart';
import '../chat/chat_detail_screen.dart';

class ElonDetailScreen extends StatefulWidget {
  const ElonDetailScreen({super.key, required this.elonId});

  final int elonId;

  @override
  State<ElonDetailScreen> createState() => _ElonDetailScreenState();
}

class _ElonDetailScreenState extends State<ElonDetailScreen> {
  final _elonlarService = ElonlarService();
  final _chatService = ChatService();
  final _favoriteService = FavoriteService();
  ElonModel? _elon;
  bool _loading = true;
  int _currentImageIndex = 0;
  bool _openingChat = false;
  bool _isFavorited = false;
  bool _togglingFavorite = false;

  bool _isGuest = true;

  @override
  void initState() {
    super.initState();
    _load();
    _initAuth();
    AnalyticsService().trackPageView('elon_detail');
  }

  Future<void> _initAuth() async {
    final loggedIn = await isLoggedIn();
    if (mounted) setState(() => _isGuest = !loggedIn);
    if (loggedIn) _checkFavorite();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final elon = await _elonlarService.getById(widget.elonId);
    if (mounted) {
      setState(() {
        _elon = elon;
        _loading = false;
      });
      if (elon != null && elon.images.isNotEmpty) {
        for (final img in elon.images) {
          if (img.url.isNotEmpty) {
            precacheImage(CachedNetworkImageProvider(img.url), context);
          }
        }
      }
    }
  }

  Future<void> _checkFavorite() async {
    final result = await _favoriteService.checkFavorite(widget.elonId);
    if (mounted) setState(() => _isFavorited = result);
  }

  Future<void> _toggleFavorite() async {
    if (_isGuest) {
      await requireAuth(context, message: 'Sevimlilar uchun hisobingizga kiring.');
      return;
    }
    if (_togglingFavorite) return;
    setState(() => _togglingFavorite = true);
    final result = await _favoriteService.toggle(widget.elonId);
    if (mounted) {
      setState(() {
        _togglingFavorite = false;
        if (result.success) _isFavorited = result.isFavorited;
      });
      showSnackBar(context, result.message, isError: !result.success);
    }
  }

  void _shareElon() {
    if (_elon == null) return;
    final elon = _elon!;
    final title = '${elon.marka} ${elon.model ?? ''}'.trim();
    final text = '$title — ${elon.narxFormatted}\n'
        '${ApiConstants.imageBaseUrl}/elon/${elon.id}';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("E'lon")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_elon == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("E'lon")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(PhosphorIconsRegular.warning, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                "E'lon topilmadi",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Orqaga'),
              ),
            ],
          ),
        ),
      );
    }

    final elon = _elon!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("E'lon"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value, elon),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'report',
                child: ListTile(
                  leading: Icon(Icons.flag_outlined, color: Colors.orange),
                  title: Text('Shikoyat qilish'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (elon.userId != null)
                const PopupMenuItem(
                  value: 'block',
                  child: ListTile(
                    leading: Icon(Icons.block, color: Colors.red),
                    title: Text('Foydalanuvchini bloklash'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagesSection(elon),
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(elon),
                    const SizedBox(height: 16),
                    _buildInfoCard(elon),
                    if (elon.tavsif != null && elon.tavsif!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildTavsifCard(elon),
                    ],
                    if (elon.telefon.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildContactSection(elon),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagesSection(ElonModel elon) {
    if (elon.images.isEmpty) {
      return _placeholderImage();
    }

    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            itemCount: elon.images.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (_, i) {
              final img = elon.images[i];
              return GestureDetector(
                onTap: () => FullScreenImageViewer.show(
                  context,
                  urls: elon.images.map((e) => e.url).toList(),
                  initialIndex: i,
                ),
                child: CachedNetworkImage(
                  imageUrl: img.url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => _placeholderImage(),
                ),
              );
            },
          ),
        ),
        if (elon.images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              elon.images.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentImageIndex == i ? 10 : 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == i
                      ? AppColors.primary
                      : AppColors.primaryLight.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 280,
      width: double.infinity,
      color: AppColors.primaryLight.withValues(alpha: 0.2),
      child: PhosphorIcon(PhosphorIconsRegular.car, size: 80, color: AppColors.primaryLight),
    );
  }

  Widget _buildHeaderCard(ElonModel elon) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  elon.narxFormatted,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${elon.marka} ${elon.model ?? ''}'.trim(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: _isFavorited
                ? PhosphorIconsFill.heart
                : PhosphorIconsRegular.heart,
            color: _isFavorited ? AppColors.error : theme.colorScheme.onSurfaceVariant,
            onTap: _togglingFavorite ? null : _toggleFavorite,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: PhosphorIconsRegular.shareFat,
            color: theme.colorScheme.onSurfaceVariant,
            onTap: _shareElon,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PhosphorIcon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ElonModel elon) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildInfoSection(elon),
    );
  }

  Widget _buildTavsifCard(ElonModel elon) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tavsif',
            style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            elon.tavsif!,
            style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(String action, ElonModel elon) async {
    if (_isGuest) {
      await requireAuth(context, message: 'Bu funksiya uchun hisobingizga kiring.');
      return;
    }
    switch (action) {
      case 'report':
        ReportBottomSheet.show(
          context,
          reportableType: 'elon',
          reportableId: elon.id,
          title: "E'longa shikoyat",
        );
        break;
      case 'block':
        if (elon.userId == null) return;
        _showBlockConfirmation(elon.userId!, elon.ownerName ?? "E'lon egasi");
        break;
    }
  }

  Future<void> _showBlockConfirmation(int userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Foydalanuvchini bloklash'),
        content: Text(
          '"$userName" ni bloklaysizmi?\n\nBloklangan foydalanuvchining e\'lonlari va xabarlari sizga ko\'rinmaydi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Bloklash'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ModerationService().blockUser(userId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );

    if (result.success) {
      Navigator.pop(context);
    }
  }

  Future<void> _openChat(ElonModel elon) async {
    if (_isGuest) {
      await requireAuth(context, message: 'Xabar yozish uchun hisobingizga kiring.');
      return;
    }
    final userId = elon.userId;
    if (userId == null || _openingChat) return;

    setState(() => _openingChat = true);
    final result = await _chatService.createConversation(userId);
    if (!mounted) return;
    setState(() => _openingChat = false);

    if (result.success && result.conversation != null) {
      final otherUser = ChatUserModel(
        id: userId,
        name: elon.ownerName ?? 'E\'lon egasi',
        phone: elon.ownerPhone ?? elon.telefon,
        avatarUrl: elon.ownerAvatarUrl,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: result.conversation!.id,
            otherUser: otherUser,
          ),
        ),
      );
    } else {
      showSnackBar(context, 'Chat ochilmadi', isError: true);
    }
  }

  Widget _buildContactSection(ElonModel elon) {
    final theme = Theme.of(context);
    final canChat = elon.userId != null;
    final hasTelegram = elon.ownerTelegramUsername != null &&
        elon.ownerTelegramUsername!.trim().isNotEmpty;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aloqa',
                style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatPhone(elon.telefon),
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                    ),
                  ),
                  if (canChat)
                    _buildIconBtn(
                      onTap: _openingChat ? null : () => _openChat(elon),
                      icon: _openingChat
                          ? null
                          : PhosphorIconsRegular.chatCircle,
                      loading: _openingChat,
                    ),
                  if (hasTelegram) ...[
                    if (canChat) const SizedBox(width: 8),
                    _buildIconBtn(
                      onTap: () => launchTelegram(elon.ownerTelegramUsername!),
                      icon: PhosphorIconsRegular.telegramLogo,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => launchPhone(elon.telefon),
                  icon: PhosphorIcon(PhosphorIconsRegular.phone, size: 20, color: Colors.white),
                  label: const Text('Qo\'ng\'iroq qilish'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              if (canChat || hasTelegram) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (canChat)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openingChat ? null : () => _openChat(elon),
                          icon: PhosphorIcon(PhosphorIconsRegular.chatCircle, size: 20, color: AppColors.primary),
                          label: Text('Xabar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    if (canChat && hasTelegram) const SizedBox(width: 10),
                    if (hasTelegram)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchTelegram(elon.ownerTelegramUsername!),
                          icon: Icon(Icons.send_rounded, size: 18, color: AppColors.primary),
                          label: Text('Telegram', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconBtn({VoidCallback? onTap, IconData? icon, bool loading = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
          ),
          child: loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : PhosphorIcon(icon!, color: AppColors.primary, size: 24),
        ),
      ),
    );
  }

  Widget _buildInfoSection(ElonModel elon) {
    final modelName = '${elon.marka} ${elon.model ?? ''}'.trim();
    final items = <_InfoItem>[
      if (modelName.isNotEmpty) _InfoItem(PhosphorIconsRegular.car, 'Moshina', modelName),
      _InfoItem(PhosphorIconsRegular.calendar, 'Yil', '${elon.yil}'),
      _InfoItem(PhosphorIconsRegular.gauge, 'Probeg', '${elon.probeg} km'),
      _InfoItem(PhosphorIconsRegular.mapPin, 'Shahar', elon.shahar),
    ];
    if (elon.rang != null && elon.rang!.isNotEmpty) {
      items.add(_InfoItem(PhosphorIconsRegular.palette, 'Rang', elon.rang!));
    }
    if (elon.yoqilgiTuri != null && elon.yoqilgiTuri!.isNotEmpty) {
      final label = ElonOptions.yoqilgiTuriLabels[elon.yoqilgiTuri!] ?? elon.yoqilgiTuri!;
      items.add(_InfoItem(PhosphorIconsRegular.gasPump, 'Yoqilg\'i', label));
    }
    if (elon.uzatishQutisi != null && elon.uzatishQutisi!.isNotEmpty) {
      items.add(_InfoItem(PhosphorIconsRegular.gear, 'Uzatish qutisi', elon.uzatishQutisi!));
    }
    if (elon.kraskaHolati != null && elon.kraskaHolati!.isNotEmpty) {
      items.add(_InfoItem(PhosphorIconsRegular.paintBrush, 'Kraska holati', elon.kraskaHolati!));
    }
    if (elon.bankKredit == true) {
      items.add(_InfoItem(PhosphorIconsRegular.bank, 'Bank kredit', 'Ha'));
    }
    if (elon.general == true) {
      items.add(_InfoItem(PhosphorIconsRegular.checkCircle, 'General', 'Ha'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((e) => _infoRow(e.icon, e.label, e.value)).toList(),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(icon, size: 18, color: AppColors.primary.withValues(alpha: 0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem(this.icon, this.label, this.value);
}
