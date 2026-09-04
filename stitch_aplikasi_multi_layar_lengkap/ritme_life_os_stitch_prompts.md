# Ritme — Personal Life & Learning OS — Google Stitch UI/UX Prompt Kit

Aplikasi all-in-one modular dashboard: produktivitas harian, keuangan, musik, belajar, dan Gemini AI Core sebagai lapisan kecerdasan lintas-modul. Gaya visual mengikuti referensi infografis "7 UI Design Trends 2026" — **vibrant purple gradient, glassmorphism, bold typography, floating stat cards, micro-interaction friendly**.

**Cara pakai:**
1. Buka Google Stitch, mode "Mobile App".
2. Tempel Screen 0 (Design System) di awal setiap prompt sebagai acuan gaya.
3. Generate urutan yang disarankan ada di bagian paling bawah file ini.
4. File ini panjang (23 prompt) — generate bertahap, jangan semua sekaligus, biar hasil tiap screen tetap presisi.

---

## 0. Design System / Style Reference (tempel di awal setiap prompt)

```
Design a mobile app UI called "Ritme" — an all-in-one Personal Life & Learning OS combining daily tasks, finance, music, learning notes, and a Gemini AI assistant core.

Visual style — 2026 UI trend-forward, vibrant and modern:
- Base background: soft off-white/lavender-white (#F7F5FF), with large soft purple blob/gradient shapes bleeding from edges as ambient decoration
- Primary color: vibrant rich purple (#6C4CE0 to #8B6FF0 gradient), used for primary buttons, active nav states, and hero cards
- Glassmorphism: frosted translucent white cards with soft purple-tinted blur, subtle white border highlight, floating above the background with soft drop shadow
- Bold typography: large, heavy-weight sans-serif for headlines and key numbers (like a big "$8,540.00" balance style), clean medium-weight for body/labels, occasional playful script/handwritten-style accent font for small greeting text ("Hello, Creative! 👋" style)
- Floating mini stat cards: small rounded-square cards (like "75%" progress ring, "1.2K" with heart icon, "+18.6%" trend) that appear to float slightly offset/overlapping the main content, giving depth and energy
- Icons: rounded, friendly line icons with occasional filled purple background badges
- Buttons: fully rounded/pill primary buttons in solid purple or purple gradient, secondary buttons as light purple-tinted outline
- Charts: smooth gradient-filled line/area charts (purple gradient fading to transparent), donut/ring charts with soft rounded stroke ends
- Bottom navigation: rounded floating pill bar, 5 icons, center icon often emphasized as a raised circular purple button (+ or AI icon)
- Micro-interaction cues: subtle glow/highlight on active elements, small sparkle/star accent decorations near headlines for a "smart/AI" feel
- Overall mood: energetic yet clean — smart, modern, impactful, not corporate-boring
```

---

## 1. Onboarding & AI Setup (3 screens)

```
Design a 3-screen onboarding flow for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above).

Screen 1 — Welcome:
- Large bold logo/wordmark "Ritme" with small sparkle accent icons
- Tagline: "Your Life, In Rhythm." with subtext "Tasks, money, music, and learning — orchestrated by AI"
- Soft purple gradient blob shapes in background, subtle floating mini icons (task check, note, coin, music note) drifting around the wordmark
- "Get Started" full-width pill button (purple gradient)

Screen 2 — Meet Gemini Core:
- Headline: "Meet your AI Core" with sparkle icon accent
- Illustration: central glowing purple orb/circle (representing Gemini AI) with thin connecting lines radiating out to 4 small module icons (task, wallet, music, book) arranged around it
- Short explanation text: "Ritme's AI reads across all your modules to summarize, plan, and guide your day."
- "Next" button + progress dots indicator

Screen 3 — Quick Module Setup:
- Headline: "What matters most to you?"
- 5 selectable glassmorphism toggle cards in a grid (Tasks, Music, Finance, Learning, Habits), each with icon + label, tap to select/deselect (selected state = purple filled background, glow border)
- Subtext: "You can customize this anytime in Settings"
- "Enter Ritme" primary button
```

---

## 2. Home Dashboard (Central Hub)

