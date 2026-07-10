# TaskDice Design System

Source of truth for all visual decisions in the Flutter app. Extracted from the
Claude Design handoff (`design/TaskDice.html`, "TaskDice · mobile prototype").
If code and this file ever disagree, stop and reconcile — do not silently pick one.

**Design intent (from the handoff):** *"Dark, quiet base; one green accent reserved
for progress and earned moments. Instrument Sans for UI, IBM Plex Mono for anything
time-shaped."*

---

## 1. Color palette

### Surfaces

| Token | Value | Usage |
|---|---|---|
| `background` | `#101216` | Screen background (phone canvas) |
| `surface` | `#181B21` | Cards, sheets, list tiles |
| `surfaceRaised` | `#20242C` | Chips, secondary buttons, nested elements on `surface` |
| `surfaceSunken` | `#101216` | Inputs / segment tracks *inside* a sheet or card (same hex as background) |
| `tabBarBackground` | `#101216` @ 92% | Bottom tab bar (with blur behind it) |
| `scrim` | `#000000` @ 45–60% | Behind sheets (45–55%) and dialogs (60%) |

### Text

| Token | Value | Usage |
|---|---|---|
| `textPrimary` | `#EDEFF2` | Titles, timers, task names |
| `textSecondary` | `#C7CCD4` | Card headings, secondary-button labels |
| `textTertiary` | `#8A919E` | Body copy, metadata lines |
| `textFaint` | `#5B616C` | Captions, placeholders, inactive tabs, done-task titles |

### Accents

One green, one amber, one red. Each has an "on" ink color for text placed on a
solid accent fill.

| Token | Value | On-color | Meaning |
|---|---|---|---|
| `green` | `#35D07F` | `#0B2417` | Progress, focus, earned moments, primary actions, active states |
| `amber` | `#E8B84B` | `#231A05` | Breaks, break budget, medium priority |
| `red` | `#F26D6D` | `#2B0A0A` | Carried-over debt, interruptions, overruns, high priority |
| `redSoftText` | `#F9B9B9` | — | Title text on carried-task cards |
| `grey` (prio low) | `#7A828E` | — | Low-priority dot |

### Accent tints (translucent fills)

Accents appear far more often as tints than solids:

| Token | Value | Usage |
|---|---|---|
| `greenTint` | green @ 10% | Chips, "→ Today" buttons, completed card fill (uses 6–14% in design; 10% is the standard) |
| `greenTintStrong` | green @ 14% | Hero gradient start |
| `amberTint` | amber @ 12–14% | Break CTA fill, live-break tile |
| `redTint` | red @ 7% | Carried task card fill |
| `redBadgeTint` | red @ 13% | "carried ×N" badge fill |

Gradients (both 160°, green → transparent green):
- `heroGradient`: green 14% → green 4% ("Now tracking" hero card)
- `levelGradient`: green 12% → green 3% (Progress level card)

### Borders (hairlines)

All neutral borders are white at low alpha; accent borders are the accent at
mid alpha. Always 1 px.

| Token | Value | Usage |
|---|---|---|
| `borderHairline` | white @ 7% | Default card border (design uses 6–8%) |
| `borderInput` | white @ 9% | Inputs, secondary buttons, segment containers |
| `borderStrong` | white @ 12% | Dice, capture overlay, popovers (12–14%) |
| `borderGreen` | green @ 35% | Completed card, roll result (35–45%) |
| `borderAmber` | amber @ 35% | Break CTA (50% when break is live) |
| `borderRed` | red @ 40% | Carried cards (35–40%) |

### Bars, tracks & charts

| Token | Value | Usage |
|---|---|---|
| `track` | white @ 8% | Empty portion of progress bars/rings (6–9% in design) |
| `barEstimate` | white @ 15% | "Estimate" bar in estimate-vs-actual rows |
| `chartDotMuted` | white @ 25% | Past data points on the trend line |
| heatmap ramp | green @ 5% → 100% | Focus heatmap cell intensity (continuous alpha ramp on `green`) |

### Inverse elements

| Token | Value | Usage |
|---|---|---|
| `inverseSurface` | `#EDEFF2` | Capture FAB, toast background |
| `inverseText` | `#101216` | Icon/text on inverse surfaces |

---

## 2. Typography

Two families, hard rule:

- **Instrument Sans** — all UI text.
- **IBM Plex Mono** — anything *time-shaped or countable*: timers, points, scores,
  minute counts, ratios (`33/40`), overline labels, "captured 14:38" stamps.
  Always with tabular figures for running timers.

Weights used: Sans 400 / 500 / 600 / 700 · Mono 400 / 500 / 600.

### Roles

