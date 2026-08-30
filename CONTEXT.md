# EME app package domain glossary

Terms the code and design artifacts use with a precise meaning. Keep code
identifiers aligned with these names.

## EnterMedia HTTP

- **EmeHttp** — the deep module for all EnterMedia HTTP (`lib/eme_http.dart`):
  base-url resolution, auth headers, percent-encoding, decoding, status
  policy, logging and error recording behind three methods (`getJson`,
  `postForm`, `post`). Paths are workspace-relative; absolute URLs are
  rejected so the token can never leak to `Asset.url` hosts. Two adapters:
  `DioEmeHttp` in production, `FakeEmeHttp` in tests.
- **EmeSession** — what the module needs from auth (token + userId), read
  from the `AuthService` statics. The single token source for every HTTP
  call; also the ready-made bridge if the chat WebSocket ever unifies auth.
- **EmeAuth** — the three auth shapes as data: `token` (X-tokentype/X-token,
  default), `none` (pre-auth: login, OTP, refresh — refresh cannot recurse),
  `keyAndUser` (legacy X-entermediakey/X-userid, server list only).
- **EmeHttpException** — the module's one error mode; carries status code and
  the decoded server body. Recorded to `AppErrorHandler` exactly once inside
  the module — callers keep their policy (return empty vs rethrow) but never
  record the same failure again.
- **saveUserFields** — `AuthService`'s usersave.json convenience shared by
  the profile, consent and compliance screens (a graft, not a repository).

Out of scope by decision (see Traycer artifact `entermedia-http-seam-design`):
401/403 retry (future, lands inside `DioEmeHttp`), the media viewer's
unauthenticated `Dio` (`Asset.url` bytes), `sendUserCode`'s JSON body, and
WebSocket auth.
