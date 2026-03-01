# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

### Changed
- Changed reaction emoji sorting [PR #391](https://github.com/marmot-protocol/whitenoise/pull/391)

### Deprecated

### Removed


### Fixed

- Fix npubs middle ellipsis by adding snap to words option [PR #388](https://github.com/marmot-protocol/whitenoise/pull/388)
- Fix onboarding carousel text appearing cut off [PR #404](https://github.com/marmot-protocol/whitenoise/pull/404)

- Fix media modal blurhash issue [PR #397](https://github.com/marmot-protocol/whitenoise/pull/397)

### Security

## [0.3.0] - 2026-02-23

### Added

- Theme setup [PR #1](https://github.com/marmot-protocol/sloth/pull/1)
- CI github action [PR #2](https://github.com/marmot-protocol/sloth/pull/2)
- Dependabot action [PR #3](https://github.com/marmot-protocol/sloth/pull/3)
- Base components [PR #4](https://github.com/marmot-protocol/sloth/pull/4)
- Coverage CI check [PR #5](https://github.com/marmot-protocol/sloth/pull/5)
- Auth, routing and main screens [PR #6](https://github.com/marmot-protocol/sloth/pull/6)
- Developer settings screen  [PR #8](https://github.com/marmot-protocol/sloth/pull/8)
- Chat screen with streams [PR #12](https://github.com/marmot-protocol/sloth/pull/12)
- Show chats in chat list screen and messages in chat invite screen [PR #15](https://github.com/marmot-protocol/sloth/pull/15)
- Profile (keys, edit, share) screens [PR #22](https://github.com/marmot-protocol/sloth/pull/22)
- Send messages [PR #33](https://github.com/marmot-protocol/sloth/pull/33)
- Network relays screen [PR #43](https://github.com/marmot-protocol/sloth/pull/43)
- Search user by npub [PR #39](https://github.com/marmot-protocol/sloth/pull/39)
- Delete messages [PR #49](https://github.com/marmot-protocol/sloth/pull/49)
- Paste nsec login [PR #59](https://github.com/marmot-protocol/sloth/pull/59)
- Reactions [PR #60](https://github.com/marmot-protocol/sloth/pull/60)
- Add multi-account support [PR #78](https://github.com/marmot-protocol/sloth/pull/78)
- Emoji picker for reactions [PR #81](https://github.com/marmot-protocol/sloth/pull/81)
- Setup Widgetbook [PR #82](https://github.com/marmot-protocol/sloth/pull/82)
- Delete reactions [PR #95](https://github.com/marmot-protocol/sloth/pull/95)
- Add start chat and chat info screens with follow/unfollow [PR #96](https://github.com/marmot-protocol/sloth/pull/96)
- Avatar colors [PR #108](https://github.com/marmot-protocol/sloth/pull/108), [PR #137](https://github.com/marmot-protocol/sloth/pull/137)
- Scan QR for nsec [PR #164](https://github.com/marmot-protocol/sloth/pull/164)
- Copy card [PR #157](https://github.com/marmot-protocol/sloth/pull/157)
- Scan QR for npub [PR #175](https://github.com/marmot-protocol/sloth/pull/175)
- Android signer (NIP-55) support [PR #48](https://github.com/marmot-protocol/sloth/pull/48)
- Delete all data [PR #225](https://github.com/marmot-protocol/whitenoise/pull/225)
- Replies [PR #179](https://github.com/marmot-protocol/whitenoise/pull/179)
- Replies scroll [PR #202](https://github.com/marmot-protocol/whitenoise/pull/202)
- Search users by name with batched streaming results [PR #234](https://github.com/marmot-protocol/whitenoise/pull/234)
- Loading indicator in search field during name search [PR #234](https://github.com/marmot-protocol/whitenoise/pull/234)
- Pass metadata to start chat screen for instant display [PR #234](https://github.com/marmot-protocol/whitenoise/pull/234)
- Invite callout [PR #230](https://github.com/marmot-protocol/whitenoise/pull/230)
- Show replies in invite screen [PR #232](https://github.com/marmot-protocol/whitenoise/pull/232)
- Show last message for invites in chat list [#310](https://github.com/marmot-protocol/whitenoise/pull/310)
- Create group [PR #288](https://github.com/marmot-protocol/whitenoise/pull/288)
- Group info & management [PR #315](https://github.com/marmot-protocol/whitenoise/pull/315)
- Copy message to clipboard from message actions [PR #317](https://github.com/marmot-protocol/whitenoise/pull/317)
- Mark messages as read [PR #316](https://github.com/marmot-protocol/whitenoise/pull/316)
- Images in chat [PR #249](https://github.com/marmot-protocol/whitenoise/pull/249)
- Show last message sender name in chat list [PR #322](https://github.com/marmot-protocol/whitenoise/pull/322)
- Add to group from group member screen and start chat screen [PR #323](https://github.com/marmot-protocol/whitenoise/pull/323)
- Text drafts [PR #328](https://github.com/marmot-protocol/whitenoise/pull/328)
- Search messages in chat with match navigation [PR #355](https://github.com/marmot-protocol/whitenoise/pull/355)
- Add to group button in chat info screen navigates to add to group screen [PR #355](https://github.com/marmot-protocol/whitenoise/pull/355)
- Invite to White Noise [PR #354](https://github.com/marmot-protocol/whitenoise/pull/354)
- Add missing translations for switch profile screen [PR #368](https://github.com/marmot-protocol/whitenoise/pull/368)
- Prevent multiple DM chats with same peer [PR #371](https://github.com/marmot-protocol/whitenoise/pull/371)

### Changed

- Rename "Follow"/"Unfollow" buttons to "Add as contact"/"Remove as contact" [PR #323](https://github.com/marmot-protocol/whitenoise/pull/323)

- Improve profile onboarding and account add flows: signup now pre-fills a generated display name with one-tap clear, and the "Add a new profile" slate is compact and bottom-anchored. [PR #313](https://github.com/marmot-protocol/whitenoise/pull/313)
- Redesign chat info as a non-opaque over-chat slate matching Figma: updated action layout, refined spacing, lighter overlay blur, and header name/avatar tap navigation to chat info. [PR #303](https://github.com/marmot-protocol/whitenoise/pull/303)
- Redesign user list tile to match profile switcher pattern [PR #234](https://github.com/marmot-protocol/whitenoise/pull/234)
- Sort follows list: users with metadata alphabetically first, then users without [PR #234](https://github.com/marmot-protocol/whitenoise/pull/234)
- Periodically refresh follows list to pick up background metadata updates [PR #234](https://github.com/marmot-protocol/whitenoise/pull/234)
- Truncate long about text to 10 lines in user profile card [PR #234](https://github.com/marmot-protocol/whitenoise/pull/234)

- Replace all snackbars with system notice [PR #168](https://github.com/marmot-protocol/sloth/pull/168)
- Use large size for login and signup buttons [PR #165](https://github.com/marmot-protocol/sloth/pull/165)
- Change hooks that received refs to receive data [PR #27](https://github.com/marmot-protocol/sloth/pull/27)
- Update chat list using streams [PR #36](https://github.com/marmot-protocol/sloth/pull/36)
- Use Rust as source of truth for locale settings, properly persist "System" language preference [PR #109](https://github.com/marmot-protocol/sloth/pull/109)
- Implement isFollowingUser method [PR #132](https://github.com/marmot-protocol/sloth/pull/132)
- Npub formatting [PR #157](https://github.com/marmot-protocol/sloth/pull/157)
- Migrate to whitenoise app bundle id [PR #163](https://github.com/marmot-protocol/sloth/pull/163)
- Change chat header style to match slate design [PR #258](https://github.com/marmot-protocol/whitenoise/pull/258)
- Message bubbles style [PR #329](https://github.com/marmot-protocol/whitenoise/pull/329)

### Deprecated

### Removed

### Fixed

- Fix emoji overflow on message actions screen [PR #375](https://github.com/marmot-protocol/whitenoise/pull/375)
- Fix app crashes on upgrade from older versions by wiping incompatible data before Rust initialization [PR #312](https://github.com/marmot-protocol/whitenoise/pull/312)
- Disable foreground task plugin receivers to prevent crashes on package update [PR #312](https://github.com/marmot-protocol/whitenoise/pull/312)
- Adds internet permission in android manifest [PR #7](https://github.com/marmot-protocol/sloth/pull/7)
- Fixes logout not working after app reinstall [PR #31](https://github.com/marmot-protocol/sloth/pull/31)
- Fixes sign out exception and adds dedicated sign out screen with private key backup [PR #45](https://github.com/marmot-protocol/sloth/pull/45)
- QR code color now uses theme-aware color [PR #183](https://github.com/marmot-protocol/sloth/pull/183)
- DM avatar color inconsistency [PR #199](https://github.com/marmot-protocol/sloth/pull/199), [PR #232](https://github.com/marmot-protocol/whitenoise/pull/232)
- Ignore duplicate newMessage for accounts on same device [PR #244](https://github.com/marmot-protocol/whitenoise/pull/244)
- Sanitize malformed UTF-16 in user metadata to prevent rendering crashes [PR #234](https://github.com/marmot-protocol/whitenoise/pull/234)
- Lock app orientation to portrait mode [PR #235](https://github.com/marmot-protocol/whitenoise/pull/235)
- Fix camera permission flow [PR #194](https://github.com/marmot-protocol/sloth/pull/194)
- Fix notifications arriving on foreground after accepting invite [PR #361](https://github.com/marmot-protocol/whitenoise/pull/361)

### Security
