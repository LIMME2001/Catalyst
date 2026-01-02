# Catalyst

**Catalyst** is a simple productivity tracker built with Flutter to help me keep track of my everyday habits and goals. Goal tracking is visualized with a heatmap and streaks are displayed. 

---

## Features

- **Goal Tracking**
  - Add numeric goals (e.g., pages read, minutes studied) or completion-based goals (e.g., finish a book).
  - Record daily values and completions.
  - Track streaks to stay motivated.

- **Heatmap Visualization**
  - Year-long calendar heatmap for each goal.
  - Heat intensity based on your progress.
  - Highlight today and completed items for easy overview.

- **Tasks**
  - Add tasks and mark them as completed.
  - Undo completed tasks if needed.
  - Separate view for active and completed tasks.

- **Customizable Goals**
  - Assign colors to goals automatically (cycles through a palette).
  - Add custom completion labels.

- **Persistent Storage**
  - All goals, tasks, and daily data are saved locally in JSON files.
  - Fully offline: no account required.

---

## Screenshots

<img src="https://github.com/user-attachments/assets/1fcda00f-3054-429c-9eb8-d6509872d2be" width="300" />
<img src="https://github.com/user-attachments/assets/025c500b-fb57-48df-9f3d-eb7b77f1f87e" width="300" />
<img src="https://github.com/user-attachments/assets/a690dd8e-0862-4746-be3b-baaf134af1e5" width="300" />

---

## Getting Started

### Requirements

- Flutter 3.0+
- Dart SDK
- Android or iOS device/emulator

### Running the App

Clone the repository:

```
git clone https://github.com/yourusername/Catalyst.git
cd Catalyst
```

Install dependencies:

```
flutter pub get
```

Run on your device:

```
flutter run
```

To build a release APK for Android:

```
flutter build apk --release
```

---

## File Structure

- `lib/main.dart` – Main app entry point and UI
- `lib/widgets/` – Optional custom widgets (if added later)
- `assets/` – App icons and other assets
- JSON files stored in local app directory:
  - `goals.json` – List of goals
  - `goalData.json` – Daily goal progress
  - `tasks.json` – Task data

---

## Customizing the App

- **Colors**: Modify `_goalColors` in `GoalsScreen` to change goal colors.
- **Icons**: Change the app icon in `android/app/src/main/res/mipmap-*` folders.
- **Theme**: Modify `ThemeData.dark()` in `CatalystApp` for custom colors.

---

## Deleting Goals or Tasks

- **Goals**: Use the “Delete” button next to each goal in the Goals screen.
- **Tasks**: Use the trash icon in the task list to delete a task permanently.
- **Backup Tips**: You can access the JSON files in the app’s local storage for manual backups or edits.

---
<!--
## Contributing

Contributions are welcome!

- Report bugs via GitHub Issues.
- Submit pull requests with feature improvements or bug fixes.
- Please follow Flutter’s [style guide](https://flutter.dev/docs/development/tools/formatting).

---
!-->
## License

MIT License – see `LICENSE` file for details.
