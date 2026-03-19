extends Control
# ═══════════════════════════════════════════════
# GameBoard.gd — 游戏主界面（纯代码构建所有节点）
# 目标分辨率 1280×720
# 布局仿照原始 JS index.html CSS Grid 7列×5行结构
# ═══════════════════════════════════════════════

# ── 网格布局常量（对应 JS grid-template-columns: 4.5% 13% 13% 1fr 13% 13% 4.5%）─────
# 整体游戏区宽度 1000px，右侧 280px 为日志覆层
const BOARD_W   := 1000
const BOARD_Y   := 22     # 游戏区顶部（敌方信息条下方）
const BOARD_H   := 516    # 游戏区高度（22 + 516 = 538）

# 7列 X 坐标（col1=积分左 | col2=传奇 | col3=英雄 | col4=基地区中央 | col5=英雄 | col6=传奇 | col7=积分右）
const GCW_SC   := 46    # 积分轨道列宽
const GCW_ZN   := 128   # 英雄/传奇/牌堆列宽
const GC_GAP   := 2     # 列间距

const GX1 := 0                                    # col1 左积分
const GX2 := GX1 + GCW_SC + GC_GAP               # = 48   col2 左传奇
const GX3 := GX2 + GCW_ZN + GC_GAP               # = 178  col3 左英雄
const GX4 := GX3 + GCW_ZN + GC_GAP               # = 308  col4 基地中央
const GCW_CENTER := 384                            # 中央列宽
const GX5 := GX4 + GCW_CENTER + GC_GAP           # = 694  col5 右英雄
const GX6 := GX5 + GCW_ZN + GC_GAP               # = 824  col6 右传奇
const GX7 := GX6 + GCW_ZN + GC_GAP               # = 954  col7 右积分

# 5行高度（对应 JS grid-template-rows: 64px 65px 1fr 65px 64px）
const GRH1 := 64    # 行1：敌方基地 + 弃牌
const GRH2 := 65    # 行2：敌方符文 + 牌堆
const GRH3 := 250   # 行3：战场（1fr）
const GRH4 := 65    # 行4：我方符文 + 弃牌
const GRH5 := 64    # 行5：我方基地 + 牌堆
const GR_GAP := 2

# 各行 Y 偏移（相对于 BOARD_Y=22）
const GRY1 := 0                                   # 行1起始
const GRY2 := GRY1 + GRH1 + GR_GAP               # = 66
const GRY3 := GRY2 + GRH2 + GR_GAP               # = 133
const GRY4 := GRY3 + GRH3 + GR_GAP               # = 385
const GRY5 := GRY4 + GRH4 + GR_GAP               # = 452

# 英雄/传奇跨2行总高度
const GRH_EHL := GRH1 + GR_GAP + GRH2   # = 131 敌方英雄传奇区（行1+2）
const GRH_PHL := GRH4 + GR_GAP + GRH5   # = 131 我方英雄传奇区（行4+5）

# 界面其他区域
const ENEMY_STRIP_H := BOARD_Y             # = 22（敌方信息条高度）
const P_STRIP_Y := BOARD_Y + BOARD_H       # = 538
const P_STRIP_H := 24
const ACTION_Y  := P_STRIP_Y + P_STRIP_H  # = 562
const ACTION_H  := 46
const HAND_Y    := ACTION_Y + ACTION_H    # = 608
const HAND_H    := 112                    # 720-608=112

# 日志覆层（右侧全高面板）
const LOG_X := 1000
const LOG_W := 280
const LOG_Y := 0     # 从顶部开始
const LOG_H := 720   # 全屏高度

# ── 卡牌尺寸（各区域使用不同尺寸）─────────────
const CW_HERO  := 88    # 英雄/传奇区卡宽（跨行大区）
const CH_HERO  := 116   # 英雄/传奇区卡高
const CW_BASE  := 34    # 基地单位卡宽（紧凑区）
const CH_BASE  := 48    # 基地单位卡高
const CW_BF    := 65    # 战场单位卡宽
const CH_BF    := 90    # 战场单位卡高
const CW_HAND  := 75    # 手牌卡宽
const CH_HAND  := 100   # 手牌卡高
const RUNE_D   := 26    # 符文按钮边长（26px 圆形，h_sep=2 时每行可放13个）

# ── 颜色 ──────────────────────────────────────
const C_BG          = Color(0.005, 0.012, 0.030)
const C_STRIP_E     = Color(0.04, 0.05, 0.12)
const C_STRIP_P     = Color(0.04, 0.08, 0.05)
const C_BASE_E      = Color(0.04, 0.06, 0.13, 0.95)
const C_BASE_P      = Color(0.04, 0.09, 0.05, 0.95)
const C_HERO_ZONE   = Color(0.04, 0.06, 0.13, 0.92)
const C_PILE_ZONE   = Color(0.02, 0.06, 0.12, 0.95)
const C_BF_BG       = Color(0.02, 0.04, 0.08)
const C_BF_PANEL    = Color(0.03, 0.06, 0.11)
const C_HAND_BG     = Color(0.01, 0.02, 0.05)
const C_ACTION_BG   = Color(0.02, 0.03, 0.07)
const C_LOG_BG      = Color(0.01, 0.02, 0.04, 0.95)
const C_ZONE_BORDER = Color(0.78, 0.67, 0.43, 0.85)
const C_LABEL_DIM   = Color(0.55, 0.52, 0.44)

const C_CARD_FOLLOW = Color(0.16, 0.24, 0.40)
const C_CARD_SPELL  = Color(0.20, 0.14, 0.38)
const C_CARD_EQUIP  = Color(0.34, 0.20, 0.10)
const C_CARD_HERO   = Color(0.28, 0.18, 0.44)
const C_CARD_LEG    = Color(0.30, 0.18, 0.05)
const C_CARD_BACK   = Color(0.12, 0.14, 0.20)

const RUNE_COLORS := {
	"blazing":  Color(0.90, 0.40, 0.10),
	"radiant":  Color(0.90, 0.85, 0.30),
	"verdant":  Color(0.20, 0.75, 0.30),
	"crushing": Color(0.55, 0.35, 0.85),
	"chaos":    Color(0.80, 0.20, 0.20),
	"order":    Color(0.20, 0.55, 0.90),
}
const RUNE_ABBR := {
	"blazing": "炽", "radiant": "灵", "verdant": "翠",
	"crushing": "摧", "chaos": "混", "order": "序",
}

# ── 游戏内容容器（log 折叠时居中平移）──
var _game_container: Control = null   # 包裹所有游戏元素的容器
var _gc:             Node    = null   # 构建期临时父节点引用（build 完成后不再使用）

# ── 交互状态 ──────────────────────────────────
var _sel_uid:       int        = -1
var _sel_card:      Dictionary = {}
var _target_mode:   bool       = false
var _target_uids:   Array      = []   # 当前法术的合法目标 UID 列表
var _move_mode:     bool       = false
var _move_unit:     Dictionary = {}
var _move_from_loc: String     = "base"
var _dragging_card: Dictionary = {}   # 当前正在拖拽的手牌

# ── 节点引用 ──────────────────────────────────
# 信息条
var _enemy_info_lbl:    Label
var _player_info_lbl:   Label
var _phase_lbl:         Label
var _score_lbl:         Label
var _msg_lbl:           Label

# 敌方区域
var _enemy_rune_row:    HFlowContainer
var _enemy_base_row:    HBoxContainer   # 敌方基地单位（不含英雄传奇）
var _enemy_hero_zone:   Control         # 敌方英雄专属区
var _enemy_legend_zone: Control         # 敌方传奇专属区
var _e_deck_lbl:        Label           # 敌方主牌堆计数
var _e_rune_pile_lbl:   Label           # 敌方符文牌堆计数
var _e_discard_lbl:     Label           # 敌方弃牌计数

# 战场
var _bf_eu:           Array[HBoxContainer] = []
var _bf_pu:           Array[HBoxContainer] = []
var _bf_ctrl_lbls:    Array[Label]         = []
var _bf_card_lbls:    Array[Label]         = []
var _bf_atk_btns:     Array[Button]        = []
var _bf_panels:       Array[Control]       = []   # 战场面板根节点（用于移动模式高亮）
var _standby_slots:   Array[Control]       = []   # 待命槽节点（索引对应 bf 索引）

# 我方区域
var _player_base_row:   HBoxContainer   # 我方基地单位（不含英雄传奇）
var _player_hero_zone:  Control         # 我方英雄专属区
var _player_legend_zone: Control        # 我方传奇专属区
var _player_rune_row:   HFlowContainer
var _p_deck_lbl:        Label
var _p_rune_pile_lbl:   Label
var _p_discard_lbl:     Label

# 手牌
var _hand_row:          HBoxContainer

# 按钮
var _btn_end:           Button
var _btn_tap_all:       Button
var _btn_duel_pass:     Button
var _btn_reaction_pass: Button
var _btn_play:          Button   # 手牌出牌按钮（文字随选中牌类型变化）
var _btn_bf1:           Button   # 移动模式：上战场1
var _btn_bf2:           Button   # 移动模式：上战场2

# 积分轨道
var _score_circles_p:   Array[Label] = []
var _score_circles_e:   Array[Label] = []

# 日志
var _log_lbl:           Label                 # 废弃，保留防止旧引用报错
var _log_lines:         Array[String] = []    # 废弃
var _log_rtl:           RichTextLabel = null
var _log_panel:         Control = null
var _log_btn:           Button = null
var _log_tab_btn:       Button = null   # 折叠后在右边缘浮现的展开 Tab
var _log_collapsed:     bool = false

var _prompt_overlay:    Control = null
var _banner_lbl:        Label = null
var _banner_tween:      Tween = null

# 卡牌详情弹窗（右键点击任意卡牌触发）
var _card_detail_overlay: Control = null

# ── 动画 / 音频 ──
var _prev_bf_uids:   Array = []           # 上一帧战场单位 UID，用于检测新入场
var _prev_hand_uids: Array = []           # 上一帧手牌 UID，用于检测新摸牌（入场动画）
var _prev_p_score:   int = 0              # 上一帧玩家分，用于检测得分时机
var _prev_e_score:   int = 0
var _bgm_player:     AudioStreamPlayer = null

# ── 倒计时（对应 JS ui.js startTurnTimer / clearTurnTimer）──
const TIMER_MAX: float = 30.0
var _timer_secs:        float   = TIMER_MAX
var _timer_running:     bool    = false
var _timer_should_run:  bool    = false  # 状态机：防止 _refresh 每帧重置
var _timer_container:   Control = null
var _timer_num_lbl:     Label   = null
var _timer_bar:         ColorRect = null

# ── 符文多选待确认 ──
var _rune_tap_uids:     Array = []   # 待横置符文 UID 列表
var _rune_recycle_uids: Array = []   # 待回收符文 UID 列表
var _rune_confirm_bar:  Control = null   # 已废弃，保留避免空引用
var _rune_confirm_lbl:  Label   = null   # 已废弃，保留避免空引用


# ═══════════════════════════════════════════════
# 初始化
# ═══════════════════════════════════════════════
func _ready() -> void:
	anchor_right  = 1.0
	anchor_bottom = 1.0
	_build_board()
	_build_card_detail_overlay()
	_build_timer_widget()
	_connect_signals()
	_start_bgm()
	PromptManager.auto_mode = false
	GameState.start_game("kaisa", "masteryi")
	await _show_coin_flip()
	await _show_mulligan()
	await GameState.start_turn(GameState.first)


func _connect_signals() -> void:
	GameState.state_updated.connect(_refresh)
	GameState.phase_changed.connect(func(_p): _refresh())
	GameState.score_changed.connect(_on_score_changed)
	GameState.log_entry.connect(_on_log)
	GameState.game_over_signal.connect(_on_game_over)
	GameState.banner_shown.connect(_on_banner)
	GameState.unit_damaged.connect(_on_unit_damaged)
	GameState.turn_started.connect(func(_who): _sfx("draw"))
	PromptManager.show_prompt_requested.connect(_on_prompt_requested)
	CombatManager.combat_about_to_start.connect(_on_combat_start)
	CombatManager.unit_moved.connect(func(_uid, _from, _to, _side): _refresh())


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _card_detail_overlay and _card_detail_overlay.visible:
			_hide_card_detail()
			get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_spawn_click_ripple(event.position)


func _process(delta: float) -> void:
	if not _timer_running:
		return
	_timer_secs -= delta
	_update_timer_display()
	if _timer_secs <= 0.0:
		_timer_running   = false
		_timer_should_run = false
		_timer_container.visible = false
		_on_timer_expired()


# ═══════════════════════════════════════════════
# 布局构建（一次性，_ready 时调用）
# ═══════════════════════════════════════════════
func _build_board() -> void:
	_gc = self   # 第一阶段：直接加到 self

	# 全屏深色背景
	_add_rect(_gc, C_BG, 0, 0, 1280, 720)
	# 中央微弱蓝色光晕（营造深度感）
	var glow := ColorRect.new()
	glow.color = Color(0.04, 0.08, 0.18, 0.28)
	_set_abs(glow, 150, 80, 850, 560)
	_gc.add_child(glow)
	# 战场区域专属暗色叠加（让战场更像竞技场）
	var arena_shadow := ColorRect.new()
	arena_shadow.color = Color(0.00, 0.01, 0.03, 0.45)
	_set_abs(arena_shadow, GX2, BOARD_Y + GRY3, GX7 - GX2, GRH3)
	_gc.add_child(arena_shadow)
	# 背景粒子：Control 树无法在背景与 UI 之间插入 z 层，改为静态装饰
	# _build_particle_bg() 已停用，按需特效（_spawn_burst / _spawn_click_ripple）正常工作

	# ── 拖拽落区：直接设在 self（GameBoard）──
	# Godot 4 拖拽时沿"父节点链"查找接收方；self 是所有游戏控件的祖先，
	# 无论拖到哪个子按钮上，最终都会向上找到 self 作为 drop target。
	self.set_drag_forwarding(
		func(_at): return null,                           # self 不是拖拽源
		func(_at, data): return _can_drop_play(data),     # 检查是否允许落下
		func(_at, data): _drop_play_card(data))           # 执行打出逻辑

	# ── 视觉装饰层（必须在游戏容器之前加入，渲染在所有UI之下）──
	var aesthetic: Node2D = load("res://scenes/BoardAesthetic.gd").new()
	add_child(aesthetic)

	# ── 游戏内容容器（第二阶段：所有游戏元素加入容器）──
	# log 折叠时 tween 此容器 position.x 实现居中；PASS 保证事件冒泡到 self
	_game_container = Control.new()
	_game_container.position = Vector2.ZERO
	_game_container.size = Vector2(BOARD_W, 720)
	_game_container.mouse_filter = Control.MOUSE_FILTER_PASS
	# _game_container 是所有游戏元素的公共祖先（PASS 节点），
	# 拖拽落点在空白 ColorRect（IGNORE）上时会沿链到这里
	_game_container.set_drag_forwarding(
		func(_at): return null,
		func(_at, data): return _can_drop_play(data),
		func(_at, data): _drop_play_card(data))
	add_child(_game_container)
	_gc = _game_container   # 切换：此后所有构建函数加入容器

	# ── 敌方信息条（顶部全宽）──
	_build_enemy_strip()

	# ── 游戏区（CSS Grid 7列×5行）──
	_build_board_grid()

	# ── 玩家信息条 ──
	_build_player_strip()

	# ── 行动栏 ──
	_build_action_panel()

	# ── 手牌区 ──
	_build_hand_zone()

	# ── 日志覆层（右侧）──
	_build_log_panel()

	# ── 横幅提示（留在 self 最顶层）──
	_banner_lbl = Label.new()
	_banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_banner_lbl.add_theme_font_size_override("font_size", 22)
	_banner_lbl.add_theme_color_override("font_color", Color.YELLOW)
	_set_abs(_banner_lbl, 200, 300, 600, 60)
	_banner_lbl.visible = false
	add_child(_banner_lbl)


## 顶部敌方信息条
func _build_enemy_strip() -> void:
	var bg := _add_rect(_gc, C_STRIP_E, 0, 0, BOARD_W, ENEMY_STRIP_H)
	_enemy_info_lbl = _add_label(bg, "", 10, Color.LIGHT_GRAY, 6, 4)
	_enemy_info_lbl.anchor_right = 1.0; _enemy_info_lbl.anchor_bottom = 1.0
	_enemy_info_lbl.offset_left = 6; _enemy_info_lbl.offset_top = 3
	_enemy_info_lbl.offset_right = -6; _enemy_info_lbl.offset_bottom = 0


