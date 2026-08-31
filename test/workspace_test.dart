import 'package:eme_app_package/models/workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Workspace round trip', () {
    // WorkspaceService persists custom workspaces with toJson and restores
    // them with fromJson. toJson writes 'mediadb'; fromJson used to read only
    // 'mediaDBRoot'/'mediadbroot', so every saved workspace came back with an
    // empty root and was skipped on restart ("has no mediaDBRoot, skip").
    test('survives toJson -> fromJson', () {
      final original = Workspace(
        id: 'primary',
        name: 'GenAILabs',
        mediaDBRoot: 'https://minsur.genailabs.tech/site/mediadb',
      );

      final restored = Workspace.fromJson(original.toJson());

      expect(restored.mediaDBRoot, original.mediaDBRoot);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
    });

    test('still accepts the other two spellings of the root', () {
      for (final key in ['mediaDBRoot', 'mediadbroot', 'mediadb']) {
        final ws = Workspace.fromJson({
          'id': 'w',
          'name': 'W',
          key: 'https://example.com/site/mediadb',
        });
        expect(ws.mediaDBRoot, isNotEmpty, reason: 'key $key was dropped');
      }
    });
  });
}
