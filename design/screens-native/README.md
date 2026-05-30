# Native SwiftUI Direction

These are flat, production-direction mockups for the Campus Lock MVP.

Design constraints:

- Native SwiftUI surfaces first: grouped lists, cards, sliders, sheets, shields.
- No 3D device renders, floating hardware, neon depth, or marketing compositions.
- Minimal words: short labels, system-style controls, icon-first rows.
- Mostly monochrome with one system-blue accent and system-green success states.
- Dark mode only where the real product benefits from it: active lock and shield.

Screens:

1. ![Setup checklist](01-setup-checklist.png)
2. ![App selection](02-app-selection.png)
3. ![Zone builder](03-zone-builder.png)
4. ![Focus active](04-focus-active.png)
5. ![Outside zone](05-outside-zone.png)
6. ![Attendance](06-attendance.png)
7. ![Insights export](07-insights-export.png)
8. ![App shield](08-app-shield.png)

Regenerate:

```sh
python3 design/generate_native_mockups.py
```
