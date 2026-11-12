# SkillBridge AI mobile app

The `mobile_app` package combines Candidate Profile & Skill Management with
vacancy browsing, bookmarks, applications, and staff shortlisting/AI/analytics.
Authentication and the Candidate providers initialize before protected screens.

Run `flutter pub get`, `flutter analyze`, `flutter test`, then `flutter run`.
The backend is the ASP.NET Core API. Use `--dart-define=API_BASE_URL=http://YOUR_HOST:5264/api`
for a physical device; defaults support the Android emulator and local web development.

Android uses Java/Kotlin 17 and compile SDK 36, including the file_picker
library compatibility override. Platform scaffolding from main is retained.
