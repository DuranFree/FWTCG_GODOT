extends Node2D
## BoardAesthetic.gd — 纯视觉装饰层
## 挂在 GameBoard._game_container 之前（z_index=-1），不干涉任何游戏逻辑。
## 参考设计：LoR / 蒸汽朋克青铜机械风格

# ── 布局常量（与 GameBoard.gd 完全一致）─────────────────────
const BOARD_W    := 1000
const BOARD_H    := 516
const BOARD_Y    := 22

const GX1 := 0;    const GX2 := 48;   const GX3 := 178
const GX4 := 308;  const GX5 := 694;  const GX6 := 824;  const GX7 := 954
const GCW_SC     := 46
const GCW_CENTER := 384
const GRY1 := 0;   const GRY2 := 66;  const GRY3 := 133
const GRY4 := 385; const GRY5 := 452
const GRH1 := 64;  const GRH2 := 65;  const GRH3 := 250
const GRH4 := 65;  const GRH5 := 64
const GRH_EHL := 131
const GRH_PHL := 131

const FULL_H := 720   # 屏幕总高

# ── 颜色常量 ─────────────────────────────────────────────────
const CB_LT  := Color(0.92, 0.72, 0.24)          # 青铜亮
const CB_MD  := Color(0.65, 0.46, 0.13)          # 青铜中
const CB_DK  := Color(0.32, 0.20, 0.05)          # 青铜暗
const CB_GEM := Color(0.95, 0.80, 0.30, 0.90)    # 宝石金
const CR_GW  := Color(0.50, 0.28, 0.90, 0.65)    # 符文紫辉光
const CR_BR  := Color(0.68, 0.48, 1.00, 0.90)    # 符文紫亮
const CS_DK  := Color(0.04, 0.07, 0.14)          # 钢铁深色
const CS_MD  := Color(0.08, 0.13, 0.22)          # 钢铁中色
const CG_BG  := Color(0.008, 0.015, 0.035)       # 全局背景

# ── 运行时变量 ────────────────────────────────────────────────
var _time: float = 0.0
var _spiral_mat: ShaderMaterial = null
var _rune_l: Node2D = null   # 左符文环
var _rune_r: Node2D = null   # 右符文环（镜像）

# ── 符文字符序列 ───────────────────────────────────────────────
const RUNE_GLYPHS := ["ᚠ","ᚢ","ᚦ","ᚨ","ᚱ","ᚲ","ᚷ","ᚹ","ᚺ","ᚾ","ᛁ","ᛃ"]

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	z_index = -1
	_build_global_background()
	_build_center_spiral()
	_build_side_pillars()
	_build_zone_frames()
	_build_divider_accents()
	_build_rune_rings()
	_build_score_col_decoration()

# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	_time += delta
	if _spiral_mat:
		_spiral_mat.set_shader_parameter("u_time", _time)
	if _rune_l: _rune_l.rotation = _time * 0.12
	if _rune_r: _rune_r.rotation = -_time * 0.12


# ═══════════════════════════════════════════════════════════════
# 1. 全局深色背景
# ═══════════════════════════════════════════════════════════════
func _build_global_background() -> void:
	var rect := ColorRect.new()
	rect.color = CG_BG
	rect.position = Vector2.ZERO
	rect.size = Vector2(BOARD_W, FULL_H)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = -2
	add_child(rect)

	# 上下端轻微渐变压暗（用叠加的半透明黑色矩形模拟）
	for y_pos in [0, FULL_H - 60]:
		var fade := ColorRect.new()
		fade.color = Color(0, 0, 0, 0.35)
		fade.position = Vector2(0, y_pos)
		fade.size = Vector2(BOARD_W, 60)
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade.z_index = -1
		add_child(fade)


