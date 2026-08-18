# Project Brief: 一字日记 (OneWord Diary)

## 1. Project Overview
**OneWord Diary** is a minimalist, high-fidelity HarmonyOS native mobile application designed for private, offline-first journaling. The app follows a "Modern Eastern White Space" and "Gallery Editorial" aesthetic, focusing on a single character per day to provide a sense of ritual and tranquility in personal reflection.

## 2. Core Philosophy
- **Minimalism**: Removing all non-essential UI elements to focus on the content.
- **Quietness**: A soft, warm-white and ink-gray palette that creates a peaceful atmosphere.
- **Ritual**: The act of "dropping a word" (落字) is treated as a meaningful daily interaction.
- **Privacy**: Offline-first architecture ensuring personal thoughts remain private.

## 3. Visual Identity (Design System)
- **Palette**:
  - Surface: `#fdf8f7` (Warm White / Paper Texture)
  - Primary Text: `#282622` (Ink Gray)
  - Accent: `#C85A48` (Light Cinnabar)
- **Typography**: Noto Serif (Serif font for a literary, classic feel).
- **Style**: Modern Eastern Minimalism, ample white space, refined stroke weights, and clear hierarchy.

## 4. Key Features & Screens
### A. Daily Input (今日输入)
- **Core Action**: A central area to input the "One Word" for the day.
- **Remark Feature**: A secondary "Remark" button (circular, white) positioned to the right of the central "Drop Word" button.
- **Layout**: The word is displayed large and centered, with the remark in a smaller, lighter font centered directly below it.

### B. Daily Detail (单日详情)
- **Focus**: A gallery-like view of a specific entry.
- **Layout**: The core character sits at the absolute visual center. Date and remarks are positioned below it with elegant spacing.
- **Interactions**: Subtle back navigation and a hidden share trigger.

### C. Text Scroll (文字长卷)
- **Concept**: A vertical timeline of entries resembling a traditional Chinese scroll or a modern poetry book.
- **Layout**:
  - A centered vertical timeline axis.
  - **Interlaced Rhythm**: Entries (word + remark) alternate left and right of the timeline.
  - **Empty States**: Dates without entries are centered on the axis.
- **Details**: Includes day of the week next to the date for better context.

### D. Sharing & Preview (分享预览)
- **Consistency**: The sharing preview matches the "Text Scroll" layout exactly (interlaced rhythm).
- **Options**: Supports "Single Day" or "Recent 7 Days" sharing.
- **Aesthetic**: Designed to look like a complete work of art when shared.

### E. Settings & Management (设置)
- **Lists**: Clean, high-breathability list items for style selection, data backup, and clearing data.
- **Feedback**: Refined dialogs for confirmation and status updates (e.g., "Import Successful").

## 5. Technical Requirements
- **Platform**: HarmonyOS (ArkUI native implementation).
- **Performance**: High emphasis on smooth transitions and "Drop Word" animations.
- **Data**: Local storage priority (Offline-first).

## 6. Design Principles for Future Iterations
- **Fidelity**: Always maintain the warm-white paper texture and serif typography.
- **Constraint**: Do not add complex navigation bars or social feeds.
- **Rhythm**: Maintain the balance between "Solid" (text) and "Void" (white space).