## 主游戏区（7列×5行网格）
func _build_board_grid() -> void:
	# 网格背景
	_add_rect(_gc, C_BG, 0, BOARD_Y, BOARD_W, BOARD_H)

	# ── 积分轨道（非对称：玩家左下，AI右上）──
	_build_score_track_player()
	_build_score_track_enemy()

	# ── 行1：敌方基地 / 英雄 / 传奇 / 弃牌 ──
	_build_enemy_base_row()

	# ── 行2：敌方符文行 / 牌堆 ──
	_build_enemy_rune_row()

	# ── 行3：战场 ──
	_build_battlefield_row()

	# ── 行4：我方符文行 / 弃牌 ──
	_build_player_rune_row()

	# ── 行5：我方基地 / 英雄 / 传奇 / 牌堆 ──
	_build_player_base_row()


## 玩家积分轨道（左侧，覆盖行3-5）
func _build_score_track_player() -> void:
	var y := BOARD_Y + GRY3
	var h := GRH3 + GR_GAP + GRH4 + GR_GAP + GRH5   # = 383
	var bg := _add_rect(_gc, Color(0.03, 0.08, 0.04, 0.97), GX1, y, GCW_SC, h)
	_add_zone_border(bg)
	var win: int = GameState.win_score if GameState.win_score > 0 else 8
	var step: float = float(h) / float(win + 1)
	for v in range(win + 1):
		var lbl := Label.new()
		lbl.text = str(win - v)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.25, 0.85, 0.35))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_set_abs(lbl, 0, int(step * v), GCW_SC, int(step))
		bg.add_child(lbl)
		_score_circles_p.append(lbl)


## AI 积分轨道（右侧，覆盖行1-3）
func _build_score_track_enemy() -> void:
	var y := BOARD_Y + GRY1
	var h := GRH1 + GR_GAP + GRH2 + GR_GAP + GRH3   # = 383
	var bg := _add_rect(_gc, Color(0.09, 0.03, 0.03, 0.97), GX7, y, GCW_SC, h)
	_add_zone_border(bg)
	var win: int = GameState.win_score if GameState.win_score > 0 else 8
	var step: float = float(h) / float(win + 1)
	for v in range(win + 1):
		var lbl := Label.new()
		lbl.text = str(v)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.90, 0.30, 0.28))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_set_abs(lbl, 0, int(step * v), GCW_SC, int(step))
		bg.add_child(lbl)
		_score_circles_e.append(lbl)


## 行1+行2左侧：敌方传奇区（跨2行，col2）
## 行1+行2：敌方英雄区（跨2行，col3）
## 行1 col4：敌方基地单位
## 行1 col5-6：敌方弃牌/放逐
func _build_enemy_base_row() -> void:
	var ay := BOARD_Y + GRY1   # 绝对Y

	# 敌方传奇区（col2，跨行1+2）
	_enemy_legend_zone = _build_hero_legend_slot(GX2, ay, GCW_ZN, GRH_EHL, "传奇位", true)

	# 敌方英雄区（col3，跨行1+2）
	_enemy_hero_zone = _build_hero_legend_slot(GX3, ay, GCW_ZN, GRH_EHL, "英雄位", true)

	# 敌方基地区（col4，行1）
	var base_bg := _build_zone(GX4, ay, GCW_CENTER, GRH1, C_BASE_E, "敌方基地")
	_enemy_base_row = _add_hbox(base_bg, 3, 2, 4, 2, GCW_CENTER - 4, GRH1 - 6)

	# 敌方弃牌/放逐（col5-6，行1）
	var discard_w := GCW_ZN * 2 + GC_GAP
	var discard_bg := _build_zone(GX5, ay, discard_w, GRH1, C_PILE_ZONE, "墓地 / 放逐")
	_e_discard_lbl = _add_label(discard_bg, "弃牌:0  放逐:0", 9, C_LABEL_DIM, 6, 18)
	var e_discard_btn := Button.new(); e_discard_btn.flat = true
	_set_abs(e_discard_btn, 0, 0, discard_w, GRH1)
	e_discard_btn.modulate = Color(1, 1, 1, 0)
	e_discard_btn.pressed.connect(func(): _show_discard_viewer("enemy"))
	discard_bg.add_child(e_discard_btn)


## 行2 col4：敌方符文行，行2 col5：符文牌堆，行2 col6：主牌堆
func _build_enemy_rune_row() -> void:
	var ay := BOARD_Y + GRY2

	# 敌方符文行（col4，行2）—— HFlowContainer 自动换行
	var rune_bg := _build_zone(GX4, ay, GCW_CENTER, GRH2, C_BASE_E, "")
	_enemy_rune_row = HFlowContainer.new()
	_enemy_rune_row.add_theme_constant_override("h_separation", 2)
	_enemy_rune_row.add_theme_constant_override("v_separation", 2)
	_set_abs(_enemy_rune_row, 2, 2, GCW_CENTER - 4, GRH2 - 4)
	rune_bg.add_child(_enemy_rune_row)

	# 敌方符文牌堆（col5，行2）
	var rpile_bg := _build_pile_zone(GX5, ay, GCW_ZN, GRH2, "符文牌堆")
	_e_rune_pile_lbl = _add_label(rpile_bg, "12", 12, Color(0.6, 0.7, 0.9), 0, GRH2 - 16)
	_e_rune_pile_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_e_rune_pile_lbl.anchor_right = 1.0; _e_rune_pile_lbl.offset_right = 0

	# 敌方主牌堆（col6，行2）
	var mpile_bg := _build_pile_zone(GX6, ay, GCW_ZN, GRH2, "主牌堆")
	_e_deck_lbl = _add_label(mpile_bg, "36", 12, Color(0.7, 0.8, 1.0), 0, GRH2 - 16)
	_e_deck_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_e_deck_lbl.anchor_right = 1.0; _e_deck_lbl.offset_right = 0


## 行3：战场（col2-6）
func _build_battlefield_row() -> void:
	var ay := BOARD_Y + GRY3
	var bf_x := GX2
	var bf_w := GX7 - GX2   # 906px
	var bf_bg := _add_rect(_gc, C_BF_BG, bf_x, ay, bf_w, GRH3)

	# 战场分区：两块战场 + 待命列
	var standby_w := 72
	var panel_w   := (bf_w - standby_w - 4) / 2   # 约 415px

	for i in range(2):
		var px := i * (panel_w + 2)
		var panel := _add_rect(bf_bg, C_BF_PANEL, px, 0, panel_w, GRH3)
		_add_zone_border(panel)
		_build_bf_slot(panel, i, panel_w)

	# 待命列（两个战场各一个待命槽）
	var sb_x := panel_w * 2 + 4
	var sb_bg := _add_rect(bf_bg, Color(0.03, 0.06, 0.09), sb_x, 0, standby_w, GRH3)
	_add_zone_border(sb_bg)
	var sb_lbl1 := _add_label(sb_bg, "待\n命\n1", 9, C_LABEL_DIM, 0, 20)
	sb_lbl1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sb_lbl1.anchor_right = 1.0; sb_lbl1.offset_right = 0
	var sb_slot1 := Control.new()
	sb_slot1.set_position(Vector2(8, 45))
	sb_slot1.set_size(Vector2(standby_w - 16, 80))
	sb_bg.add_child(sb_slot1)
	var sb_slot1_bg := _add_rect(sb_slot1, Color(0.05, 0.08, 0.12), 0, 0, standby_w - 16, 80)
	_add_zone_border(sb_slot1_bg)
	_standby_slots.append(sb_slot1)
	var sb_lbl2 := _add_label(sb_bg, "待\n命\n2", 9, C_LABEL_DIM, 0, 140)
	sb_lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sb_lbl2.anchor_right = 1.0; sb_lbl2.offset_right = 0
	var sb_slot2 := Control.new()
	sb_slot2.set_position(Vector2(8, 165))
	sb_slot2.set_size(Vector2(standby_w - 16, 80))
	sb_bg.add_child(sb_slot2)
	var sb_slot2_bg := _add_rect(sb_slot2, Color(0.05, 0.08, 0.12), 0, 0, standby_w - 16, 80)
	_add_zone_border(sb_slot2_bg)
	_standby_slots.append(sb_slot2)


## 行4 col4：我方符文行，行4 col2-3：我方弃牌
## 行4 col5-6（跨行4+5）：我方英雄/传奇
func _build_player_rune_row() -> void:
	var ay := BOARD_Y + GRY4

	# 我方弃牌/放逐（col2-3，行4）
	var discard_w := GCW_ZN * 2 + GC_GAP
	var discard_bg := _build_zone(GX2, ay, discard_w, GRH4, C_PILE_ZONE, "墓地 / 放逐")
	_p_discard_lbl = _add_label(discard_bg, "弃牌:0  放逐:0", 9, C_LABEL_DIM, 6, 18)
	var p_discard_btn := Button.new(); p_discard_btn.flat = true
	_set_abs(p_discard_btn, 0, 0, discard_w, GRH4)
	p_discard_btn.modulate = Color(1, 1, 1, 0)
	p_discard_btn.pressed.connect(func(): _show_discard_viewer("player"))
	discard_bg.add_child(p_discard_btn)

	# 我方符文行（col4，行4）—— HFlowContainer 自动换行
	var rune_bg := _build_zone(GX4, ay, GCW_CENTER, GRH4, C_BASE_P, "")
	_player_rune_row = HFlowContainer.new()
	_player_rune_row.add_theme_constant_override("h_separation", 2)
	_player_rune_row.add_theme_constant_override("v_separation", 2)
	_set_abs(_player_rune_row, 2, 2, GCW_CENTER - 4, GRH4 - 4)
	rune_bg.add_child(_player_rune_row)
	# _rune_confirm_bar 已废弃：改为复用 _btn_tap_all 作确认按钮

	# 我方英雄区（col5，跨行4+5）
	_player_hero_zone = _build_hero_legend_slot(GX5, ay, GCW_ZN, GRH_PHL, "英雄位", false)

	# 我方传奇区（col6，跨行4+5）
	_player_legend_zone = _build_hero_legend_slot(GX6, ay, GCW_ZN, GRH_PHL, "传奇位", false)


## 行5 col4：我方基地，行5 col2：主牌堆，行5 col3：符文牌堆
func _build_player_base_row() -> void:
	var ay := BOARD_Y + GRY5

	# 我方主牌堆（col2，行5）
	var mpile_bg := _build_pile_zone(GX2, ay, GCW_ZN, GRH5, "主牌堆")
	_p_deck_lbl = _add_label(mpile_bg, "12", 12, Color(0.7, 0.8, 1.0), 0, GRH5 - 16)
	_p_deck_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p_deck_lbl.anchor_right = 1.0; _p_deck_lbl.offset_right = 0

	# 我方符文牌堆（col3，行5）
	var rpile_bg := _build_pile_zone(GX3, ay, GCW_ZN, GRH5, "符文牌堆")
	_p_rune_pile_lbl = _add_label(rpile_bg, "12", 12, Color(0.6, 0.7, 0.9), 0, GRH5 - 16)
	_p_rune_pile_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p_rune_pile_lbl.anchor_right = 1.0; _p_rune_pile_lbl.offset_right = 0

	# 我方基地区（col4，行5）
	var base_bg := _build_zone(GX4, ay, GCW_CENTER, GRH5, C_BASE_P, "我方基地")
	_player_base_row = _add_hbox(base_bg, 3, 2, 4, 2, GCW_CENTER - 4, GRH5 - 6)


## 玩家信息条（游戏区下方）
func _build_player_strip() -> void:
	var bg := _add_rect(_gc, C_STRIP_P, 0, P_STRIP_Y, BOARD_W, P_STRIP_H)
	_player_info_lbl = _add_label(bg, "", 10, Color.LIGHT_GRAY, 6, 4)
	_player_info_lbl.anchor_right = 1.0; _player_info_lbl.anchor_bottom = 1.0
	_player_info_lbl.offset_left = 6; _player_info_lbl.offset_top = 3
	_player_info_lbl.offset_right = -6; _player_info_lbl.offset_bottom = 0


## 行动栏
func _build_action_panel() -> void:
	var bg := _add_rect(_gc, C_ACTION_BG, 0, ACTION_Y, BOARD_W, ACTION_H)

	_phase_lbl = _add_label(bg, "阶段: 初始化", 10, Color(0.7, 0.8, 1.0), 6, 4)
	_set_abs(_phase_lbl, 6, 3, 350, 20)

	_score_lbl = _add_label(bg, "P: 0 │ E: 0  目标: 8", 10, Color.YELLOW, 0, 0)
	_set_abs(_score_lbl, 6, 24, 350, 18)

	_msg_lbl = _add_label(bg, "", 10, Color.TOMATO, 0, 0)
	_set_abs(_msg_lbl, 360, 4, 530, 38)
	_msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_btn_tap_all = _mk_button("横置全部符文", _tap_all_or_confirm)
	_set_abs(_btn_tap_all, 500, 5, 140, 36)
	bg.add_child(_btn_tap_all)

	# 出牌/部署按钮（手牌选中时显示，文字随卡牌类型变化；move_mode 时隐藏）
	_btn_play = _mk_button("打出选中牌", _play_selected)
	_set_abs(_btn_play, 652, 5, 220, 36)
	bg.add_child(_btn_play)

	_btn_end = _mk_button("结束回合", _end_turn)
	_set_abs(_btn_end, 880, 5, 106, 36)
	bg.add_child(_btn_end)
	var end_style := StyleBoxFlat.new()
	end_style.bg_color = Color(0.15, 0.08, 0.02)
	end_style.border_color = Color(0.85, 0.70, 0.28)
	end_style.set_border_width_all(2)
	end_style.corner_radius_top_left = 5; end_style.corner_radius_top_right = 5
	end_style.corner_radius_bottom_left = 5; end_style.corner_radius_bottom_right = 5
	_btn_end.add_theme_stylebox_override("normal", end_style)
	_btn_end.add_theme_color_override("font_color", Color(0.95, 0.82, 0.42))
	_btn_end.add_theme_font_size_override("font_size", 13)

	_btn_duel_pass = _mk_button("⚔ 跳过对决", _duel_pass)
	_set_abs(_btn_duel_pass, 652, 5, 220, 36)
	_btn_duel_pass.visible = false
	_btn_duel_pass.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	bg.add_child(_btn_duel_pass)

	_btn_reaction_pass = _mk_button("⚡ 跳过反应", _reaction_pass)
	_set_abs(_btn_reaction_pass, 652, 5, 220, 36)
	_btn_reaction_pass.visible = false
	_btn_reaction_pass.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	bg.add_child(_btn_reaction_pass)

	# 移动模式（选中基地单位后）占据同一区域：左半「上战场1」，右半「上战场2」
	_btn_bf1 = _mk_button("▶ 上战场1", func(): _on_bf_click(1))
	_set_abs(_btn_bf1, 652, 5, 106, 36)
	_btn_bf1.visible = false
	_btn_bf1.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	bg.add_child(_btn_bf1)

	_btn_bf2 = _mk_button("▶ 上战场2", func(): _on_bf_click(2))
	_set_abs(_btn_bf2, 762, 5, 106, 36)
	_btn_bf2.visible = false
	_btn_bf2.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	bg.add_child(_btn_bf2)


## 手牌区
func _build_hand_zone() -> void:
	var bg := _add_rect(_gc, C_HAND_BG, 0, HAND_Y, LOG_X, HAND_H)
	_hand_row = _add_hbox(bg, 4, 4, 4, 4, LOG_X - 8, HAND_H - 8)