```
Design the Home Dashboard for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above). This is the central hub combining all modules.

Layout:
- Top bar: hamburger menu icon (left), handwritten-style greeting "Hello, Creative! 👋" with subtext "Let's make today productive" below it, notification bell icon (right) with small red dot badge
- Search bar: rounded pill input, "Search anything..." placeholder, small filter/sliders icon on the right
- Hero card: large glassmorphism purple gradient card — "Today's Briefing" label, AI-generated one-line summary text (e.g. "3 urgent tasks, $42 safe to spend today, 20 min learning goal left"), small Gemini sparkle icon badge in corner, subtle line chart or productivity trend graphic at the bottom of the card
- Floating overlapping mini stat cards near the hero card edges (offset/tilted slightly like the reference image): small "Focus: 75%" donut ring card, small "Streak: 12 days 🔥" card, small "Budget: 68% used" card
- Module quick-access row: horizontal scroll of 5 glassmorphism module icon cards (Tasks, Music, Finance, Learning, Habits) each with icon, label, and tiny live stat (e.g. "3 due today")
- "Recent Activity" section: list combining cross-module events — small colored icon per row (task check, coin, music note, book), title text, timestamp/amount, "See all" link top-right of section
- Bottom navigation: floating rounded pill bar, 5 icons — Home (active), Tasks, centered raised circular AI/Gemini button (prominent, glowing), Finance, Profile
```

---

## 3. Gemini AI Assistant — Chat/Command Screen

```
Design the Gemini AI Assistant screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above), accessed via the center nav button.

Layout:
- Top bar: close/minimize chevron-down, "Gemini Core" title with small pulsing sparkle icon, three-dot menu
- Central glowing orb animation placeholder at top when idle (soft pulsing purple gradient circle, representing the AI listening/thinking state)
- Chat-style conversation area: AI messages as left-aligned glassmorphism bubble cards (can contain rich content — e.g. an embedded mini task-list card or a mini chart, not just text), user messages as right-aligned solid purple filled bubbles
- Example AI response shown as a rich card: "Here's your day" with a compact bulleted summary (3 tasks, budget status, learning goal) inside a bordered mini-card within the chat bubble
- Suggested prompt chips row (horizontal scroll, above input): "Summarize my week", "Where did I overspend?", "Plan tomorrow", "Quiz me on Chapter 3"
- Bottom input bar: rounded pill text input "Ask Gemini anything...", microphone icon (purple filled circle button) for voice input, send arrow icon
- Small persistent hint text above input: "Gemini can see your Tasks, Finance, Music & Learning data"
```

---

## 4. Daily Task Manager — Dashboard (Eisenhower Matrix)

```
Design the Daily Task Manager dashboard for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above), using the Eisenhower priority method.

Layout:
- Top bar: back button, title "Tasks", add (+) icon
- View toggle: segmented pill control — "List View" / "Matrix View"
- Matrix View (main focus): 2x2 quadrant grid with soft glassmorphism cell backgrounds, each quadrant labeled and color-tinted:
  - "Urgent & Important" (top-left, red-purple tint) — "Do First"
  - "Important, Not Urgent" (top-right, purple tint) — "Schedule"
  - "Urgent, Not Important" (bottom-left, amber-purple tint) — "Delegate"
  - "Not Urgent, Not Important" (bottom-right, muted gray-purple tint) — "Eliminate"
  Each quadrant contains 2-3 small compact task chips (title + tiny deadline tag)
- Project label filter row (horizontal scroll pill chips): "All", "Work", "Personal", "Study", each with a small colored dot matching project color-coding
- Floating action button (bottom right, circular purple gradient): "+" to add new task
- Bottom navigation with Tasks tab active
```

---

## 5. Add/Edit Task Screen

```
Design an "Add Task" form screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above).

Layout:
- Top bar: close/X, title "New Task", checkmark save button
- Input: "Task Title" large text input
- Eisenhower Quadrant Selector: 2x2 mini grid selector (visually mirroring the matrix), tap a quadrant to assign — selected quadrant highlighted with purple glow
- Row: "Due Date" (calendar icon) + "Due Time" (clock icon) pickers
- "Project Label" selector: horizontal scroll of colored pill tags (Work, Personal, Study, + Add New)
- Toggle: "Set Reminder"
- Small AI suggestion chip below the form (glassmorphism, sparkle icon): "Gemini suggests: Important, Not Urgent — based on similar past tasks" — tappable to auto-fill
- Bottom sticky "Save Task" button (full-width purple gradient pill)
```

