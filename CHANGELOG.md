# Changelog

## [Unreleased] - 2026-04-15

### Added
- **Google and Phone Authentication**: Integrated Google Sign-In and Phone OTP verification in `AuthRepository` and auth screens.
- Added new Phone Auth numeric entry dialog featuring an `intl_phone_field` country code picker.
- Implemented `SocialIconButton` for a clean circular social button interface.

### Changed
- Updated app icon for both Android and iOS with a modern design featuring green bars on a navy background.
- Regenerated all native app icon assets using `flutter_launcher_icons`.

### Fixed
- Resolved `GoException` by correcting redirect and navigation paths from `/dashboard` to `/home` in auth screens.

## [Unreleased] - 2026-03-14

### Added
- New premium repository cover image in `assets/readme/cover_image.png`.
- Repository tags and enhanced project description in `README.md`.

### Changed
- Refactored `README.md` header for better visual presentation.

### Removed
- `PAYMENT_SYSTEM_SPECIFICATION.md`: Internal specification file.
- `docs/PLAY_STORE_REQUIREMENTS.md`: Internal planning file.
