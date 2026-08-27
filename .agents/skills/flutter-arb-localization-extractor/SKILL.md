---
name: flutter-arb-localization-extractor
description: Extracts hardcoded string literals from a Flutter/Dart project's UI code, adds them as keyed entries to ARB localization files (e.g. lib/l10n/app_en.arb, app_es.arb), auto-translates non-English locale files, and rewrites the Dart source to call the generated AppLocalizations instead of the literal text. Use this whenever the user wants to internationalize/localize a Flutter app, mentions "l10n", ".arb files", "app_en.arb", "app_es.arb", "hardcoded strings", "extract strings for translation", or asks to find/replace string literals across a Flutter project with localization calls. Also use it if the user has an existing partially-localized Flutter app and wants to find strings that were missed and add them to the existing ARB files.
---

# Flutter ARB Localization Extractor

## What this skill does and why it's structured this way

Turning a Flutter app's hardcoded strings into a proper localization setup has three parts that need different kinds of judgment:

1. **Finding candidate strings** is mechanical — a script can walk every `.dart` file and list every string literal.
2. **Deciding which of those are real user-facing UI text** (versus asset paths, log messages, JSON keys, route names, format strings, etc.) needs context and judgment, not just a regex.
3. **Naming keys well, writing translations, and rewriting the call sites** needs to understand what the app actually does.

So this skill pairs a bundled scanner script (`scripts/find_string_literals.py`) that handles part 1 mechanically and pre-filters a lot of part 2, with a workflow for you to do the judgment calls in parts 2 and 3 properly. Don't skip straight to editing files off the raw scan — read the candidates, and read the surrounding file when a string's purpose isn't obvious from one line of context.

## Step 0: Understand the project's localization setup

The file paths `lib/l10n/app_en.arb` / `lib/l10n/app_es.arb` are the standard convention for Flutter's official `flutter gen-l10n` tooling (not `easy_localization`, which uses JSON assets, or GetX translations). Before touching anything, check if `lib/l10n/app_en.arb` already has entries, read them first. Reuse existing keys for strings that already have a translation instead of creating duplicates with the same value.

## Step 1: Scan for string literals

Run the bundled scanner over `lib/` (adjust the path if the project layout differs):

```bash
python3 scripts/find_string_literals.py path/to/project/lib --json /tmp/arb_scan.json
```

This is a heuristic lexer, not a full Dart parser — it correctly skips comments and handles interpolation, but it can't know your app's intent. It splits results into:

- `candidates`: strings with no obvious reason to skip — your real worklist.
- `skipped`: strings it auto-classified as non-UI (asset paths, URLs, log/debug calls, import statements, route-like identifiers, JSON/map keys, date-format patterns, already-localized calls, hex colors, empty/symbol strings) along with _why_, in `skip_reason`.

Read through `skipped` too, briefly — heuristics misfire. A string like `'/settings'` gets skipped as a route name, but `'N/A'` might get flagged as an identifier when it's actually a label a user sees. When in doubt, open the file at that line rather than trusting the one-line `context_line`.

Also use your own judgment to skip things the scanner can't know about: brand names, technical error codes shown only to developers, strings only used in tests, `kDebugMode`-gated text, and strings that are really format templates for `DateFormat`/`NumberFormat` rather than sentences.

## Step 2: Decide keys and build the extraction plan

For each string you're keeping, work out:

- **Key name**: camelCase, derived from meaning and location, e.g. a "Sign in" button on the login screen → `signInButtonLabel`, not `text1` or `signIn` if there could be ambiguity with another "Sign in" elsewhere with different phrasing. Reuse a key if the exact same English text already appears with the same meaning elsewhere (a shared "Cancel" button, for instance) — don't create near-duplicate keys for identical strings.
- **Placeholders**: if `is_interpolated` is true, work out what's being interpolated (e.g. `'Hello, $name!'`) and design an ICU placeholder for it (`"Hello, {name}!"`). Check the interpolated expression's type where you can (a `String`, `int`, etc.) — ARB placeholders should declare a `type`.
- **Plurals**: if a string branches on a count (e.g. via a manual `count == 1 ? '...' : '...'` or a `Intl.plural` call already), use ICU `plural` syntax in the ARB value instead of two separate keys. This is the one case worth flagging to the user if you're unsure how they want it handled, since it also changes the call site shape.

Group the plan by file so you can apply edits file-by-file in step 4.

## Step 3: Write the ARB files

`lib/l10n/app_en.arb` (the template) gets both the value and metadata:

```json
{
	"signInButtonLabel": "Sign in",
	"@signInButtonLabel": {
		"description": "Label on the button that submits the login form"
	},
	"greeting": "Hello, {name}!",
	"@greeting": {
		"description": "Welcome message shown on the home screen after login",
		"placeholders": {
			"name": { "type": "String" }
		}
	}
}
```

`lib/l10n/app_es.arb` and other non-template locale files get **only** the translated key/value pairs — no `@` metadata blocks (that metadata belongs solely to the template file):

```json
{
	"signInButtonLabel": "Iniciar sesión",
	"greeting": "Hola, {name}!"
}
```

Translate the English text yourself, matching the register and tone of the surrounding UI copy (formal vs. casual, sentence case vs. title case) rather than doing a literal word-for-word translation. Preserve placeholders exactly (`{name}`) untranslated. If a file already exists, merge your new keys in rather than overwriting the whole file — read it first, then add to it.

Keep both files' key sets in sync: every key in the template must have a matching key in every other locale file, or `flutter gen-l10n` will fail (unless the project's `l10n.yaml` explicitly allows partial translations via `nullable-getter`/`use-escaping` settings — check before relying on that).

## Step 4: Rewrite the Dart call sites

For each extracted string, replace the literal with a call on the generated class, using the `output-class` name you found in Step 0 (default `AppLocalizations`):

- Plain string: `Text('Sign in')` → `Text(AppLocalizations.of(context)!.signInButtonLabel)`
- With placeholders: `Text('Hello, $name!')` → `Text(AppLocalizations.of(context)!.greeting(name))`

Make sure each edited file imports the generated localizations file, typically:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

(the exact package/path depends on `output-localization-file` and the project's package name — confirm from `l10n.yaml` or an existing import elsewhere in the project rather than assuming).

`AppLocalizations.of(context)` needs a `BuildContext`. This is usually available directly inside `build()` methods and widget callbacks. If a string lives somewhere without a `context` in scope (a top-level function, a model class, a `static` method), don't force it — flag it to the user rather than inventing a context threading solution that changes the class's API without their say-so.

Use `str_replace` for each call site so you can verify you're editing the exact original literal, not a similar-looking one elsewhere in the file.

## Step 5: Verify

After editing, try running codegen so obvious mistakes (duplicate keys, mismatched placeholders, missing keys in a locale file) surface immediately:

```bash
cd path/to/project && flutter gen-l10n
```

If `flutter` isn't available in the environment, at minimum validate both ARB files parse as JSON and have matching key sets:

```bash
python3 -c "
import json
en = json.load(open('lib/l10n/app_en.arb'))
es = json.load(open('lib/l10n/app_es.arb'))
en_keys = {k for k in en if not k.startswith('@')}
es_keys = set(es)
print('missing from es:', en_keys - es_keys)
print('extra in es:', es_keys - en_keys)
"
```

## Step 6: Report back

Summarize for the user: how many strings were extracted, how many the scanner auto-skipped (with a couple of examples so they can spot-check the heuristics), which files were edited, and any strings you deliberately left alone and why (no `BuildContext` available, ambiguous plural handling, looked like a technical/dev-only string, etc.) so they can decide on those manually.
