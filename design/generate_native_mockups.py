#!/usr/bin/env python3
from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUT_DIR = Path(__file__).resolve().parent / "screens-native"
W, H = 1179, 2556

FONT_REG = "/System/Library/Fonts/SFNS.ttf"
FONT_ROUNDED = "/System/Library/Fonts/SFNSRounded.ttf"
FONT_MONO = "/System/Library/Fonts/SFNSMono.ttf"


def font(size: int, rounded: bool = False, mono: bool = False) -> ImageFont.FreeTypeFont:
    path = FONT_MONO if mono else (FONT_ROUNDED if rounded else FONT_REG)
    return ImageFont.truetype(path, size)


@dataclass(frozen=True)
class Theme:
    bg: str
    card: str
    card2: str
    text: str
    muted: str
    faint: str
    line: str
    accent: str
    accent_soft: str
    good: str
    warn: str


LIGHT = Theme(
    bg="#F5F5F7",
    card="#FFFFFF",
    card2="#F0F1F3",
    text="#101114",
    muted="#6E7077",
    faint="#A7AAB1",
    line="#E5E5EA",
    accent="#0A84FF",
    accent_soft="#E7F1FF",
    good="#34C759",
    warn="#FF9500",
)

DARK = Theme(
    bg="#050506",
    card="#111113",
    card2="#1C1C1E",
    text="#F5F5F7",
    muted="#A1A1A6",
    faint="#5D5F66",
    line="#2C2C2E",
    accent="#0A84FF",
    accent_soft="#10243D",
    good="#30D158",
    warn="#FFD60A",
)


def new_screen(theme: Theme = LIGHT) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", (W, H), theme.bg)
    draw = ImageDraw.Draw(img)
    return img, draw


def text(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    value: str,
    size: int,
    color: str,
    *,
    rounded: bool = False,
    mono: bool = False,
    anchor: str | None = None,
) -> None:
    draw.text(xy, value, font=font(size, rounded=rounded, mono=mono), fill=color, anchor=anchor)


def text_size(value: str, size: int, *, rounded: bool = False, mono: bool = False) -> tuple[int, int]:
    bbox = ImageDraw.Draw(Image.new("RGB", (1, 1))).textbbox(
        (0, 0), value, font=font(size, rounded=rounded, mono=mono)
    )
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def status_bar(draw: ImageDraw.ImageDraw, theme: Theme, dark: bool = False) -> None:
    c = theme.text if not dark else "#FFFFFF"
    text(draw, (86, 66), "9:41", 38, c, rounded=True)
    x = 965
    for i, hgt in enumerate([16, 22, 29, 36]):
        draw.rounded_rectangle((x + i * 18, 86 - hgt, x + 10 + i * 18, 86), radius=4, fill=c)
    draw.arc((1052, 49, 1110, 98), 205, 335, fill=c, width=8)
    draw.rounded_rectangle((1124, 58, 1160, 86), radius=8, outline=c, width=4)
    draw.rounded_rectangle((1129, 63, 1147, 81), radius=5, fill=c)
    draw.rectangle((1162, 66, 1167, 78), fill=c)


def home_indicator(draw: ImageDraw.ImageDraw, theme: Theme) -> None:
    color = "#000000" if theme.bg != "#050506" else "#FFFFFF"
    draw.rounded_rectangle((421, 2491, 758, 2505), radius=8, fill=color)


def nav(draw: ImageDraw.ImageDraw, theme: Theme, title: str, subtitle: str | None = None) -> None:
    text(draw, (72, 156), title, 64, theme.text, rounded=True)
    if subtitle:
        text(draw, (75, 229), subtitle, 30, theme.muted)


def card(
    draw: ImageDraw.ImageDraw,
    xyxy: tuple[int, int, int, int],
    theme: Theme,
    *,
    fill: str | None = None,
    radius: int = 42,
    outline: bool = False,
) -> None:
    draw.rounded_rectangle(
        xyxy,
        radius=radius,
        fill=fill or theme.card,
        outline=theme.line if outline else None,
        width=2 if outline else 1,
    )


