import math
from pathlib import Path
from datetime import datetime

from kivy.app import App
from kivy.core.window import Window
from kivy.core.text import Label as CoreLabel
from kivy.graphics import (
    Color, Line, Rectangle, Ellipse, Triangle, RoundedRectangle
)
from kivy.metrics import dp, sp
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.relativelayout import RelativeLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.uix.spinner import Spinner
from kivy.uix.widget import Widget
from kivy.uix.popup import Popup

# Color Theme
BG = (0.82, 0.89, 0.97, 1)          
PANEL_BG = (0.96, 0.98, 1.00, 1)    
WHITE = (1, 1, 1, 1)
BLACK = (0.08, 0.12, 0.18, 1)
DARK = (0.08, 0.16, 0.28, 1)
GRAY = (0.24, 0.31, 0.40, 1)
BLUE = (0.08, 0.38, 0.85, 1)
BLUE_DARK = (0.04, 0.25, 0.62, 1)
BLUE_LIGHT = (0.75, 0.88, 1.00, 1)
RED = (0.88, 0.08, 0.10, 1)
GREEN = (0.04, 0.55, 0.25, 1)
LIGHT_BORDER = (0.65, 0.75, 0.88, 1)
SOFT_BLUE = (0.88, 0.94, 1.00, 1)
EPS = 1e-9

def parse_measurement(value):
    if value is None:
        raise ValueError("Measurement is empty.")
    s = str(value).strip().lower()
    if not s:
        raise ValueError("Measurement is empty.")
    s = s.replace("feet", "ft").replace("foot", "ft").replace("inches", "in").replace("inch", "in")
    feet, inches = 0.0, 0.0
    if "'" in s:
        parts = s.split("'")
        feet_text = parts[0].strip()
        if feet_text:
            feet = float(feet_text)
        rest = parts[1].strip()
        if rest:
            rest = rest.replace('"', "").replace("in", "").replace("-", " ").strip()
            if rest:
                inches = float(rest)
        return feet + inches / 12.0
    if "ft" in s or "in" in s:
        temp = s.replace("-", " ")
        tokens = temp.split()
        i = 0
        while i < len(tokens):
            token = tokens[i]
            if token == "ft" and i > 0:
                feet = float(tokens[i - 1])
            elif token == "in" and i > 0:
                inches = float(tokens[i - 1])
            i += 1
        return feet + inches / 12.0
    return float(s)

def feet_inches(value):
    if value is None:
        return "-"
    value = max(0.0, float(value))
    total_inches = round(value * 12)
    return f"{total_inches // 12}'-{total_inches % 12}\""

def distance(p1, p2):
    return math.hypot(p2[0] - p1[0], p2[1] - p1[1])

def polygon_area(points):
    if len(points) < 3:
        return 0.0
    area = 0.0
    for i in range(len(points)):
        x1, y1 = points[i]
        x2, y2 = points[(i + 1) % len(points)]
        area += x1 * y2 - x2 * y1
    return abs(area) / 2.0

def polygon_angle(points, index):
    if len(points) < 3:
        return 0.0
    a, b, c = points[index - 1], points[index], points[(index + 1) % len(points)]
    v1, v2 = (a[0] - b[0], a[1] - b[1]), (c[0] - b[0], c[1] - b[1])
    len1, len2 = math.hypot(*v1), math.hypot(*v2)
    if len1 < EPS or len2 < EPS:
        return 0.0
    dot = max(-1.0, min(1.0, (v1[0]*v2[0] + v1[1]*v2[1]) / (len1 * len2)))
    return math.degrees(math.acos(dot))

def circle_intersections(c1, r1, c2, r2):
    x1, y1, x2, y2 = c1[0], c1[1], c2[0], c2[1]
    dx, dy = x2 - x1, y2 - y1
    d = math.hypot(dx, dy)
    if d < EPS or d > r1 + r2 + EPS or d < abs(r1 - r2) - EPS:
        return []
    aa = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
    h = math.sqrt(max(0.0, r1 * r1 - aa * aa))
    xm, ym = x1 + aa * dx / d, y1 + aa * dy / d
    rx, ry = -dy * h / d, dx * h / d
    return [(xm + rx, ym + ry), (xm - rx, ym - ry)]

def build_triangle(a, b, c):
    if a <= 0 or b <= 0 or c <= 0 or a + b <= c or a + c <= b or b + c <= a:
        raise ValueError("Invalid Triangle Dimensions.")
    A, B = (0.0, 0.0), (a, 0.0)
    x = (a * a + c * c - b * b) / (2 * a)
    y = math.sqrt(max(0.0, c * c - x * x))
    return [A, B, (x, y)]