## 右侧日志覆层
func _build_log_panel() -> void:
	# ── 外层面板（可折叠，初始宽 LOG_W）──
	_log_panel = ColorRect.new()
	_log_panel.color = C_LOG_BG
	_log_panel.position = Vector2(LOG_X, LOG_Y)
	_log_panel.size = Vector2(LOG_W, LOG_H)
	_log_panel.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	add_child(_log_panel)

	# ── 顶部工具栏（30px 高）──
	var toolbar := ColorRect.new()
	toolbar.color = Color(0.02, 0.03, 0.06)
	toolbar.position = Vector2(0, 0)
	toolbar.size = Vector2(LOG_W, 30)
	_log_panel.add_child(toolbar)

	_log_btn = Button.new()
	_log_btn.text = "◀ 战斗记录"
	_log_btn.flat = true
	_log_btn.position = Vector2(2, 2)
	_log_btn.size = Vector2(140, 26)
	_log_btn.add_theme_font_size_override("font_size", 10)
	_log_btn.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	_log_btn.pressed.connect(_toggle_log)
	_log_panel.add_child(_log_btn)

	var clear_btn := Button.new()
	clear_btn.text = "清除"
	clear_btn.flat = true
	clear_btn.position = Vector2(LOG_W - 46, 2)
	clear_btn.size = Vector2(44, 26)
	clear_btn.add_theme_font_size_override("font_size", 9)
	clear_btn.add_theme_color_override("font_color", Color(0.45, 0.38, 0.30))
	clear_btn.pressed.connect(func():
		if _log_rtl: _log_rtl.clear()
	)
	_log_panel.add_child(clear_btn)

	# ── ScrollContainer + RichTextLabel ──
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 30)
	scroll.size = Vector2(LOG_W, LOG_H - 30)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_log_panel.add_child(scroll)

	_log_rtl = RichTextLabel.new()
	_log_rtl.bbcode_enabled = true
	_log_rtl.fit_content = true
	_log_rtl.scroll_following = true
	_log_rtl.custom_minimum_size = Vector2(LOG_W - 4, 0)
	_log_rtl.add_theme_font_size_override("normal_font_size", 9)
	scroll.add_child(_log_rtl)

	# ── 折叠后在右边缘浮现的展开 Tab（初始隐藏）──
	_log_tab_btn = Button.new()
	_log_tab_btn.text = "日\n志"
	_log_tab_btn.flat = false
	_log_tab_btn.visible = false
	_log_tab_btn.z_index = 100
	_log_tab_btn.add_theme_font_size_override("font_size", 12)
	_log_tab_btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
	# 醒目金色背景
	var tab_style := StyleBoxFlat.new()
	tab_style.bg_color = Color(0.88, 0.72, 0.20)
	tab_style.corner_radius_top_left    = 6
	tab_style.corner_radius_bottom_left = 6
	_log_tab_btn.add_theme_stylebox_override("normal", tab_style)
	var tab_hover := tab_style.duplicate() as StyleBoxFlat
	tab_hover.bg_color = Color(1.0, 0.85, 0.30)
	_log_tab_btn.add_theme_stylebox_override("hover",  tab_hover)
	_set_abs(_log_tab_btn, 1238, 280, 42, 120)
	_log_tab_btn.pressed.connect(_toggle_log)
	add_child(_log_tab_btn)


# ── 区域构建辅助 ─────────────────────────────

## 带边框和标签的普通区域背景
func _build_zone(x: int, y: int, w: int, h: int, color: Color, label: String) -> ColorRect:
	var bg := _add_rect(_gc, color, x, y, w, h)
	_add_zone_border(bg)
	if label != "":
		var lbl := _add_label(bg, label, 8, C_LABEL_DIM, 0, 2)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.anchor_right = 1.0; lbl.offset_right = 0
	return bg


## 英雄/传奇专属槽（跨行大区）
## 返回内部卡牌槽容器（用于 _clear_children，不含标签/背景）
func _build_hero_legend_slot(x: int, y: int, w: int, h: int, label: String, is_enemy: bool) -> Control:
	var bg := _add_rect(_gc, C_HERO_ZONE, x, y, w, h)
	_add_zone_border(bg)
	# 固定区域标签（贴顶/贴底）
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", C_LABEL_DIM)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.anchor_right = 1.0; lbl.offset_right = 0
	if is_enemy:
		lbl.anchor_top = 0.0; lbl.anchor_bottom = 0.0
		lbl.offset_top = 2; lbl.offset_bottom = 14
	else:
		lbl.anchor_top = 1.0; lbl.anchor_bottom = 1.0
		lbl.offset_top = -14; lbl.offset_bottom = -2
	bg.add_child(lbl)
	# 卡牌槽（动态清空区，不含标签）
	var slot := Control.new()
	slot.anchor_right = 1.0; slot.anchor_bottom = 1.0
	bg.add_child(slot)
	return slot   # ← 仅返回槽位，refresh 时只清空此节点的子节点


## 牌堆展示区（深色背景 + 卡背图标 + 标签）
func _build_pile_zone(x: int, y: int, w: int, h: int, label: String) -> ColorRect:
	var bg := _add_rect(_gc, C_PILE_ZONE, x, y, w, h)
	_add_zone_border(bg)
	# 卡背矩形（模拟卡堆）
	var card_w := mini(w - 20, 32)
	var card_h := mini(h - 20, 44)
	var cx := (w - card_w) / 2
	var cy := (h - card_h) / 2 - 6
	var card_icon := _add_rect(bg, C_CARD_BACK, cx, cy, card_w, card_h)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.11, 0.20)
	card_style.border_color = Color(0.72, 0.60, 0.28, 0.85)
	card_style.set_border_width_all(2)
	card_style.corner_radius_top_left = 3; card_style.corner_radius_top_right = 3
	card_style.corner_radius_bottom_left = 3; card_style.corner_radius_bottom_right = 3
	# 标签
	var lbl := _add_label(bg, label, 7, C_LABEL_DIM, 0, 2)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.anchor_right = 1.0; lbl.offset_right = 0
	return bg


## 金色厚边框（2px + 四角高亮）
func _add_zone_border(node: ColorRect) -> void:
	var bc := C_ZONE_BORDER   # 金色
	var bw := 2
	# 上边
	var t := ColorRect.new(); t.color = bc
	t.anchor_right = 1.0; t.offset_top = 0; t.offset_bottom = bw
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE; t.z_index = 5
	node.add_child(t)
	# 下边
	var b := ColorRect.new(); b.color = bc
	b.anchor_top = 1.0; b.anchor_right = 1.0; b.anchor_bottom = 1.0
	b.offset_top = -bw; b.offset_bottom = 0
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.z_index = 5
	node.add_child(b)
	# 左边
	var l := ColorRect.new(); l.color = bc
	l.anchor_bottom = 1.0; l.offset_left = 0; l.offset_right = bw
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE; l.z_index = 5
	node.add_child(l)
	# 右边
	var r := ColorRect.new(); r.color = bc
	r.anchor_left = 1.0; r.anchor_right = 1.0; r.anchor_bottom = 1.0
	r.offset_left = -bw; r.offset_right = 0
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE; r.z_index = 5
	node.add_child(r)
	# 四角高亮点（6×6 亮金色方块）
	var cc := Color(0.96, 0.88, 0.48, 0.95)
	var cs := 5
	# 左上
	var c1 := ColorRect.new(); c1.color = cc; c1.mouse_filter = Control.MOUSE_FILTER_IGNORE; c1.z_index = 6
	_set_abs(c1, 0, 0, cs, cs); node.add_child(c1)
	# 右上
	var c2 := ColorRect.new(); c2.color = cc; c2.mouse_filter = Control.MOUSE_FILTER_IGNORE; c2.z_index = 6
	c2.anchor_left = 1.0; c2.anchor_right = 1.0; c2.offset_left = -cs; c2.offset_right = 0
	c2.offset_top = 0; c2.offset_bottom = cs; node.add_child(c2)
	# 左下
	var c3 := ColorRect.new(); c3.color = cc; c3.mouse_filter = Control.MOUSE_FILTER_IGNORE; c3.z_index = 6
	c3.anchor_top = 1.0; c3.anchor_bottom = 1.0; c3.offset_top = -cs; c3.offset_bottom = 0
	c3.offset_left = 0; c3.offset_right = cs; node.add_child(c3)
	# 右下
	var c4 := ColorRect.new(); c4.color = cc; c4.mouse_filter = Control.MOUSE_FILTER_IGNORE; c4.z_index = 6
	c4.anchor_left = 1.0; c4.anchor_right = 1.0; c4.anchor_top = 1.0; c4.anchor_bottom = 1.0
	c4.offset_left = -cs; c4.offset_right = 0; c4.offset_top = -cs; c4.offset_bottom = 0; node.add_child(c4)


## 战场槽位内部构建
func _build_bf_slot(parent: Control, idx: int, panel_w: int) -> void:
	_bf_panels.append(parent)   # 记录面板根节点（供移动模式高亮）
	var half_h := 104   # 敌我各半

	# 敌方单位区（上半）
	var e_bg := _add_rect(parent, Color(0.04, 0.04, 0.14, 0.75), 2, 2, panel_w - 4, half_h)
	_add_zone_border(e_bg)
	var eu := _add_hbox(e_bg, 3, 3, 3, 3, panel_w - 10, half_h - 6)
	_bf_eu.append(eu)

	# 中间分隔条（控制状态 + 战场名）
	var div := _add_rect(parent, Color(0.18, 0.16, 0.10), 2, half_h + 4, panel_w - 4, 20)
	var ctrl_lbl := _add_label(div, "─ 战场%d ─" % (idx + 1), 9, Color.GRAY, 0, 2)
	ctrl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ctrl_lbl.anchor_right = 0.5; ctrl_lbl.offset_right = 0; ctrl_lbl.offset_left = 4
	_bf_ctrl_lbls.append(ctrl_lbl)
	var card_lbl := _add_label(div, "", 9, Color.WHEAT, 0, 2)
	card_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card_lbl.anchor_left = 0.5; card_lbl.anchor_right = 1.0; card_lbl.offset_right = -4
	_bf_card_lbls.append(card_lbl)

	# 我方单位区（下半）
	var p_bg_y := half_h + 26
	var p_bg := _add_rect(parent, Color(0.04, 0.12, 0.05, 0.75), 2, p_bg_y, panel_w - 4, half_h)
	_add_zone_border(p_bg)
	var pu := _add_hbox(p_bg, 3, 3, 3, 3, panel_w - 10, half_h - 6)
	_bf_pu.append(pu)

	# 进攻按钮（右下角）
	var atk_btn := Button.new()
	atk_btn.text = ">> 进攻"
	atk_btn.disabled = true
	_set_abs(atk_btn, panel_w - 120, GRH3 - 32, 115, 28)
	var atk_style := StyleBoxFlat.new()
	atk_style.bg_color = Color(0.65, 0.12, 0.12)
	atk_style.corner_radius_top_left = 4; atk_style.corner_radius_top_right = 4
	atk_style.corner_radius_bottom_left = 4; atk_style.corner_radius_bottom_right = 4
	atk_btn.add_theme_stylebox_override("normal", atk_style)
	var _idx2 := idx
	atk_btn.pressed.connect(func(): _on_bf_attack(_idx2 + 1))
	parent.add_child(atk_btn)
	_bf_atk_btns.append(atk_btn)

	# 透明点击覆盖层（用于战场移动目标选择）
	var bf_btn := Button.new()
	bf_btn.flat = true
	bf_btn.custom_minimum_size = Vector2(panel_w, GRH3)
	_set_abs(bf_btn, 0, 0, panel_w, GRH3)
	bf_btn.modulate = Color(1, 1, 1, 0)
	var _idx := idx
	bf_btn.pressed.connect(func(): _on_bf_click(_idx + 1))
	# 战场覆盖层也挂 drop forwarding：它是 MOUSE_FILTER_STOP，
	# 链会在此终止，所以必须直接在它上面处理拖拽落点
	bf_btn.set_drag_forwarding(
		func(_at): return null,
		func(_at, data): return _can_drop_play(data),
		func(_at, data): _drop_play_card(data))
	parent.add_child(bf_btn)


# ═══════════════════════════════════════════════
# 刷新 — 每次 state_updated 后重绘所有动态区域
# ═══════════════════════════════════════════════
func _refresh() -> void:
	_check_timer_state()
	_refresh_info_strips()
	_refresh_enemy_units()
	_refresh_enemy_runes()
	_refresh_battlefields()
	_refresh_standby()
	_refresh_player_units()
	_refresh_player_runes()
	_refresh_pile_counts()
	_refresh_hand()
	_refresh_buttons()
	_refresh_score_track()
	# 刷新后更新战场 UID 快照（供下次 _refresh 判断新入场单位）
	_prev_bf_uids.clear()
	for bfd: Dictionary in GameState.bf:
		for u: Dictionary in bfd.get("eU", []):
			_prev_bf_uids.append(u.get("uid", ""))
		for u: Dictionary in bfd.get("pU", []):
			_prev_bf_uids.append(u.get("uid", ""))


func _refresh_info_strips() -> void:
	var ep  := GameState.phase
	var et  := GameState.turn
	var p_name := GameState.p_deck_name
	var e_name := GameState.e_deck_name
	var p_mana := GameState.p_mana
	var e_mana := GameState.e_mana
	var p_hand := GameState.p_hand.size()
	var e_hand := GameState.e_hand.size()
	var p_deck := GameState.p_deck.size()
	var e_deck := GameState.e_deck.size()
	var e_runes := GameState.e_runes.size()
	var p_runes := GameState.p_runes.size()

	_enemy_info_lbl.text = "AI（%s）  手牌:%d  法力:%d  符文:%d  符能:%s  %s" % [
		e_name, e_hand, e_mana, e_runes, _sch_str("enemy"),
		"[AI行动中...]" if et == "enemy" else ""]

	_player_info_lbl.text = "玩家（%s）  手牌:%d  牌库:%d  法力:%d  符文:%d  符能:%s" % [
		p_name, p_hand, p_deck, p_mana, p_runes, _sch_str("player")]

	_score_lbl.text = "P: %d │ E: %d  目标: %d" % [
		GameState.p_score, GameState.e_score, GameState.win_score]

	var duel_str: String = ""
	if GameState.duel_active:
		duel_str = "  ⚔对决[%s]" % ("你" if GameState.duel_turn == "player" else "AI")
	elif GameState.reaction_active:
		duel_str = "  ⚡反应窗口[%s]" % ("你" if GameState.reaction_turn == "player" else "AI")
	_phase_lbl.text = "回合%d  阶段: %s  轮次: %s%s" % [
		GameState.round, _phase_name(ep), "玩家" if et == "player" else "AI", duel_str]


func _phase_name(p: String) -> String:
	match p:
		"init":   return "初始化"
		"awaken": return "唤醒"
		"start":  return "开始"
		"summon": return "召出"
		"draw":   return "抽牌"
		"action": return "行动"
		"end":    return "结束"
		_: return p


func _refresh_enemy_units() -> void:
	# 基地单位行
	_clear_children(_enemy_base_row)
	for u in GameState.e_base:
		_enemy_base_row.add_child(_mk_card_node(u, "enemy", "base", CW_BASE, CH_BASE))

	# 英雄专属区
	_clear_children(_enemy_hero_zone)
	if not GameState.e_hero.is_empty():
		var node := _mk_card_node(GameState.e_hero, "enemy", "hero", CW_HERO, CH_HERO)
		_center_in_zone(node, _enemy_hero_zone, GCW_ZN, GRH_EHL)
		_enemy_hero_zone.add_child(node)

	# 传奇专属区
	_clear_children(_enemy_legend_zone)
	if not GameState.e_leg.is_empty():
		var node := _mk_legend_node(GameState.e_leg, "enemy", CW_HERO, CH_HERO)
		_center_in_zone(node, _enemy_legend_zone, GCW_ZN, GRH_EHL)
		_enemy_legend_zone.add_child(node)


func _refresh_enemy_runes() -> void:
	_clear_children(_enemy_rune_row)
	# 直接显示符文圆形图标（文字信息已在顶部信息栏）
	for r in GameState.e_runes:
		_enemy_rune_row.add_child(_mk_rune_display(r, false))