# ═══════════════════════════════════════════════════════════════
# 2. 中央战场螺旋（Shader）
# ═══════════════════════════════════════════════════════════════
const SPIRAL_SHADER_CODE := """
shader_type canvas_item;
uniform float u_time : hint_range(0.0, 628.0) = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);
	float angle = atan(uv.y, uv.x);

	// 四臂螺旋
	float spiral = sin(angle * 4.0 - dist * 10.0 + u_time * 0.5) * 0.5 + 0.5;

	// 边缘衰减
	float fade = 1.0 - smoothstep(0.25, 1.0, dist);
	float inner_fade = smoothstep(0.0, 0.12, dist);

	// 深蓝钢铁色
	vec3 c_dark  = vec3(0.022, 0.038, 0.072);
	vec3 c_light = vec3(0.055, 0.090, 0.165);
	vec3 col = mix(c_dark, c_light, spiral * fade * 0.7);

	// 中心亮核
	col += vec3(0.05, 0.08, 0.14) * (1.0 - smoothstep(0.0, 0.10, dist));

	// 微弱金色光晕
	float gold = pow(max(0.0, 1.0 - dist * 1.8), 3.0);
	col += vec3(0.04, 0.025, 0.005) * gold;

	float alpha = 0.90 * inner_fade;
	COLOR = vec4(col, alpha);
}
"""

func _build_center_spiral() -> void:
	var sh := Shader.new()
	sh.code = SPIRAL_SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_spiral_mat = mat

	var rect := ColorRect.new()
	# 覆盖整个战场区域（两个战场 + 行3）
	var sx := GX4
	var sy := BOARD_Y + GRY3
	var sw := GCW_CENTER
	var sh2 := GRH3
	rect.position = Vector2(sx, sy)
	rect.size = Vector2(sw, sh2)
	rect.material = mat
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = 0
	add_child(rect)


# ═══════════════════════════════════════════════════════════════
# 3. 两侧机械柱（青铜蒸汽朋克）
# ═══════════════════════════════════════════════════════════════
func _build_side_pillars() -> void:
	_add_pillar(GX1, BOARD_Y, GCW_SC, BOARD_H, false)
	_add_pillar(GX7, BOARD_Y, GCW_SC, BOARD_H, true)


func _add_pillar(px: int, py: int, pw: int, ph: int, flip: bool) -> void:
	# 深底色
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.12)
	bg.position = Vector2(px, py)
	bg.size = Vector2(pw, ph)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 内侧垂直高光线
	var edge := ColorRect.new()
	var ex := px + (pw - 2) if flip else px
	edge.color = CB_MD
	edge.position = Vector2(ex, py)
	edge.size = Vector2(2, ph)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(edge)

	# 顶部齿轮装饰
	_add_gear_strip(px, py, pw, 14, flip)
	# 底部齿轮装饰
	_add_gear_strip(px, py + ph - 14, pw, 14, flip)
	# 中间位置再加一组较小齿条
	_add_gear_strip(px, py + ph / 2 - 7, pw, 14, flip)

	# 竖向铆钉点
	var rivet_x := px + pw / 2
	for i in range(5):
		var rivet_y := py + 30 + i * (ph / 6)
		_add_rivet(rivet_x, rivet_y)


func _add_gear_strip(px: int, py: int, pw: int, ph: int, _flip: bool) -> void:
	# 背板
	var base := ColorRect.new()
	base.color = CB_DK
	base.position = Vector2(px, py)
	base.size = Vector2(pw, ph)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	# 高亮上沿
	var top_line := ColorRect.new()
	top_line.color = CB_LT
	top_line.position = Vector2(px, py)
	top_line.size = Vector2(pw, 1)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_line)
	# 齿牙（每6px一个，宽4px，高5px，从顶部突出）
	var tooth_w := 4
	var tooth_h := 5
	var gap := 6
	var nx := px + 2
	while nx + tooth_w <= px + pw - 2:
		var tooth := ColorRect.new()
		tooth.color = CB_MD
		tooth.position = Vector2(nx, py - tooth_h + 1)
		tooth.size = Vector2(tooth_w, tooth_h)
		tooth.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tooth)
		nx += tooth_w + gap


func _add_rivet(cx: int, cy: int) -> void:
	var r := ColorRect.new()
	r.color = CB_MD
	r.position = Vector2(cx - 3, cy - 3)
	r.size = Vector2(6, 6)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	var dot := ColorRect.new()
	dot.color = CB_LT
	dot.position = Vector2(cx - 1, cy - 1)
	dot.size = Vector2(2, 2)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dot)