---

## 6. Music Hub — Library & Mood Tagging

```
Design the Music Hub screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above), integrated conceptually with Spotify/Apple Music.

Layout:
- Top bar: back button, title "Music Hub", connected-service icon badge (small Spotify/Apple Music logo indicator, "Connected" label)
- "Mood Tags" horizontal scroll row: pill chips with emoji/icon — "Focus 🎯", "Chill 🌙", "Energize ⚡", "Deep Work 📚", "Relax 🍃" — tap to filter library by mood
- "Your Playlists" section: horizontal scroll of square album-art cards with gradient purple overlay, playlist name + mood tag badge overlaid at bottom
- "Recently Tagged" list: rows with small album art thumbnail, song title, artist, small mood tag pill on the right, three-dot menu
- Mini persistent player bar above bottom nav: album art thumbnail, song/artist marquee text, play/pause, skip icons, thin progress line at top edge of bar
- Bottom navigation with Music tab active
```

---

## 7. Finance Tracker — Dashboard

```
Design the Finance Tracker dashboard for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above).

Layout:
- Top bar: back button, title "Finance", calendar/month selector icon
- Large hero card: "Total Balance" label, big bold number "$8,540.00", small percentage change badge "+12.5% from last month" (green), smooth purple gradient area chart underneath showing balance trend over the month
- Two compact action buttons below hero card: "Add Income" and "Add Expense" (pill buttons, one filled purple, one outline)
- Budget category cards (list or 2-column grid): each showing category icon, category name (Food, Transport, Hobby, Subscriptions), thin progress bar showing "% of monthly limit used" (color shifts from purple to amber to red as it approaches limit), remaining amount text
- "Recent Activity" list: rows with small colored category icon badge, merchant/note name, subscription tag if recurring, amount (red for expense, green for income), date
- Donut chart card: "Spending Distribution" ring chart with category color segments, legend list with dots + percentages below
- Bottom navigation with Finance tab active
```

---

## 8. Finance — Add Transaction Screen

```
Design an "Add Transaction" form screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above).

Layout:
- Top bar: close/X, title "New Transaction", save checkmark
- Income/Expense segmented toggle at top (pill style)
- Large centered nominal input: big number display style, currency prefix
- Category selector: horizontal scroll of icon badge chips (Food, Transport, Bills, Hobby, Shopping, + Add New)
- Input: "Note" text field
- Input: "Date" picker row
- Small AI-assist banner card (glassmorphism, sparkle icon): "Snap a receipt instead? Gemini can fill this in for you" with a small "Scan Receipt" camera-icon button inline
- Bottom sticky "Save Transaction" button
```

---

## 9. AI Receipt Scanner Screen

```
Design an AI Receipt Scanner screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above), a camera-based Gemini feature.

Layout:
- Full-screen camera viewfinder background (dark overlay), rounded rectangle scan-guide frame in center with animated corner brackets (purple glowing corners) showing where to align the receipt
- Top bar: close X icon, flash toggle icon, gallery/upload icon (to pick existing screenshot instead of live camera)
- Bottom capture button: large circular white/purple ring shutter button, centered
- Small instruction text above capture button: "Align receipt within frame" with small sparkle icon
- Second screen state (processing/result): after capture, show a glassmorphism result card sliding up from bottom — "Gemini found:" header, extracted fields displayed as editable rows (Store: "Warung Kopi Ranin", Total: "$35,000", Date: "Today", Category: auto-suggested pill "Food & Drink" with edit pencil icon), "Confirm & Save" full-width button at the bottom, "Edit Details" text link
```

---

## 10. Learning Hub — Notes Library

```
Design the Learning Hub screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above), a Markdown-based notes/knowledge base.

Layout:
- Top bar: back button, title "Learning Hub", add (+) icon
- Search bar with filter icon
- "Continue Learning" horizontal scroll card row: each card shows subject/course cover color-block, title, small progress bar (% complete), last-edited timestamp
- Folder/subject grid (2 columns): each folder card with icon, subject name (e.g. "Data Structures", "UI/UX Design", "Book Summaries"), note count badge
- Recent notes list below: rows with small markdown/doc icon, note title, short preview snippet of content (muted text), tags (small pill chips), last edited date
- Floating action button (bottom right): "+" to create new note
- Bottom navigation with Learning tab active
```

