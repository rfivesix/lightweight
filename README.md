<!-- FÜGE HIER DEIN LOGO EIN, z.B. <p align="center"><img src=".github/assets/logo.png" width="200"></p> -->

<h1 align="center">Light Weight</h1>

<p align="center">
  <strong>Eine moderne, datenschutzfreundliche Fitness- und Ernährungs-App. <br>Offline-First, ohne Cloud-Zwang, gebaut mit Flutter.</strong>
</p>

<p align="center">
  <img alt="GitHub License" src="https://img.shields.io/github/license/rfivesix/lightweight?style=for-the-badge">
  <img alt="GitHub Stars" src="https://img.shields.io/github/stars/rfivesix/lightweight?style=for-the-badge&logo=github">
</p>

---

## ✨ Kernphilosophie

Light Weight wurde nach vier klaren Prinzipien entwickelt, die es von vielen anderen Fitness-Apps unterscheiden:

*   🔒 **Datenhoheit & Offline-First:** Deine persönlichen Gesundheitsdaten gehören dir. Alle deine Einträge (Ernährung, Workouts, Maße) werden **ausschließlich lokal auf deinem Gerät** gespeichert. Es gibt keine Registrierung, keine Cloud und kein Tracking.
*   🎨 **Modernes Material You Design:** Die Benutzeroberfläche passt sich dynamisch an dein System-Theme an und nutzt das `Material You`-Design von Android für eine nahtlose und ästhetische Integration.
*   💸 **Keine Abos, keine Werbung:** Light Weight ist als Werkzeug für den Nutzer konzipiert, nicht als Daten- oder Geld-sammelnde Plattform. Der Kern der App wird immer kostenlos und Open Source bleiben.
*   🚀 **Leistungsstark & Intuitiv:** Unter der einfachen Oberfläche verbirgt sich eine mächtige App mit Features, die normalerweise nur in teuren Premium-Apps zu finden sind – von einem riesigen Übungskatalog bis hin zu detaillierten Analyse-Werkzeugen.

---

## 🚀 Features

Vita ist in drei Kernmodule unterteilt, die nahtlos zusammenarbeiten:

### 🥗 Ernährung
*   **Umfassendes Tracking:** Erfasse Kalorien und Makronährstoffe (Protein, Kohlenhydrate, Fett) sowie Mikronährstoffe (Zucker, Ballaststoffe, Salz).
*   **Riesige Lebensmittel-Datenbank:** Durchsuche hunderttausende Produkte aus der deutschen **Open Food Facts**-Datenbank.
*   **Schnelle Eingabe:** Barcode-Scanner (zukünftig), Favoriten-Listen, "Zuletzt verwendet"-Listen und die Möglichkeit, eigene Lebensmittel zu erstellen.
*   **Detaillierte Analyse:** Ein eigener Analyse-Screen mit dynamischer Tages- und Mehrtagesansicht, Filter-Chips und einer ausklappbaren Nährwert-Zusammenfassung.

### 💪 Workout
*   **Gigantischer Übungskatalog:** Über 380+ Übungen mit zweisprachigen Beschreibungen und Bildern, basierend auf der **wger**-Datenbank. Inklusive Filterung nach Muskelgruppen/Kategorien.
*   **Flexibler Trainingsplaner (`EditRoutineScreen`):**
    *   Erstelle und bearbeite eine unbegrenzte Anzahl an Trainingsplänen.
    *   Füge Übungen aus dem Katalog oder eigene hinzu.
    *   Plane jeden Satz individuell mit Typ (Normal, Warmup etc.), Ziel-Gewicht und Ziel-Wiederholungen.
    *   Definiere individuelle Pausenzeiten für jede Übung.
    *   Sortiere Übungen intuitiv per **Drag-and-Drop**.
