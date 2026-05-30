#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUTPUT_DIR = Path(__file__).resolve().parent / "screens-final"
SCREEN_WIDTH = 1290
SCREEN_HEIGHT = 2796
SAFE_LEFT = 72
SAFE_RIGHT = SCREEN_WIDTH - 72

FONT_REGULAR = "/System/Library/Fonts/SFNS.ttf"
FONT_ROUNDED = "/System/Library/Fonts/SFNSRounded.ttf"
FONT_MONO = "/System/Library/Fonts/SFNSMono.ttf"


@dataclass(frozen=True)
class Palette:
    background: str
    surface: str
    surface_alt: str
    elevated: str
    text: str
    secondary: str
    tertiary: str
    separator: str
    accent: str
    accent_soft: str
    success: str
    warning: str
    destructive: str


LIGHT = Palette(
    background="#F5F5F7",
    surface="#FFFFFF",
    surface_alt="#EEEEF2",
    elevated="#FAFAFC",
    text="#111114",
    secondary="#6D7078",
    tertiary="#A7AAB2",
    separator="#E3E4EA",
    accent="#007AFF",
    accent_soft="#E7F2FF",
    success="#34C759",
    warning="#FF9F0A",
    destructive="#FF3B30",
)

DARK = Palette(
    background="#030304",
    surface="#111113",
    surface_alt="#1C1C1E",
    elevated="#171719",
    text="#F5F5F7",
    secondary="#A1A1A6",
    tertiary="#666970",
    separator="#2C2C2E",
    accent="#0A84FF",
    accent_soft="#10243D",
    success="#30D158",
    warning="#FFD60A",
    destructive="#FF453A",
)


def load_font(size: int, *, rounded: bool = False, mono: bool = False) -> ImageFont.FreeTypeFont:
    font_path = FONT_MONO if mono else FONT_ROUNDED if rounded else FONT_REGULAR
    return ImageFont.truetype(font_path, size)


def new_canvas(palette: Palette) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGB", (SCREEN_WIDTH, SCREEN_HEIGHT), palette.background)
    return image, ImageDraw.Draw(image)


def draw_text(
    draw: ImageDraw.ImageDraw,
    position: tuple[int, int],
    value: str,
    size: int,
    color: str,
    *,
    rounded: bool = False,
    mono: bool = False,
    anchor: str | None = None,
) -> None:
    draw.text(position, value, font=load_font(size, rounded=rounded, mono=mono), fill=color, anchor=anchor)


def measure_text(value: str, size: int, *, rounded: bool = False, mono: bool = False) -> tuple[int, int]:
    text_draw = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    bounds = text_draw.textbbox((0, 0), value, font=load_font(size, rounded=rounded, mono=mono))
    return bounds[2] - bounds[0], bounds[3] - bounds[1]


def rounded_rect(
    draw: ImageDraw.ImageDraw,
    bounds: tuple[int, int, int, int],
    radius: int,
    fill: str,
    *,
    outline: str | None = None,
    width: int = 1,
) -> None:
    draw.rounded_rectangle(bounds, radius=radius, fill=fill, outline=outline, width=width)


def card(
    draw: ImageDraw.ImageDraw,
    bounds: tuple[int, int, int, int],
    palette: Palette,
    *,
    fill: str | None = None,
    radius: int = 40,
    outline: bool = False,
) -> None:
    rounded_rect(
        draw,
        bounds,
        radius,
        fill or palette.surface,
        outline=palette.separator if outline else None,
        width=2 if outline else 1,
    )


def status_bar(draw: ImageDraw.ImageDraw, palette: Palette) -> None:
    draw_text(draw, (92, 66), "9:41", 38, palette.text, rounded=True)
    signal_left = SCREEN_WIDTH - 244
    for bar_index, bar_height in enumerate([16, 22, 29, 36]):
        bar_left = signal_left + bar_index * 19
        draw.rounded_rectangle(
            (bar_left, 88 - bar_height, bar_left + 10, 88),
            radius=4,
            fill=palette.text,
        )
    draw.arc((SCREEN_WIDTH - 149, 50, SCREEN_WIDTH - 94, 100), 205, 335, fill=palette.text, width=7)
    draw.rounded_rectangle((SCREEN_WIDTH - 70, 60, SCREEN_WIDTH - 28, 88), radius=9, outline=palette.text, width=4)
    draw.rounded_rectangle((SCREEN_WIDTH - 64, 66, SCREEN_WIDTH - 45, 82), radius=5, fill=palette.text)
    draw.rectangle((SCREEN_WIDTH - 25, 68, SCREEN_WIDTH - 20, 80), fill=palette.text)


