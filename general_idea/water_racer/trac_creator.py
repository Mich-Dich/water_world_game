import pygame
import sys
import random
import math
from dataclasses import dataclass
from typing import List, Tuple, Optional

# ========== CONFIGURATION ==========
WIDTH, HEIGHT = 1200, 800
PANEL_WIDTH = 260
VIEW_WIDTH = WIDTH - PANEL_WIDTH
BACKGROUND_COLOR = (20, 20, 30)
PANEL_COLOR = (30, 30, 40)
SLIDER_BG = (50, 50, 65)
SLIDER_FILL = (80, 160, 255)
TEXT_COLOR = (220, 220, 240)
POINT_COLOR = (200, 200, 200)
LINE_COLOR = (80, 160, 255)
START_COLOR = (255, 100, 100)
CHECKPOINT_COLOR = (255, 200, 100)      # orange for checkpoint gates
DIRECTION_COLOR = (200, 100, 255)        # purple for direction arrows
RADIUS_PREVIEW_COLOR = (255, 255, 100, 128)

# Default settings
DEFAULT_NUM_POINTS = 15
DEFAULT_MAX_BEND = 80
DEFAULT_MERGE_RADIUS = 30
DEFAULT_MARGIN = 100
DEFAULT_SPLIT_SEGMENTS = 2

# Checkpoint visualization
CHECKPOINT_LINE_LENGTH = 40              # total length of perpendicular line
ARROW_SIZE = 12                          # size of direction arrow

