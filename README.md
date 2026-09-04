<div align="center">

# 🎵 RITME — Life & Learning OS

**An AI-Powered Productivity, Financial Intelligence & Deep Focus Workspace**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![NeonDB](https://img.shields.io/badge/NeonDB-PostgreSQL_17-00E599?style=for-the-badge&logo=postgresql&logoColor=black)](https://neon.tech)
[![Google Gemini](https://img.shields.io/badge/Google_Gemini-AI_Core-8E75B2?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

*Sync your life, manage your finances, boost your focus, and accelerate your learning — all guided by real-time AI intelligence.*

---

</div>

## ✨ Overview

**Ritme** is a next-generation **Life & Learning Operating System** built with Flutter. It seamlessly merges **financial management**, **task execution**, **study pods**, and **AI interaction** into a unified, responsive glassmorphism workspace.

Powered by **Google Gemini AI** and **NeonDB Serverless PostgreSQL**, Ritme automatically adapts to your workflow — whether you're logging expenses in natural language, mastering new subjects with AI-generated quizzes, or locking into deep focus sessions with a visual BPM metronome.

---

## 🔥 Key Features

### 🤖 1. Gemini AI Core & Natural Language Actions
- **Smart Function Calling**: Type natural commands like *"Catat makan malam 25rb"* or *"Saldo awal 5jt"* and Gemini AI automatically parses, categorizes, and executes database transactions in real-time.
- **Persistent Chat History**: Seamless chat persistence backed by cloud PostgreSQL and local storage.
- **Markdown & Code Rendering**: Rich AI responses formatted with code blocks, list highlights, and clean typography.

### ☁️ 2. Hybrid Cloud & Offline Database Engine
- **NeonDB PostgreSQL Cloud**: Powered by serverless PostgreSQL 17 on AWS with SSL mode enforcement for real-time cloud sync.
- **Transparent Offline Fallback**: Built-in SQLite local fallback engine ensures 100% offline availability without app crashes or data loss.

### ⚡ 3. Real-Time Inter-Tab Data Reactivity
- **Event-Driven Architecture**: Powered by a custom `RitmeDataNotifier` singleton, any data update (adding tasks, logging expenses, deleting pods) instantly updates all open screens across the app without manual reloads.

### 🎯 4. Task Tempo Sync & Deep Focus Timer
- **Eisenhower Priority Matrix**: Organize tasks by Urgent/Important quadrants.
- **Focus Pomodoro Timer & BPM Metronome**: 25-minute Pomodoro focus session equipped with a visual pulsing metronome synced to AI-recommended BPM rates.

### 📊 5. Financial Intelligence & Spending Radar
- **Expense & Income Tracking**: Real-time balance calculations, category breakdowns, and filterable transaction logs.
- **Impulsive Spending Radar**: Smart detection to keep budget overspends in check.

### 🧠 6. Audio Study Pod & Interactive AI Quiz Generator
- **Subject Study Hubs**: Organize study materials, notes, and audio study pods.
- **AI Quiz Generator**: Convert lecture notes (`ai_notes`) into interactive multiple-choice quizzes with real-time scoring and instant feedback.

### 🎨 7. Adaptive Glassmorphism UI
- **Futuristic Aesthetics**: Custom glassmorphism cards, dynamic gradients, smooth micro-animations, and full dark-mode optimization.

---

## 🛠️ Tech Stack & Architecture

| Layer | Technology |
| :--- | :--- |
| **Framework** | [Flutter 3.x](https://flutter.dev) (Dart 3) |
| **Cloud Database** | [NeonDB](https://neon.tech) (Serverless PostgreSQL 17) |
| **Local Database** | [SQLite](https://sqlite.org) / FFI (`sqflite_common_ffi`) |
| **AI Integration** | [Google Generative AI SDK](https://pub.dev/packages/google_generative_ai) (Gemini API) |
| **Design System** | Glassmorphism, [Google Fonts (Outfit / Inter)](https://fonts.google.com), `flutter_animate` |
| **State Sync** | Custom Event-Driven Singleton Notifier (`RitmeDataNotifier`) |

---

## 📁 Repository Structure

```
ritme/
├── lib/
│   ├── database/
│   │   ├── database_helper.dart      # Hybrid Database Handler (NeonDB + SQLite Fallback)
│   │   └── neon_database_helper.dart # NeonDB PostgreSQL Direct Driver
│   ├── models/
│   │   ├── task_model.dart           # Task Entity
│   │   ├── transaction_model.dart    # Financial Transaction Entity
│   │   └── study_pod_model.dart      # Study Pod & Quiz Entity
│   ├── screens/
│   │   ├── adaptive_glass_scaffold.dart # Main Navigation Layout
│   │   ├── home_dashboard_screen.dart   # Dashboard Overview
│   │   ├── finance_tracker_screen.dart # Finance & Budgeting
│   │   ├── task_tempo_sync_screen.dart # Task Matrix & Focus Timer
│   │   ├── audio_study_pod_screen.dart # Study Pods & AI Quiz
│   │   └── gemini_assistant_screen.dart# Gemini AI Core Chat
│   ├── services/
│   │   ├── gemini_service.dart       # Gemini AI Function Calling & Intent Processor
│   │   └── ritme_data_notifier.dart  # Real-Time Event State Notifier
│   └── main.dart                     # Entry Point
├── test/                             # Automated Unit & Integration Tests
└── .env                              # Environment Credentials Configuration
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.13.2`)
- [Dart SDK](https://dart.dev/get-dart)
- A **Google Gemini API Key** (Get one at [Google AI Studio](https://aistudio.google.com/))
- A **NeonDB Connection String** (Get one at [Neon.tech](https://neon.tech/))

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/FahryAditya/Ritme-Life-Learning-OS.git
   cd Ritme-Life-Learning-OS
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**
   Create a `.env` file in the root project directory:
   ```env
   GEMINI_API_KEY=your_gemini_api_key_here
   DATABASE_URL=postgresql://user:password@ep-your-neon-host.aws.neon.tech/neondb?sslmode=require
   ```

4. **Run Automated Tests**
   ```bash
   flutter test
   ```

5. **Launch the Application**
   ```bash
   flutter run
   ```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [Issues page](https://github.com/FahryAditya/Ritme-Life-Learning-OS/issues).

---

## 📝 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

<div align="center">
  <sub>Built with ❤️ by <b>Fahry Aditya</b></sub>
</div>