func _refresh_battlefields() -> void:
	for i in range(2):
		_clear_children(_bf_eu[i])
		_clear_children(_bf_pu[i])
		var b: Dictionary = GameState.bf[i]

		var ctrl: Variant = b.get("ctrl")
		if ctrl == "player":
			_bf_ctrl_lbls[i].text = "★ 玩家控制 ★"
			_bf_ctrl_lbls[i].add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
			if i < _bf_panels.size():
				_bf_panels[i].self_modulate = Color(0.85, 1.05, 0.85)  # 绿色控制光晕
		elif ctrl == "enemy":
			_bf_ctrl_lbls[i].text = "★ AI控制 ★"
			_bf_ctrl_lbls[i].add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
			if i < _bf_panels.size():
				_bf_panels[i].self_modulate = Color(1.05, 0.85, 0.85)  # 红色控制光晕
		else:
			_bf_ctrl_lbls[i].text = "─ 战场%d ─" % (i + 1)
			_bf_ctrl_lbls[i].add_theme_color_override("font_color", Color.GRAY)
			if i < _bf_panels.size():
				_bf_panels[i].self_modulate = Color.WHITE

		var bc: Variant = b.get("card")
		_bf_card_lbls[i].text = bc.get("name", "") if bc != null else ""

		for u: Dictionary in b.get("eU", []):
			var eu_node := _mk_card_node(u, "enemy", "bf", CW_BF, CH_BF)
			_bf_eu[i].add_child(eu_node)
			if u.get("uid", "") not in _prev_bf_uids:
				_anim_enter(eu_node)
		for u: Dictionary in b.get("pU", []):
			var pu_node := _mk_card_node(u, "player", "bf", CW_BF, CH_BF)
			_bf_pu[i].add_child(pu_node)
			if u.get("uid", "") not in _prev_bf_uids:
				_anim_enter(pu_node)

		var can_atk: bool = (
			GameState.turn == "player" and
			GameState.phase == "action" and
			not GameState.duel_active and
			not GameState.reaction_active and
			not b.get("pU", []).is_empty() and
			not b.get("eU", []).is_empty()
		)
		_bf_atk_btns[i].disabled = not can_atk
		# 移动模式：高亮战场面板提示可点击目标
		if i < _bf_panels.size():
			_bf_panels[i].modulate = Color(0.8, 1.3, 0.8) if _move_mode else Color.WHITE


func _refresh_standby() -> void:
	const SW := 56; const SH := 80  # 待命槽尺寸（standby_w - 16, 80）
	for i in range(_standby_slots.size()):
		var slot: Control = _standby_slots[i]
		_clear_children(slot)
		var slot_bg := _add_rect(slot, Color(0.05, 0.08, 0.12), 0, 0, SW, SH)
		_add_zone_border(slot_bg)
		if i >= GameState.bf.size():
			continue
		var b: Dictionary = GameState.bf[i]
		var standby: Variant = b.get("standby", null)
		if standby == null:
			continue
		var card: Dictionary = standby.get("card", {})
		var sb_owner: String = standby.get("owner", "")
		if card.is_empty():
			continue
		# 显示待命卡（半透明若未到打出时机）
		var can_play: bool = KeywordManager.can_play_from_standby(i + 1, sb_owner)
		var card_node := _mk_card_base(card, SW - 4, SH - 4)
		card_node.set_position(Vector2(2, 2))
		if not can_play:
			card_node.modulate = Color(0.6, 0.6, 0.6, 0.8)
		else:
			card_node.modulate = Color(1.0, 1.0, 0.6, 1.0)  # 金色高亮：可打出
		slot.add_child(card_node)
		# 仅己方待命牌且可打出时叠加透明按钮（最后添加以捕获点击）
		if sb_owner == "player" and can_play:
			var btn := Button.new()
			btn.flat = true
			_set_abs(btn, 0, 0, SW, SH)
			btn.modulate = Color(1, 1, 1, 0)
			var _i := i
			btn.pressed.connect(func(): _on_standby_click(_i))
			slot.add_child(btn)


func _on_standby_click(bf_idx: int) -> void:
	if GameState.turn != "player" or GameState.phase != "action":
		return
	var bf_id: int = bf_idx + 1
	if not KeywordManager.can_play_from_standby(bf_id, "player"):
		_show_msg("待命牌尚未就绪（需等待下一回合）")
		return
	var card: Dictionary = KeywordManager.play_from_standby(bf_id, "player")
	if card.is_empty():
		return
	card["cost"] = 0  # 待命出牌：无视基础法力费用（规则 723）
	await SpellManager.play_card(card, "player")


func _refresh_player_units() -> void:
	# 基地单位行
	_clear_children(_player_base_row)
	for u in GameState.p_base:
		_player_base_row.add_child(_mk_card_node(u, "player", "pbase", CW_BASE, CH_BASE))

	# 英雄专属区
	_clear_children(_player_hero_zone)
	if not GameState.p_hero.is_empty():
		var node := _mk_card_node(GameState.p_hero, "player", "hero", CW_HERO, CH_HERO)
		_center_in_zone(node, _player_hero_zone, GCW_ZN, GRH_PHL)
		_player_hero_zone.add_child(node)

	# 传奇专属区
	_clear_children(_player_legend_zone)
	if not GameState.p_leg.is_empty():
		var node := _mk_legend_node(GameState.p_leg, "player", CW_HERO, CH_HERO)
		_center_in_zone(node, _player_legend_zone, GCW_ZN, GRH_PHL)
		_player_legend_zone.add_child(node)


func _refresh_player_runes() -> void:
	# 若当前阶段已不允许该操作，自动清除待确认状态
	var ok_tap     := (GameState.turn == "player" and GameState.phase in ["summon", "action"])
	var ok_recycle := (GameState.turn == "player" and GameState.phase == "action")
	if not ok_tap:     _rune_tap_uids.clear()
	if not ok_recycle: _rune_recycle_uids.clear()
	if _rune_tap_uids.is_empty() and _rune_recycle_uids.is_empty():
		if _btn_tap_all: _btn_tap_all.text = "横置全部符文"
	_clear_children(_player_rune_row)
	for i in range(GameState.p_runes.size()):
		var r: Dictionary = GameState.p_runes[i]
		_player_rune_row.add_child(_mk_rune_btn(r, i))


func _refresh_pile_counts() -> void:
	if _e_deck_lbl:        _e_deck_lbl.text       = str(GameState.e_deck.size())
	if _e_rune_pile_lbl:   _e_rune_pile_lbl.text  = str(GameState.e_rune_deck.size())
	if _p_deck_lbl:        _p_deck_lbl.text        = str(GameState.p_deck.size())
	if _p_rune_pile_lbl:   _p_rune_pile_lbl.text  = str(GameState.p_rune_deck.size())
	if _e_discard_lbl:     _e_discard_lbl.text     = "弃牌:%d  放逐:0" % GameState.e_discard.size()
	if _p_discard_lbl:     _p_discard_lbl.text     = "弃牌:%d  放逐:0" % GameState.p_discard.size()


func _refresh_hand() -> void:
	_clear_children(_hand_row)
	var is_action := (GameState.turn == "player" and GameState.phase == "action")
	for card in GameState.p_hand:
		GameState.ensure_uid(card)
	var i := 0
	for card in GameState.p_hand:
		var node := _mk_hand_card(card, is_action)
		_hand_row.add_child(node)
		if card.get("uid", -1) not in _prev_hand_uids:
			_anim_hand_enter(node, i)
		i += 1
	_prev_hand_uids = GameState.p_hand.map(func(c): return c.get("uid", -1))


func _refresh_score_track() -> void:
	var ps: int = GameState.p_score
	var es: int = GameState.e_score
	var win: int = GameState.win_score
	# 玩家积分：v=0 显示"win"，v=win 显示"0"；累积高亮已获分段
	for v in range(_score_circles_p.size()):
		var val: int  = win - v          # 该圆圈代表的分值
		var current: bool = val == ps    # 当前分恰好到这里
		var scored: bool  = val < ps     # 已超过这里（累积已得）
		if current:
			_score_circles_p[v].add_theme_color_override("font_color", Color(0.15, 1.0, 0.25))
			_score_circles_p[v].add_theme_font_size_override("font_size", 15)
		elif scored:
			_score_circles_p[v].add_theme_color_override("font_color", Color(0.1, 0.65, 0.18))
			_score_circles_p[v].add_theme_font_size_override("font_size", 11)
		else:
			_score_circles_p[v].add_theme_color_override("font_color", Color(0.18, 0.30, 0.18))
			_score_circles_p[v].add_theme_font_size_override("font_size", 9)
	# AI积分：v=0 显示"0"，v=win 显示"win"；累积高亮已获分段
	for v in range(_score_circles_e.size()):
		var val: int  = v                # 该圆圈代表的分值
		var current: bool = val == es
		var scored: bool  = val < es
		if current:
			_score_circles_e[v].add_theme_color_override("font_color", Color(1.0, 0.25, 0.15))
			_score_circles_e[v].add_theme_font_size_override("font_size", 15)
		elif scored:
			_score_circles_e[v].add_theme_color_override("font_color", Color(0.65, 0.12, 0.10))
			_score_circles_e[v].add_theme_font_size_override("font_size", 11)
		else:
			_score_circles_e[v].add_theme_color_override("font_color", Color(0.30, 0.14, 0.14))
			_score_circles_e[v].add_theme_font_size_override("font_size", 9)


func _refresh_buttons() -> void:
	var is_action := (GameState.turn == "player" and GameState.phase == "action")
	var in_duel   := GameState.duel_active    and GameState.duel_turn     == "player"
	var in_reaction := GameState.reaction_active and GameState.reaction_turn == "player"

	_btn_end.disabled  = not is_action or in_duel or in_reaction
	_btn_tap_all.disabled = not is_action

	# 对决/反应专用按钮
	_btn_duel_pass.visible     = in_duel
	_btn_reaction_pass.visible = in_reaction

	# ── 中间功能区：move_mode / 普通出牌 / 对决反应 三选一 ──
	var show_bf := _move_mode and is_action and not in_duel and not in_reaction
	if _btn_bf1 and _btn_bf2:
		_btn_bf1.visible = show_bf
		_btn_bf2.visible = show_bf
		if show_bf:
			_btn_bf1.disabled = GameState.bf[0].get("pU", []).size() >= 2
			_btn_bf2.disabled = GameState.bf[1].get("pU", []).size() >= 2

	if _btn_play:
		_btn_play.visible = not show_bf and not in_duel and not in_reaction
		# 按选中牌类型更新文字
		var ctype: String = str(_sel_card.get("type", "")) if not _sel_card.is_empty() else ""
		match ctype:
			"follower": _btn_play.text = "▶ 部署到基地"
			"spell":    _btn_play.text = "▶ 施放法术"
			"equip":    _btn_play.text = "▶ 装备"
			_:          _btn_play.text = "▶ 打出选中牌"


# ═══════════════════════════════════════════════
# 节点工厂
# ═══════════════════════════════════════════════

## 手牌卡（带点击交互）
func _mk_hand_card(card: Dictionary, is_action: bool) -> Control:
	var node := _mk_card_base(card, CW_HAND, CH_HAND)
	node.custom_minimum_size = Vector2(CW_HAND, CH_HAND)

	var in_duel: bool     = GameState.duel_active and GameState.duel_turn == "player"
	var in_reaction: bool = GameState.reaction_active and GameState.reaction_turn == "player"
	if card.get("uid", -2) == _sel_uid:
		_set_panel_border(node, Color(0.2, 0.9, 0.3), 3)
	elif is_action and SpellManager.can_play(card, "player"):
		if in_duel and not KeywordManager.can_play_in_timing(card, "duel"):
			node.modulate = Color(0.45, 0.45, 0.45, 0.85)  # 对决中不可用的牌变暗
		elif in_reaction and not KeywordManager.can_play_in_timing(card, "time_point"):
			node.modulate = Color(0.45, 0.45, 0.45, 0.85)  # 反应窗口中不可用的牌变暗
		else:
			_set_panel_border(node, Color(0.8, 0.8, 0.1), 1)

	var _c := card.duplicate()
	var gb := Button.new()
	gb.flat = true
	gb.custom_minimum_size = Vector2(CW_HAND, CH_HAND)
	_set_abs(gb, 0, 0, CW_HAND, CH_HAND)
	gb.modulate = Color(1, 1, 1, 0)
	gb.pressed.connect(func(): _on_hand_card_click(_c))
	# 拖拽支持设在 gb：gb 是实际接收鼠标事件的顶层控件
	# node.set_drag_forwarding 永远不会触发，因为 gb（FILTER_STOP）在其上方先拦截
	gb.set_drag_forwarding(
		func(_at): return _hand_get_drag(_c, gb),
		func(_at, _d): return false,
		func(_at, _d): pass)
	# 右键显示卡牌详情（gb 是顶层按钮，pc.gui_input 无法捕获）
	gb.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			_show_card_detail(_c))
	node.add_child(gb)

	return node


## 场上单位卡节点（支持不同尺寸）
func _mk_card_node(card: Dictionary, p_owner: String, loc: String, cw: int, ch: int) -> Control:
	var node := _mk_card_base(card, cw, ch)
	node.custom_minimum_size = Vector2(cw, ch)

	if card.get("exhausted", false):
		node.modulate = Color(0.6, 0.6, 0.6, 1.0)
	if card.get("stunned", false):
		node.modulate = Color(0.5, 0.5, 0.85, 1.0)
	if _move_mode and card.get("uid", -2) == _move_unit.get("uid", -3):
		_set_panel_border(node, Color(0.2, 0.9, 0.3), 3)
	if _target_mode and card.get("uid", -2) in _target_uids:
		var tgt_color := Color(0.9, 0.3, 0.2) if p_owner != "player" else Color(0.2, 0.8, 0.9)
		_set_panel_border(node, tgt_color, 2)

	if loc in ["pbase", "bf", "hero"] or _target_mode:
		var _c := card.duplicate()
		var _o := p_owner; var _l := loc
		var btn := Button.new()
		btn.flat = true
		_set_abs(btn, 0, 0, cw, ch)
		btn.modulate = Color(1, 1, 1, 0)
		btn.pressed.connect(func(): _on_unit_click(_c, _o, _l))
		# 右键显示卡牌详情（btn 是顶层 STOP 节点，pc.gui_input 无法捕获）
		btn.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
				_show_card_detail(_c))
		# 单位卡按钮是 MOUSE_FILTER_STOP，在此处转发拖拽落点
		btn.set_drag_forwarding(
			func(_at): return null,
			func(_at, data): return _can_drop_play(data),
			func(_at, data): _drop_play_card(data))
		node.add_child(btn)
	else:
		# 无交互按钮的卡（敌方基地等）：左键直接显示卡牌详情
		var _c := card.duplicate()
		node.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
				_show_card_detail(_c))
	return node


## 传奇节点
func _mk_legend_node(leg: Dictionary, p_owner: String, cw: int, ch: int) -> Control:
	var node := _mk_card_base(leg, cw, ch)
	node.custom_minimum_size = Vector2(cw, ch)
	if leg.get("exhausted", false):
		node.modulate = Color(0.6, 0.6, 0.6, 1.0)
	if p_owner == "player":
		var _l := leg.duplicate()
		var btn := Button.new()
		btn.flat = true
		_set_abs(btn, 0, 0, cw, ch)
		btn.modulate = Color(1, 1, 1, 0)
		btn.pressed.connect(func(): _on_legend_click(_l, p_owner))
		node.add_child(btn)
	return node