| Role | Family | Weight | Size | Notes |
|---|---|---|---|---|
| `timerDisplay` | Mono | 600 | 64 | Focus-mode timer; ls −0.02em; tabular |
| `timerMedium` | Mono | 600 | 32 | Hero-card timer; tabular |
| `ringValueLarge` | Mono | 600 | 30 | Daily-review ring |
| `ringValue` | Mono | 600 | 24 | Home efficiency ring |
| `statValue` | Mono | 600 | 18–20 | Points, stat tiles, break-sheet timer |
| `monoValue` | Mono | 600 | 14 | Focused/break/done splits |
| `monoBody` | Mono | 500 | 13 | "focus 15:44 · break 2:40" line |
| `monoCaption` | Mono | 500 | 11–12 | Axis labels, xp counts, badges |
| `overline` | Mono | 600 | 11 | UPPERCASE, ls +0.12em (0.10–0.14 in design); section labels, "NOW TRACKING", "IN FOCUS" |
| `pageTitle` | Sans | 700 | 24 | Screen titles; ls −0.01em |
| `focusTitle` | Sans | 600 | 19 | Active task name in Focus mode; lh 1.35 |
| `cardTitle` | Sans | 700 | 17–18 | Sheet titles, roll result title, level card |
| `heroTitle` | Sans | 600 | 16.5 | Task name in "Now tracking" hero |
| `taskTitle` | Sans | 600 | 14.5 | Task-card titles |
| `itemTitle` | Sans | 500 | 14 | Inbox item text, input text |
| `body` | Sans | 400 | 13–13.5 | Body copy; lh 1.5–1.65 |
| `meta` | Sans | 400 | 12 | Task metadata ("Deep work · est 60m · High") |
| `caption` | Sans | 400 | 11.5 | Hints, footnotes |
| `micro` | Sans | 400 | 10.5 | Stat-tile sublabels |
| `buttonLarge` | Sans | 700 | 16–17 | Roll CTA, break CTA |
| `button` | Sans | 700 | 13–14 | Complete, Add, Start now |
| `buttonSecondary` | Sans | 600 | 12.5–13.5 | Pause, Re-roll, Later |
| `chip` | Sans | 500–600 | 11.5–12 | Reason chips, segment labels, tag chips |
| `tabLabel` | Sans | 600 | 12 | Bottom tab bar |

**Font delivery:** via the `google_fonts` package (fetched and cached at runtime).
Can be swapped for bundled TTFs later without touching any screen code — only
`app_tokens.dart` references the families.

---

## 3. Spacing

4-ish px rhythm with even in-between steps. Named by pixel value to avoid ambiguity:

`2 · 4 · 6 · 8 · 10 · 12 · 14 · 16 · 18 · 20 · 24`

Common applications:
- Screen padding: **20 horizontal**, 12 top, ~120 bottom (clears tab bar + FAB)
- Gap between cards in a list column: **12–16**
- Card internal padding: **14–20** (task card `14 × 16`, hero/stat cards `18`, large cards `20`)
- Chip padding: `6 × 12` (buttons-as-chips), `4 × 8` (tag badges), `6 × 13` (reason pills)
- Inline gaps: 6 (chip rows), 8 (form rows), 10 (button rows), 12 (card content), 14–18 (stat groups)

---

## 4. Corner radii

| Token | Value | Usage |
|---|---|---|
| `rBadge` | 6 | "carried ×N", why-chips |
| `rChip` | 8 | Quick-action chips, segment inner (8–9) |
| `rInput` | 10 | Small inputs, segment containers (10–12) |
| `rButton` | 12 | Buttons, text inputs, quick-add chips |
| `rCardSmall` | 14 | Inbox cards, badge tiles, secondary action buttons |
| `rCard` | 16 | Task cards, stat cards, chart cards |
| `rCardProminent` | 18 | Break CTA, roll result, review insight cards |
| `rCardHero` | 20 | Hero cards, efficiency card, roll CTA, level card |
| `rSheet` | 26 | Bottom sheet (top corners only) |
| `rDice` | 28 | The dice tile |
| `rPill` | 999 | Reason chips (fully rounded) |
| circle | 50% | Dots, FAB, dice pips, energy faces |

Sheet grab handle: 36 × 4, white @ 20%, r2.

---

## 5. Shadows / elevation

Dark UI — elevation is mostly borders + fills; shadows only for things that float:

| Token | Value | Usage |
|---|---|---|
| `shadowFloating` | `0 8 24` black @ 50% | FAB, toast |
| `shadowOverlay` | `0 12 32` black @ 40% | Dice, energy check-in popover |

(The `0 24 60 @ 50%` phone-frame shadow is presentation-only — not used in app.)

---