---

## 11. Learning Hub — Markdown Note Editor

```
Design a Markdown Note Editor screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above).

Layout:
- Top bar: back/save-draft chevron, note title as editable large text field inline in the top bar area, three-dot menu (share, delete, export)
- Formatting toolbar (horizontal scroll icon row, sticky above keyboard): bold, italic, heading, bullet list, numbered list, code block, image insert, link insert
- Main editor body: clean writing area, markdown rendered live style (headings appear bold/large as typed, code blocks shown in a dark glassmorphism inset box with monospace font, inline links shown underlined in purple)
- Small floating toolbar/chip near selected text (contextual, shown as example): "Ask Gemini" sparkle icon option appearing when text is selected, for quick AI actions (summarize/explain selection)
- Bottom bar: small tag chips row (add topic tags), word count indicator, small cloud-sync status icon (checkmark = synced)
```

---

## 12. AI Quiz & Flashcard Generator

```
Design an AI-Generated Quiz screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above), generated by Gemini from a learning note.

Layout:
- Top bar: close X, title "Quiz: Chapter 3 — Data Structures", progress indicator "Question 3/10" as a thin purple progress bar
- Question card: glassmorphism card with question text (medium-bold), 4 multiple-choice answer options as selectable pill/rounded-rect buttons stacked vertically, selected option highlighted with purple border glow
- Bottom: "Next Question" button (disabled/muted until an answer is selected, then becomes solid purple)
- Small "Generated by Gemini from your notes" badge/label near the top with sparkle icon, subtle and small (credibility note, not prominent)
- Alternate screen state — Flashcard Mode: single centered glassmorphism card, front side showing a term/question (large centered text), small "Tap to flip" hint text below, subtle flip-card visual affordance (card edge shadow suggesting depth); back side (shown as a second state) reveals answer with a spaced-repetition rating row at the bottom — "Again", "Hard", "Good", "Easy" as 4 colored pill buttons
```

---

## 13. Focus Mode (Pomodoro + Music Player)

```
Design a Focus Mode screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above), combining a Pomodoro timer with an integrated music player, minimalist single-screen layout.

Layout:
- Minimal top bar: small close/exit icon only (top-left, subtle), small "Do Not Disturb Active" badge (top-right, muted)
- Large centered circular timer ring: thick rounded-stroke progress ring showing countdown, big bold time text in center ("18:32"), small label below ring "Focus Session · 4 of 4"
- Session type indicator: small segmented pill showing "Focus" / "Short Break" / "Long Break", current one highlighted
- Below timer: compact now-playing music card (glassmorphism), small album art, song/artist name, mini play/pause + skip controls — visually secondary/smaller than the timer to keep focus on the task
- Bottom: large circular pause/play button for the timer (primary action, purple gradient, prominent), small "End Session" text link below it (muted, requires confirmation)
- Ambient background: subtle slow-moving soft purple gradient blobs, very minimal/calm compared to other screens — reinforcing the "focus" mood
```

---

## 14. Mood & Lifestyle Correlation Screen

```
Design a Mood & Lifestyle Correlation screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above), showing AI-analyzed patterns between mood, music, productivity, and spending.

Layout:
- Top bar: back button, title "Mood Insights", date range selector ("This Month")
- Quick mood check-in card at top: row of 5 emoji-style mood icons (very sad to very happy) for daily logging, small streak indicator "Logged 18/20 days"
- Correlation chart card: multi-line overlay chart (2-3 thin colored lines representing mood score, productivity score, spending level) plotted over the past 30 days, smooth curves, small legend below
- AI Insight card (glassmorphism, sparkle icon prominent): highlighted text insight, e.g. "You tend to spend 23% more on days you listen to high-energy playlists after 9 PM" — styled as a distinct "AI finding" card with a subtle glowing border
- Secondary insight cards (smaller, stacked list): additional short AI-generated correlation observations, each with a small relevant icon (music note, wallet, checkmark)
- Bottom navigation with Home tab active (this is an insights sub-screen, likely accessed from Home or Profile)
```

---

## 15. Daily & Weekly Executive Briefing

