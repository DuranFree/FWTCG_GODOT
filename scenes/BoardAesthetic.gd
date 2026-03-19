extends Node2D
## BoardAesthetic.gd — 纯视觉装饰层（蒸汽朋克青铜风格）
## 策略：背景层 z=-1，装饰叠加层 z=20（mouse_filter=IGNORE，不拦截点击）

# ── 布局常量（与 GameBoard.gd 完全一致）─────────────────────
const BOARD_W    := 1000
const BOARD_H    := 516
const BOARD_Y    := 22
const FULL_H     := 720

const GX1 := 0;    const GX2 := 48;   const GX3 := 178
const GX4 := 308;  const GX5 := 694;  const GX6 := 824;  const GX7 := 954
const GCW_SC     := 46
const GCW_CENTER := 384
const GRY1 := 0;   const GRY2 := 66;  const GRY3 := 133
const GRY4 := 385; const GRY5 := 452
const GRH1 := 64;  const GRH2 := 65;  const GRH3 := 250
const GRH4 := 65;  const GRH5 := 64

# ── 颜色常量 ─────────────────────────────────────────────────
const CB_LT  := Color(0.95, 0.75, 0.25)
const CB_MD  := Color(0.68, 0.48, 0.13)
const CB_DK  := Color(0.30, 0.18, 0.04)
const CB_GEM := Color(1.00, 0.88, 0.32, 0.95)
const CR_GW  := Color(0.45, 0.22, 0.85, 0.70)
const CR_BR  := Color(0.65, 0.45, 1.00, 0.95)
const CB_BL  := Color(0.22, 0.55, 0.95, 0.70)
const CB_BLB := Color(0.35, 0.72, 1.00, 0.95)

var _time: float = 0.0
var _spiral_mat: ShaderMaterial = null
var _rune_l: _RuneRing = null
var _rune_r: _RuneRing = null

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_global_bg()
	_build_spiral_overlay()
	_build_side_pillars()
	_build_zone_frames()
	_build_divider_accents()
	_build_rune_rings()


func _process(delta: float) -> void:
	_time += delta
	if _spiral_mat:
		_spiral_mat.set_shader_parameter("u_time", _time)


# ═══════════════════════════════════════════════════════════════
# 1. 全局深色背景（z=-2，在最底层）
# ═══════════════════════════════════════════════════════════════
func _build_global_bg() -> void:
	var r := _rect(0, 0, BOARD_W, FULL_H, Color(0.008, 0.014, 0.032))
	r.z_index = -2
	add_child(r)


# ═══════════════════════════════════════════════════════════════
# 2. 战场螺旋叠加（z=20，半透明覆盖在战场区域之上）
# ═══════════════════════════════════════════════════════════════
const _SPIRAL_CODE := """
shader_type canvas_item;
uniform float u_time : hint_range(0.0, 628.0) = 0.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);
	float angle = atan(uv.y, uv.x);

	float spiral = sin(angle * 4.0 - dist * 9.0 + u_time * 0.45) * 0.5 + 0.5;
	float fade   = 1.0 - smoothstep(0.15, 1.0, dist);
	float inner  = 1.0 - smoothstep(0.0, 0.08, dist);

	vec3 c_dark  = vec3(0.025, 0.042, 0.080);
	vec3 c_light = vec3(0.070, 0.115, 0.210);
	vec3 col = mix(c_dark, c_light, spiral * fade * 0.75);
	col += vec3(0.06, 0.09, 0.18) * inner;
	col += vec3(0.045, 0.030, 0.006) * pow(max(0.0, 1.0 - dist * 2.2), 3.0);

	// 整体 alpha 较低，叠加在游戏内容上只留氛围感
	float alpha = 0.38 * fade + 0.06 * inner;
	COLOR = vec4(col, alpha);
}
"""

func _build_spiral_overlay() -> void:
	var sh := Shader.new()
	sh.code = _SPIRAL_CODE
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_spiral_mat = mat

	# 覆盖整个游戏中央列（两个战场）
	var cr := _rect(GX4, BOARD_Y + GRY3, GCW_CENTER, GRH3, Color.WHITE)
	cr.material = mat
	cr.z_index = 20
	add_child(cr)

	# 同样在基地区加一层更淡的
	var cr2 := _rect(GX4, BOARD_Y + GRY1, GCW_CENTER, GRH2, Color.WHITE)
	var mat2 := ShaderMaterial.new()
	mat2.shader = sh
	cr2.material = mat2
	cr2.modulate = Color(1, 1, 1, 0.4)
	cr2.z_index = 20
	add_child(cr2)
	var cr3 := _rect(GX4, BOARD_Y + GRY4, GCW_CENTER, GRH4 + GRH5, Color.WHITE)
	var mat3 := ShaderMaterial.new()
	mat3.shader = sh
	cr3.material = mat3
	cr3.modulate = Color(1, 1, 1, 0.4)
	cr3.z_index = 20
	add_child(cr3)