## 基础卡牌外观（PanelContainer + 标签）
func _mk_card_base(card: Dictionary, cw: int, ch: int) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(cw, ch)

	var style := StyleBoxFlat.new()
	style.bg_color = _card_color(card)
	style.border_color = Color(0.62, 0.52, 0.22, 0.75)  # 金色卡框
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	pc.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	pc.add_child(vbox)

	# 顶部：费用 + 攻击
	var top := HBoxContainer.new()
	var cost_lbl := Label.new()
	cost_lbl.text = str(card.get("cost", 0))
	cost_lbl.add_theme_font_size_override("font_size", maxi(8, cw / 9))
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	top.add_child(cost_lbl)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	if card.get("atk", 0) > 0:
		var atk_lbl := Label.new()
		var atk_val = GameState.get_atk(card) if card.has("uid") else card.get("atk", 0)
		atk_lbl.text = str(atk_val)
		atk_lbl.add_theme_font_size_override("font_size", maxi(8, cw / 9))
		atk_lbl.add_theme_color_override("font_color", Color.WHITE)
		top.add_child(atk_lbl)
	vbox.add_child(top)

	# 图片区域
	var img_path: String = card.get("img", "")
	var img_h := maxi(ch - 30, 20)
	if img_path != "" and ResourceLoader.exists(img_path):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(img_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.custom_minimum_size = Vector2(cw - 6, img_h)
		tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(tex_rect)
	else:
		var img_ph := ColorRect.new()
		img_ph.color = Color(0, 0, 0, 0.35)
		img_ph.custom_minimum_size = Vector2(cw - 6, img_h)
		img_ph.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(img_ph)

	# 卡名
	var name_lbl := Label.new()
	name_lbl.text = card.get("name", "?")
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", maxi(7, cw / 12))
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_lbl)

	# 生命/战力（单位）
	if card.get("type", "") in ["follower", "equipment"] or card.get("hero", false):
		var hp_cur = card.get("current_hp", card.get("hp", 0))
		var atk_cur = GameState.get_atk(card) if card.has("uid") else card.get("atk", 0)
		var stat_lbl := Label.new()
		stat_lbl.text = "%d/%d" % [atk_cur, hp_cur]
		stat_lbl.add_theme_font_size_override("font_size", maxi(8, cw / 11))
		stat_lbl.add_theme_color_override("font_color",
			Color(0.4, 0.9, 0.4) if hp_cur > 0 else Color(0.9, 0.3, 0.3))
		vbox.add_child(stat_lbl)

	# 关键词
	var kws: Array = card.get("keywords", [])
	if not kws.is_empty() and ch >= 80:
		var kw_lbl := Label.new()
		kw_lbl.text = " ".join(kws)
		kw_lbl.clip_text = true
		kw_lbl.add_theme_font_size_override("font_size", 7)
		kw_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4))
		vbox.add_child(kw_lbl)

	# 已装配装备标签（橙色小字）
	var equips: Array = card.get("attached_equipments", [])
	if not equips.is_empty():
		for eq in equips:
			var eq_lbl := Label.new()
			var bonus: int = eq.get("atk_bonus", 0)
			eq_lbl.text = "⚙ %s%s" % [eq.get("name", "装备"), ("+%d" % bonus) if bonus > 0 else ""]
			eq_lbl.clip_text = true
			eq_lbl.add_theme_font_size_override("font_size", 7)
			eq_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.1))
			vbox.add_child(eq_lbl)

	return pc


# ═══════════════════════════════════════════════
# 卡牌详情弹窗（右键触发，参考 JS showCardPreview）
# ═══════════════════════════════════════════════

func _build_card_detail_overlay() -> void:
	# 全屏半透明遮罩
	_card_detail_overlay = Control.new()
	_card_detail_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card_detail_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_card_detail_overlay.visible = false
	_card_detail_overlay.z_index = 300
	add_child(_card_detail_overlay)

	# 点击遮罩关闭弹窗
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_hide_card_detail())  # 左键或右键点遮罩外围均关闭
	_card_detail_overlay.add_child(bg)

	# 中央卡牌信息面板（内容由 _show_card_detail 填充）
	var panel := PanelContainer.new()
	panel.name = "DetailPanel"
	panel.custom_minimum_size = Vector2(300, 400)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	# 右键点击面板本身也关闭
	panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
			_hide_card_detail())
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.06, 0.10, 0.97)
	ps.border_color = Color(0.55, 0.72, 0.88)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", ps)
	_card_detail_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "DetailVBox"
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)


# ═══════════════════════════════════════════════
# 倒计时系统（对应 JS ui.js startTurnTimer / clearTurnTimer / updateTimerDisplay）
# ═══════════════════════════════════════════════

func _build_timer_widget() -> void:
	# 位置：屏幕顶部居中，不遮挡游戏元素
	_timer_container = Control.new()
	_timer_container.set_position(Vector2(580, 6))
	_timer_container.set_size(Vector2(120, 70))
	_timer_container.z_index = 150
	_timer_container.visible = false
	_timer_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_timer_container)

	# 背景面板
	var bg := Panel.new()
	bg.set_position(Vector2(0, 0))
	bg.set_size(Vector2(120, 70))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sbox := StyleBoxFlat.new()
	sbox.bg_color = Color(0.04, 0.06, 0.10, 0.92)
	sbox.border_color = Color(0.3, 0.5, 0.3, 0.7)
	sbox.set_border_width_all(1)
	sbox.set_corner_radius_all(6)
	bg.add_theme_stylebox_override("panel", sbox)
	_timer_container.add_child(bg)

	# 标题
	var title := Label.new()
	title.set_position(Vector2(0, 3))
	title.set_size(Vector2(120, 14))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	title.text = "⏱ 行动倒计时"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_container.add_child(title)

	# 大数字
	_timer_num_lbl = Label.new()
	_timer_num_lbl.set_position(Vector2(0, 15))
	_timer_num_lbl.set_size(Vector2(120, 38))
	_timer_num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_num_lbl.add_theme_font_size_override("font_size", 30)
	_timer_num_lbl.add_theme_color_override("font_color", Color(0.3, 0.87, 0.5))
	_timer_num_lbl.text = "30"
	_timer_num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_container.add_child(_timer_num_lbl)

	# 进度条底色
	var bar_bg := ColorRect.new()
	bar_bg.set_position(Vector2(4, 60))
	bar_bg.set_size(Vector2(112, 5))
	bar_bg.color = Color(0.12, 0.15, 0.18)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_container.add_child(bar_bg)

	# 进度条填充（宽度随时间缩短）
	_timer_bar = ColorRect.new()
	_timer_bar.set_position(Vector2(4, 60))
	_timer_bar.set_size(Vector2(112, 5))
	_timer_bar.color = Color(0.3, 0.87, 0.5)
	_timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_container.add_child(_timer_bar)


## 判断当前状态是否应该运行倒计时，并在状态切换时启停（对应 JS keepRunning 逻辑）
func _check_timer_state() -> void:
	var should: bool = (
		not GameState.game_over and (
			(GameState.turn == "player" and GameState.phase == "action"
				and not GameState.duel_active and not GameState.reaction_active) or
			(GameState.duel_active    and GameState.duel_turn     == "player") or
			(GameState.reaction_active and GameState.reaction_turn == "player")
		)
	)
	if should and not _timer_should_run:
		_timer_should_run = true
		_start_timer()
	elif not should and _timer_should_run:
		_timer_should_run = false
		_stop_timer()


func _start_timer() -> void:
	_timer_secs = TIMER_MAX
	_timer_running = true
	_timer_container.visible = true
	_update_timer_display()


func _stop_timer() -> void:
	_timer_running = false
	_timer_container.visible = false


## 更新数字 + 进度条 + 颜色（绿→黄→橙→红，对应 JS updateTimerDisplay）
func _update_timer_display() -> void:
	var pct: float = _timer_secs / TIMER_MAX
	var col: Color
	if pct > 0.5:    col = Color(0.30, 0.87, 0.50)  # 绿
	elif pct > 0.3:  col = Color(0.98, 0.80, 0.08)  # 黄
	elif pct > 0.15: col = Color(0.98, 0.57, 0.18)  # 橙
	else:            col = Color(0.97, 0.53, 0.53)  # 红
	_timer_num_lbl.text = str(ceili(_timer_secs))
	_timer_num_lbl.add_theme_color_override("font_color", col)
	_timer_bar.size.x = 112.0 * maxf(pct, 0.0)
	_timer_bar.color  = col


## 超时处理（对应 JS onTurnTimerExpired）
func _on_timer_expired() -> void:
	if GameState.game_over:
		return
	# 反应窗口超时 → 自动跳过
	if GameState.reaction_active and GameState.reaction_turn == "player":
		GameState._log("[反应超时] 自动跳过反应", "phase")
		_reaction_pass()
		return
	# 法术对决超时 → 自动 Pass
	if GameState.duel_active and GameState.duel_turn == "player":
		GameState._log("[对决超时] 自动 Pass", "phase")
		_duel_pass()
		return
	# 行动阶段超时 → 随机出牌，否则结束回合
	if GameState.turn != "player" or GameState.phase != "action":
		return
	var playable: Array = GameState.p_hand.filter(func(c): return SpellManager.can_play(c, "player"))
	if playable.size() > 0:
		var c: Dictionary = playable[randi() % playable.size()]
		GameState._log("[超时] 随机打出【%s】" % c.get("name", "?"), "phase")
		_sel_card = c
		_sel_uid  = c.get("uid", -1)
		_play_selected()
	else:
		GameState._log("[超时] 无可用操作，自动结束行动阶段", "phase")
		GameState.player_end_turn()


func _show_card_detail(card: Dictionary) -> void:
	if _card_detail_overlay == null:
		return
	var panel: PanelContainer = _card_detail_overlay.get_node("DetailPanel")
	var vbox: VBoxContainer = panel.get_node("DetailVBox")
	# 清空旧内容
	for child in vbox.get_children():
		child.queue_free()

	# ── 图片（若存在）──
	var img_path: String = card.get("img", "")
	if img_path != "" and ResourceLoader.exists(img_path):
		var tex := load(img_path) as Texture2D
		if tex:
			var tr := TextureRect.new()
			tr.texture = tex
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(0, 180)
			vbox.add_child(tr)

	# ── 名称 ──
	var name_lbl := Label.new()
	name_lbl.text = card.get("name", "?")
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# ── 费用 / 类型 ──
	var type_map: Dictionary = {"follower": "单位", "spell": "法术", "equipment": "装备", "champion": "英雄"}
	var meta_lbl := Label.new()
	var type_str: String = type_map.get(card.get("type",""), card.get("type",""))
	var cost_str: String = "费用 %d" % card.get("cost", 0)
	var sch_cost: int = card.get("sch_cost", 0)
	var sch_type: String = card.get("sch_type", "")
	const _RUNE_SHORT: Dictionary = {"blazing":"炽烈","radiant":"灵光","verdant":"翠意","crushing":"摧破","chaos":"混沌","order":"序理"}
	var sch_str: String = "" if sch_cost == 0 else ("  +%d%s符能" % [sch_cost, _RUNE_SHORT.get(sch_type, sch_type)])
	meta_lbl.text = "%s · %s%s" % [type_str, cost_str, sch_str]
	meta_lbl.add_theme_font_size_override("font_size", 12)
	meta_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	meta_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(meta_lbl)

	# ── 战力/生命（单位/装备）──
	if card.get("atk", 0) > 0 or card.get("type", "") == "equipment":
		var stat_lbl := Label.new()
		var atk_val: int = GameState.get_atk(card) if card.has("uid") else card.get("atk", 0)
		var hp_val: int  = card.get("current_hp", card.get("atk", 0)) if card.has("uid") else card.get("atk", 0)
		stat_lbl.text = "战力 %d  /  生命 %d" % [atk_val, hp_val]
		stat_lbl.add_theme_font_size_override("font_size", 14)
		stat_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(stat_lbl)

	# ── 关键词 ──
	var kws: Array = card.get("keywords", [])
	if not kws.is_empty():
		var kw_lbl := Label.new()
		kw_lbl.text = "【" + "】【".join(kws) + "】"
		kw_lbl.add_theme_font_size_override("font_size", 12)
		kw_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		kw_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kw_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(kw_lbl)

	# ── 效果文字 ──
	var text_str: String = card.get("text", "")
	if text_str != "":
		var sep := HSeparator.new()
		vbox.add_child(sep)
		var text_lbl := Label.new()
		text_lbl.text = text_str
		text_lbl.add_theme_font_size_override("font_size", 11)
		text_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
		text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(text_lbl)

	# ── 故事文字 ──
	var lore_str: String = card.get("lore", "")
	if lore_str != "":
		var lore_lbl := Label.new()
		lore_lbl.text = lore_str
		lore_lbl.add_theme_font_size_override("font_size", 10)
		lore_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
		lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lore_lbl)

	# ── 关闭提示 ──
	var hint_lbl := Label.new()
	hint_lbl.text = "右键 / 点击任意处 关闭"
	hint_lbl.add_theme_font_size_override("font_size", 9)
	hint_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint_lbl)

	# 重新居中（内容填充后 size 可能变化）
	panel.set_anchors_preset(Control.PRESET_CENTER)
	_card_detail_overlay.visible = true


func _hide_card_detail() -> void:
	if _card_detail_overlay:
		_card_detail_overlay.visible = false


## 废牌堆查看器：点击墓地区域弹出卡牌列表，再右键任意牌可看详情
func _show_discard_viewer(side: String) -> void:
	if _card_detail_overlay == null:
		return
	var pile: Array = GameState.p_discard if side == "player" else GameState.e_discard
	var panel: PanelContainer = _card_detail_overlay.get_node("DetailPanel")
	var vbox: VBoxContainer    = panel.get_node("DetailVBox")
	for child in vbox.get_children():
		child.queue_free()

	# 标题
	var title := Label.new()
	title.text = ("我方" if side == "player" else "敌方") + " 废牌堆（%d张）" % pile.size()
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	if pile.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "（空）"
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty_lbl)
	else:
		# 滚动容器
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(280, 300)
		vbox.add_child(scroll)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 4)
		flow.add_theme_constant_override("v_separation", 4)
		scroll.add_child(flow)
		for c in pile:
			var cn := _mk_card_base(c, CW_HAND, CH_HAND)
			var _cr: Dictionary = c
			cn.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed:
					_show_card_detail(_cr))
			flow.add_child(cn)

	var hint := Label.new()
	hint.text = "右键查看卡片详情  |  点击任意处关闭"
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	panel.set_anchors_preset(Control.PRESET_CENTER)
	_card_detail_overlay.visible = true


## 将卡牌节点居中放置于英雄/传奇区
func _center_in_zone(node: Control, zone: Control, zone_w: int, zone_h: int) -> void:
	var cw := node.custom_minimum_size.x
	var ch := node.custom_minimum_size.y
	var cx := (zone_w - cw) / 2
	var cy := (zone_h - ch) / 2
	_set_abs(node, cx, cy, cw, ch)


## 符文按钮（玩家端）— 左键选「横置」，右键选「回收」，点确定才执行
func _mk_rune_btn(rune: Dictionary, _idx: int) -> Control:
	var rtype:  String = rune.get("rune_type", "blazing")
	var tapped: bool   = rune.get("tapped", false)
	var uid:    int    = rune.get("uid", -1)
	var rcolor: Color  = RUNE_COLORS.get(rtype, Color.GRAY)
	if tapped:
		rcolor = rcolor.darkened(0.5)

	var btn := Button.new()
	btn.text = RUNE_ABBR.get(rtype, "?")
	btn.custom_minimum_size = Vector2(RUNE_D, RUNE_D)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical   = Control.SIZE_SHRINK_CENTER

	var sbtn := StyleBoxFlat.new()
	sbtn.bg_color = rcolor
	sbtn.corner_radius_top_left     = RUNE_D / 2
	sbtn.corner_radius_top_right    = RUNE_D / 2
	sbtn.corner_radius_bottom_left  = RUNE_D / 2
	sbtn.corner_radius_bottom_right = RUNE_D / 2

	# 选中高亮描边：横置=金色，回收=蓝色（可同时选中两个列表）
	if uid in _rune_tap_uids or uid in _rune_recycle_uids:
		var bc := Color(0.3, 0.8, 1.0) if uid in _rune_recycle_uids else Color(1.0, 0.9, 0.2)
		sbtn.border_width_left   = 2; sbtn.border_width_right  = 2
		sbtn.border_width_top    = 2; sbtn.border_width_bottom = 2
		sbtn.border_color = bc

	btn.add_theme_stylebox_override("normal", sbtn)
	btn.add_theme_stylebox_override("hover",  sbtn)

	if tapped:
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	else:
		var _uid := uid
		var is_action := (GameState.turn == "player" and GameState.phase == "action")
		var is_summon := (GameState.turn == "player" and GameState.phase == "summon")
		# 左键 → 选横置（召出阶段 / 行动阶段均可）
		if is_action or is_summon:
			btn.pressed.connect(func(): _select_rune(_uid, "tap"))
		# 右键 → 选回收（仅行动阶段）
		if is_action:
			btn.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed \
						and ev.button_index == MOUSE_BUTTON_RIGHT:
					_select_rune(_uid, "recycle"))

	# 保留拖拽落点转发（出牌落入符文区）
	btn.set_drag_forwarding(
		func(_at): return null,
		func(_at, data): return _can_drop_play(data),
		func(_at, data): _drop_play_card(data))

	return btn