## 6. Motion

| Token | Spec | Usage |
|---|---|---|
| `popIn` | scale 0.85→1 + fade, 250–350 ms ease | Completed card, roll result, capture overlay, popovers |
| `sheetUp` | translateY 60→0 + fade, 300 ms `cubic(.22,1,.36,1)` | Bottom sheet |
| `toastUp` | translateY 14→0 + fade, 300 ms ease | Toast (auto-dismiss ~2.4 s) |
| `breathe` | opacity 1→0.35→1, 2 s loop | Live dots ("in focus", "on break") |
| `diceShake` | rotate ±14° + slight scale, 500 ms loop | Dice while rolling (~1.45 s, name cycles every 110 ms) |
| `ringFill` | stroke offset, 800 ms `cubic(.22,1,.36,1)` | Efficiency ring |
| `pressScale` | scale 0.97 (0.92–0.98 by size) while pressed | Every tappable card/button |
| bar fills | width, 500 ms | Budget/progress bars |

Standard curve: `Curves.easeOutQuint`-like `cubic-bezier(.22, 1, .36, 1)` → use
`Cubic(0.22, 1.0, 0.36, 1.0)` (token `emphasized`).

---

## 7. Recurring components

Names below are the canonical widget names for the Flutter build.

| Widget | Description |
|---|---|
| `EfficiencyRing` | Circular score ring: track white 8%, green arc, round caps, starts at 12 o'clock; mono score centered. Sizes: 92 (home, stroke 8), 110 (review, stroke 9) |
| `TaskCard` | r16 card: 8 px priority dot · title + meta · optional trailing `CarriedBadge` / ✓. Carried variant: red tint fill, red border, `redSoftText` title. Done variant: faint struck-through title |
| `CarriedBadge` | `carried ×N` — mono 600 10.5, red on red 13%, r6 |
| `PriorityDot` | 8 px circle: High red / Med amber / Low grey |
| `RollCta` | Solid green r20 bar, dice glyph + "Roll a task", on-green ink |
| `DiceTile` | 120×120 r28 `surface` tile, strong border, 3×3 grid of green pips (5 shown), `shadowOverlay` |
| `WhyChip` | Roll-explanation chip: mono 500 11, green on green 10%, r6 |
| `SegmentedToggle` | Pill container (`surface`/`surfaceSunken`, r10–12, 3 px inner pad); active segment = solid accent + on-ink, inactive = transparent + `textTertiary`. Green (Smart/Random), amber/red (Break/Interruption) |
| `BreakSheet` | Bottom sheet r26: grab handle, title + type toggle, live-break tile, `+3/+5/+10 min` chips, manual HH:MM range row, `ReasonChip` wrap |
| `ReasonChip` | Pill r999: selected = solid amber + on-amber; unselected = `surfaceRaised` + `textTertiary` |
| `StatTile` | Centered mono value + faint micro label, r16 hairline card |
| `HairlineBar` | 4–8 px progress bar, r2–4, `track` background, accent fill |
| `EstimateVsActualRow` | Title + `Nm / Nm` mono (green ≤ estimate+15%, red over); two stacked bars: estimate (white 15%) over actual (green/red) |
| `FocusHeatmap` | 12-col grid of 22 px r4 cells, green alpha ramp, mono axis labels |
| `TrendLine` | Green 2.5 px polyline, muted past dots, green 4 px current dot |
| `AccuracyBars` | Mini bar chart, green alpha ramp by recency |
| `AppTabBar` | Translucent blurred bar, hairline top border; labels only (600 12); active green, inactive faint |
| `CaptureFab` | 54 px inverse circle "+", bottom-right above tab bar, `shadowFloating` |
| `AppToast` | Inverse pill r12, floats above tab bar, auto-dismiss 2.4 s |
| `EnergyCheckIn` | Floating popover card (r18, strong border, `shadowOverlay`): 5 emoji 😴😕😐🙂⚡, press scales up 1.25 |
| `CaptureOverlay` | Centered-top dialog card r20: title, hint, input, solid green save button |
| `CompletedCard` | Green tint + border r18: "✓ title", mono points summary, note |
| `LevelCard` | `levelGradient` r20: level name, xp mono, 8 px green bar, streak stats row |
| `BadgeTile` | r14 tile: emoji, name, requirement; locked = 45% opacity |
| `RewardCard` | r16: name + progress mono + green bar; claimable = green tint/border + solid `Claim` button |
| `InboxCard` | r14 card: text, mono timestamp, action row (`→ Today` green tint / `Later` raised / `Delete` bare faint) |
| `GrabHandle` | 36×4 white 20% r2, centered |
| `SectionLabel` | Mono overline section header (600 11, +0.12em, uppercase); `textFaint` default, red variant for "Carried over — clear these first" |
| `AddTaskCard` | Plan composer, r16 hairline card: borderless input + `est Nm` / tag ▾ / priority ▾ chip menus + solid green Add chip |
| `ChipMenu` | Chip (`surfaceRaised`, r8, `6×10`) that opens a dropdown: `surfaceRaised` menu, r12, strong border, item text 13. *Added during build — dropdowns aren't drawn in the handoff, only implied by the ▾ chips* |
| `EditTaskSheet` | Task editor, opened by long-pressing a task on Plan. Composed from existing patterns: bottom sheet (r26 + grab handle), sunken title input, the composer's est/tag/priority chip menus + a "due today" toggle chip (green tint when on), solid green Save, bare red Delete. *Added during build — no editor is drawn in the handoff; "tap fields to edit in the full app" implies one* |