# ========== UI SLIDER CLASS ==========
@dataclass
class Slider:
    x: int
    y: int
    width: int
    height: int
    min_val: float
    max_val: float
    value: float
    label: str
    integer: bool = True

    def get_handle_x(self) -> int:
        ratio = (self.value - self.min_val) / (self.max_val - self.min_val)
        return self.x + int(ratio * self.width)

    def set_from_mouse(self, mouse_x: int):
        rel_x = max(0, min(self.width, mouse_x - self.x))
        ratio = rel_x / self.width
        val = self.min_val + ratio * (self.max_val - self.min_val)
        if self.integer:
            val = round(val)
        self.value = val

    def draw(self, screen: pygame.Surface, font: pygame.font.Font):
        track_rect = pygame.Rect(self.x, self.y + self.height//2 - 2, self.width, 4)
        pygame.draw.rect(screen, SLIDER_BG, track_rect)
        fill_width = self.get_handle_x() - self.x
        fill_rect = pygame.Rect(self.x, self.y + self.height//2 - 2, fill_width, 4)
        pygame.draw.rect(screen, SLIDER_FILL, fill_rect)
        handle_x = self.get_handle_x()
        pygame.draw.circle(screen, (255, 255, 255), (handle_x, self.y + self.height//2), 8)
        pygame.draw.circle(screen, SLIDER_FILL, (handle_x, self.y + self.height//2), 5)
        label_surf = font.render(f"{self.label}: {self.value:.0f}" if self.integer else f"{self.label}: {self.value:.1f}", True, TEXT_COLOR)
        screen.blit(label_surf, (self.x, self.y - 20))

# ========== TRACK GENERATION FUNCTIONS ==========
def random_point(margin: int) -> Tuple[float, float]:
    return (random.randint(margin, VIEW_WIDTH - margin),
            random.randint(margin, HEIGHT - margin))

def angle_between(v1, v2):
    dot = v1[0]*v2[0] + v1[1]*v2[1]
    mag1 = math.hypot(*v1)
    mag2 = math.hypot(*v2)
    if mag1 == 0 or mag2 == 0:
        return 0
    cos_angle = max(-1.0, min(1.0, dot / (mag1 * mag2)))
    return math.degrees(math.acos(cos_angle))

def turn_angle(p_prev, p_curr, p_next):
    v_in = (p_curr[0] - p_prev[0], p_curr[1] - p_prev[1])
    v_out = (p_next[0] - p_curr[0], p_next[1] - p_curr[1])
    return angle_between(v_in, v_out)

def insert_smooth_point(p1, p2, p3, max_bend, margin):
    v_in = (p1[0] - p2[0], p1[1] - p2[1])
    v_out = (p3[0] - p2[0], p3[1] - p2[1])
    len_in = math.hypot(*v_in)
    len_out = math.hypot(*v_out)
    if len_in == 0 or len_out == 0:
        return None, False
    u_in = (v_in[0]/len_in, v_in[1]/len_in)
    u_out = (v_out[0]/len_out, v_out[1]/len_out)
    bisector = (u_in[0] + u_out[0], u_in[1] + u_out[1])
    bis_len = math.hypot(*bisector)
    if bis_len == 0:
        return None, False
    bisector = (bisector[0]/bis_len, bisector[1]/bis_len)
    dist = min(len_in, len_out) * 0.4
    new_x = p2[0] + bisector[0] * dist
    new_y = p2[1] + bisector[1] * dist
    new_x = max(margin, min(VIEW_WIDTH - margin, new_x))
    new_y = max(margin, min(HEIGHT - margin, new_y))
    return (new_x, new_y), True

def generate_smooth_track(points, max_bend_deg, margin):
    if len(points) < 3:
        return points[:]
    pts = points[:]
    max_iter = 100
    for _ in range(max_iter):
        modified = False
        n = len(pts)
        for i in range(n):
            p_prev = pts[i-1]
            p_curr = pts[i]
            p_next = pts[(i+1) % n]
            angle = turn_angle(p_prev, p_curr, p_next)
            if angle > max_bend_deg:
                new_pt, ok = insert_smooth_point(p_prev, p_curr, p_next, max_bend_deg, margin)
                if ok:
                    pts.insert(i+1, new_pt)
                    modified = True
                    break
        if not modified:
            break
    return pts

def merge_close_points(points, min_dist):
    if len(points) < 3:
        return points[:]
    pts = points[:]
    changed = True
    while changed:
        changed = False
        n = len(pts)
        for i in range(n):
            p1 = pts[i]
            p2 = pts[(i+1) % n]
            dist = math.hypot(p2[0]-p1[0], p2[1]-p1[1])
            if dist < min_dist:
                avg = ((p1[0]+p2[0])/2, (p1[1]+p2[1])/2)
                if i == n-1:
                    pts[0] = avg
                    pts.pop()
                else:
                    pts[i] = avg
                    pts.pop(i+1)
                changed = True
                break
    return pts

def generate_base_track(num_points, max_bend, merge_radius, margin):
    pts = [random_point(margin) for _ in range(num_points)]
    cx = sum(p[0] for p in pts) / len(pts)
    cy = sum(p[1] for p in pts) / len(pts)
    pts.sort(key=lambda p: math.atan2(p[1]-cy, p[0]-cx))
    pts = generate_smooth_track(pts, max_bend, margin)
    pts = merge_close_points(pts, merge_radius)
    return pts

# ========== SPLIT & MERGE FEATURE ==========
def add_split_merge(track: List[Tuple[float, float]], num_segments: int) -> List[Tuple[float, float]]:
    if len(track) < 5 or num_segments < 1:
        return track[:]

    n = len(track)
    split_idx = random.randint(1, n - 3)
    merge_idx = (split_idx + random.randint(2, n - 2)) % n

    p_split = track[split_idx]
    p_merge = track[merge_idx]

    dx = p_merge[0] - p_split[0]
    dy = p_merge[1] - p_split[1]
    length = math.hypot(dx, dy)
    if length < 1e-6:
        return track[:]

    perp_x = -dy / length
    perp_y = dx / length
    offset = min(length * 0.3, 150)

    def create_chain(perp_sign):
        chain = [p_split]
        for i in range(1, num_segments + 1):
            t = i / (num_segments + 1)
            base_x = p_split[0] + dx * t
            base_y = p_split[1] + dy * t
            off = offset * perp_sign * (1 - 0.3 * math.sin(t * math.pi))
            pt = (base_x + perp_x * off, base_y + perp_y * off)
            pt = (max(50, min(VIEW_WIDTH-50, pt[0])),
                  max(50, min(HEIGHT-50, pt[1])))
            chain.append(pt)
        chain.append(p_merge)
        return chain

    path_a = create_chain(1.0)
    path_b = create_chain(-1.0)

    arc = []
    i = merge_idx
    while i != split_idx:
        arc.append(track[i])
        i = (i + 1) % n
    arc.append(track[split_idx])

    new_track = []
    new_track.append(p_split)
    new_track.extend(path_a[1:-1])
    new_track.append(p_merge)
    new_track.extend(arc)
    if new_track[-1] == p_split:
        new_track.extend(path_b[1:-1])
        new_track.append(p_merge)
    else:
        new_track.append(p_split)
        new_track.extend(path_b[1:-1])
        new_track.append(p_merge)

    return new_track

# ========== CHECKPOINT DRAWING ==========
def draw_checkpoints(screen: pygame.Surface, track_points: List[Tuple[float, float]]):
    """Draw a perpendicular gate and direction arrow at each track vertex."""
    if len(track_points) < 3:
        return

    n = len(track_points)
    for i in range(n):
        p_curr = track_points[i]
        p_prev = track_points[i-1]
        p_next = track_points[(i+1) % n]

        # Compute incoming and outgoing direction vectors
        v_in = (p_curr[0] - p_prev[0], p_curr[1] - p_prev[1])
        v_out = (p_next[0] - p_curr[0], p_next[1] - p_curr[1])

        # Normalize
        len_in = math.hypot(*v_in)
        len_out = math.hypot(*v_out)
        if len_in == 0 or len_out == 0:
            continue
        u_in = (v_in[0]/len_in, v_in[1]/len_in)
        u_out = (v_out[0]/len_out, v_out[1]/len_out)

        # Track direction at point: average of incoming and outgoing (bisector)
        dir_x = u_in[0] + u_out[0]
        dir_y = u_in[1] + u_out[1]
        dir_len = math.hypot(dir_x, dir_y)
        if dir_len == 0:
            # Straight line, use perpendicular to one segment
            perp = (-u_out[1], u_out[0])
            dir_x, dir_y = u_out
        else:
            dir_x /= dir_len
            dir_y /= dir_len
            # Perpendicular (rotate by 90 degrees)
            perp = (-dir_y, dir_x)

        # Draw perpendicular line (checkpoint gate)
        half = CHECKPOINT_LINE_LENGTH // 2
        start = (p_curr[0] - perp[0] * half, p_curr[1] - perp[1] * half)
        end = (p_curr[0] + perp[0] * half, p_curr[1] + perp[1] * half)
        pygame.draw.line(screen, CHECKPOINT_COLOR, start, end, 2)

        # Draw direction arrow (pointing along track direction)
        arrow_tip = (p_curr[0] + dir_x * ARROW_SIZE, p_curr[1] + dir_y * ARROW_SIZE)
        # Arrow head (simple triangle)
        arrow_left = (p_curr[0] + dir_x * (ARROW_SIZE//2) - perp[0] * (ARROW_SIZE//2),
                      p_curr[1] + dir_y * (ARROW_SIZE//2) - perp[1] * (ARROW_SIZE//2))
        arrow_right = (p_curr[0] + dir_x * (ARROW_SIZE//2) + perp[0] * (ARROW_SIZE//2),
                       p_curr[1] + dir_y * (ARROW_SIZE//2) + perp[1] * (ARROW_SIZE//2))
        pygame.draw.polygon(screen, DIRECTION_COLOR, [arrow_tip, arrow_left, arrow_right])

# ========== MAIN ==========
def main():
    pygame.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    pygame.display.set_caption("Racetrack Generator with Checkpoints")
    clock = pygame.time.Clock()
    font = pygame.font.SysFont("Arial", 18)
    small_font = pygame.font.SysFont("Arial", 14)

    # Track state
    random.seed(42)
    track_points = []
    base_track = []

    # Settings
    num_points = DEFAULT_NUM_POINTS
    max_bend = DEFAULT_MAX_BEND
    merge_radius = DEFAULT_MERGE_RADIUS
    margin = DEFAULT_MARGIN
    split_segments = DEFAULT_SPLIT_SEGMENTS

    def regenerate_base():
        nonlocal base_track, track_points
        random.seed()
        base_track = generate_base_track(num_points, max_bend, merge_radius, margin)
        track_points = base_track[:]

    def apply_split_merge():
        nonlocal track_points
        if len(track_points) >= 5:
            track_points = add_split_merge(track_points, int(split_segments))

    regenerate_base()

    # UI Sliders
    slider_x = VIEW_WIDTH + 20
    slider_width = PANEL_WIDTH - 40

    slider_num = Slider(slider_x, 80, slider_width, 20, 3, 30, num_points, "Num Points")
    slider_bend = Slider(slider_x, 160, slider_width, 20, 30, 150, max_bend, "Max Bend Angle")
    slider_merge = Slider(slider_x, 240, slider_width, 20, 0, 100, merge_radius, "Merge Radius")
    slider_margin = Slider(slider_x, 320, slider_width, 20, 50, 250, margin, "Margin")
    slider_split = Slider(slider_x, 400, slider_width, 20, 1, 3, split_segments, "Split Segments", integer=True)

    sliders = [slider_num, slider_bend, slider_merge, slider_margin, slider_split]

    active_slider: Optional[Slider] = None
    regen_button = pygame.Rect(slider_x, 480, slider_width, 40)
    split_button = pygame.Rect(slider_x, 540, slider_width, 40)
    reset_button = pygame.Rect(slider_x, 600, slider_width, 40)

    running = True
    while running:
        mouse_pos = pygame.mouse.get_pos()
        mouse_pressed = pygame.mouse.get_pressed()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                for s in sliders:
                    handle_rect = pygame.Rect(s.get_handle_x()-10, s.y, 20, s.height)
                    if handle_rect.collidepoint(mouse_pos):
                        active_slider = s
                        break
                if regen_button.collidepoint(mouse_pos):
                    num_points = int(slider_num.value)
                    max_bend = slider_bend.value
                    merge_radius = slider_merge.value
                    margin = int(slider_margin.value)
                    split_segments = slider_split.value
                    regenerate_base()
                elif split_button.collidepoint(mouse_pos):
                    split_segments = slider_split.value
                    apply_split_merge()
                elif reset_button.collidepoint(mouse_pos):
                    track_points = base_track[:]
            elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
                active_slider = None
            elif event.type == pygame.MOUSEMOTION:
                if active_slider is not None and mouse_pressed[0]:
                    active_slider.set_from_mouse(mouse_pos[0])

        # Drawing
        screen.fill(BACKGROUND_COLOR)
        pygame.draw.rect(screen, (40, 40, 50), (0, 0, VIEW_WIDTH, HEIGHT), 1)

        # Draw track
        if len(track_points) >= 2:
            pygame.draw.lines(screen, LINE_COLOR, True, track_points, 3)

        # Draw checkpoints (gates and direction arrows)
        draw_checkpoints(screen, track_points)

        # Draw points
        for i, pt in enumerate(track_points):
            color = START_COLOR if i == 0 else POINT_COLOR
            pygame.draw.circle(screen, color, (int(pt[0]), int(pt[1])), 5)

        # Draw base track faintly for reference
        if base_track and track_points != base_track:
            pygame.draw.lines(screen, (60, 60, 80), True, base_track, 1)

        # Merge radius preview
        preview_center = (VIEW_WIDTH - 80, 60)
        preview_surf = pygame.Surface((merge_radius*2, merge_radius*2), pygame.SRCALPHA)
        pygame.draw.circle(preview_surf, RADIUS_PREVIEW_COLOR, (merge_radius, merge_radius), merge_radius)
        screen.blit(preview_surf, (preview_center[0]-merge_radius, preview_center[1]-merge_radius))
        pygame.draw.line(screen, (255,255,200), (preview_center[0]-merge_radius, preview_center[1]),
                         (preview_center[0]+merge_radius, preview_center[1]), 1)
        pygame.draw.line(screen, (255,255,200), (preview_center[0], preview_center[1]-merge_radius),
                         (preview_center[0], preview_center[1]+merge_radius), 1)
        text = small_font.render(f"Merge Radius: {merge_radius:.0f} px", True, TEXT_COLOR)
        screen.blit(text, (preview_center[0]-60, preview_center[1]-merge_radius-25))

        # Right panel
        panel_rect = pygame.Rect(VIEW_WIDTH, 0, PANEL_WIDTH, HEIGHT)
        pygame.draw.rect(screen, PANEL_COLOR, panel_rect)
        pygame.draw.line(screen, (60,60,80), (VIEW_WIDTH, 0), (VIEW_WIDTH, HEIGHT), 2)

        for s in sliders:
            s.draw(screen, font)

        # Buttons
        pygame.draw.rect(screen, (60, 100, 150), regen_button, border_radius=8)
        btn_text = font.render("Regenerate Base", True, (255,255,255))
        screen.blit(btn_text, (regen_button.x + (regen_button.width - btn_text.get_width())//2,
                               regen_button.y + (regen_button.height - btn_text.get_height())//2))

        pygame.draw.rect(screen, (100, 150, 60), split_button, border_radius=8)
        btn_text2 = font.render("Add Split/Merge", True, (255,255,255))
        screen.blit(btn_text2, (split_button.x + (split_button.width - btn_text2.get_width())//2,
                                split_button.y + (split_button.height - btn_text2.get_height())//2))

        pygame.draw.rect(screen, (150, 80, 80), reset_button, border_radius=8)
        btn_text3 = font.render("Reset to Base", True, (255,255,255))
        screen.blit(btn_text3, (reset_button.x + (reset_button.width - btn_text3.get_width())//2,
                                reset_button.y + (reset_button.height - btn_text3.get_height())//2))

        # Info
        info_y = 670
        info1 = small_font.render(f"Track Points: {len(track_points)}", True, TEXT_COLOR)
        screen.blit(info1, (slider_x, info_y))
        info2 = small_font.render("Orange: checkpoints", True, (150,150,180))
        screen.blit(info2, (slider_x, info_y+25))
        info3 = small_font.render("Purple: direction", True, (150,150,180))
        screen.blit(info3, (slider_x, info_y+45))

        pygame.display.flip()
        clock.tick(60)

    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()