## 符文展示（AI侧，不可交互）— 与玩家符文相同圆形样式
func _mk_rune_display(rune: Dictionary, p_interactive: bool) -> Control:
	var rtype: String = rune.get("rune_type", "blazing")
	var tapped: bool  = rune.get("tapped", false)
	var rcolor: Color = RUNE_COLORS.get(rtype, Color.GRAY)
	if tapped:
		rcolor = rcolor.darkened(0.5)

	var btn := Button.new()
	btn.text = RUNE_ABBR.get(rtype, "?")
	btn.custom_minimum_size = Vector2(RUNE_D, RUNE_D)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # 防止水平拉伸成胶囊
	btn.size_flags_vertical   = Control.SIZE_SHRINK_CENTER  # 防止垂直拉伸成胶囊
	btn.disabled = true  # AI符文不可点击
	var sbtn := StyleBoxFlat.new()
	sbtn.bg_color = rcolor
	sbtn.corner_radius_top_left     = RUNE_D / 2
	sbtn.corner_radius_top_right    = RUNE_D / 2
	sbtn.corner_radius_bottom_left  = RUNE_D / 2
	sbtn.corner_radius_bottom_right = RUNE_D / 2
	btn.add_theme_stylebox_override("normal",   sbtn)
	btn.add_theme_stylebox_override("disabled", sbtn)
	if tapped:
		btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
	else:
		btn.add_theme_color_override("font_disabled_color", Color.WHITE)
	return btn


# ═══════════════════════════════════════════════
# 交互处理
# ═══════════════════════════════════════════════

func _on_hand_card_click(card: Dictionary) -> void:
	if GameState.turn != "player" or GameState.phase != "action":
		return
	if GameState.reaction_active:
		if GameState.reaction_turn != "player":
			_show_msg("现在是 AI 的反应窗口，请等待")
			return
		if not KeywordManager.can_play_in_timing(card, "time_point"):
			_show_msg("【%s】没有反应关键词，此时机无法打出" % card.get("name", "?"))
			return
	elif GameState.duel_active:
		if GameState.duel_turn != "player":
			_show_msg("现在是对手的对决回合，请等待")
			return
		if not KeywordManager.can_play_in_timing(card, "duel"):
			_show_msg("【%s】没有迅捷/反应关键词，对决中无法打出" % card.get("name", "?"))
			return
	if not SpellManager.can_play(card, "player"):
		var need: int = SpellManager.get_effective_cost(card, "player")
		var have: int = GameState.p_mana
		var untapped: int = GameState.p_runes.filter(func(r): return not r.get("tapped", false)).size()
		if have < need and untapped > 0:
			_show_msg("法力不足！请先点击【横置全部符文】获取法力（当前%d，需要%d，可横置%d枚符文）" % [have, need, untapped])
		else:
			_show_msg("资源不足，无法打出【%s】（法力%d/%d）" % [card.get("name", "?"), have, need])
		return

	if _sel_uid == card.get("uid", -2):
		_sel_uid     = -1
		_sel_card    = {}
		_target_mode = false
		_target_uids = []
		_show_msg("")
		_refresh_hand()
		return

	_sel_uid  = card.get("uid", -1)
	_sel_card = card

	if card.get("type", "") == "spell":
		var targets = SpellManager.get_spell_targets(card, "player")
		if targets != null and not targets.is_empty():
			_target_mode = true
			_target_uids = targets
			_show_msg("选择目标施放【%s】（点击目标单位）" % card.get("name", "?"))
			_refresh()
			return

	_target_mode = false
	_show_msg("请按【打出选中牌】按钮打出 【%s】" % card.get("name", "?"))
	_refresh_hand()


func _on_unit_click(card: Dictionary, p_owner: String, loc: String) -> void:
	# 敌方单位（非目标模式）→ 直接显示卡牌详情（对应 JS onClick = showCardPreview）
	if p_owner == "enemy" and not _target_mode:
		_show_card_detail(card)
		return

	if _target_mode:
		if card.get("uid", -2) in _target_uids:
			var c := _sel_card.duplicate()
			_exit_selection()
			await SpellManager.play_card(c, "player", card.get("uid", -1))
			if GameState.duel_active and GameState.duel_turn == "player":
				GameState.duel_skips = 0
				GameState.duel_turn = "enemy"
				GameState.emit_signal("duel_player_acted")
			elif GameState.reaction_active and GameState.reaction_turn == "player":
				GameState.emit_signal("reaction_player_acted")
		else:
			_show_msg("请选择高亮的合法目标，或重新点击手牌取消")
		return

	if _move_mode and loc == "bf":
		if _move_from_loc != "base" and p_owner == "player":
			if _move_unit.get("uid", -1) == card.get("uid", -2):
				_move_mode = false
				_move_unit = {}
				_move_from_loc = "base"
				_show_msg("")
				_refresh_battlefields()
		return

	if loc == "pbase" and p_owner == "player" and GameState.turn == "player" and GameState.phase == "action":
		# 装备牌：点击后触发装配流程（而非移动到战场）
		if card.get("type", "") == "equipment":
			await _activate_equipment(card)
			return
		if _move_unit.get("uid", -1) == card.get("uid", -2):
			_move_mode = false
			_move_unit = {}
			_move_from_loc = "base"
			_show_msg("")
		elif card.get("exhausted", false):
			# 规则140：标准移动费用=让单位进入休眠，已休眠则无法支付移动费用
			_show_msg("【%s】处于休眠状态，本回合无法移动（等下回合唤醒后再出击）" % card.get("name", "?"))
			return
		else:
			_move_mode = true
			_move_unit = card
			_move_from_loc = "base"
			_show_msg("选中【%s】→ 点「上战场1/2」部署，或再次点击取消" % card.get("name", "?"))
		_refresh_player_units()
		_refresh_battlefields()    # 绿光高亮战场面板
		_refresh_buttons()         # 显示/隐藏「上战场」按钮
		return

	if loc == "bf" and p_owner == "player" and GameState.turn == "player" and GameState.phase == "action":
		if GameState.has_keyword(card, "游走") and not card.get("exhausted", false):
			var source_bf_id: int = -1
			for b in GameState.bf:
				for u in b["pU"]:
					if u.get("uid", -1) == card.get("uid", -2):
						source_bf_id = b["id"]
			if source_bf_id == -1:
				return
			if _move_unit.get("uid", -1) == card.get("uid", -2):
				_move_mode = false
				_move_unit = {}
				_move_from_loc = "base"
				_show_msg("")
			else:
				_move_mode = true
				_move_unit = card
				_move_from_loc = str(source_bf_id)
				_show_msg("【游走】选中【%s】，点击目标战场" % card.get("name", "?"))
			_refresh_battlefields()
			_refresh_buttons()


func _on_bf_click(bf_id: int) -> void:
	if _move_mode and not _move_unit.is_empty():
		var u := _move_unit.duplicate()
		var from := _move_from_loc
		# 移动前记录目标战场是否无人控制（决定是否需要征服流程）
		var was_empty: bool = GameState.bf[bf_id - 1].get("ctrl") == null
		_move_mode = false
		_move_unit = {}
		_move_from_loc = "base"
		_show_msg("")
		CombatManager.move_unit(u, from, bf_id, "player")
		_refresh()
		if was_empty:
			# 规则 516.5.b + 630：空战场 → 法术对决 → 征服得分
			await CombatManager.trigger_empty_bf_conquer(bf_id, "player")
			_refresh()
		return
	if _target_mode:
		return


## 装配装备：点击基地装备 → 选单位 → 付符能费 → 附着
func _activate_equipment(equip: Dictionary) -> void:
	var effect: String = equip.get("effect", "")
	# 中娅沙漏：纯被动，无装配目标
	if effect == "death_shield":
		_show_msg("【%s】已在基地，等待自动触发（无需手动装配）" % equip.get("name", "?"))
		return

	var equip_sch_cost: int  = equip.get("equip_sch_cost", 0)
	var equip_sch_type: String = equip.get("equip_sch_type", "")
	# 检查符能是否足够
	if equip_sch_cost > 0:
		var have_sch: int = GameState.get_sch("player", equip_sch_type)
		if have_sch < equip_sch_cost:
			_show_msg("装配【%s】需要 %d %s符能，当前仅有 %d" % [
				equip.get("name","?"), equip_sch_cost, equip_sch_type, have_sch])
			return

	# 筛选基地中的可装配单位（非装备）
	var candidates: Array = GameState.p_base.filter(func(u): return u.get("type","") != "equipment")
	if candidates.is_empty():
		_show_msg("基地中无可装配的单位")
		return

	# 玩家选择目标单位
	var chosen_uid = await PromptManager.ask({
		"title": "装配装备",
		"msg": "选择一名基地单位装配【%s】（%s）" % [
			equip.get("name","?"),
			("消耗 %d %s符能" % [equip_sch_cost, equip_sch_type]) if equip_sch_cost > 0 else "无符能费用"],
		"type": "cards",
		"cards": candidates,
		"optional": true
	})
	if chosen_uid == null:
		return

	var eq_target: Dictionary = {}
	for u in candidates:
		if u.get("uid", -1) == chosen_uid:
			eq_target = u
			break
	if eq_target.is_empty():
		return

	# 支付装配符能费
	if equip_sch_cost > 0:
		GameState.spend_sch("player", equip_sch_type, equip_sch_cost)

	# 应用 ATK 加成
	var bonus: int = equip.get("atk_bonus", 0)
	if bonus > 0:
		eq_target["current_atk"] = eq_target.get("current_atk", 0) + bonus
		eq_target["current_hp"]  = eq_target.get("current_hp",  0) + bonus
		eq_target["atk"]         = eq_target.get("atk", 0) + bonus

	# 特殊标记
	if effect == "trinity_equip":
		eq_target["trinity_equipped"] = true
	elif effect == "guardian_equip":
		eq_target["guardian_equipped"] = true

	# 从基地移除装备，附着到目标
	var eq_uid: int = equip.get("uid", -1)
	GameState.p_base = GameState.p_base.filter(func(u): return u.get("uid",-1) != eq_uid)
	if not eq_target.get("attached_equipments"):
		eq_target["attached_equipments"] = []
	eq_target["attached_equipments"].append(equip)

	GameState._log("【装配】%s 装备了【%s】，战力+%d！" % [
		eq_target.get("name","?"), equip.get("name","?"), bonus], "imp")
	GameState.emit_signal("state_updated")


func _on_bf_attack(bf_id: int) -> void:
	if GameState.turn != "player" or GameState.phase != "action" or GameState.duel_active or GameState.reaction_active:
		return
	_exit_selection()
	_show_msg("战斗结算中...")
	await CombatManager.trigger_combat(bf_id, "player")
	_show_msg("")


func _on_legend_click(leg: Dictionary, p_owner: String) -> void:
	if p_owner != "player": return
	var ab: Dictionary = {}
	for a in GameState.p_leg.get("abilities", []):
		if a.get("type", "") == "active":
			ab = a
			break
	if ab.is_empty() or not LegendManager.can_use_legend_ability("player", ab):
		_show_msg("当前无法使用传奇技能（未到行动阶段、已休眠或对决时机不符）")
		return
	LegendManager.activate_legend_ability("player", ab.get("id", ""))
	# 对决或反应窗口中使用传奇技能视为"行动"，推进流程
	if GameState.duel_active and GameState.duel_turn == "player":
		GameState.duel_skips = 0
		GameState.duel_turn = "enemy"
		GameState.emit_signal("duel_player_acted")
	elif GameState.reaction_active and GameState.reaction_turn == "player":
		GameState.emit_signal("reaction_player_acted")


## 拖拽发起：返回 {card:...} 数据并设置幽灵预览
func _hand_get_drag(_card: Dictionary, _from_node: Control) -> Variant:
	# 拖拽出牌已禁用（窗口缩放时坐标偏移，改用点击+「打出选中牌」按钮）
	return null


## 拖拽落区：是否允许接收
func _can_drop_play(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var card: Dictionary = data.get("card", {})
	if card.is_empty():
		return false
	if GameState.turn != "player" or GameState.phase != "action":
		return false
	return SpellManager.can_play(card, "player")


## 拖拽落区：实际打出
func _drop_play_card(data: Variant) -> void:
	var card: Dictionary = data.get("card", {})
	if card.is_empty():
		return
	_dragging_card = {}
	_sel_uid  = card.get("uid", -1)
	_sel_card = card
	_play_selected()   # 内部有 await，作为独立协程运行


func _play_selected() -> void:
	if _sel_card.is_empty() or _sel_uid == -1:
		_show_msg("请先从手牌选择一张牌")
		return
	if GameState.turn != "player" or GameState.phase != "action":
		return
	var c := _sel_card.duplicate()

	if GameState.has_keyword(c, "待命"):
		var standby_bfs: Array = []
		for b in GameState.bf:
			if KeywordManager.can_deploy_standby(c, b["id"], "player"):
				standby_bfs.append(b)
		if not standby_bfs.is_empty():
			var bf_options: Array = []
			for b in standby_bfs:
				var bf_name: String = b.get("card", {}).get("name", "战场%d" % b["id"]) if b.get("card") != null else "战场%d" % b["id"]
				bf_options.append({"uid": b["id"], "name": "待命→" + bf_name})
			var res = await PromptManager.ask({
				"title": "待命部署",
				"msg": "【%s】可待命部署。选择战场或跳过（正常打出）：" % c.get("name", "?"),
				"type": "cards",
				"cards": bf_options,
				"optional": true
			})
			if res != null:
				var hand_idx: int = -1
				for i in range(GameState.p_hand.size()):
					if GameState.p_hand[i].get("uid", -1) == c.get("uid", -2):
						hand_idx = i
						break
				if hand_idx >= 0:
					GameState.p_hand.remove_at(hand_idx)
				_exit_selection()
				KeywordManager.deploy_standby(c, res, "player")
				return

	_exit_selection()
	_sfx("card_play")
	await SpellManager.play_card(c, "player")
	if GameState.duel_active and GameState.duel_turn == "player":
		GameState.duel_skips = 0
		GameState.duel_turn = "enemy"
		GameState.emit_signal("duel_player_acted")
	elif GameState.reaction_active and GameState.reaction_turn == "player":
		GameState.emit_signal("reaction_player_acted")


## 横置全部 / 确认已选符文（复用同一按钮）
func _tap_all_or_confirm() -> void:
	if not _rune_tap_uids.is_empty() or not _rune_recycle_uids.is_empty():
		_confirm_rune_action()
	else:
		_tap_all_runes()


func _tap_all_runes() -> void:
	if GameState.turn != "player": return
	# 直接批量横置，只发一次 state_updated，避免多次重绘卡顿
	var changed := false
	for r in GameState.p_runes:
		if not r.get("tapped", false):
			r["tapped"] = true
			GameState.p_mana += 1
			changed = true
	if changed:
		GameState._log("横置所有符文，+%d法力（共%d）" % [GameState.p_runes.size(), GameState.p_mana], "phase")
		GameState.emit_signal("state_updated")


## 构建符文操作确认浮层（在符文行顶部悬浮，默认隐藏）
func _build_rune_confirm_bar(px: int, py: int) -> void:
	var bar := PanelContainer.new()
	bar.visible = false
	bar.z_index = 30
	_set_abs(bar, px, py, GCW_CENTER, 28)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.18, 0.94)
	sb.corner_radius_top_left     = 4
	sb.corner_radius_top_right    = 4
	sb.corner_radius_bottom_left  = 4
	sb.corner_radius_bottom_right = 4
	sb.border_width_left = 1; sb.border_width_right  = 1
	sb.border_width_top  = 1; sb.border_width_bottom = 1
	sb.border_color = Color(0.6, 0.6, 0.9, 0.6)
	bar.add_theme_stylebox_override("panel", sb)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(lbl)
	_rune_confirm_lbl = lbl
	var ok_btn := Button.new()
	ok_btn.text = "✓ 确定"
	ok_btn.custom_minimum_size = Vector2(64, 0)
	ok_btn.add_theme_font_size_override("font_size", 11)
	ok_btn.pressed.connect(_confirm_rune_action)
	hbox.add_child(ok_btn)
	var cancel_btn := Button.new()
	cancel_btn.text = "✕ 取消"
	cancel_btn.custom_minimum_size = Vector2(64, 0)
	cancel_btn.add_theme_font_size_override("font_size", 11)
	cancel_btn.pressed.connect(_cancel_rune_action)
	hbox.add_child(cancel_btn)
	bar.add_child(hbox)
	_game_container.add_child(bar)
	_rune_confirm_bar = bar