# ═══════════════════════════════════════════════════════════════
# 3. 两侧机械青铜柱（z=25，覆盖在积分列之上）
# ═══════════════════════════════════════════════════════════════
func _build_side_pillars() -> void:
	_add_pillar(GX1, BOARD_Y, GCW_SC, BOARD_H, false)
	_add_pillar(GX7, BOARD_Y, GCW_SC, BOARD_H, true)


func _add_pillar(px: int, py: int, pw: int, ph: int, flip: bool) -> void:
	# 深色底板
	var bg := _rect(px, py, pw, ph, Color(0.045, 0.062, 0.110, 0.92))
	bg.z_index = 25
	add_child(bg)

	# 内侧高光竖线
	var ex := px + pw - 2 if flip else px
	var el := _rect(ex, py, 2, ph, CB_MD)
	el.z_index = 26
	add_child(el)

	# 齿轮条（顶/中/底三处）
	for gear_y in [py, py + ph/2 - 7, py + ph - 14]:
		_add_gear_strip(px, gear_y, pw, 14, 26)

	# 铆钉
	for i in range(6):
		var ry := py + 24 + i * (ph - 48) / 5
		_add_rivet(px + pw/2, ry, 27)

	# 符文环（中间位置）
	var ring_node := _rect(0, 0, 0, 0, Color.TRANSPARENT)
	ring_node.z_index = 28
	add_child(ring_node)


func _add_gear_strip(px: int, py: int, pw: int, ph: int, z: int) -> void:
	var base := _rect(px, py, pw, ph, CB_DK)
	base.z_index = z
	add_child(base)
	var shine := _rect(px, py, pw, 1, CB_LT)
	shine.z_index = z + 1
	add_child(shine)
	# 齿牙
	var tx := px + 2
	while tx + 4 <= px + pw - 2:
		var tooth := _rect(tx, py - 4, 4, 5, CB_MD)
		tooth.z_index = z + 1
		add_child(tooth)
		tx += 7


func _add_rivet(cx: int, cy: int, z: int) -> void:
	var r := _rect(cx - 3, cy - 3, 6, 6, CB_MD)
	r.z_index = z
	add_child(r)
	var hi := _rect(cx - 1, cy - 1, 2, 2, Color(1.0, 0.92, 0.65, 0.9))
	hi.z_index = z + 1
	add_child(hi)


# ═══════════════════════════════════════════════════════════════
# 4. 区域金属边框（z=22，覆盖在区域背景之上，不覆盖卡牌）
# ═══════════════════════════════════════════════════════════════
func _build_zone_frames() -> void:
	# 游戏区总外框
	_frame(GX2, BOARD_Y, GX7 - GX2, BOARD_H, 2, CB_MD, 22)

	# 战场区内框（亮色）
	_frame(GX4 - 1, BOARD_Y + GRY3 - 1, GCW_CENTER + 2, GRH3 + 2, 2, CB_LT, 22)

	# 各行分隔横线
	for ry in [GRY2, GRY3, GRY4, GRY5]:
		var ln := _rect(GX2, BOARD_Y + ry - 1, GX7 - GX2, 2, CB_MD)
		ln.z_index = 22
		add_child(ln)
		var sh := _rect(GX2, BOARD_Y + ry + 1, GX7 - GX2, 1,
				Color(CB_LT.r, CB_LT.g, CB_LT.b, 0.30))
		sh.z_index = 22
		add_child(sh)

	# 各列分隔竖线
	for gx in [GX2, GX3, GX5, GX6, GX7]:
		var vl := _rect(gx - 1, BOARD_Y, 2, BOARD_H, Color(CB_MD.r, CB_MD.g, CB_MD.b, 0.70))
		vl.z_index = 22
		add_child(vl)

	# 四角宝石
	for cx in [GX2, GX7]:
		for cy_off in [0, BOARD_H]:
			_gem(cx, BOARD_Y + cy_off, 23)

	# 战场四角宝石
	for cx in [GX4, GX5]:
		for cy_off in [GRY3, GRY4]:
			_gem(cx, BOARD_Y + cy_off, 23)

	# 行分隔与列分隔交叉点宝石
	for gx in [GX3, GX6]:
		for ry in [GRY3, GRY4]:
			_gem(gx, BOARD_Y + ry, 23)


func _frame(px: float, py: float, pw: float, ph: float,
		t: int, col: Color, z: int) -> void:
	for r in [
		_rect(px,        py,        pw, t, col),
		_rect(px,        py+ph-t,   pw, t, col),
		_rect(px,        py,        t, ph, col),
		_rect(px+pw-t,   py,        t, ph, col)
	]:
		r.z_index = z
		add_child(r)


