# 👶 KiddoAI - Flutter Frontend

**KiddoAI** is a mobile-first educational app built with **Flutter**. It offers Tunisian primary school children (starting at age 6) a fun, interactive learning experience using **AI, child profiling**, and cartoon-style personalization.

> Ce projet Flutter fait partie de l'application éducative **KiddoAI**, destinée aux enfants de 6 ans (1ère année primaire en Tunisie). L’interface est conçue pour être simple, engageante et accessible aux jeunes enfants.

---

## 🚀 Project Overview | Vue d'ensemble

### EN 🇬🇧
This is the **Flutter frontend** of the KiddoAI app. It features:
- 🎨 A kid-friendly UI built for touchscreen navigation
- 🧒 Sign-up with avatar selection (SpongeBob, Hello Kitty, Gumball, etc.)
- 🧠 IQ Test screen on first login
- 💬 Chat assistant powered by OpenAI (Tunisian Arabic)
- 🎙️ Voice features (STT + TTS with cloned voices via Coqui & DeepSeek)
- 📚 Dynamic lesson and subject pages
- 🎮 Interactive AI-generated activities
- 🔐 Integrated child safety design (alerts shown via backend logic)

### FR 🇫🇷
Voici le **frontend Flutter** de l’application KiddoAI. Il comprend :
- 🎨 Une interface enfantine intuitive et simple à utiliser
- 🧒 Inscription avec choix de personnage favori
- 🧠 Test de QI au premier lancement
- 💬 Assistant vocal en arabe tunisien (via OpenAI)
- 🎙️ Reconnaissance et synthèse vocale (DeepSeek, XTTS, Coqui)
- 📚 Navigation entre matières et leçons dynamiques
- 🎮 Activités interactives générées par IA
- 🔐 Système de sécurité enfant intégré (liée au backend)

---

## 🧑‍💻 Tech Stack | Technologies

| Component | Technology |
|----------|-------------|
| UI Framework | Flutter |
| State Management | Provider |
| Voice | STT (Google), TTS (DeepSeek + XTTS + Coqui) |
| Backend Integration | REST (Spring Boot) |
| Storage | SharedPreferences |
| Animation | Lottie |
| Custom Widgets | Avatar themes, Audio player, Whiteboard |

---

## 📷 Screenshots (Coming Soon)

We will add UI screenshots here for the home, chat, and lesson views.  
Nous ajouterons ici des captures d'écran de l'interface très prochainement.

---

## ⚙️ Getting Started | Lancer le projet

### EN 🇬🇧
To run the app:
```bash
flutter pub get
flutter run
Ensure you have:

Flutter SDK installed

Android/iOS emulator or real device

API URLs configured in constants.dart

FR 🇫🇷
Pour lancer le projet :

bash

flutter pub get
flutter run
Assurez-vous d’avoir :

Le SDK Flutter installé

Un émulateur ou un appareil connecté

Les liens API configurés dans constants.dart

👥 Contributors | Contributeurs
👨‍💻 Achref Lajmi

👨‍💻 Firas Guesmi

👨‍💻 Ahmed Hamza

👨‍💻 Aziz Gaaya

👨‍💻 Achref Ben Moulehom

📄 License | Licence
This project is developed for academic purposes at ESPRIT Tunisia.
Ce projet est développé dans le cadre académique à ESPRIT Tunisie.

🙌 Special Thanks
To our mentors and professors for guiding our learning journey.