## 选中/取消符文（左键=横置列表，右键=回收列表，再点同张同操作=取消）
func _select_rune(uid: int, action: String) -> void:
	if GameState.turn != "player": return
	if action == "tap"     and GameState.phase not in ["summon", "action"]: return
	if action == "recycle" and GameState.phase != "action": return
	if action == "tap":
		if uid in _rune_tap_uids:
			_rune_tap_uids.erase(uid)      # 再点 → 取消
		else:
			_rune_tap_uids.append(uid)
			_rune_recycle_uids.erase(uid)  # 同一张不能同时两个操作
	else:
		if uid in _rune_recycle_uids:
			_rune_recycle_uids.erase(uid)
		else:
			_rune_recycle_uids.append(uid)
			_rune_tap_uids.erase(uid)
	_update_tap_all_btn_text()
	_refresh_player_runes()


## 更新横置全部/确定按钮文字
func _update_tap_all_btn_text() -> void:
	if not _btn_tap_all: return
	var t := _rune_tap_uids.size()
	var r := _rune_recycle_uids.size()
	if t == 0 and r == 0:
		_btn_tap_all.text = "横置全部符文"
	else:
		var parts: Array = []
		if t > 0: parts.append("横置×%d" % t)
		if r > 0: parts.append("回收×%d" % r)
		_btn_tap_all.text = "✓ 确定（%s）" % "  ".join(parts)


## 确定执行所有已选符文操作
func _confirm_rune_action() -> void:
	if _rune_tap_uids.is_empty() and _rune_recycle_uids.is_empty(): return
	var taps     := _rune_tap_uids.duplicate()
	var recycles := _rune_recycle_uids.duplicate()
	# 先清状态，防止 state_updated 回调重入
	_rune_tap_uids.clear()
	_rune_recycle_uids.clear()
	if _btn_tap_all: _btn_tap_all.text = "横置全部符文"
	for uid in taps:
		GameState.tap_rune("player", uid)
	for uid in recycles:
		GameState.recycle_rune("player", uid)


## 取消全部符文选中
func _cancel_rune_action() -> void:
	_rune_tap_uids.clear()
	_rune_recycle_uids.clear()
	if _btn_tap_all: _btn_tap_all.text = "横置全部符文"
	_refresh_player_runes()


func _tap_rune(uid: int) -> void:
	if GameState.turn != "player": return
	GameState.tap_rune("player", uid)


func _recycle_rune(uid: int) -> void:
	if GameState.turn != "player" or GameState.phase != "action": return
	GameState.recycle_rune("player", uid)


func _end_turn() -> void:
	if GameState.turn != "player" or GameState.phase != "action": return
	_exit_selection()
	await GameState.player_end_turn()


func _duel_pass() -> void:
	if not GameState.duel_active or GameState.duel_turn != "player":
		return
	GameState.duel_skips += 1
	GameState.duel_turn = "enemy"
	GameState._log("你跳过对决。", "phase")
	GameState.emit_signal("state_updated")
	GameState.emit_signal("duel_player_acted")


func _reaction_pass() -> void:
	if not GameState.reaction_active or GameState.reaction_turn != "player":
		return
	GameState._log("你跳过反应。", "phase")
	GameState.emit_signal("state_updated")
	GameState.emit_signal("reaction_player_acted")


func _exit_selection() -> void:
	_sel_uid       = -1
	_sel_card      = {}
	_target_mode   = false
	_target_uids   = []
	_move_mode     = false
	_move_unit     = {}
	_move_from_loc = "base"
	_show_msg("")


# ═══════════════════════════════════════════════
# PromptManager 弹窗
# ═══════════════════════════════════════════════
func _on_prompt_requested(options: Dictionary) -> void:
	_close_prompt()
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.anchor_right  = 1.0
	overlay.anchor_bottom = 1.0
	overlay.z_index       = 100
	add_child(overlay)
	_prompt_overlay = overlay

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 180)
	_set_abs(panel, 440, 260, 400, 200)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = options.get("title", "选择")
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var msg: String = options.get("msg", "")
	if msg != "":
		var msg_lbl := Label.new()
		msg_lbl.text = msg
		msg_lbl.add_theme_font_size_override("font_size", 11)
		msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(msg_lbl)

	var prompt_type: String = options.get("type", "confirm")
	match prompt_type:
		"confirm":
			var hbox := HBoxContainer.new()
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.add_theme_constant_override("separation", 12)
			var btn_yes := _mk_button("确认", func(): _resolve_prompt(true))
			var btn_no  := _mk_button("取消", func(): _resolve_prompt(null))
			hbox.add_child(btn_yes); hbox.add_child(btn_no)
			vbox.add_child(hbox)
		"cards":
			var cards: Array = options.get("cards", [])
			var hbox := HBoxContainer.new()
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			for c in cards:
				var cb := _mk_button(c.get("name", "?"), func(): _resolve_prompt(c.get("uid")))
				hbox.add_child(cb)
			vbox.add_child(hbox)
			if options.get("optional", false):
				var skip_btn := _mk_button("跳过", func(): _resolve_prompt(null))
				vbox.add_child(skip_btn)
		_:
			var btn_ok := _mk_button("确认", func(): _resolve_prompt(true))
			vbox.add_child(btn_ok)


func _resolve_prompt(value) -> void:
	_close_prompt()
	PromptManager.resolve(value)


func _close_prompt() -> void:
	if _prompt_overlay != null and is_instance_valid(_prompt_overlay):
		_prompt_overlay.queue_free()
		_prompt_overlay = null


# ═══════════════════════════════════════════════
# 信号回调
# ═══════════════════════════════════════════════
func _on_log(text: String, category: String) -> void:
	if _log_rtl == null:
		return
	var col: String
	match category:
		"imp":    col = "#f9d71c"
		"combat": col = "#f87171"
		"score":  col = "#4ade80"
		"phase":  col = "#60a5fa"
		"spell":  col = "#c084fc"
		_:        col = "#c8c4b8"
	var prefix := match_log_prefix(category)
	_log_rtl.append_text("[color=%s]%s%s[/color]\n" % [col, prefix, text])


func match_log_prefix(cat: String) -> String:
	match cat:
		"imp":    return "▶ "
		"combat": return "⚔ "
		"score":  return "★ "
		"phase":  return "  "
		_:        return "  "


func _toggle_log() -> void:
	_log_collapsed = !_log_collapsed
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# 日志折叠时游戏区居中偏移 = (全屏宽 - 游戏区宽) / 2
	const CENTER_X := (1280 - BOARD_W) / 2   # = 140
	if _log_collapsed:
		# 日志面板完全滑出屏幕右侧
		tw.tween_property(_log_panel, "position:x", 1280.0, 0.28)
		# 游戏容器平移居中
		if _game_container:
			tw.tween_property(_game_container, "position:x", float(CENTER_X), 0.28)
		# 展开 Tab 按钮出现在右边缘
		if _log_tab_btn: _log_tab_btn.visible = true
		if _log_btn: _log_btn.text = "▶"
	else:
		# 日志面板归位
		tw.tween_property(_log_panel, "position:x", float(LOG_X), 0.28)
		# 游戏容器回到 x=0
		if _game_container:
			tw.tween_property(_game_container, "position:x", 0.0, 0.28)
		# 展开 Tab 按钮隐藏
		if _log_tab_btn: _log_tab_btn.visible = false
		if _log_btn:
			_log_btn.text     = "◀ 战斗记录"
			_log_btn.position = Vector2(2, 2)
			_log_btn.size     = Vector2(140, 26)


func _on_game_over(winner: String, msg: String) -> void:
	_sfx("victory" if winner == "player" else "defeat")
	_close_prompt()
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.anchor_right  = 1.0
	overlay.anchor_bottom = 1.0
	overlay.z_index       = 200
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 220)
	_set_abs(panel, 400, 250, 480, 220)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var win_lbl := Label.new()
	win_lbl.text = "游戏结束！" + ("玩家胜利" if winner == "player" else "AI胜利")
	win_lbl.add_theme_font_size_override("font_size", 20)
	win_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(win_lbl)

	var msg_lbl := Label.new()
	msg_lbl.text = msg
	msg_lbl.add_theme_font_size_override("font_size", 12)
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg_lbl)

	var btn_restart := _mk_button("再来一局", func(): _restart_game(overlay))
	btn_restart.custom_minimum_size = Vector2(160, 44)
	vbox.add_child(btn_restart)


func _restart_game(overlay: Control) -> void:
	overlay.queue_free()
	_log_lines.clear()
	if _log_rtl: _log_rtl.clear()
	_exit_selection()
	PromptManager.auto_mode = false
	GameState.start_game("kaisa", "masteryi")
	await _show_coin_flip()
	await _show_mulligan()
	await GameState.start_turn(GameState.first)


func _show_msg(text: String) -> void:
	if _msg_lbl != null:
		_msg_lbl.text = text


func _on_banner(text: String, style: String) -> void:
	if _banner_lbl == null:
		return
	# 根据样式决定颜色
	var col: Color
	if style.begins_with("score-player"):
		col = Color(0.2, 1.0, 0.4)   # 绿色：玩家得分
	elif style.begins_with("score-enemy"):
		col = Color(1.0, 0.35, 0.2)  # 红色：AI得分
	elif style == "duel":
		col = Color(1.0, 0.85, 0.1)  # 金色：法术对决
	else:
		col = Color(0.9, 0.9, 0.9)   # 白色：其他（回合提示等）
	_banner_lbl.add_theme_color_override("font_color", col)
	_banner_lbl.text    = text
	_banner_lbl.visible = true
	_banner_lbl.modulate.a = 1.0
	# 停止上一次的淡出动画
	if _banner_tween != null and _banner_tween.is_running():
		_banner_tween.kill()
	# 显示 1.5 秒后淡出
	_banner_tween = create_tween()
	_banner_tween.tween_interval(1.5)
	_banner_tween.tween_property(_banner_lbl, "modulate:a", 0.0, 0.5)
	_banner_tween.tween_callback(func(): _banner_lbl.visible = false)


# ═══════════════════════════════════════════════
# 辅助工具
# ═══════════════════════════════════════════════
func _card_color(card: Dictionary) -> Color:
	match card.get("type", ""):
		"spell":     return C_CARD_SPELL
		"equipment": return C_CARD_EQUIP
		_:
			if card.get("hero", false): return C_CARD_HERO
			if card.has("abilities"):   return C_CARD_LEG
			return C_CARD_FOLLOW


func _sch_str(side: String) -> String:
	var sch: Dictionary = GameState.p_sch if side == "player" else GameState.e_sch
	var parts: Array[String] = []
	for k in sch:
		if sch[k] > 0:
			parts.append("%s×%d" % [RUNE_ABBR.get(k, k[0]), sch[k]])
	return " ".join(parts) if not parts.is_empty() else "0"


func _set_panel_border(pc: PanelContainer, color: Color, width: int) -> void:
	var style := pc.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null: return
	style.border_color         = color
	style.border_width_top     = width
	style.border_width_bottom  = width
	style.border_width_left    = width
	style.border_width_right   = width


func _add_rect(parent: Node, color: Color, x: int, y: int, w: int, h: int) -> ColorRect:
	var cr := ColorRect.new()
	cr.color = color
	_set_abs(cr, x, y, w, h)
	parent.add_child(cr)
	return cr


func _add_label(parent: Node, text: String, size: int, color: Color, x: int, y: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.position = Vector2(x, y)
	parent.add_child(lbl)
	return lbl


func _add_hbox(parent: Node, sep: int, x: int, y: int, _unused: int, w: int, h: int) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", sep)
	_set_abs(hb, x, y, w, h)
	parent.add_child(hb)
	return hb


func _set_abs(node: Control, x: int, y: int, w: int, h: int) -> void:
	node.anchor_left   = 0.0
	node.anchor_top    = 0.0
	node.anchor_right  = 0.0
	node.anchor_bottom = 0.0
	node.offset_left   = x
	node.offset_top    = y
	node.offset_right  = x + w
	node.offset_bottom = y + h


func _mk_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(callback)
	return btn


func _clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


# ═══════════════════════════════════════════════
# [M5] 动画系统
# ═══════════════════════════════════════════════

## 单位入场动画：缩放弹入 + 淡入 + 粒子爆破
func _anim_enter(node: Control) -> void:
	# 先用 custom_minimum_size 做 pivot（layout 完成前 size 为 0）
	var half := node.custom_minimum_size / 2.0 if node.custom_minimum_size != Vector2.ZERO else Vector2(32.0, 45.0)
	node.pivot_offset = half
	node.scale        = Vector2(0.3, 0.3)
	node.modulate.a   = 0.0
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1.15, 1.15), 0.22)\
	  .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(1.0, 1.0), 0.12)\
	  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(node, "modulate:a", 1.0, 0.20)
	# 延迟一帧后在世界坐标创建粒子（确保 layout 完成）
	(func(): _spawn_burst(node)).call_deferred()


## CPUParticles2D 金色爆破（入场、得分等关键时刻）
func _spawn_burst(node: Control, burst_color: Color = Color(0.98, 0.82, 0.15)) -> void:
	if not is_instance_valid(node):
		return
	var p := CPUParticles2D.new()
	p.emitting          = false
	p.one_shot          = true
	p.explosiveness     = 0.95
	p.amount            = 40
	p.lifetime          = 1.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 240.0
	p.spread            = 180.0
	p.gravity           = Vector2(0.0, 280.0)
	p.scale_amount_min  = 3.0
	p.scale_amount_max  = 7.0
	p.color             = burst_color
	p.z_index           = 200
	# 用 global_position：layout 完成后 node.size 才有效，优先用 custom_minimum_size
	var sz := node.size if node.size != Vector2.ZERO else node.custom_minimum_size
	p.global_position   = node.global_position + sz * 0.5
	add_child(p)
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(p): p.queue_free()
	)


## 分数弹跳动画（得分时调用 label）
func _anim_score_bounce(lbl: Label) -> void:
	if not is_instance_valid(lbl): return
	lbl.pivot_offset = lbl.size / 2.0
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "scale", Vector2(1.5, 1.5), 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_IN)


## ── 得分事件处理（弹跳 + 粒子 + 音效）──
func _on_score_changed(ps: int, es: int) -> void:
	_sfx("score")
	_refresh()
	var win := GameState.win_score
	# 玩家得分
	if ps > _prev_p_score:
		for v in range(_score_circles_p.size()):
			if (win - v) == ps:
				_anim_score_bounce(_score_circles_p[v])
				_spawn_burst(_score_circles_p[v], Color(0.2, 1.0, 0.35))
				break
	# AI 得分
	if es > _prev_e_score:
		for v in range(_score_circles_e.size()):
			if v == es:
				_anim_score_bounce(_score_circles_e[v])
				_spawn_burst(_score_circles_e[v], Color(1.0, 0.3, 0.2))
				break
	_prev_p_score = ps
	_prev_e_score = es


## ── 战斗开始：攻击方金色闪，防御方红色闪 + 屏幕震动 ──
func _on_combat_start(bf_id: int, attacker: String) -> void:
	var idx := bf_id - 1
	if idx < 0 or idx >= _bf_pu.size(): return
	var atk_row := _bf_pu[idx] if attacker == "player" else _bf_eu[idx]
	var def_row := _bf_eu[idx] if attacker == "player" else _bf_pu[idx]
	for child: CanvasItem in atk_row.get_children():
		_flash_node(child, Color(1.8, 1.6, 0.5))   # 金色 = 攻击方
	for child: CanvasItem in def_row.get_children():
		_flash_node(child, Color(2.0, 0.35, 0.35))  # 红色 = 受击方
	_anim_screen_shake()
	_sfx("combat")


## 单节点色彩闪烁（modulate 闪白后复原）
func _flash_node(node: CanvasItem, flash_col: Color) -> void:
	if not is_instance_valid(node): return
	var tw := node.create_tween()
	tw.tween_property(node, "modulate", flash_col, 0.06)
	tw.tween_property(node, "modulate", Color.WHITE, 0.08)
	tw.tween_property(node, "modulate", flash_col * 0.8, 0.06)
	tw.tween_property(node, "modulate", Color.WHITE, 0.40)


# ═══════════════════════════════════════════════
# [M7] BGM 系统
# ═══════════════════════════════════════════════