```
Design a Daily Executive Briefing screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above), an AI-generated morning summary.

Layout:
- Top: large handwritten-style greeting "Good morning, Creative ☀️" with today's date subtext
- Hero briefing card (large, prominent glassmorphism with purple gradient): "Today's Briefing" label with sparkle icon, 3-4 line AI-written summary paragraph covering most urgent tasks, safe-to-spend amount, and today's learning target — written in warm conversational tone
- Below the briefing text: 3 compact stat chips inline — "🔥 3 urgent tasks", "💰 $42 safe today", "📚 20 min goal"
- "Your Day at a Glance" timeline section: vertical timeline with time markers and small event cards (task deadlines, calendar-like blocks) color-coded by module
- Bottom CTA: "Start My Day" full-width button (purple gradient)
- Alternate state — Weekly Recap (toggle or separate screen, same visual style): headline "Your Week in Review", larger summary card with weekly stats grid (Tasks completed, Money saved, Hours learned, Mood average), small celebratory sparkle/confetti accent illustration, shareable "Export Summary" button
```

---

## 16. Smart Budget Alert (Notification/Modal)

```
Design a Smart Budget Alert modal/notification screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above), a predictive Gemini AI warning.

Layout:
- Modal card (centered overlay on dimmed background): warning-toned icon badge at top (amber-purple gradient circle with exclamation/alert icon, softened not alarming)
- Headline: "Heads up — you're spending faster than usual"
- AI explanation text: "At this pace, you'll exceed your 'Dining Out' budget by $85 before month end." with a small mini bar chart showing projected vs. budget line
- Category context row: small icon + "Dining Out" category name + current progress bar (amber, near-full)
- Two action buttons: "Adjust Budget" (primary, purple gradient) and "Dismiss" (text button, muted)
- Small footer text: "Powered by Gemini predictive insights" with sparkle icon
```

---

## 17. Habit Tracker & Streaks

```
Design a Habit Tracker screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above).

Layout:
- Top bar: back button, title "Habits", add (+) icon
- Streak summary hero card: large flame icon with bold number "12 Day Streak 🔥", small subtext "Your longest streak: 28 days"
- Habit list, each as a card row: habit icon (book, dumbbell, wallet, water drop, etc.), habit name ("Read 15 min", "Log daily expenses", "Workout"), weekly mini-grid of 7 small squares/dots showing completion history (filled purple = done, outline = missed, today highlighted), checkmark button on the right to mark today complete
- Tapping a habit shows expanded detail (design as a second state): larger calendar heatmap-style grid (like a contribution graph) showing full month/year streak history in purple intensity shades, stats row (Current streak, Best streak, Completion rate %)
- Floating action button: "+" to add new habit
- Bottom navigation with Habits accessible (could be under Home or a dedicated tab)
```

---

## 18. Milestone Mapper (Long-Term Goals)

```
Design a Milestone Mapper screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above), connecting long-term goals to savings and daily tasks.

Layout:
- Top bar: back button, title "Milestones", add (+) icon
- Active milestone cards (vertical list), each a larger glassmorphism card showing:
  - Goal icon/image (laptop, certificate, travel icon, etc.), goal name ("New MacBook Pro", "AWS Certification")
  - Progress ring or horizontal progress bar: "$1,850 / $2,500 saved" with percentage
  - Target date: "By March 2027"
  - Small linked-items row: "3 linked tasks" badge + "Monthly contribution: $150" badge
  - "View Plan" chevron link
- Milestone detail expanded state (second screen): savings progress chart over time (line chart trending up), linked task checklist section (small checkboxes, tasks pulled from Task Manager), "Adjust Monthly Contribution" slider control, "Edit Milestone" button
- Empty state: illustration of a target/flag icon, "Set your first big goal", CTA "Create Milestone"
```

---

## 19. Offline Sync Status Screen/Indicator

