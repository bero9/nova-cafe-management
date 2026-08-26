# Nova - Study Cafe Management System ☕📚

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Hive](https://img.shields.io/badge/Hive-FFCA28?style=for-the-badge&logo=databricks&logoColor=black)

*(Scroll down for the German version | Deutsche Version unten)*

---

## 🇬🇧 English

### 📌 About The Project
**Nova** is a comprehensive, offline-first point-of-sale (POS) and management system built specifically for Study Cafes. Developed with Flutter and powered by the blazing-fast Hive local database, this application allows cafe owners to seamlessly manage tables, track time-based billing, handle subscriptions, and calculate daily/monthly revenues without requiring an active internet connection. The core logic and robust models are handled efficiently within the customized `nova.dart` module.

### ✨ Key Features
*   **Time-Based Billing:** Automatically calculates table costs based on entry time, with an adjustable hourly rate and a smart 6-hour billing cap.
*   **Subscriber System:** Manage weekly and monthly subscribers who receive exemptions from time costs and only pay for extra purchases.
*   **Order Management:** Add, edit, or delete drinks and snacks for active tables in real-time.
*   **Dynamic Editing:** Fully editable sessions (modify customer names, adjust entry times, and manage orders before checkout).
*   **Financial Dashboards:** Generates detailed daily logs and monthly statistical summaries (splitting income between time-costs and purchases).
*   **Offline-First & Secure:** Uses **Hive NoSQL** to store all sessions, logs, and subscribers locally. Data is safe even if the app closes unexpectedly.
*   **Responsive UI:** An intuitive, Arabic-localized interface featuring a responsive grid layout optimized for tablets and POS screens.

### 🛠 Tech Stack
*   **Framework:** Flutter (Dart)
*   **Database:** Hive (Local NoSQL Database)
*   **Architecture:** Stateful/ValueListenableBuilder for reactive UI updates
*   **Assets:** Native Splash Screen & Custom Launcher Icons

### 🚀 How to Run
1. Clone the repository: `git clone https://github.com/YourUsername/nova.git`
2. Fetch dependencies: `flutter pub get`
3. Generate Hive adapters: `dart run build_runner build --delete-conflicting-outputs`
4. Run the app: `flutter run`

---

## 🇩🇪 Deutsch

### 📌 Über das Projekt
**Nova** ist ein umfassendes, offline-fähiges Kassensystem (POS) und Verwaltungstool, das speziell für Lerncafés (Study Cafes) entwickelt wurde. Diese mit Flutter entwickelte und von der blitzschnellen lokalen Hive-Datenbank angetriebene Anwendung ermöglicht es Café-Besitzern, Tische nahtlos zu verwalten, zeitbasierte Abrechnungen durchzuführen, Abonnements zu verwalten und tägliche/monatliche Einnahmen ohne aktive Internetverbindung zu berechnen. Die Kernlogik und die robusten Modelle werden effizient im angepassten `nova.dart`-Modul verarbeitet.

### ✨ Hauptmerkmale
*   **Zeitbasierte Abrechnung:** Berechnet automatisch die Tischkosten basierend auf der Eintrittszeit, mit einem anpassbaren Stundensatz und einer intelligenten 6-Stunden-Abrechnungsgrenze.
*   **Abonnenten-System:** Verwaltung von wöchentlichen und monatlichen Abonnenten, die von den Zeitkosten befreit sind und nur für zusätzliche Käufe zahlen.
*   **Bestellverwaltung:** Hinzufügen, Bearbeiten oder Löschen von Getränken und Snacks für aktive Tische in Echtzeit.
*   **Dynamische Bearbeitung:** Vollständig bearbeitbare Sitzungen (Kundennamen ändern, Eintrittszeiten anpassen und Bestellungen vor dem Bezahlen verwalten).
*   **Finanz-Dashboards:** Generiert detaillierte Tagesprotokolle und monatliche statistische Zusammenfassungen (Aufteilung der Einnahmen in Zeitkosten und Käufe).
*   **Offline-First & Sicher:** Verwendet **Hive NoSQL**, um alle Sitzungen, Protokolle und Abonnenten lokal zu speichern. Daten sind sicher, selbst wenn die App unerwartet geschlossen wird.
*   **Responsive UI:** Eine intuitive, auf Arabisch lokalisierte Benutzeroberfläche mit einem reaktionsschnellen Rasterlayout, optimiert für Tablets und POS-Bildschirme.

### 🛠 Verwendete Technologien
*   **Framework:** Flutter (Dart)
*   **Datenbank:** Hive (Lokale NoSQL-Datenbank)
*   **Architektur:** Stateful/ValueListenableBuilder für reaktive UI-Updates
*   **Assets:** Native Splash Screen & Benutzerdefinierte Launcher-Icons

### 🚀 Ausführung
1. Repository klonen: `git clone https://github.com/YourUsername/nova.git`
2. Abhängigkeiten abrufen: `flutter pub get`
3. Hive-Adapter generieren: `dart run build_runner build --delete-conflicting-outputs`
4. App starten: `flutter run`