func _start_bgm() -> void:
	var bgm_res: AudioStream = load("res://assets/bgm.m4a")
	if bgm_res == null:
		push_warning("[GameBoard] BGM 加载失败：res://assets/bgm.m4a")
		return
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.stream    = bgm_res
	_bgm_player.volume_db = -14.0
	_bgm_player.autoplay  = false
	add_child(_bgm_player)
	_bgm_player.play()


# ═══════════════════════════════════════════════
# M1：硬币先后手动画 + Mulligan 重置牌
# ═══════════════════════════════════════════════

func _show_coin_flip() -> void:
	# ── 全屏半透明覆盖层 ──
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.88)
	_set_abs(overlay, 0, 0, 1280, 720)
	overlay.z_index = 400
	add_child(overlay)

	# ── 决定先后手 ──
	var player_first: bool = (randi() % 2 == 0)
	GameState.first = "player" if player_first else "enemy"
	GameState.turn  = GameState.first

	# ── 硬币图片 ──
	var coin_rect := TextureRect.new()
	coin_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_rect.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	coin_rect.custom_minimum_size = Vector2(200, 200)
	_set_abs(coin_rect, 540, 200, 200, 200)
	overlay.add_child(coin_rect)

	var tex_front: Texture2D = null
	var tex_back:  Texture2D = null
	if ResourceLoader.exists("res://assets/coins/xianshou.png"):
		tex_front = load("res://assets/coins/xianshou.png")
	if ResourceLoader.exists("res://assets/coins/houshou.png"):
		tex_back = load("res://assets/coins/houshou.png")

	# 初始显示"正在抛掷…"状态（中间过渡贴图）
	if tex_front != null:
		coin_rect.texture = tex_front

	# ── 提示文字 ──
	var hint_lbl := Label.new()
	hint_lbl.text = "正在抛掷硬币…"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 18)
	hint_lbl.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5))
	_set_abs(hint_lbl, 340, 160, 600, 36)
	overlay.add_child(hint_lbl)

	var result_lbl := Label.new()
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.add_theme_font_size_override("font_size", 22)
	result_lbl.modulate.a = 0.0
	_set_abs(result_lbl, 240, 430, 800, 50)
	overlay.add_child(result_lbl)

	# ── Tween 翻转动画（Y 轴缩放 1→0→1，中途换面）──
	var tw := create_tween()
	tw.tween_property(coin_rect, "scale:y", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		# 换为结果面
		if player_first:
			if tex_front != null: coin_rect.texture = tex_front
		else:
			if tex_back != null: coin_rect.texture = tex_back
	)
	tw.tween_property(coin_rect, "scale:y", 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished

	# ── 显示结果 ──
	if player_first:
		result_lbl.text = "⚔ 硬币落地！【你是先手】"
		result_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	else:
		result_lbl.text = "🛡 硬币落地！【AI 是先手】"
		result_lbl.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))

	var tw2 := create_tween()
	tw2.tween_property(result_lbl, "modulate:a", 1.0, 0.4)
	await tw2.finished
	await get_tree().create_timer(1.6).timeout

	overlay.queue_free()
	GameState._log("游戏开始！%s" % ("你是先手方" if player_first else "AI是先手方"), "imp")


func _show_mulligan() -> void:
	var hand := GameState.p_hand
	if hand.is_empty():
		return

	# ── 全屏覆盖层 ──
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0.02, 0.05, 0.92)
	_set_abs(overlay, 0, 0, 1280, 720)
	overlay.z_index = 400
	add_child(overlay)

	# ── 标题 ──
	var title_lbl := Label.new()
	title_lbl.text = "【调度阶段】选择最多 2 张放回牌库底重抽（可不换）"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.5))
	_set_abs(title_lbl, 100, 80, 1080, 36)
	overlay.add_child(title_lbl)

	# ── 传奇名称提示 ──
	var leg_name: String = GameState.p_leg.get("name", "?") if not GameState.p_leg.is_empty() else "?"
	var leg_lbl := Label.new()
	leg_lbl.text = "你的传奇：【%s】" % leg_name
	leg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leg_lbl.add_theme_font_size_override("font_size", 13)
	leg_lbl.add_theme_color_override("font_color", Color(0.6, 0.5, 0.35))
	_set_abs(leg_lbl, 100, 122, 1080, 28)
	overlay.add_child(leg_lbl)

	# ── 手牌展示（横排） ──
	var card_count := hand.size()
	var card_w := 110
	var card_h := 150
	var gap := 20
	var total_w := card_count * card_w + (card_count - 1) * gap
	var start_x := (1280 - total_w) / 2
	var card_y := 200

	var selected_indices: Array[int] = []
	var card_nodes: Array[PanelContainer] = []

	for i in range(card_count):
		var card: Dictionary = hand[i]
		var cn := _mk_card_base(card, card_w, card_h)
		_set_abs(cn, start_x + i * (card_w + gap), card_y, card_w, card_h)
		overlay.add_child(cn)
		card_nodes.append(cn)

		# 点击切换选中（同步更新 counter_lbl，在 card 循环外定义后传入）
		var idx := i
		cn.gui_input.connect(func(ev: InputEvent):
			if not (ev is InputEventMouseButton): return
			if not (ev as InputEventMouseButton).pressed: return
			if (ev as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT: return
			if idx in selected_indices:
				selected_indices.erase(idx)
			elif selected_indices.size() < 2:
				selected_indices.append(idx)
			# 更新高亮
			for j in range(card_nodes.size()):
				var st := card_nodes[j].get_theme_stylebox("panel") as StyleBoxFlat
				if st:
					if j in selected_indices:
						st.border_color = Color(1.0, 0.85, 0.1)
						st.border_width_top = 3; st.border_width_bottom = 3
						st.border_width_left = 3; st.border_width_right = 3
					else:
						st.border_color = Color(0, 0, 0, 0)
						st.border_width_top = 0; st.border_width_bottom = 0
						st.border_width_left = 0; st.border_width_right = 0
		)

	# ── 计数器 ──
	var counter_lbl := Label.new()
	counter_lbl.text = "已选 0 / 2 张"
	counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_lbl.add_theme_font_size_override("font_size", 13)
	counter_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_set_abs(counter_lbl, 340, 370, 600, 30)
	overlay.add_child(counter_lbl)

	# 补充卡片点击时更新 counter_lbl
	for cn2 in card_nodes:
		cn2.gui_input.connect(func(_ev: InputEvent):
			counter_lbl.text = "已选 %d / 2 张" % selected_indices.size()
		)

	# ── 确认按钮 ──
	var confirm_btn := Button.new()
	confirm_btn.text = "确定换牌"
	confirm_btn.add_theme_font_size_override("font_size", 16)
	_set_abs(confirm_btn, 540, 420, 200, 48)
	overlay.add_child(confirm_btn)

	# ── 等待确认（直接 await 信号，避免 bool 闭包捕获问题）──
	await confirm_btn.pressed

	overlay.queue_free()

	# ── 执行换牌 ──
	if not selected_indices.is_empty():
		# 倒序处理，避免索引偏移
		var sorted_sel := selected_indices.duplicate()
		sorted_sel.sort()
		sorted_sel.reverse()
		var shelved: Array = []
		for idx in sorted_sel:
			shelved.append(GameState.p_hand[idx])
			GameState.p_hand.remove_at(idx)
		# 从牌库顶补抽
		for _i in range(shelved.size()):
			if not GameState.p_deck.is_empty():
				GameState.p_hand.append(GameState.p_deck.pop_back())
		# 搁置的牌放到牌库底
		for c in shelved:
			GameState.p_deck.insert(0, c)
		GameState._log("调度完成：换了 %d 张牌" % shelved.size(), "phase")
	else:
		GameState._log("调度完成：保留初始手牌", "phase")


# ═══════════════════════════════════════════════
# [EXP] 体验层扩展：屏幕震动 / 伤害浮字 / 点击涟漪 / 粒子背景 / SFX / 手牌入场
# ═══════════════════════════════════════════════

## 屏幕轻微震动（战斗时调用）
func _anim_screen_shake() -> void:
	if _game_container == null:
		return
	var origin := _game_container.position
	var tw := create_tween()
	tw.tween_property(_game_container, "position", origin + Vector2(6, 2), 0.05)
	tw.tween_property(_game_container, "position", origin + Vector2(-5, -1), 0.05)
	tw.tween_property(_game_container, "position", origin + Vector2(4, 1), 0.04)
	tw.tween_property(_game_container, "position", origin + Vector2(-3, 0), 0.04)
	tw.tween_property(_game_container, "position", origin, 0.04)


## 浮动伤害数字（从目标位置向上飘）
func _spawn_damage_text(pos: Vector2, amount: int, is_leg: bool) -> void:
	var lbl := Label.new()
	lbl.text = "-%d" % amount
	lbl.add_theme_font_size_override("font_size", 30 if is_leg else 22)
	var col := Color(1.0, 0.95, 0.2) if is_leg else Color(1.0, 0.25, 0.25)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.position = pos
	lbl.z_index  = 250
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	# 先放大弹出，再飘上淡出
	var tw := lbl.create_tween()
	lbl.pivot_offset = lbl.size / 2
	lbl.scale = Vector2(1.6, 1.6)
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "position:y", pos.y - 85, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.35)
	tw.tween_callback(lbl.queue_free)


## 估算单位的大致屏幕坐标（用于伤害浮字定位）
func _estimate_unit_screen_pos(uid: int, is_leg: bool) -> Vector2:
	if is_leg:
		return Vector2(180, BOARD_Y + GRY5 + 30)  # 我方传奇/英雄区估算
	for u in GameState.p_base:
		if u.get("uid", -1) == uid:
			return Vector2(GX4 + 50, BOARD_Y + GRY5 + 32)
	for u in GameState.e_base:
		if u.get("uid", -1) == uid:
			return Vector2(GX4 + 50, BOARD_Y + GRY1 + 32)
	for b in GameState.bf:
		var bfcx := GX4 + int((b["id"] - 1) * (GCW_CENTER / 2.0 + GC_GAP)) + GCW_CENTER / 4
		for u in b.get("pU", []):
			if u.get("uid", -1) == uid:
				return Vector2(bfcx, BOARD_Y + GRY3 + int(GRH3 * 0.75))
		for u in b.get("eU", []):
			if u.get("uid", -1) == uid:
				return Vector2(bfcx, BOARD_Y + GRY3 + int(GRH3 * 0.25))
	return Vector2(500, 360)


## 单位受伤信号回调（显示浮动伤害数字 + 音效）
func _on_unit_damaged(uid: int, amount: int, is_leg: bool) -> void:
	_sfx("damage")
	var pos := _estimate_unit_screen_pos(uid, is_leg)
	# 小幅随机偏移，避免多段伤害堆叠
	pos += Vector2(randf_range(-12, 12), randf_range(-8, 8))
	_spawn_damage_text(pos, amount, is_leg)


## 鼠标点击涟漪（双环扩散：内圈亮金 + 外圈蓝）
func _spawn_click_ripple(pos: Vector2) -> void:
	# 内圈：亮金色，小快
	var r1 := ColorRect.new()
	r1.size = Vector2(18, 18)
	r1.color = Color(0.98, 0.88, 0.42, 0.90)
	r1.position = pos - r1.size / 2
	r1.z_index = 90
	r1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r1.pivot_offset = r1.size / 2
	add_child(r1)
	var tw1 := r1.create_tween()
	tw1.tween_property(r1, "scale", Vector2(5.5, 5.5), 0.32).set_ease(Tween.EASE_OUT)
	tw1.parallel().tween_property(r1, "modulate:a", 0.0, 0.32)
	tw1.tween_callback(r1.queue_free)
	# 外圈：蓝白色，大慢
	var r2 := ColorRect.new()
	r2.size = Vector2(30, 30)
	r2.color = Color(0.50, 0.78, 1.0, 0.70)
	r2.position = pos - r2.size / 2
	r2.z_index = 89
	r2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r2.pivot_offset = r2.size / 2
	add_child(r2)
	var tw2 := r2.create_tween()
	tw2.tween_property(r2, "scale", Vector2(7.0, 7.0), 0.55).set_ease(Tween.EASE_OUT)
	tw2.parallel().tween_property(r2, "modulate:a", 0.0, 0.55)
	tw2.tween_callback(r2.queue_free)


## 手牌新摸入场动画（缩放弹入 + 淡入，按顺序错开）
func _anim_hand_enter(node: Control, idx: int) -> void:
	# 使用 custom_minimum_size 作为 pivot，因为 layout 尚未运行时 size 为 (0,0)
	var half := node.custom_minimum_size / 2.0 if node.custom_minimum_size != Vector2.ZERO else Vector2(37.5, 50.0)
	node.pivot_offset = half
	node.scale        = Vector2(0.65, 0.65)
	node.modulate.a   = 0.0
	var tw := node.create_tween()
	tw.tween_interval(idx * 0.055)
	tw.tween_property(node, "scale", Vector2(1.0, 1.0), 0.28)\
	  .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(node, "modulate:a", 1.0, 0.22)


## 背景粒子系统（金色 + 蓝色漂浮光点，低透明度环境效果）
func _build_particle_bg() -> void:
	# z_index=8：浮在所有游戏UI(z=0)之上，低于弹窗(z=100+)
	# 金色主粒子
	var p := CPUParticles2D.new()
	p.z_index          = 8
	p.emitting          = true
	p.amount            = 35
	p.lifetime          = 10.0
	p.preprocess        = 5.0
	p.direction         = Vector2(0.12, -1.0)
	p.spread            = 42.0
	p.gravity           = Vector2(0.0, -6.0)
	p.initial_velocity_min = 15.0
	p.initial_velocity_max = 38.0
	p.scale_amount_min  = 1.5
	p.scale_amount_max  = 4.0
	p.color             = Color(1.0, 0.85, 0.22, 0.45)
	p.emission_shape    = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(500, 360)
	p.position          = Vector2(500, 360)
	add_child(p)
	# 蓝色次粒子
	var p2 := CPUParticles2D.new()
	p2.z_index          = 8
	p2.emitting          = true
	p2.amount            = 18
	p2.lifetime          = 13.0
	p2.preprocess        = 6.0
	p2.direction         = Vector2(-0.08, -1.0)
	p2.spread            = 30.0
	p2.gravity           = Vector2(0.0, -4.0)
	p2.initial_velocity_min = 10.0
	p2.initial_velocity_max = 26.0
	p2.scale_amount_min  = 1.0
	p2.scale_amount_max  = 3.0
	p2.color             = Color(0.28, 0.55, 1.0, 0.32)
	p2.emission_shape    = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p2.emission_rect_extents = Vector2(500, 360)
	p2.position          = Vector2(500, 360)
	add_child(p2)


## SFX 音效（AudioStreamGenerator 程序化生成音调，无需外部音频文件）
func _sfx(note: String) -> void:
	const FREQ: Dictionary = {
		"card_play": 600.0, "draw": 420.0, "rune": 510.0, "combat": 220.0,
		"spell": 650.0, "score": 860.0, "damage": 190.0, "coin": 540.0,
		"victory": 1040.0, "defeat": 140.0, "error": 175.0
	}
	const DUR: Dictionary = {
		"card_play": 0.10, "draw": 0.07, "rune": 0.07, "combat": 0.20,
		"spell": 0.13, "score": 0.16, "damage": 0.14, "coin": 0.24,
		"victory": 0.55, "defeat": 0.55, "error": 0.13
	}
	var freq: float = FREQ.get(note, 440.0)
	var dur:  float = DUR.get(note, 0.1)
	var gen := AudioStreamGenerator.new()
	gen.mix_rate      = 22050.0
	gen.buffer_length = dur + 0.04
	var player := AudioStreamPlayer.new()
	player.stream    = gen
	player.volume_db = -10.0
	add_child(player)
	player.play()
	var pb := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		player.queue_free()
		return
	var frames := int(gen.mix_rate * dur)
	for fi in range(frames):
		var t: float   = float(fi) / gen.mix_rate
		var env: float = exp(-t * 9.0)
		var sample: float = sin(TAU * freq * t) * env * 0.28
		pb.push_frame(Vector2(sample, sample))
	get_tree().create_timer(dur + 0.12).timeout.connect(func():
		if is_instance_valid(player): player.queue_free()
	)