# ═══════════════════════════════════════════════════════════════
# 4. 区域金属边框强化
# ═══════════════════════════════════════════════════════════════
func _build_zone_frames() -> void:
	# 整个游戏区外框（大框）
	_add_frame_border(GX1, BOARD_Y, BOARD_W - LOG_W(), BOARD_H, 2, CB_MD)

	# 战场区域（行3）两侧竖线强化
	var bf_y := BOARD_Y + GRY3
	var bf_h := GRH3
	# 战场左边缘
	_add_frame_border(GX4 - 1, bf_y, GCW_CENTER + 2, bf_h, 1, CB_LT)

	# 区域分隔横线（行1/2 之间，行2/3 之间，行3/4 之间，行4/5 之间）
	for ry in [GRY2, GRY3, GRY4, GRY5]:
		var line := ColorRect.new()
		line.color = CB_MD
		line.position = Vector2(GX2, BOARD_Y + ry - 1)
		line.size = Vector2(GX7 - GX2, 1)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(line)
		# 亮高光线
		var shine := ColorRect.new()
		shine.color = Color(CB_LT.r, CB_LT.g, CB_LT.b, 0.4)
		shine.position = Vector2(GX2, BOARD_Y + ry)
		shine.size = Vector2(GX7 - GX2, 1)
		shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shine)

	# 四角装饰宝石（游戏区四个角）
	for corner in [
		Vector2(GX2, BOARD_Y),
		Vector2(GX7, BOARD_Y),
		Vector2(GX2, BOARD_Y + BOARD_H),
		Vector2(GX7, BOARD_Y + BOARD_H)
	]:
		_add_corner_gem(corner.x, corner.y)

	# 战场区内部四角
	for corner in [
		Vector2(GX4, BOARD_Y + GRY3),
		Vector2(GX5, BOARD_Y + GRY3),
		Vector2(GX4, BOARD_Y + GRY4),
		Vector2(GX5, BOARD_Y + GRY4)
	]:
		_add_corner_gem(corner.x, corner.y)


const LOG_W_CONST := 280
func LOG_W() -> int: return LOG_W_CONST


func _add_frame_border(px: float, py: float, pw: float, ph: float,
		thickness: int, col: Color) -> void:
	# 上
	var t := ColorRect.new(); t.color = col
	t.position = Vector2(px, py); t.size = Vector2(pw, thickness)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(t)
	# 下
	var b := ColorRect.new(); b.color = col
	b.position = Vector2(px, py + ph - thickness); b.size = Vector2(pw, thickness)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(b)
	# 左
	var l := ColorRect.new(); l.color = col
	l.position = Vector2(px, py); l.size = Vector2(thickness, ph)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(l)
	# 右
	var r := ColorRect.new(); r.color = col
	r.position = Vector2(px + pw - thickness, py); r.size = Vector2(thickness, ph)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(r)


func _add_corner_gem(cx: float, cy: float) -> void:
	# 5×5 小宝石
	var gem := ColorRect.new()
	gem.color = CB_GEM
	gem.position = Vector2(cx - 3, cy - 3)
	gem.size = Vector2(6, 6)
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gem)
	# 内部高亮点
	var hi := ColorRect.new()
	hi.color = Color(1.0, 0.95, 0.7, 0.9)
	hi.position = Vector2(cx - 1, cy - 1)
	hi.size = Vector2(2, 2)
	hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hi)


# ═══════════════════════════════════════════════════════════════
# 5. 战场分隔线 + 进攻方向箭头
# ═══════════════════════════════════════════════════════════════
func _build_divider_accents() -> void:
	# 战场中线（行3 水平中线，作为两个战场分界）
	var mid_y := BOARD_Y + GRY3 + GRH3 / 2
	var acc := ColorRect.new()
	acc.color = Color(CB_MD.r, CB_MD.g, CB_MD.b, 0.5)
	acc.position = Vector2(GX4, mid_y)
	acc.size = Vector2(GCW_CENTER, 2)
	acc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(acc)

	# 进攻箭头（战场中线两侧）
	_add_attack_arrows(GX4, mid_y, GCW_CENTER, false)  # 上半战场箭头向下
	_add_attack_arrows(GX4, mid_y, GCW_CENTER, true)   # 下半战场箭头向上

	# 列分隔竖线（英雄/传奇区 左右）
	for gx in [GX2, GX3, GX5, GX6, GX7]:
		var vline := ColorRect.new()
		vline.color = Color(CB_MD.r, CB_MD.g, CB_MD.b, 0.5)
		vline.position = Vector2(gx - 1, BOARD_Y)
		vline.size = Vector2(2, BOARD_H)
		vline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(vline)


