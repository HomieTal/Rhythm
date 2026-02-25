<p align="center">
  <img src="assets/images/app_icon.png" alt="Rhythm Logo" width="150"/>
</p>

<h1 align="center">Rhythm</h1>

<p align="center">
  <b>A Beautiful, Feature-Rich Music Player for Android</b>
</p>

<p align="center">
  <a href="https://github.com/HomieTal/rhythm/releases"><img src="https://img.shields.io/github/v/release/HomieTal/rhythm?style=flat-square" alt="Release"></a>
  <a href="https://github.com/HomieTal/rhythm/blob/main/LICENSE"><img src="https://img.shields.io/github/license/HomieTal/rhythm?style=flat-square" alt="License"></a>
  <a href="https://github.com/HomieTal/rhythm/stargazers"><img src="https://img.shields.io/github/stars/HomieTal/rhythm?style=flat-square" alt="Stars"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-blue?style=flat-square&logo=flutter" alt="Flutter"></a>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#building-from-source">Build</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## ✨ Features

### 🎵 Music Playback
- **Local Music Library** - Scan and play all audio files from your device
- **Background Playback** - Keep listening while using other apps
- **Notification Controls** - Play, pause, skip tracks from the notification panel
- **Lock Screen Player** - Control playback without unlocking your phone
- **Sleep Timer** - Auto-stop music after a set duration

### 🎨 Customization
- **Theme Support** - Light, Dark, and System-follow themes
- **Custom Accent Colors** - Personalize with your favorite color
- **Navigation Styles** - Choose between bottom navigation or sidebar
- **Material Design 3** - Modern, beautiful UI

### 📚 Library Management
- **Playlists** - Create and manage custom playlists
- **Albums & Artists** - Browse by album or artist
- **Favorites** - Quick access to your loved tracks
- **Recently Played** - Track your listening history
- **Search** - Fuzzy search for songs, albums, and artists

### 🎤 Lyrics
- **Synced Lyrics** - Real-time lyrics display
- **Lyrics Settings** - Customize lyrics display

### 🔧 Audio Features
- **Equalizer** - Fine-tune your audio experience
- **Shuffle & Repeat** - Multiple playback modes
- **Queue Management** - View and edit the upcoming songs

### 🌐 Online Features
- **Online Search** - Search and stream songs from Saavn
- **Album Browsing** - Explore online albums

### ⚙️ Additional Features
- **Share Songs** - Share music files with friends
- **File Location** - View song file details
- **Cache Management** - Control app storage
- **Auto Updates** - Check for new versions

---

## 📸 Screenshots

<!-- Add your screenshots here -->
<!-- 
<p align="center">
  <img src="screenshots/home.png" width="200" />
  <img src="screenshots/player.png" width="200" />
  <img src="screenshots/library.png" width="200" />
  <img src="screenshots/settings.png" width="200" />
</p>
-->

*Screenshots coming soon!*

---

## 📥 Installation

### Download APK
Download the latest APK from the [Releases](https://github.com/HomieTal/rhythm/releases) page.

### Requirements
- Android 6.0 (API 23) or higher
- Storage permission for accessing local music files

---

## 🔨 Building from Source

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or higher)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- Android SDK

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/HomieTal/rhythm.git
   cd rhythm
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

4. **Build release APK**
   ```bash
   flutter build apk --release
   ```
   The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter |
| Language | Dart |
| State Management | Provider |
| Audio | just_audio, audio_service |
| Local Storage | shared_preferences, sqflite |
| API | JioSaavn (for online search) |
| Permissions | permission_handler |

---

## 📦 Dependencies

```yaml
dependencies:
  flutter: sdk
  just_audio: ^0.9.36
  audio_service: ^0.18.12
  audio_session: ^0.1.18
  provider: ^6.0.5
  shared_preferences: ^2.2.2
  on_audio_query: ^2.9.0
  permission_handler: ^11.1.0
  file_picker: ^10.3.8
  google_fonts: ^6.1.0
  flutter_colorpicker: ^1.1.0
  lottie: ^2.4.2
  url_launcher: ^6.3.0
  fuzzywuzzy: ^1.2.0
  # ... and more
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a new branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Ways to Contribute
- 🐛 Report bugs and issues
- 💡 Suggest new features
- 🌍 Help with translations
- 📖 Improve documentation
- 🔧 Submit pull requests

---

## 📋 Roadmap

- [ ] iOS support
- [ ] Crossfade between tracks
- [ ] Lyrics editing
- [ ] Backup & restore
- [ ] Widget support
- [ ] Android Auto support
- [ ] More online music sources

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Developer

<p align="center">
  <img src="assets/images/developer.jpg" width="100" style="border-radius: 50%"/>
  <br>
  <b>CrackDevelopers</b>
  <br>
  <a href="https://github.com/HomieTal">GitHub</a>
</p>

---

## 🙏 Acknowledgments

- [JioSaavn](https://www.jiosaavn.com/) for the music API
- Flutter team for the amazing framework
- All the package authors whose libraries made this possible
- Everyone who contributes to this project

---

<p align="center">
  Made with ❤️ using Flutter
</p>

<p align="center">
  ⭐ Star this repo if you like what you see!
</p>
