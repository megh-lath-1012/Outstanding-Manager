# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-03-11

### Added
- **Smart OCR Invoice Scanner**: AI-powered feature to scan and parse physical invoices (Number, Date, Amount) using Gemini 2.0 Flash Vision.
- **Feature Flagging System**: Introduced `ConfigService` to manage features like the OCR Scanner, enabling controlled rollouts and closed testing.
- **OCR Service & Model**: New `OCRService` and `OcrResult` model to handle image-to-data transformation via Firebase Cloud Functions.
- **UI Integrations**: Added "Scan Invoice" capability to `AddSalesRecordScreen` and `AddPurchaseRecordScreen` with a native `image_picker` interface.
- **Stitch Redesign Prompt**: A high-fidelity prompt for `stitch.withgoogle.com` to generate modern, premium UI assets and prototypes.
- **Feature Expansion Proposal**: A roadmap artifact with innovative ideas like WhatsApp integration, multilingual voice entry, and dynamic trust scoring.

### Dependencies
- Added `image_picker: ^1.0.7` for cross-platform image capture and selection.
