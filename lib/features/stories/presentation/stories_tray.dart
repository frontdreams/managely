import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/story.dart';
import '../../profile/providers/profile_providers.dart';
import '../providers/stories_providers.dart';

/// The horizontal row of story-category circles shown on Home, right
/// under the app bar and above the "Ready to practise?" hero card. Each
/// circle gets a colored ring when that category has an unseen story,
/// and a muted gray ring otherwise (empty or already viewed) — same
/// visual language as Instagram's story tray, toned down to fit a
/// professional coaching app rather than a social feed.
class StoriesTray extends ConsumerWidget {
  const StoriesTray({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(userProfileProvider.select((p) => p.isAdmin));

    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          if (isAdmin)
            _PostStoryCircle(onTap: () => context.push('/admin/post-story')),
          for (final category in StoryCategory.values)
            _StoryCategoryCircle(
              category: category,
              onTap: () => context.push('/story/${category.name}'),
            ),
        ],
      ),
    );
  }
}

class _StoryCategoryCircle extends ConsumerWidget {
  final StoryCategory category;
  final VoidCallback onTap;
  const _StoryCategoryCircle({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasUnseen = ref.watch(hasUnseenStoriesProvider(category));
    final stories = ref.watch(storiesForCategoryProvider(category));
    final isEmpty = stories.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: isEmpty ? null : onTap,
        child: Opacity(
          opacity: isEmpty ? 0.45 : 1,
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasUnseen ? category.color : AppColors.borderLight,
                    width: hasUnseen ? 2.2 : 1.5,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: category.color.withOpacity(0.12),
                  ),
                  child: Icon(category.icon, color: category.color, size: 24),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.label,
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textOnBrandMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostStoryCircle extends StatelessWidget {
  final VoidCallback onTap;
  const _PostStoryCircle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight,
                border: Border.all(color: AppColors.borderLight, width: 1.5),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              'Post',
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textOnBrandMuted),
            ),
          ],
        ),
      ),
    );
  }
}