func _add_attack_arrows(bx: int, mid_y: int, bw: int, upward: bool) -> void:
	# 4个简单三角箭头均匀分布
	var arrow_w := 14
	var arrow_h := 8
	var dir := -1 if upward else 1
	var ay := mid_y - arrow_h * dir - 4 if upward else mid_y + 4
	var positions := [bx + bw/4 - arrow_w/2,
					  bx + bw/2 - arrow_w/2,
					  bx + bw * 3/4 - arrow_w/2]
	for ax in positions:
		# 用ColorRect模拟箭头（中心矩形 + 两侧斜切暗色）
		var arrow := ColorRect.new()
		arrow.color = Color(CB_MD.r, CB_MD.g, CB_MD.b, 0.55)
		arrow.position = Vector2(ax, ay)
		arrow.size = Vector2(arrow_w, arrow_h / 2)
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(arrow)


# ═══════════════════════════════════════════════════════════════
# 6. 符文环（左右积分列，程序化旋转）
# ═══════════════════════════════════════════════════════════════
func _build_rune_rings() -> void:
	# 左侧符文环，居中于积分列
	var lx := GX1 + GCW_SC / 2
	var ly := BOARD_Y + BOARD_H / 2
	_rune_l = _make_rune_ring(lx, ly, 17.0, true)
	add_child(_rune_l)

	# 右侧镜像
	var rx := GX7 + GCW_SC / 2
	_rune_r = _make_rune_ring(rx, ly, 17.0, false)
	add_child(_rune_r)


func _make_rune_ring(cx: float, cy: float, radius: float, glow_purple: bool) -> Node2D:
	var ring := _RuneRing.new()
	ring.position = Vector2(cx, cy)
	ring.ring_radius = radius
	ring.glow_color = CR_GW if glow_purple else Color(0.20, 0.50, 0.90, 0.55)
	ring.bright_color = CR_BR if glow_purple else Color(0.35, 0.70, 1.00, 0.85)
	ring.bronze_color = CB_MD
	return ring


# ═══════════════════════════════════════════════════════════════
# 7. 积分列额外装饰（刻度线）
# ═══════════════════════════════════════════════════════════════
func _build_score_col_decoration() -> void:
	# 左右积分列各加9条横向刻度线（对应0-8分）
	for col_x in [GX1, GX7]:
		for i in range(9):
			var tick_y := BOARD_Y + 30 + i * (BOARD_H - 60) / 8
			var tick := ColorRect.new()
			tick.color = Color(CB_MD.r, CB_MD.g, CB_MD.b, 0.50)
			tick.position = Vector2(col_x + 4, tick_y)
			tick.size = Vector2(GCW_SC - 8, 1)
			tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(tick)


# ═══════════════════════════════════════════════════════════════
# 内部类：符文环（Node2D，用 _draw() 绘制旋转圆环）
# ═══════════════════════════════════════════════════════════════
class _RuneRing extends Node2D:
	var ring_radius: float = 17.0
	var glow_color:   Color = Color(0.5, 0.3, 0.9, 0.6)
	var bright_color: Color = Color(0.7, 0.5, 1.0, 0.9)
	var bronze_color: Color = Color(0.65, 0.46, 0.13)

	func _ready() -> void:
		# 每帧重绘以实现旋转效果
		set_process(true)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		# 外圆弧（青铜色）
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, bronze_color, 1.5, true)
		# 内圆弧（辉光）
		draw_arc(Vector2.ZERO, ring_radius - 3.0, 0.0, TAU, 32,
				Color(glow_color.r, glow_color.g, glow_color.b, 0.4), 1.0, true)
		# 8个刻度点均匀分布在圆周
		for i in range(8):
			var angle := i * TAU / 8.0
			var pt := Vector2(cos(angle), sin(angle)) * ring_radius
			var pt2 := Vector2(cos(angle), sin(angle)) * (ring_radius - 4.0)
			draw_line(pt, pt2, bright_color, 1.5, true)
		# 中心小点
		draw_circle(Vector2.ZERO, 2.5, Color(bright_color.r, bright_color.g,
				bright_color.b, 0.7))
		# 3个符文字符（每120°）—— 仅绘制小点代替（GDScript无内置字体可靠绘制）
		for i in range(3):
			var angle := i * TAU / 3.0
			var pt := Vector2(cos(angle), sin(angle)) * (ring_radius - 6.0)
			draw_circle(pt, 1.5, bright_color)