def build_quadrilateral(a, b, c, d, diagonal):
    A, C = (0.0, 0.0), (diagonal, 0.0)
    sol_b = circle_intersections(A, a, C, b)
    if not sol_b: raise ValueError("Cannot construct Corner B.")
    sol_d = circle_intersections(A, d, C, c)
    if not sol_d: raise ValueError("Cannot construct Corner D.")
    return [A, max(sol_b, key=lambda p: p[1]), C, min(sol_d, key=lambda p: p[1])]

def build_pentagon(a, b, c, d, e, diag_ac, diag_ad):
    A, C = (0.0, 0.0), (diag_ac, 0.0)
    sol_b = circle_intersections(A, a, C, b)
    sol_d = circle_intersections(A, diag_ad, C, c)
    if not sol_b or not sol_d: raise ValueError("Cannot construct Pentagon Vertices.")
    D = min(sol_d, key=lambda p: p[1])
    sol_e = circle_intersections(A, e, D, d)
    if not sol_e: raise ValueError("Cannot construct Corner E.")
    return [A, max(sol_b, key=lambda p: p[1]), C, D, min(sol_e, key=lambda p: p[0])]

def clip_polygon(points, nx, ny, c):
    result = []
    for i in range(len(points)):
        cur, prev = points[i], points[i - 1]
        cur_v, prev_v = nx * cur[0] + ny * cur[1] - c, nx * prev[0] + ny * prev[1] - c
        if cur_v <= EPS and prev_v <= EPS:
            result.append(cur)
        elif prev_v <= EPS and cur_v > EPS:
            t = prev_v / (prev_v - cur_v)
            result.append((prev[0] + t * (cur[0] - prev[0]), prev[1] + t * (cur[1] - prev[1])))
        elif prev_v > EPS and cur_v <= EPS:
            t = prev_v / (prev_v - cur_v)
            result.append((prev[0] + t * (cur[0] - prev[0]), prev[1] + t * (cur[1] - prev[1])))
            result.append(cur)
    return result

def calculate_divisions(points, percentages, direction):
    total = polygon_area(points)
    nx, ny = (0.0, 1.0) if direction.lower() == "horizontal" else (1.0, 0.0)
    divisions, cut_offsets, cumulative = [], [], 0.0
    for pct in percentages[:-1]:
        cumulative += pct
        target = total * (cumulative / 100.0)
        lo, hi = min(nx*p[0] + ny*p[1] for p in points), max(nx*p[0] + ny*p[1] for p in points)
        for _ in range(50):
            mid = (lo + hi) / 2.0
            if polygon_area(clip_polygon(points, nx, ny, mid)) < target: lo = mid
            else: hi = mid
        c = (lo + hi) / 2.0
        cut_offsets.append(c)
    
    portion_areas = [total * pct / 100.0 for pct in percentages]
    return divisions, portion_areas

def corner_letter(i): return chr(65 + i)

def draw_text(canvas, text, x, y, size=12, color=BLACK, bold=False):
    lbl = CoreLabel(text=str(text), font_size=sp(size), color=color, bold=bold)
    lbl.refresh()
    Rectangle(pos=(x, y), size=lbl.texture.size, texture=lbl.texture)