---

## 8. Logic reference (from the prototype script)

Not visual tokens, but the design encodes these rules — screens must match:

- **Task:** `title, tag, prio (Low/Med/High), est (min), status (planned/carried/done), carried (count), due (bool), actual (min)`
- **Efficiency score** = `round(40·FR + 35·CR + 25·EA)` where
  `FR = focus/(focus+break)` (1 if no time), `CR = done/total`,
  `EA = avg over done tasks of max(0, 1 − |actual−est|/est)`
- **Points on complete** = `focusMinutes + {Low: 25, Med: 50, High: 100}[prio] + 20 bonus if |actual−est|/est ≤ 0.15`
- **Smart roll weight** = `1 + {Low:1, Med:2, High:3}[prio] + 3·isCarried + 2·isDueToday` (design copy also mentions `+1 energy match` — not implemented in the prototype)
- **Roll animation:** cycle candidate names every 110 ms for ~1.45 s, then weighted pick
- **Break budget:** default 60 min/day; breaks pause "focus" accounting but the task keeps tracking
- **Timer model:** `elapsed = accum + (now − runningSince)`; `focus = elapsed − breaks`; pause stops `runningSince`
- **Carried-over rule:** unfinished tasks carry to the next day with `carried+1` and a priority bump (shown as "High ↑ (was Med)")
- **New-task defaults:** est 25 m · Med · "Inbox" tag (15 m when promoted from inbox)
- **Energy check-in:** prompt during focus (18 s in the demo — real cadence TBD); logs 1–5
- Demo-only: sessions pre-warm ~26 min — **do not** replicate in the app

---

## 9. Open questions (flagged for review)

0. **Daily Review entry point.** No launcher for the review is drawn in the
   handoff. Built as: tapping the "Efficiency today" card on Today pushes the
   Daily Review as a full route (with a "· review →" affordance on the card).
   The review is data-driven (sub-scores, points-earned, estimate-vs-actual all
   from live state), so it populates as tasks complete. Change the entry point
   if you'd prefer it on Trends or an end-of-day prompt.
0b. **Trends needs history the app doesn't store.** The efficiency line,
   heatmap, break-patterns, and accuracy chart all require days/weeks of past
   data. Built against a seeded `TrendsData.demo()` (in `models/trends.dart`) —
   representative placeholder history a real backend or on-device day-log would
   populate. Also relevant: break patterns are shown per-category (Messages /
   Snack / …), but the live app only tracks total break minutes + a single
   selected reason per session — a proper per-break log is still needed to make
   this card live.
0c. **Progress/game engine is stubbed.** Level, XP, streak, multiplier, and
   badges are seeded (`GameData.demo()` in `models/game.dart`) — there's no XP
   accrual, streak tracking, or badge-unlock engine yet. Rewards ARE live:
   Claim marks a reward claimed and Add appends one, both through `AppState`.
   A real build needs an XP/streak/badge engine driven by completions.
1. **Tab bar destinations — RESOLVED as built.** The live prototype's tab bar
   is *Today · Plan · Roll · Inbox*; static screen 01 shows
   *Today · Plan · Trends · Progress*. Built as 5 tabs —
   *Today · Plan · Roll · Trends · Progress*. Focus mode is a non-tab route
   (entered by starting a task). Daily Review is pushed from the Today
   efficiency card. **Inbox is pushed from an "Inbox N" pill in the Today
   header** (the capture FAB writes to it; this pill reads it). Revisit if you
   want Inbox promoted to a tab.
2. **Fonts at runtime vs bundled.** Starting with `google_fonts` (runtime fetch,
   cached). Swap to bundled TTFs before any offline-first release.
3. **Focus-state styling for inputs** isn't shown in the design. Theme uses a
   brighter hairline (white 20%) on focus — keeps green reserved for progress.