def home_indicator(draw: ImageDraw.ImageDraw, palette: Palette) -> None:
    rounded_rect(draw, (470, SCREEN_HEIGHT - 66, 820, SCREEN_HEIGHT - 51), 8, palette.text)


def nav_title(draw: ImageDraw.ImageDraw, palette: Palette, title: str, subtitle: str | None = None) -> None:
    draw_text(draw, (SAFE_LEFT, 166), title, 70, palette.text, rounded=True)
    if subtitle:
        draw_text(draw, (SAFE_LEFT + 2, 246), subtitle, 31, palette.secondary)


def pill(
    draw: ImageDraw.ImageDraw,
    bounds: tuple[int, int, int, int],
    label: str,
    palette: Palette,
    *,
    fill: str | None = None,
    color: str | None = None,
    size: int = 29,
) -> None:
    radius = (bounds[3] - bounds[1]) // 2
    rounded_rect(draw, bounds, radius, fill or palette.surface_alt)
    draw_text(
        draw,
        ((bounds[0] + bounds[2]) // 2, (bounds[1] + bounds[3]) // 2 - 2),
        label,
        size,
        color or palette.text,
        rounded=True,
        anchor="mm",
    )


def button(
    draw: ImageDraw.ImageDraw,
    bounds: tuple[int, int, int, int],
    label: str,
    palette: Palette,
    *,
    primary: bool = True,
) -> None:
    if primary:
        fill = palette.text if palette.background == LIGHT.background else palette.accent
        text_color = palette.background if palette.background == LIGHT.background else "#FFFFFF"
        outline = None
    else:
        fill = palette.surface_alt if palette.background == LIGHT.background else palette.surface
        text_color = palette.text
        outline = palette.separator
    rounded_rect(draw, bounds, 34, fill, outline=outline, width=2)
    draw_text(
        draw,
        ((bounds[0] + bounds[2]) // 2, (bounds[1] + bounds[3]) // 2 - 3),
        label,
        36,
        text_color,
        rounded=True,
        anchor="mm",
    )


def draw_check(draw: ImageDraw.ImageDraw, center: tuple[int, int], color: str, scale: float = 1.0) -> None:
    center_x, center_y = center
    points = [
        (center_x - int(23 * scale), center_y),
        (center_x - int(7 * scale), center_y + int(16 * scale)),
        (center_x + int(28 * scale), center_y - int(24 * scale)),
    ]
    draw.line(points, fill=color, width=max(4, int(10 * scale)), joint="curve")


def draw_lock(draw: ImageDraw.ImageDraw, center: tuple[int, int], color: str, scale: float = 1.0) -> None:
    center_x, center_y = center
    line_width = max(4, int(9 * scale))
    draw.arc(
        (
            center_x - int(34 * scale),
            center_y - int(56 * scale),
            center_x + int(34 * scale),
            center_y + int(20 * scale),
        ),
        180,
        360,
        fill=color,
        width=line_width,
    )
    draw.rounded_rectangle(
        (
            center_x - int(55 * scale),
            center_y - int(9 * scale),
            center_x + int(55 * scale),
            center_y + int(72 * scale),
        ),
        radius=int(18 * scale),
        outline=color,
        width=line_width,
    )
    draw.ellipse(
        (
            center_x - int(8 * scale),
            center_y + int(26 * scale),
            center_x + int(8 * scale),
            center_y + int(42 * scale),
        ),
        fill=color,
    )


def draw_apps(draw: ImageDraw.ImageDraw, center: tuple[int, int], color: str, scale: float = 1.0) -> None:
    center_x, center_y = center
    spacing = int(34 * scale)
    square = int(17 * scale)
    for row_index in range(3):
        for column_index in range(3):
            square_x = center_x + (column_index - 1) * spacing
            square_y = center_y + (row_index - 1) * spacing
            rounded_rect(
                draw,
                (
                    square_x - square // 2,
                    square_y - square // 2,
                    square_x + square // 2,
                    square_y + square // 2,
                ),
                max(3, int(5 * scale)),
                color,
            )


def draw_pin(draw: ImageDraw.ImageDraw, center: tuple[int, int], color: str, scale: float = 1.0) -> None:
    center_x, center_y = center
    radius = int(39 * scale)
    draw.ellipse((center_x - radius, center_y - radius, center_x + radius, center_y + radius), outline=color, width=int(8 * scale))
    draw.ellipse(
        (
            center_x - int(11 * scale),
            center_y - int(11 * scale),
            center_x + int(11 * scale),
            center_y + int(11 * scale),
        ),
        fill=color,
    )
    draw.line((center_x, center_y + radius - 2, center_x, center_y + int(82 * scale)), fill=color, width=int(8 * scale))


def draw_id(draw: ImageDraw.ImageDraw, center: tuple[int, int], color: str, scale: float = 1.0) -> None:
    center_x, center_y = center
    draw.rounded_rectangle(
        (
            center_x - int(60 * scale),
            center_y - int(42 * scale),
            center_x + int(60 * scale),
            center_y + int(42 * scale),
        ),
        radius=int(17 * scale),
        outline=color,
        width=int(7 * scale),
    )
    draw.ellipse(
        (
            center_x - int(42 * scale),
            center_y - int(12 * scale),
            center_x - int(18 * scale),
            center_y + int(12 * scale),
        ),
        outline=color,
        width=max(3, int(5 * scale)),
    )
    draw.line((center_x + int(3 * scale), center_y - int(16 * scale), center_x + int(44 * scale), center_y - int(16 * scale)), fill=color, width=max(3, int(5 * scale)))
    draw.line((center_x + int(3 * scale), center_y + int(14 * scale), center_x + int(50 * scale), center_y + int(14 * scale)), fill=color, width=max(3, int(5 * scale)))


def draw_clock(draw: ImageDraw.ImageDraw, center: tuple[int, int], color: str, scale: float = 1.0) -> None:
    center_x, center_y = center
    radius = int(48 * scale)
    draw.ellipse((center_x - radius, center_y - radius, center_x + radius, center_y + radius), outline=color, width=int(7 * scale))
    draw.line((center_x, center_y, center_x, center_y - int(28 * scale)), fill=color, width=int(7 * scale))
    draw.line((center_x, center_y, center_x + int(24 * scale), center_y + int(18 * scale)), fill=color, width=int(7 * scale))


def icon_badge(draw: ImageDraw.ImageDraw, center: tuple[int, int], palette: Palette, icon: str, *, active: bool = True) -> None:
    center_x, center_y = center
    fill = palette.accent_soft if active else palette.surface_alt
    color = palette.accent if active else palette.secondary
    draw.ellipse((center_x - 54, center_y - 54, center_x + 54, center_y + 54), fill=fill)
    if icon == "check":
        draw_check(draw, center, color, 0.9)
    elif icon == "pin":
        draw_pin(draw, (center_x, center_y - 18), color, 0.72)
    elif icon == "apps":
        draw_apps(draw, center, color, 0.95)
    elif icon == "id":
        draw_id(draw, center, color, 0.68)
    elif icon == "lock":
        draw_lock(draw, (center_x, center_y - 12), color, 0.62)
    else:
        draw_clock(draw, center, color, 0.74)


def draw_bottom_tabs(draw: ImageDraw.ImageDraw, palette: Palette, active: str) -> None:
    bar_top = SCREEN_HEIGHT - 244
    card(draw, (44, bar_top, SCREEN_WIDTH - 44, SCREEN_HEIGHT - 104), palette, fill=palette.surface, radius=48)
    tabs = [("Lock", "lock"), ("Apps", "apps"), ("Zone", "pin"), ("Stats", "clock")]
    for tab_index, (label, icon) in enumerate(tabs):
        center_x = 168 + tab_index * 318
        center_y = bar_top + 62
        is_active = label == active
        icon_color = palette.accent if is_active else palette.tertiary
        if icon == "lock":
            draw_lock(draw, (center_x, center_y - 8), icon_color, 0.35)
        elif icon == "apps":
            draw_apps(draw, (center_x, center_y), icon_color, 0.48)
        elif icon == "pin":
            draw_pin(draw, (center_x, center_y - 8), icon_color, 0.35)
        else:
            draw_clock(draw, (center_x, center_y), icon_color, 0.42)
        draw_text(draw, (center_x, bar_top + 113), label, 24, icon_color, rounded=True, anchor="mm")


def metric_chip(draw: ImageDraw.ImageDraw, bounds: tuple[int, int, int, int], value: str, label: str, palette: Palette) -> None:
    card(draw, bounds, palette)
    draw_text(draw, (bounds[0] + 38, bounds[1] + 77), value, 56, palette.text, rounded=True)
    draw_text(draw, (bounds[0] + 40, bounds[1] + 132), label, 25, palette.secondary)


def setup_screen() -> Image.Image:
    image, draw = new_canvas(LIGHT)
    status_bar(draw, LIGHT)
    nav_title(draw, LIGHT, "Campus", "Set up once")
    draw_text(draw, (SAFE_LEFT, 350), "Everything needed before the first lock.", 34, LIGHT.secondary)

    rows = [
        ("Screen Time", "App blocking", "lock"),
        ("Apps", "Choose what pauses", "apps"),
        ("Location", "Zone automation", "pin"),
        ("Attendance", "Local check-ins", "id"),
    ]
    top = 494
    for row_index, (title, subtitle, icon) in enumerate(rows):
        row_top = top + row_index * 190
        card(draw, (SAFE_LEFT, row_top, SAFE_RIGHT, row_top + 154), LIGHT)
        icon_badge(draw, (154, row_top + 77), LIGHT, icon)
        draw_text(draw, (238, row_top + 62), title, 38, LIGHT.text, rounded=True)
        draw_text(draw, (238, row_top + 110), subtitle, 28, LIGHT.secondary)
        draw_check(draw, (SAFE_RIGHT - 54, row_top + 76), LIGHT.success, 0.8)

    card(draw, (SAFE_LEFT, 1374, SAFE_RIGHT, 1658), LIGHT, fill=LIGHT.elevated)
    draw_text(draw, (126, 1458), "MVP flow", 29, LIGHT.secondary)
    draw_text(draw, (126, 1530), "Tap in. Lock apps. Walk out.", 53, LIGHT.text, rounded=True)
    draw_text(draw, (126, 1598), "No admin/student split for the demo.", 29, LIGHT.secondary)

    button(draw, (SAFE_LEFT, 2356, SAFE_RIGHT, 2472), "Continue", LIGHT)
    home_indicator(draw, LIGHT)
    return image


def apps_screen() -> Image.Image:
    image, draw = new_canvas(LIGHT)
    status_bar(draw, LIGHT)
    nav_title(draw, LIGHT, "Apps", "Paused during class")
    rounded_rect(draw, (SAFE_LEFT, 326, SAFE_RIGHT, 420), 30, LIGHT.surface_alt)
    draw_text(draw, (126, 383), "Search apps or categories", 34, LIGHT.tertiary)

    rows = [
        ("Social", "6 apps", True),
        ("Video", "4 apps", True),
        ("Games", "8 apps", True),
        ("Messages", "Allowed", False),
        ("Maps", "Allowed", False),
        ("Phone", "Allowed", False),
    ]
    top = 492
    for row_index, (title, subtitle, enabled) in enumerate(rows):
        row_top = top + row_index * 166
        card(draw, (SAFE_LEFT, row_top, SAFE_RIGHT, row_top + 132), LIGHT)
        draw_apps(draw, (144, row_top + 66), LIGHT.accent if enabled else LIGHT.secondary, 0.72)
        draw_text(draw, (222, row_top + 55), title, 35, LIGHT.text, rounded=True)
        draw_text(draw, (222, row_top + 98), subtitle, 25, LIGHT.secondary)
        switch_left = SAFE_RIGHT - 142
        switch_fill = LIGHT.accent if enabled else LIGHT.surface_alt
        rounded_rect(draw, (switch_left, row_top + 38, switch_left + 92, row_top + 88), 25, switch_fill)
        knob_left = switch_left + 48 if enabled else switch_left + 4
        draw.ellipse((knob_left, row_top + 42, knob_left + 42, row_top + 84), fill="#FFFFFF")

    card(draw, (SAFE_LEFT, 1580, SAFE_RIGHT, 1786), LIGHT, fill=LIGHT.elevated)
    draw_text(draw, (126, 1660), "18", 78, LIGHT.text, rounded=True)
    draw_text(draw, (238, 1684), "apps pause in focus", 34, LIGHT.secondary)
    draw_text(draw, (126, 1740), "Core safety apps stay available.", 29, LIGHT.secondary)

    button(draw, (SAFE_LEFT, 2356, SAFE_RIGHT, 2472), "Save Apps", LIGHT)
    draw_bottom_tabs(draw, LIGHT, "Apps")
    home_indicator(draw, LIGHT)
    return image


def zone_screen() -> Image.Image:
    image, draw = new_canvas(LIGHT)
    status_bar(draw, LIGHT)
    nav_title(draw, LIGHT, "Zone", "Current location radius")

    map_bounds = (SAFE_LEFT, 314, SAFE_RIGHT, 1470)
    card(draw, map_bounds, LIGHT, fill="#EEF1F4")
    clip_left, clip_top, clip_right, clip_bottom = map_bounds
    for line_index in range(-3, 10):
        start_x = clip_left + line_index * 154
        draw.line((start_x, clip_top, start_x + 360, clip_bottom), fill="#DCE0E6", width=3)
    for line_index in range(0, 10):
        start_y = clip_top + line_index * 145
        draw.line((clip_left, start_y, clip_right, start_y - 255), fill="#DCE0E6", width=3)
    zone_center = (SCREEN_WIDTH // 2, 844)
    zone_radius = 342
    draw.ellipse(
        (
            zone_center[0] - zone_radius,
            zone_center[1] - zone_radius,
            zone_center[0] + zone_radius,
            zone_center[1] + zone_radius,
        ),
        fill="#D8ECFF",
        outline=LIGHT.accent,
        width=7,
    )
    draw.ellipse((zone_center[0] - 20, zone_center[1] - 20, zone_center[0] + 20, zone_center[1] + 20), fill=LIGHT.accent)
    pill(draw, (SCREEN_WIDTH // 2 - 104, 1230, SCREEN_WIDTH // 2 + 104, 1290), "150 m", LIGHT, fill="#FFFFFF", size=31)

    card(draw, (SAFE_LEFT, 1530, SAFE_RIGHT, 1794), LIGHT)
    draw_text(draw, (126, 1610), "Radius", 31, LIGHT.secondary)
    draw_text(draw, (126, 1686), "150 meters", 57, LIGHT.text, rounded=True)
    rounded_rect(draw, (126, 1748, SAFE_RIGHT - 58, 1766), 9, LIGHT.separator)
    rounded_rect(draw, (126, 1748, 718, 1766), 9, LIGHT.accent)
    draw.ellipse((690, 1720, 748, 1778), fill="#FFFFFF", outline=LIGHT.separator, width=2)

    button(draw, (SAFE_LEFT, 2356, SAFE_RIGHT, 2472), "Enable Zone", LIGHT)
    draw_bottom_tabs(draw, LIGHT, "Zone")
    home_indicator(draw, LIGHT)
    return image


def ready_screen() -> Image.Image:
    image, draw = new_canvas(LIGHT)
    status_bar(draw, LIGHT)
    nav_title(draw, LIGHT, "Ready", "Biology · Room 204")
    pill(draw, (SAFE_RIGHT - 204, 164, SAFE_RIGHT, 230), "150 m", LIGHT, fill=LIGHT.accent_soft, color=LIGHT.accent)

    center = (SCREEN_WIDTH // 2, 802)
    for radius, outline, width in [(350, "#E6E8EF", 18), (272, "#D7E9FF", 12), (198, LIGHT.accent, 9)]:
        draw.ellipse((center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius), outline=outline, width=width)
    draw.ellipse((center[0] - 134, center[1] - 134, center[0] + 134, center[1] + 134), fill=LIGHT.text)
    draw_text(draw, center, "Tap", 58, "#FFFFFF", rounded=True, anchor="mm")
    draw_text(draw, (center[0], center[1] + 58), "in", 34, "#FFFFFF", rounded=True, anchor="mm")

    draw_text(draw, (SCREEN_WIDTH // 2, 1226), "Start focus + attendance", 42, LIGHT.text, rounded=True, anchor="mm")
    draw_text(draw, (SCREEN_WIDTH // 2, 1284), "One action at the classroom door.", 30, LIGHT.secondary, anchor="mm")

    metric_chip(draw, (SAFE_LEFT, 1414, SAFE_LEFT + 346, 1618), "18", "apps", LIGHT)
    metric_chip(draw, (SCREEN_WIDTH // 2 - 173, 1414, SCREEN_WIDTH // 2 + 173, 1618), "47m", "class", LIGHT)
    metric_chip(draw, (SAFE_RIGHT - 346, 1414, SAFE_RIGHT, 1618), "4m", "pass", LIGHT)

    card(draw, (SAFE_LEFT, 1696, SAFE_RIGHT, 1876), LIGHT, fill=LIGHT.elevated)
    icon_badge(draw, (154, 1786), LIGHT, "id")
    draw_text(draw, (238, 1768), "Attendance", 36, LIGHT.text, rounded=True)
    draw_text(draw, (238, 1814), "Marks present when focus starts", 27, LIGHT.secondary)

    draw_bottom_tabs(draw, LIGHT, "Lock")
    home_indicator(draw, LIGHT)
    return image


def focus_screen() -> Image.Image:
    image, draw = new_canvas(DARK)
    status_bar(draw, DARK)
    draw_text(draw, (SAFE_LEFT, 166), "Campus Lock", 40, DARK.secondary, rounded=True)
    pill(draw, (SAFE_RIGHT - 238, 152, SAFE_RIGHT, 218), "Room 204", DARK, fill="#151518", color=DARK.text, size=27)

    center = (SCREEN_WIDTH // 2, 778)
    for radius, outline, width in [(386, "#121214", 26), (304, "#202024", 17), (222, "#343438", 10)]:
        draw.ellipse((center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius), outline=outline, width=width)
    draw.ellipse((center[0] - 140, center[1] - 140, center[0] + 140, center[1] + 140), fill="#FFFFFF")
    draw_lock(draw, (center[0], center[1] - 38), DARK.background, 0.88)
    draw_text(draw, (SCREEN_WIDTH // 2, 1124), "Locked", 86, DARK.text, rounded=True, anchor="mm")
    draw_text(draw, (SCREEN_WIDTH // 2, 1194), "Attendance marked", 34, DARK.secondary, anchor="mm")

    card(draw, (SAFE_LEFT, 1388, SAFE_RIGHT, 1646), DARK, fill=DARK.surface_alt)
    draw_text(draw, (126, 1462), "Focus", 30, DARK.secondary)
    draw_text(draw, (126, 1556), "18:42", 82, DARK.text, rounded=True, mono=True)
    draw_text(draw, (744, 1462), "Passing", 30, DARK.secondary)
    draw_text(draw, (744, 1556), "4:15", 82, DARK.text, rounded=True, mono=True)

    card(draw, (SAFE_LEFT, 1718, SAFE_RIGHT, 1894), DARK, fill=DARK.surface)
    draw_text(draw, (126, 1788), "Allowed", 29, DARK.secondary)
    draw_text(draw, (126, 1848), "Phone · Messages · Maps", 36, DARK.text, rounded=True)

    button(draw, (SAFE_LEFT, 2356, SAFE_RIGHT, 2472), "Unlock", DARK, primary=False)
    home_indicator(draw, DARK)
    return image


def exit_screen() -> Image.Image:
    image, draw = new_canvas(LIGHT)
    status_bar(draw, LIGHT)
    nav_title(draw, LIGHT, "Unlocked", "Outside class zone")

    center = (SCREEN_WIDTH // 2, 690)
    draw.ellipse((center[0] - 238, center[1] - 238, center[0] + 238, center[1] + 238), outline=LIGHT.success, width=14)
    draw_check(draw, center, LIGHT.success, 2.0)
    draw_text(draw, (SCREEN_WIDTH // 2, 1020), "Apps available", 62, LIGHT.text, rounded=True, anchor="mm")
    draw_text(draw, (SCREEN_WIDTH // 2, 1084), "Checked out automatically", 31, LIGHT.secondary, anchor="mm")

    card(draw, (SAFE_LEFT, 1260, SAFE_RIGHT, 1484), LIGHT)
    draw_text(draw, (126, 1338), "Session", 31, LIGHT.secondary)
    draw_text(draw, (126, 1416), "Biology · 47 min", 54, LIGHT.text, rounded=True)

    card(draw, (SAFE_LEFT, 1546, SAFE_RIGHT, 1770), LIGHT)
    draw_text(draw, (126, 1624), "Attendance", 31, LIGHT.secondary)
    draw_text(draw, (126, 1702), "Present · 10:24 checkout", 54, LIGHT.text, rounded=True)

    button(draw, (SAFE_LEFT, 2356, SAFE_RIGHT, 2472), "Start Next Class", LIGHT)
    draw_bottom_tabs(draw, LIGHT, "Lock")
    home_indicator(draw, LIGHT)
    return image


def attendance_screen() -> Image.Image:
    image, draw = new_canvas(LIGHT)
    status_bar(draw, LIGHT)
    nav_title(draw, LIGHT, "Attendance", "Today")

    card(draw, (SAFE_LEFT, 318, SAFE_RIGHT, 694), LIGHT)
    icon_badge(draw, (164, 458), LIGHT, "id")
    draw_text(draw, (252, 424), "Biology", 58, LIGHT.text, rounded=True)
    draw_text(draw, (254, 492), "Period 3 · Room 204", 31, LIGHT.secondary)
    pill(draw, (254, 548, 440, 612), "Present", LIGHT, fill="#EAF8EE", color=LIGHT.success, size=29)

    button(draw, (SAFE_LEFT, 770, SCREEN_WIDTH // 2 - 24, 878), "Enter", LIGHT)
    button(draw, (SCREEN_WIDTH // 2 + 24, 770, SAFE_RIGHT, 878), "Exit", LIGHT, primary=False)

    rows = [
        ("1", "English", "8:10", "Done"),
        ("2", "History", "9:05", "Done"),
        ("3", "Biology", "10:00", "Live"),
        ("4", "Algebra", "11:05", "Next"),
        ("5", "Studio", "1:10", "Next"),
        ("6", "Practice", "2:15", "Next"),
    ]
    top = 982
    for row_index, (period, class_name, time_value, state) in enumerate(rows):
        row_top = top + row_index * 148
        card(draw, (SAFE_LEFT, row_top, SAFE_RIGHT, row_top + 116), LIGHT)
        draw.ellipse((116, row_top + 30, 172, row_top + 86), fill=LIGHT.surface_alt)
        draw_text(draw, (144, row_top + 58), period, 26, LIGHT.text, rounded=True, anchor="mm")
        draw_text(draw, (220, row_top + 48), class_name, 34, LIGHT.text, rounded=True)
        draw_text(draw, (220, row_top + 88), time_value, 24, LIGHT.secondary)
        state_color = LIGHT.success if state == "Done" else LIGHT.accent if state == "Live" else LIGHT.tertiary
        pill(draw, (SAFE_RIGHT - 164, row_top + 31, SAFE_RIGHT - 42, row_top + 85), state, LIGHT, fill=LIGHT.elevated, color=state_color, size=24)

    draw_bottom_tabs(draw, LIGHT, "Lock")
    home_indicator(draw, LIGHT)
    return image


def insights_screen() -> Image.Image:
    image, draw = new_canvas(LIGHT)
    status_bar(draw, LIGHT)
    nav_title(draw, LIGHT, "Insights", "Founder demo")

    metric_chip(draw, (SAFE_LEFT, 330, SAFE_LEFT + 344, 552), "94%", "present", LIGHT)
    metric_chip(draw, (SCREEN_WIDTH // 2 - 172, 330, SCREEN_WIDTH // 2 + 172, 552), "3m", "avg pass", LIGHT)
    metric_chip(draw, (SAFE_RIGHT - 344, 330, SAFE_RIGHT, 552), "4.8h", "locked", LIGHT)

    card(draw, (SAFE_LEFT, 638, SAFE_RIGHT, 1164), LIGHT)
    draw_text(draw, (126, 724), "Week", 33, LIGHT.secondary)
    bar_values = [0.56, 0.78, 0.68, 0.91, 0.73, 0.34, 0.42]
    baseline = 1062
    for bar_index, value in enumerate(bar_values):
        bar_left = 152 + bar_index * 146
        bar_height = int(306 * value)
        bar_fill = LIGHT.accent if bar_index < 5 else LIGHT.separator
        rounded_rect(draw, (bar_left, baseline - bar_height, bar_left + 68, baseline), 32, bar_fill)

    card(draw, (SAFE_LEFT, 1252, SAFE_RIGHT, 1528), LIGHT)
    draw_text(draw, (126, 1330), "Signal", 31, LIGHT.secondary)
    draw_text(draw, (126, 1406), "Long passing periods", 54, LIGHT.text, rounded=True)
    draw_text(draw, (126, 1472), "Average is up 38 sec this week.", 29, LIGHT.secondary)

    card(draw, (SAFE_LEFT, 1602, SAFE_RIGHT, 1828), LIGHT, fill=LIGHT.elevated)
    draw_text(draw, (126, 1680), "Export", 31, LIGHT.secondary)
    draw_text(draw, (126, 1756), "Attendance · focus · zones", 50, LIGHT.text, rounded=True)
    button(draw, (SAFE_LEFT, 2356, SAFE_RIGHT, 2472), "Share CSV", LIGHT)

    draw_bottom_tabs(draw, LIGHT, "Stats")
    home_indicator(draw, LIGHT)
    return image


def shield_screen() -> Image.Image:
    image, draw = new_canvas(DARK)
    status_bar(draw, DARK)

    center = (SCREEN_WIDTH // 2, 690)
    draw.ellipse((center[0] - 206, center[1] - 206, center[0] + 206, center[1] + 206), fill=DARK.surface, outline=DARK.separator, width=4)
    draw_lock(draw, (center[0], center[1] - 42), DARK.text, 1.02)

    draw_text(draw, (SCREEN_WIDTH // 2, 1058), "Focus active", 76, DARK.text, rounded=True, anchor="mm")
    draw_text(draw, (SCREEN_WIDTH // 2, 1130), "This app is paused", 36, DARK.secondary, anchor="mm")

    card(draw, (140, 1326, SCREEN_WIDTH - 140, 1588), DARK, fill=DARK.surface)
    draw_text(draw, (SCREEN_WIDTH // 2, 1422), "Leave the class zone", 40, DARK.text, rounded=True, anchor="mm")
    draw_text(draw, (SCREEN_WIDTH // 2, 1488), "or unlock in Campus Lock.", 34, DARK.secondary, anchor="mm")

    button(draw, (140, 2356, SCREEN_WIDTH - 140, 2472), "Open Campus Lock", DARK)
    home_indicator(draw, DARK)
    return image


SCREENS = [
    ("01-setup.png", setup_screen),
    ("02-apps.png", apps_screen),
    ("03-zone.png", zone_screen),
    ("04-ready.png", ready_screen),
    ("05-focus-active.png", focus_screen),
    ("06-unlocked.png", exit_screen),
    ("07-attendance.png", attendance_screen),
    ("08-insights.png", insights_screen),
    ("09-shield.png", shield_screen),
]


def make_contact_sheet() -> None:
    paths = [OUTPUT_DIR / file_name for file_name, _factory in SCREENS]
    thumb_width = 258
    thumb_height = 559
    label_height = 42
    columns = 3
    rows = (len(paths) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * thumb_width, rows * (thumb_height + label_height)), "#FFFFFF")
    sheet_draw = ImageDraw.Draw(sheet)
    for path_index, path in enumerate(paths):
        thumb = Image.open(path).convert("RGB")
        thumb.thumbnail((thumb_width, thumb_height), Image.LANCZOS)
        column = path_index % columns
        row = path_index // columns
        left = column * thumb_width + (thumb_width - thumb.width) // 2
        top = row * (thumb_height + label_height)
        sheet.paste(thumb, (left, top))
        draw_text(sheet_draw, (column * thumb_width + 10, top + thumb_height + 24), path.name, 18, "#111114")
    sheet.save(OUTPUT_DIR / "00-contact-sheet.png", optimize=True)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for file_name, factory in SCREENS:
        image = factory()
        image.save(OUTPUT_DIR / file_name, optimize=True)
        print(OUTPUT_DIR / file_name)
    make_contact_sheet()
    print(OUTPUT_DIR / "00-contact-sheet.png")


if __name__ == "__main__":
    main()