class EngineeringDraft(Widget):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.points, self.diagonals, self.divisions = [], {}, []
        self.bind(pos=lambda *_: self.redraw(), size=lambda *_: self.redraw())

    def set_data(self, points, diagonals, divisions):
        self.points = points
        self.diagonals = diagonals
        self.divisions = divisions
        self.redraw()

    def redraw(self):
        self.canvas.clear()
        self.canvas.__enter__()
        Color(*PANEL_BG)
        Rectangle(pos=self.pos, size=self.size)
        if not self.points:
            draw_text(self.canvas, "Draft Preview Appears Here...", self.x + dp(20), self.center_y, 14, GRAY, True)
            self.canvas.__exit__(None, None, None)
            return

        xs, ys = [p[0] for p in self.points], [p[1] for p in self.points]
        min_x, max_x, min_y, max_y = min(xs), max(xs), min(ys), max(ys)
        scale = min((self.width - dp(40)) / max(1, max_x - min_x), (self.height - dp(40)) / max(1, max_y - min_y)) * 0.8

        screen_pts = []
        for p in self.points:
            sx = self.x + dp(20) + (p[0] - min_x) * scale
            sy = self.y + dp(20) + (p[1] - min_y) * scale
            screen_pts.extend([sx, sy])

        Color(0.78, 0.89, 1.00, 1)
        if len(screen_pts) >= 6:
            Triangle(points=screen_pts[:6])

        Color(*BLUE_DARK)
        Line(points=screen_pts + screen_pts[:2], width=2)
        for i in range(0, len(screen_pts), 2):
            Ellipse(pos=(screen_pts[i]-dp(4), screen_pts[i+1]-dp(4)), size=(dp(8), dp(8)))
            draw_text(self.canvas, corner_letter(i//2), screen_pts[i]+dp(6), screen_pts[i+1]+dp(6), 12, BLUE_DARK, True)

        self.canvas.__exit__(None, None, None)

class PlotDivisionApp(App):
    title = "Plot Division Pro"

    def build(self):
        if Path("icon.png").exists():
            self.icon = "icon.png"

        root_scroll = ScrollView(do_scroll_x=False)
        main_layout = BoxLayout(orientation="vertical", spacing=dp(10), padding=dp(10), size_hint_y=None)
        main_layout.bind(minimum_height=main_layout.setter("height"))

        header = Label(text="PLOT DIVISION PRO", font_size=sp(18), bold=True, color=WHITE, size_hint_y=None, height=dp(45))
        with header.canvas.before:
            Color(*BLUE_DARK)
            RoundedRectangle(pos=header.pos, size=header.size, radius=[dp(8)])
        main_layout.add_widget(header)

        self.shape_spinner = Spinner(text="Quadrilateral", values=["Pentagon", "Quadrilateral", "Triangle"], size_hint_y=None, height=dp(40))
        main_layout.add_widget(Label(text="SELECT SHAPE", bold=True, color=BLUE_DARK, size_hint_y=None, height=dp(20)))
        main_layout.add_widget(self.shape_spinner)

        self.inputs = {}
        for key in ["A", "B", "C", "D", "E", "DIAG", "DIAG2"]:
            inp = TextInput(hint_text=f"Enter {key} Measurement", multiline=False, size_hint_y=None, height=dp(40))
            self.inputs[key] = inp
            main_layout.add_widget(inp)

        self.percent_input = TextInput(text="50,50", multiline=False, size_hint_y=None, height=dp(40))
        main_layout.add_widget(Label(text="DIVISION PERCENTAGES (e.g. 50,50)", bold=True, color=BLUE_DARK, size_hint_y=None, height=dp(20)))
        main_layout.add_widget(self.percent_input)

        calc_btn = Button(text="CALCULATE PLOT", size_hint_y=None, height=dp(45), background_color=BLUE, color=WHITE, bold=True)
        calc_btn.bind(on_release=lambda *_: self.calculate())
        main_layout.add_widget(calc_btn)

        self.result_label = Label(text="Results will appear here...", color=BLACK, size_hint_y=None, height=dp(100))
        main_layout.add_widget(self.result_label)

        main_layout.add_widget(Label(text="ENGINEERING DRAFT PREVIEW", bold=True, color=BLUE_DARK, size_hint_y=None, height=dp(25)))
        self.draft = EngineeringDraft(size_hint_y=None, height=dp(350))
        main_layout.add_widget(self.draft)

        root_scroll.add_widget(main_layout)
        return root_scroll

    def calculate(self):
        try:
            shape = self.shape_spinner.text
            a, b, c = parse_measurement(self.inputs["A"].text), parse_measurement(self.inputs["B"].text), parse_measurement(self.inputs["C"].text)
            percentages = [float(p) for p in self.percent_input.text.split(",")]
            diagonals = {}

            if shape == "Triangle":
                pts = build_triangle(a, b, c)
            elif shape == "Quadrilateral":
                d, diag = parse_measurement(self.inputs["D"].text), parse_measurement(self.inputs["DIAG"].text)
                diagonals["AC"] = diag
                pts = build_quadrilateral(a, b, c, d, diag)
            else:
                d, e = parse_measurement(self.inputs["D"].text), parse_measurement(self.inputs["E"].text)
                diag1, diag2 = parse_measurement(self.inputs["DIAG"].text), parse_measurement(self.inputs["DIAG2"].text)
                diagonals["AC"], diagonals["AD"] = diag1, diag2
                pts = build_pentagon(a, b, c, d, e, diag1, diag2)

            divs, areas = calculate_divisions(pts, percentages, "Vertical")
            self.draft.set_data(pts, diagonals, divs)
            total_area = polygon_area(pts)
            self.result_label.text = f"Total Area: {total_area:,.2f} sq.ft ({total_area/9:,.2f} sq.yd)\nCalculated Portions: {len(areas)}"
        except Exception as e:
            self.result_label.text = f"Error: {str(e)}"

    def show_message(self, title, message):
        box = BoxLayout(orientation="vertical", padding=dp(15), spacing=dp(10))
        label = Label(text=str(message), color=(1, 1, 1, 1), font_size=sp(14), halign="left", valign="middle")
        label.bind(size=lambda inst, val: setattr(inst, "text_size", val))
        box.add_widget(label)

        btn = Button(text="OK", size_hint_y=None, height=dp(42), background_color=BLUE, color=WHITE, bold=True)
        box.add_widget(btn)

        popup = Popup(
            title=title, 
            content=box, 
            size_hint=(0.85, 0.4),
            background="",
            background_color=(0.12, 0.16, 0.22, 1)
        )
        btn.bind(on_release=popup.dismiss)
        popup.open()

if __name__ == "__main__":
    PlotDivisionApp().run()
