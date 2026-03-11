import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/category_model.dart';
import '../../models/advertisement_model.dart';
import '../../services/categories_service.dart';
import '../../services/advertisement_service.dart';
import '../../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onCategoryTap,
  });

  final void Function(int categoryId) onCategoryTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _categoriesService = CategoriesService();
  final _adService = AdvertisementService();
  List<CategoryModel> _categories = [];
  List<AdvertisementModel> _ads = [];
  bool _loading = true;

  final ScrollController _adScrollController = ScrollController();
  Timer? _autoScrollTimer;
  int _currentAdPage = 0;

  static const _defaultAds = [
    _DefaultAd(
      title: 'Premium Avto Salon',
      description: 'Eng sifatli avtomobillar faqat bizda!',
      gradient: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
      icon: PhosphorIconsRegular.car,
    ),
    _DefaultAd(
      title: 'Avto Kredit 0%',
      description: 'Birinchi 6 oy foizsiz kredit',
      gradient: [Color(0xFF26A69A), Color(0xFF4DB6AC)],
      icon: PhosphorIconsRegular.bank,
    ),
    _DefaultAd(
      title: 'Telegram Kanal',
      description: '@avtovodiy — eng oxirgi yangiliklar',
      gradient: [Color(0xFF9575CD), Color(0xFFB39DDB)],
      icon: PhosphorIconsRegular.telegramLogo,
    ),
    _DefaultAd(
      title: 'Avto Servis',
      description: 'Professional diagnostika va ta\'mirlash',
      gradient: [Color(0xFFEF7B45), Color(0xFFF4A261)],
      icon: PhosphorIconsRegular.wrench,
    ),
    _DefaultAd(
      title: 'Sug\'urta Xizmati',
      description: 'OSAGO va KASKO — tez va qulay',
      gradient: [Color(0xFF42A5F5), Color(0xFF64B5F6)],
      icon: PhosphorIconsRegular.shieldCheck,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _adScrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final results = await Future.wait([
      _categoriesService.getCategories(),
      _adService.getActiveAds(),
    ]);

    if (mounted) {
      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _ads = results[1] as List<AdvertisementModel>;
        _loading = false;
      });
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    final total = _ads.isNotEmpty ? _ads.length : _defaultAds.length;
    if (total <= 2) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_adScrollController.hasClients) return;
      if (!_adScrollController.position.hasContentDimensions) return;

      final screenWidth = MediaQuery.of(context).size.width;
      const padding = AppSizes.paddingMedium;
      const spacing = 10.0;
      final cardWidth = (screenWidth - padding * 2 - spacing) / 2;
      final step = cardWidth + spacing;

      _currentAdPage++;
      final maxScroll = _adScrollController.position.maxScrollExtent;
      final target = (_currentAdPage * step).clamp(0.0, maxScroll);

      if (target >= maxScroll) {
        _currentAdPage = 0;
        _adScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _adScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _onAdTap(AdvertisementModel ad) async {
    _adService.trackView(ad.id);
    if (ad.link != null && ad.link!.isNotEmpty) {
      final uri = Uri.tryParse(ad.link!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Welcome banner
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.paddingMedium, 0, AppSizes.paddingMedium, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Avto Vodiy ga\nxush kelibsiz!',
                              style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Eng yaxshi narxlardagi mashinalar",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      PhosphorIcon(PhosphorIconsRegular.car, size: 64, color: Colors.white24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reklama carousel
              _buildAdCarousel(theme),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                child: Text(
                  "Kategoriyalar",
                  style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                child: _loading
                    ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                    : _categories.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              "Kategoriyalar yo'q",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          )
                        : GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: _categories
                                .map((c) => _buildCategoryCard(
                                      context,
                                      icon: CategoryModel.iconFromString(c.icon),
                                      title: c.name,
                                      count: c.elonlarCount.toString(),
                                      onTap: () => widget.onCategoryTap(c.id),
                                    ))
                                .toList(),
                          ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                child: Text(
                  "So'nggi e'lonlar",
                  style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    "E'lonlar sahifasiga o'ting",
                    style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildAdCarousel(ThemeData theme) {
    final hasRealAds = _ads.isNotEmpty;
    final isDark = theme.brightness == Brightness.dark;
    final count = hasRealAds ? _ads.length : _defaultAds.length;

    final screenWidth = MediaQuery.of(context).size.width;
    const padding = AppSizes.paddingMedium;
    const spacing = 10.0;
    final cardWidth = (screenWidth - padding * 2 - spacing) / 2;
    final cardHeight = cardWidth / 1.35;

    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        controller: _adScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: padding),
        itemCount: count,
        itemBuilder: (context, index) {
          return Container(
            width: cardWidth,
            margin: EdgeInsets.only(right: index < count - 1 ? spacing : 0),
            child: hasRealAds
                ? _buildRealAdCard(_ads[index], theme, isDark)
                : _buildDefaultAdCard(_defaultAds[index], theme, isDark),
          );
        },
      ),
    );
  }

  Widget _buildRealAdCard(AdvertisementModel ad, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => _onAdTap(ad),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (ad.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: ad.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _adImagePlaceholder(),
                  errorWidget: (_, __, ___) => _adImagePlaceholder(),
                )
              else
                _adImagePlaceholder(),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  ad.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.2,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: PhosphorIcon(
          PhosphorIconsRegular.megaphone,
          size: 36,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildDefaultAdCard(_DefaultAd ad, ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: ad.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: ad.gradient.first.withValues(alpha: isDark ? 0.3 : 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              right: -16,
              top: -16,
              child: PhosphorIcon(
                ad.icon,
                size: 90,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: PhosphorIcon(
                      ad.icon,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ad.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          ad.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context,
      {required IconData icon, required String title, required String count, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
              Text(
                "$count ta e'lon",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultAd {
  final String title;
  final String description;
  final List<Color> gradient;
  final IconData icon;

  const _DefaultAd({
    required this.title,
    required this.description,
    required this.gradient,
    required this.icon,
  });
}
