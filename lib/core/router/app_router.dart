import 'package:go_router/go_router.dart';

import '../../features/collections/screens/collections_screen.dart';
import '../../features/collections/screens/add_edit_collection_screen.dart';
import '../../features/flashcards/screens/flashcard_list_screen.dart';
import '../../features/flashcards/screens/add_edit_flashcard_screen.dart';
import '../../features/tags/screens/tags_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/collections',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          AppShell(navigationShell: shell),
      branches: [
        // ── Branch 0: Collections ──────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/collections',
              builder: (c, s) => const CollectionsScreen(),
              routes: [
                // Literal "new" must come BEFORE parameterised ":id"
                GoRoute(
                  path: 'new',
                  builder: (c, s) => const AddEditCollectionScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (c, s) => FlashcardListScreen(
                    collectionId: s.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (c, s) => AddEditCollectionScreen(
                        collectionId: s.pathParameters['id'],
                      ),
                    ),
                    GoRoute(
                      path: 'add',
                      builder: (c, s) => AddEditFlashcardScreen(
                        collectionId: s.pathParameters['id']!,
                      ),
                    ),
                    GoRoute(
                      path: 'card/:cardId',
                      builder: (c, s) => AddEditFlashcardScreen(
                        collectionId: s.pathParameters['id']!,
                        cardId: s.pathParameters['cardId'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // ── Branch 1: Tags ─────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tags',
              builder: (c, s) => const TagsScreen(),
            ),
          ],
        ),

        // ── Branch 2: Settings ─────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (c, s) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