```
Design an Offline Sync status screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above).

Layout (as a settings sub-screen):
- Top bar: back button, title "Sync & Offline Access"
- Status hero card: large icon (cloud with checkmark = synced, or cloud with sync-arrow animation = syncing, or cloud with slash = offline), status text "All data synced" or "Offline — 3 changes pending", timestamp "Last synced: 2 min ago"
- Encryption badge row: small lock icon + "End-to-end encrypted" label, small info tooltip icon
- List of pending sync items (shown when offline changes exist): rows with small icon per module (task/finance/note), short description "Added: Grocery expense $12", small pending/clock icon
- Toggle setting: "Offline Mode" with description "Ritme works fully offline. Changes sync automatically when you're back online."
- Small illustration at bottom for empty/all-synced state: cloud + checkmark graphic, reassuring tone
- Also design a small persistent top banner variant (compact strip, not full screen) that could appear on any screen when offline: "You're offline — changes will sync later" with small icon, dismissible
```

---

## 20. Settings / Profile Screen

```
Design the Settings/Profile screen for "Ritme" mobile app (vibrant purple glassmorphism theme, see design system above).

Layout:
- Top: circular avatar placeholder, user name, small edit pencil icon
- Grouped settings sections (glassmorphism card groups):
  Section "AI & Personalization":
  - "Gemini AI Core" row with toggle + "Manage permissions" sub-link
  - "Briefing Preferences" row (time of day, tone) with chevron
  Section "Modules":
  - Toggle switches for each module visibility on Home: Tasks, Music, Finance, Learning, Habits, Milestones
  Section "Connections":
  - "Spotify / Apple Music" row with connected status badge + chevron
  - "Bank/Finance Import" row with chevron
  Section "Data & Privacy":
  - "Offline & Sync" row with chevron (links to screen 19)
  - "Export My Data" row
  - "Privacy Policy" row
  Section "Appearance":
  - "Theme" — Light / Dark / System segmented control
  - "Accent Color" — small swatch picker circles
- App version footer text
```

---

## 21. Quick Reference — Prompt Modifiers

- **Dark mode variant:** `"Generate a dark mode variant: deep near-black background with purple undertone (#15111F), keep the same glassmorphism cards but with dark frosted glass (translucent dark purple-gray), purple gradient accents remain vibrant for contrast — same layout structure."`
- **Tablet/landscape:** `"Adapt this layout for tablet landscape orientation with a two-column split (list/nav on left, detail panel on right), keep floating card style."`
- **Component sheet:** `"Also generate a component sheet showing: glassmorphism stat card, module quick-access card, progress ring, donut chart, habit streak grid, and floating bottom nav bar as standalone reusable components."`
- **Phone mockup for presentation:** `"Render this screen inside a realistic phone frame mockup with soft ambient purple gradient background and floating decorative shapes, suitable for a pitch deck or app store preview image."`
- **Widget/home-screen variant:** `"Design a small home-screen widget version of this card (2x2 grid size) showing only the most critical stat, matching the same glassmorphism purple style."`

---

## 22. Saran Urutan Prompting di Stitch

Karena ada 20 screen, generate bertahap dalam beberapa sesi:

**Sesi 1 — Fondasi & Hub:**
1. Screen 0 (Design System)
2. Onboarding (3 screens)
3. Home Dashboard
4. Gemini AI Assistant Chat

**Sesi 2 — Modul Inti:**
5. Daily Task Manager (Matrix) + Add Task
6. Finance Tracker Dashboard + Add Transaction
7. Music Hub

**Sesi 3 — Fitur AI Unggulan:**
8. AI Receipt Scanner
9. Learning Hub + Markdown Editor
10. AI Quiz & Flashcards
11. Daily/Weekly Briefing

**Sesi 4 — Fitur Pendukung:**
12. Focus Mode (Pomodoro)
13. Mood Correlation
14. Smart Budget Alert
15. Habit Tracker
16. Milestone Mapper
17. Offline Sync
18. Settings/Profile

## 23. Catatan Strategis

Untuk pitch atau presentasi produk, tiga screen paling kuat untuk ditunjukkan duluan (paling "wow factor" dan paling mencerminkan diferensiasi Ritme dibanding app produktivitas biasa):
1. **Home Dashboard** — menunjukkan integrasi semua modul dalam satu pandangan
2. **Gemini AI Assistant / Voice-to-Action flow** — menunjukkan kecerdasan lintas-modul yang jadi USP utama
3. **AI Receipt Scanner** — fitur paling konkret dan mudah dipahami sebagai demo "wow" dalam 10 detik

Gunakan ketiga screen ini di awal deck/portofolio, baru diikuti modul-modul lain sebagai pendalaman.