*   **Interaktives Live-Tracking (`LiveWorkoutScreen`):**
    *   Protokolliere dein Training in Echtzeit.
    *   Anzeige der Leistung aus dem letzten Training für progressive Steigerung.
    *   Automatischer Pausen-Timer.
    *   Passe dein Workout spontan an: Füge Sätze oder ganze Übungen hinzu, entferne sie oder ordne sie neu an.
*   **Vollständiger Workout-Verlauf:**
    *   Sieh dir jedes abgeschlossene Workout im Detail an.
    *   Bearbeite nachträglich jeden Wert, das Datum oder die Notizen.

### 📏 Messwerte
*   **Ganzheitliches Tracking:** Erfasse über 15 verschiedene Körpermaße, von Gewicht und Körperfett bis hin zu Umfängen.
*   **Visuelle Fortschrittsanalyse:** Ein interaktiver Graph zeigt dir deine Fortschritte über die Zeit. Navigiere per Pfeiltasten oder Filter-Chips durch deine Daten.
*   **Dashboard-Integration:** Der Gewichtsverlauf ist prominent auf dem Dashboard platziert, um dich täglich zu motivieren.

---

## 🛠️ Technische Architektur

Für Entwickler, die zum Projekt beitragen möchten, hier ein kurzer Überblick:

*   **State Management:** Die App nutzt bewusst den Flutter-eigenen Ansatz mit `StatefulWidget` und `setState`, um den Code einfach, verständlich und frei von externen Abhängigkeiten zu halten. Ein simpler Singleton-Service (`UiStateService`) wird für globalen, nicht-persistenten UI-Zustand verwendet.

*   **Datenbank-System (`sqflite`):** Light Weight nutzt ein einzigartiges **Drei-Datenbanken-System**, um eine saubere Trennung der Daten zu gewährleisten:
    1.  **`vita_prep_de.db` (Lebensmittel):** Eine große, schreibgeschützte Datenbank, die aus Open Food Facts-Daten generiert und aus den App-Assets kopiert wird.
    2.  **`vita_training.db` (Workouts):** Enthält den statischen Übungskatalog (aus wger) sowie die vom Nutzer erstellten Pläne und Protokolle. Wird ebenfalls aus den Assets kopiert.
    3.  **`vita_user.db` (Nutzerdaten):** Die einzige dynamische Datenbank, die auf dem Gerät des Nutzers leer erstellt wird. Sie enthält alle persönlichen Einträge wie Mahlzeiten, Wasser und Messwerte.

*   **Daten-Pipelines:** Die statischen Datenbanken werden offline mit **Python-Skripts** aufbereitet, die die Rohdaten von Open Food Facts und der wger-API herunterladen, filtern, bereinigen und in ein optimiertes SQLite-Format umwandeln.

---

## 🤝 Mitwirken (Contributing)

Feedback, Bug-Reports und Pull Requests sind herzlich willkommen!

*   **Bugs melden:** Wenn du einen Fehler findest, erstelle bitte ein [Issue](https://github.com/rfivesix/lightweight/issues) und beschreibe das Problem so detailliert wie möglich.
*   **Features vorschlagen:** Hast du eine Idee für ein neues Feature? Erstelle ebenfalls ein [Issue](https://github.com/rfivesix/lightweight/issues) und beschreibe deine Vision.

---

## 📄 Lizenz & Danksagungen

Der Quellcode dieses Projekts steht unter der **[MIT-Lizenz](LICENSE)**.

Dieses Projekt wäre nicht möglich ohne die fantastische Arbeit der folgenden Open-Data-Communitys:

*   **[Open Food Facts](https://de.openfoodfacts.org/)**: Lebensmittel-Datenbank, lizenziert unter [ODbL](https://opendatacommons.org/licenses/odbl/1-0/).
*   **[wger Workout Manager](https://wger.de/)**: Übungs-Datenbank und API, lizenziert unter [CC-BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).

---

## 📬 Kontakt

Fragen oder Feedback? Erstelle ein Issue oder kontaktiere mich unter `richard@schotte.me`.