def pill(
    draw: ImageDraw.ImageDraw,
    xyxy: tuple[int, int, int, int],
    label: str,
    theme: Theme,
    *,
    fill: str | None = None,
    color: str | None = None,
    size: int = 28,
) -> None:
    draw.rounded_rectangle(xyxy, radius=(xyxy[3] - xyxy[1]) // 2, fill=fill or theme.card2)
    text(draw, ((xyxy[0] + xyxy[2]) // 2, (xyxy[1] + xyxy[3]) // 2 - 3), label, size, color or theme.text, anchor="mm")


def button(draw: ImageDraw.ImageDraw, xyxy: tuple[int, int, int, int], label: str, theme: Theme, *, primary=True) -> None:
    fill = theme.text if primary and theme.bg != "#050506" else theme.accent if primary else theme.card
    color = theme.bg if primary and theme.bg != "#050506" else "#FFFFFF" if primary else theme.text
    draw.rounded_rectangle(xyxy, radius=34, fill=fill, outline=None if primary else theme.line, width=2)
    text(draw, ((xyxy[0] + xyxy[2]) // 2, (xyxy[1] + xyxy[3]) // 2 - 4), label, 36, color, rounded=True, anchor="mm")


def draw_check(draw: ImageDraw.ImageDraw, cx: int, cy: int, color: str, scale: float = 1.0) -> None:
    w = int(11 * scale)
    pts = [
        (cx - int(20 * scale), cy),
        (cx - int(6 * scale), cy + int(14 * scale)),
        (cx + int(24 * scale), cy - int(20 * scale)),
    ]
    draw.line(pts, fill=color, width=w, joint="curve")


def draw_lock(draw: ImageDraw.ImageDraw, cx: int, cy: int, color: str, scale: float = 1.0) -> None:
    shackle = (
        cx - int(34 * scale),
        cy - int(50 * scale),
        cx + int(34 * scale),
        cy + int(22 * scale),
    )
    draw.arc(shackle, 180, 360, fill=color, width=int(10 * scale))
    draw.rounded_rectangle(
        (cx - int(52 * scale), cy - int(8 * scale), cx + int(52 * scale), cy + int(70 * scale)),
        radius=int(18 * scale),
        outline=color,
        width=int(10 * scale),
    )
    draw.ellipse((cx - int(8 * scale), cy + int(24 * scale), cx + int(8 * scale), cy + int(40 * scale)), fill=color)


def draw_pin(draw: ImageDraw.ImageDraw, cx: int, cy: int, color: str, scale: float = 1.0) -> None:
    r = int(38 * scale)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=color, width=int(9 * scale))
    draw.ellipse((cx - int(11 * scale), cy - int(11 * scale), cx + int(11 * scale), cy + int(11 * scale)), fill=color)
    draw.line((cx, cy + r - int(2 * scale), cx, cy + int(79 * scale)), fill=color, width=int(9 * scale))


def draw_apps_icon(draw: ImageDraw.ImageDraw, cx: int, cy: int, color: str, scale: float = 1.0) -> None:
    step = int(34 * scale)
    size = int(18 * scale)
    for row in range(3):
        for col in range(3):
            x = cx + (col - 1) * step
            y = cy + (row - 1) * step
            draw.rounded_rectangle((x - size // 2, y - size // 2, x + size // 2, y + size // 2), radius=int(5 * scale), fill=color)


def draw_id_icon(draw: ImageDraw.ImageDraw, cx: int, cy: int, color: str, scale: float = 1.0) -> None:
    draw.rounded_rectangle(
        (cx - int(60 * scale), cy - int(40 * scale), cx + int(60 * scale), cy + int(40 * scale)),
        radius=int(16 * scale),
        outline=color,
        width=int(8 * scale),
    )
    draw.ellipse((cx - int(42 * scale), cy - int(10 * scale), cx - int(18 * scale), cy + int(14 * scale)), outline=color, width=int(6 * scale))
    draw.line((cx + int(4 * scale), cy - int(16 * scale), cx + int(42 * scale), cy - int(16 * scale)), fill=color, width=int(6 * scale))
    draw.line((cx + int(4 * scale), cy + int(12 * scale), cx + int(48 * scale), cy + int(12 * scale)), fill=color, width=int(6 * scale))


def draw_clock(draw: ImageDraw.ImageDraw, cx: int, cy: int, color: str, scale: float = 1.0) -> None:
    r = int(48 * scale)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=color, width=int(8 * scale))
    draw.line((cx, cy, cx, cy - int(28 * scale)), fill=color, width=int(7 * scale))
    draw.line((cx, cy, cx + int(24 * scale), cy + int(18 * scale)), fill=color, width=int(7 * scale))


def icon_circle(draw: ImageDraw.ImageDraw, cx: int, cy: int, theme: Theme, kind: str, active=True) -> None:
    fill = theme.accent_soft if active else theme.card2
    color = theme.accent if active else theme.muted
    draw.ellipse((cx - 54, cy - 54, cx + 54, cy + 54), fill=fill)
    if kind == "check":
        draw_check(draw, cx, cy, color, 1.0)
    elif kind == "apps":
        draw_apps_icon(draw, cx, cy, color, 1.0)
    elif kind == "pin":
        draw_pin(draw, cx, cy - 16, color, 0.75)
    elif kind == "lock":
        draw_lock(draw, cx, cy - 12, color, 0.62)
    elif kind == "id":
        draw_id_icon(draw, cx, cy, color, 0.7)
    else:
        draw_clock(draw, cx, cy, color, 0.7)


def setup_screen() -> Image.Image:
    img, draw = new_screen(LIGHT)
    status_bar(draw, LIGHT)
    nav(draw, LIGHT, "Setup", "Required before first lock")
    y = 340
    rows = [
        ("Screen Time", "Family Controls", "check"),
        ("Location", "When In Use", "pin"),
        ("Notifications", "Time alerts", "clock"),
        ("Attendance", "Local log", "id"),
    ]
    for title, detail, kind in rows:
        card(draw, (54, y, 1125, y + 188), LIGHT)
        icon_circle(draw, 150, y + 94, LIGHT, kind)
        text(draw, (238, y + 62), title, 40, LIGHT.text, rounded=True)
        text(draw, (238, y + 114), detail, 30, LIGHT.muted)
        draw_check(draw, 1040, y + 92, LIGHT.good, 0.9)
        y += 218
    card(draw, (54, 1326, 1125, 1618), LIGHT, fill="#FAFAFB")
    text(draw, (114, 1394), "MVP rule", 30, LIGHT.muted)
    text(draw, (114, 1458), "Select apps → draw zone → tap in", 48, LIGHT.text, rounded=True)
    text(draw, (114, 1532), "All enforcement uses Apple Screen Time APIs.", 30, LIGHT.muted)
    button(draw, (74, 2268, 1105, 2372), "Continue", LIGHT)
    home_indicator(draw, LIGHT)
    return img


def app_selection_screen() -> Image.Image:
    img, draw = new_screen(LIGHT)
    status_bar(draw, LIGHT)
    nav(draw, LIGHT, "Apps", "Choose what pauses in class")
    draw.rounded_rectangle((54, 302, 1125, 390), radius=28, fill=LIGHT.card2)
    text(draw, (112, 355), "Search apps or categories", 34, LIGHT.faint)
    categories = [
        ("Social", "6 apps", True),
        ("Video", "4 apps", True),
        ("Games", "8 apps", True),
        ("Messages", "Allowed", False),
        ("Maps", "Allowed", False),
    ]
    y = 450
    for label, count, enabled in categories:
        card(draw, (54, y, 1125, y + 154), LIGHT)
        draw_apps_icon(draw, 140, y + 77, LIGHT.accent if enabled else LIGHT.muted, 0.75)
        text(draw, (224, y + 60), label, 38, LIGHT.text, rounded=True)
        text(draw, (224, y + 108), count, 28, LIGHT.muted)
        if enabled:
            draw.ellipse((1010, y + 45, 1074, y + 109), fill=LIGHT.accent)
            draw_check(draw, 1042, y + 76, "#FFFFFF", 0.55)
        else:
            draw.ellipse((1010, y + 45, 1074, y + 109), outline=LIGHT.line, width=4)
        y += 178
    card(draw, (54, 1510, 1125, 1724), LIGHT, fill="#FAFAFB")
    text(draw, (114, 1580), "12", 76, LIGHT.text, rounded=True)
    text(draw, (226, 1604), "apps paused during focus", 34, LIGHT.muted)
    text(draw, (114, 1672), "Phone, Messages, Maps stay available.", 30, LIGHT.muted)
    button(draw, (74, 2268, 1105, 2372), "Save Apps", LIGHT)
    home_indicator(draw, LIGHT)
    return img


def zone_screen() -> Image.Image:
    img, draw = new_screen(LIGHT)
    status_bar(draw, LIGHT)
    nav(draw, LIGHT, "Zone", "Draw a campus radius")
    card(draw, (54, 302, 1125, 1528), LIGHT, fill="#ECEFF2")
    for x in range(120, 1080, 160):
        draw.line((x, 340, x + 230, 1500), fill="#DDE0E5", width=3)
    for y in range(420, 1480, 180):
        draw.line((80, y, 1100, y - 260), fill="#DDE0E5", width=3)
    cx, cy, rr = 590, 910, 330
    draw.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill="#CFE5FF", outline=LIGHT.accent, width=8)
    draw.ellipse((cx - 18, cy - 18, cx + 18, cy + 18), fill=LIGHT.accent)
    pill(draw, (440, 1268, 740, 1340), "150 m", LIGHT, fill="#FFFFFF", color=LIGHT.text, size=34)
    card(draw, (54, 1582, 1125, 1818), LIGHT)
    text(draw, (114, 1658), "Radius", 34, LIGHT.muted)
    text(draw, (114, 1728), "150 meters", 54, LIGHT.text, rounded=True)
    draw.rounded_rectangle((114, 1790, 1065, 1806), radius=8, fill=LIGHT.line)
    draw.rounded_rectangle((114, 1790, 634, 1806), radius=8, fill=LIGHT.accent)
    draw.ellipse((604, 1764, 660, 1820), fill="#FFFFFF", outline=LIGHT.line, width=2)
    button(draw, (74, 2268, 1105, 2372), "Enable Zone", LIGHT)
    home_indicator(draw, LIGHT)
    return img


def focus_active_screen() -> Image.Image:
    img, draw = new_screen(DARK)
    status_bar(draw, DARK, dark=True)
    text(draw, (72, 170), "Campus Lock", 42, DARK.muted, rounded=True)
    pill(draw, (850, 142, 1105, 210), "Room 204", DARK, fill="#171719", color=DARK.text, size=28)
    cx, cy = 590, 760
    for r, color, width in [(365, "#171719", 28), (292, "#242426", 18), (218, "#3A3A3C", 10)]:
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=color, width=width)
    draw.ellipse((cx - 132, cy - 132, cx + 132, cy + 132), fill="#FFFFFF")
    draw_lock(draw, cx, cy - 44, "#050506", 0.82)
    text(draw, (590, 1090), "Locked", 80, DARK.text, rounded=True, anchor="mm")
    text(draw, (590, 1160), "Apps paused · attendance marked", 34, DARK.muted, anchor="mm")
    card(draw, (74, 1358, 1105, 1626), DARK, fill=DARK.card2)
    text(draw, (134, 1436), "Focus", 30, DARK.muted)
    text(draw, (134, 1514), "18:42", 82, DARK.text, rounded=True, mono=True)
    text(draw, (786, 1436), "Passing", 30, DARK.muted)
    text(draw, (786, 1514), "4:15", 82, DARK.text, rounded=True, mono=True)
    card(draw, (74, 1682, 1105, 1848), DARK, fill=DARK.card)
    text(draw, (134, 1748), "Allowed", 30, DARK.muted)
    text(draw, (134, 1808), "Phone  ·  Messages  ·  Maps", 36, DARK.text, rounded=True)
    button(draw, (74, 2268, 1105, 2372), "Unlock", DARK, primary=False)
    home_indicator(draw, DARK)
    return img


def outside_zone_screen() -> Image.Image:
    img, draw = new_screen(LIGHT)
    status_bar(draw, LIGHT)
    nav(draw, LIGHT, "Free", "You left the zone")
    cx, cy = 590, 630
    draw.ellipse((cx - 230, cy - 230, cx + 230, cy + 230), outline=LIGHT.good, width=14)
    draw_check(draw, cx, cy, LIGHT.good, 2.0)
    text(draw, (590, 938), "Apps available", 62, LIGHT.text, rounded=True, anchor="mm")
    text(draw, (590, 1004), "Zone ended automatically", 32, LIGHT.muted, anchor="mm")
    card(draw, (54, 1194, 1125, 1430), LIGHT)
    text(draw, (114, 1272), "Last session", 32, LIGHT.muted)
    text(draw, (114, 1350), "Period 3  ·  47 min", 50, LIGHT.text, rounded=True)
    card(draw, (54, 1484, 1125, 1718), LIGHT)
    text(draw, (114, 1562), "Attendance", 32, LIGHT.muted)
    text(draw, (114, 1640), "Checked out at 10:24", 50, LIGHT.text, rounded=True)
    button(draw, (74, 2268, 1105, 2372), "Start Again", LIGHT)
    home_indicator(draw, LIGHT)
    return img


def attendance_screen() -> Image.Image:
    img, draw = new_screen(LIGHT)
    status_bar(draw, LIGHT)
    nav(draw, LIGHT, "Attendance", "Tap in when focus starts")
    card(draw, (54, 304, 1125, 682), LIGHT)
    draw_id_icon(draw, 180, 442, LIGHT.accent, 1.05)
    text(draw, (300, 404), "Biology", 58, LIGHT.text, rounded=True)
    text(draw, (300, 470), "Period 3 · Room 204", 32, LIGHT.muted)
    pill(draw, (300, 526, 486, 594), "Present", LIGHT, fill="#EAF8EE", color=LIGHT.good, size=30)
    button(draw, (74, 750, 556, 852), "Enter", LIGHT)
    button(draw, (624, 750, 1105, 852), "Exit", LIGHT, primary=False)
    rows = [
        ("1", "English", "8:10", "Done"),
        ("2", "History", "9:05", "Done"),
        ("3", "Biology", "10:00", "Live"),
        ("4", "Algebra", "11:05", "Next"),
        ("5", "Studio", "1:10", "Next"),
    ]
    y = 952
    for num, cls, time_value, state in rows:
        card(draw, (54, y, 1125, y + 138), LIGHT)
        draw.ellipse((108, y + 41, 166, y + 99), fill=LIGHT.card2)
        text(draw, (137, y + 70), num, 28, LIGHT.text, rounded=True, anchor="mm")
        text(draw, (214, y + 56), cls, 36, LIGHT.text, rounded=True)
        text(draw, (214, y + 102), time_value, 28, LIGHT.muted)
        color = LIGHT.good if state == "Done" else LIGHT.accent if state == "Live" else LIGHT.faint
        pill(draw, (916, y + 40, 1062, y + 98), state, LIGHT, fill=LIGHT.card2, color=color, size=26)
        y += 160
    home_indicator(draw, LIGHT)
    return img


def insights_screen() -> Image.Image:
    img, draw = new_screen(LIGHT)
    status_bar(draw, LIGHT)
    nav(draw, LIGHT, "Insights", "For the founder demo")
    metrics = [("94%", "Present"), ("3m", "Avg pass"), ("4.8h", "Locked")]
    x = 54
    for value, label in metrics:
        card(draw, (x, 310, x + 333, 552), LIGHT)
        text(draw, (x + 54, 408), value, 66, LIGHT.text, rounded=True)
        text(draw, (x + 54, 470), label, 30, LIGHT.muted)
        x += 369
    card(draw, (54, 628, 1125, 1114), LIGHT)
    text(draw, (114, 704), "Week", 34, LIGHT.muted)
    bars = [0.55, 0.8, 0.68, 0.92, 0.74, 0.36, 0.42]
    base_y = 1030
    for i, b in enumerate(bars):
        bx = 148 + i * 130
        hgt = int(300 * b)
        draw.rounded_rectangle((bx, base_y - hgt, bx + 62, base_y), radius=28, fill=LIGHT.accent if i < 5 else LIGHT.line)
    card(draw, (54, 1190, 1125, 1514), LIGHT)
    text(draw, (114, 1270), "Export", 34, LIGHT.muted)
    text(draw, (114, 1344), "Attendance · focus · zones", 50, LIGHT.text, rounded=True)
    text(draw, (114, 1416), "CSV stays local until shared.", 30, LIGHT.muted)
    button(draw, (74, 2268, 1105, 2372), "Share Report", LIGHT)
    home_indicator(draw, LIGHT)
    return img


def shield_screen() -> Image.Image:
    img, draw = new_screen(DARK)
    status_bar(draw, DARK, dark=True)
    cx, cy = 590, 640
    draw.ellipse((cx - 188, cy - 188, cx + 188, cy + 188), fill="#111113", outline="#2C2C2E", width=4)
    draw_lock(draw, cx, cy - 54, "#FFFFFF", 1.05)
    text(draw, (590, 1004), "Focus active", 72, DARK.text, rounded=True, anchor="mm")
    text(draw, (590, 1074), "This app is paused", 36, DARK.muted, anchor="mm")
    card(draw, (132, 1246, 1047, 1494), DARK, fill="#111113")
    text(draw, (590, 1332), "Leave the class zone", 40, DARK.text, rounded=True, anchor="mm")
    text(draw, (590, 1400), "or unlock in Campus Lock.", 34, DARK.muted, anchor="mm")
    button(draw, (132, 2268, 1047, 2372), "Open Campus Lock", DARK)
    home_indicator(draw, DARK)
    return img


SCREENS = [
    ("01-setup-checklist.png", setup_screen),
    ("02-app-selection.png", app_selection_screen),
    ("03-zone-builder.png", zone_screen),
    ("04-focus-active.png", focus_active_screen),
    ("05-outside-zone.png", outside_zone_screen),
    ("06-attendance.png", attendance_screen),
    ("07-insights-export.png", insights_screen),
    ("08-app-shield.png", shield_screen),
]


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, factory in SCREENS:
        img = factory()
        img.save(OUT_DIR / name, optimize=True)
        print(OUT_DIR / name)


if __name__ == "__main__":
    main()