func _gem(cx: float, cy: float, z: int) -> void:
	var g := _rect(cx - 3, cy - 3, 7, 7, CB_GEM)
	g.z_index = z
	add_child(g)
	var hi := _rect(cx - 1, cy - 1, 2, 2, Color(1, 0.97, 0.75, 0.95))
	hi.z_index = z + 1
	add_child(hi)


# ═══════════════════════════════════════════════════════════════
# 5. 战场分隔线 + 进攻方向指示
# ═══════════════════════════════════════════════════════════════
func _build_divider_accents() -> void:
	var mid_y := BOARD_Y + GRY3 + GRH3 / 2
	# 战场中线
	var ml := _rect(GX4, mid_y, GCW_CENTER, 2, Color(CB_MD.r, CB_MD.g, CB_MD.b, 0.55))
	ml.z_index = 21
	add_child(ml)
	# 进攻箭头
	for side in [-1, 1]:
		var ay := mid_y + side * 8
		for i in range(3):
			var ax := GX4 + GCW_CENTER / 4 + i * GCW_CENTER / 4 - 8
			var arr := _rect(ax, ay - 4, 16, 7, Color(CB_MD.r, CB_MD.g, CB_MD.b, 0.45))
			arr.z_index = 21
			add_child(arr)
			# 箭头尖
			var tip := _rect(ax + 4, ay + (5 if side == 1 else -5), 8, 3,
					Color(CB_LT.r, CB_LT.g, CB_LT.b, 0.50))
			tip.z_index = 21
			add_child(tip)


# ═══════════════════════════════════════════════════════════════
# 6. 符文环（积分列中央，旋转动画，z=30）
# ═══════════════════════════════════════════════════════════════
func _build_rune_rings() -> void:
	var cy := BOARD_Y + BOARD_H / 2.0
	_rune_l = _RuneRing.new()
	_rune_l.position = Vector2(GX1 + GCW_SC / 2.0, cy)
	_rune_l.ring_radius = 19.0
	_rune_l.col_glow   = CR_GW
	_rune_l.col_bright = CR_BR
	_rune_l.col_ring   = CB_MD
	_rune_l.z_index    = 30
	add_child(_rune_l)

	_rune_r = _RuneRing.new()
	_rune_r.position = Vector2(GX7 + GCW_SC / 2.0, cy)
	_rune_r.ring_radius = 19.0
	_rune_r.col_glow   = CB_BL
	_rune_r.col_bright = CB_BLB
	_rune_r.col_ring   = CB_MD
	_rune_r.z_index    = 30
	add_child(_rune_r)


# ═══════════════════════════════════════════════════════════════
# 工具函数
# ═══════════════════════════════════════════════════════════════
func _rect(px: float, py: float, pw: float, ph: float, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = col
	r.position = Vector2(px, py)
	r.size = Vector2(pw, ph)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


# ═══════════════════════════════════════════════════════════════
# 内部类：符文环（_draw 绘制旋转圆环）
# ═══════════════════════════════════════════════════════════════
class _RuneRing extends Node2D:
	var ring_radius: float = 19.0
	var col_glow:  Color = Color(0.5, 0.3, 0.9, 0.65)
	var col_bright:Color = Color(0.7, 0.5, 1.0, 0.95)
	var col_ring:  Color = Color(0.65, 0.46, 0.13)

	func _ready() -> void:
		set_process(true)

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		# 外层辉光圆弧
		draw_arc(Vector2.ZERO, ring_radius + 2.0, 0.0, TAU, 48,
				Color(col_glow.r, col_glow.g, col_glow.b, 0.35), 4.0, true)
		# 主圆弧（青铜）
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, col_ring, 2.0, true)
		# 内层细圆弧（亮色）
		draw_arc(Vector2.ZERO, ring_radius - 4.0, 0.0, TAU, 48,
				Color(col_bright.r, col_bright.g, col_bright.b, 0.5), 1.0, true)
		# 8个刻度点
		for i in range(8):
			var a := i * TAU / 8.0
			var p1 := Vector2(cos(a), sin(a)) * ring_radius
			var p2 := Vector2(cos(a), sin(a)) * (ring_radius - 5.0)
			draw_line(p1, p2, col_bright, 1.5, true)
		# 3个符文亮点（120°间隔）
		for i in range(3):
			var a := i * TAU / 3.0
			var p := Vector2(cos(a), sin(a)) * (ring_radius - 7.0)
			draw_circle(p, 2.5, col_bright)
			draw_circle(p, 4.5, Color(col_glow.r, col_glow.g, col_glow.b, 0.3))
		# 中心光核
		draw_circle(Vector2.ZERO, 3.5,
				Color(col_bright.r, col_bright.g, col_bright.b, 0.75))
		draw_circle(Vector2.ZERO, 6.0,
				Color(col_glow.r, col_glow.g, col_glow.b, 0.25))
