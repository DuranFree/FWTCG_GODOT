extends Node
# ═══════════════════════════════════════════════
# GameState.gd — 游戏全局状态 + 工具函数 (Autoload 单例)
# 对应 engine.js 中的 G 对象和全局工具函数
# 阶段二版本：加入游戏初始化、回合流程、得分系统
# ═══════════════════════════════════════════════

# ── 信号（替代 JS 中的 render() / setMsg() / showDuelBanner() / log()）──
signal state_updated                              ## 通用"重新渲染"信号（对应 JS render()）
signal score_changed(p: int, e: int)              ## 得分变化
signal game_over_signal(winner: String, msg: String) ## 游戏结束
signal log_entry(text: String, category: String) ## 游戏日志
signal phase_changed(new_phase: String)           ## 阶段切换
signal banner_shown(text: String, style: String)  ## 横幅提示（据守/征服/对决）
signal turn_started(who: String)                  ## 回合开始
signal action_phase_started(who: String)          ## 行动阶段（玩家/AI）
signal duel_player_acted                           ## 玩家在对决中行动（出牌或跳过）
signal reaction_player_acted                       ## 玩家在法术反应窗口中行动（出牌或跳过反应）
signal unit_damaged(uid: int, amount: int, is_leg: bool)  ## 单位受伤（供 GameBoard 显示浮动数字）

# ── UID 计数器（对应 JS 中的全局 uid 变量）──
var _uid_counter: int = 0

# ── 胜利分数上限（可被攀圣长阶修改）──
var win_score: int = 8

# ── 积分 ──
var p_score: int = 0
var e_score: int = 0

# ── 牌组/手牌/废牌堆 ──
var p_deck: Array = []       # 玩家主牌堆（从尾部取牌）
var e_deck: Array = []
var p_discard: Array = []    # 废牌堆
var e_discard: Array = []
var p_hand: Array = []       # 手牌（无上限，规则107.6）
var e_hand: Array = []

# ── 符文系统 ──
var p_rune_deck: Array = []  # 符文牌库（抽出后放入 p_runes）
var e_rune_deck: Array = []
var p_runes: Array = []      # 场上已召出的符文
var e_runes: Array = []

# ── 基地与战场单位 ──
var p_base: Array = []       # 玩家基地单位
var e_base: Array = []
var bf: Array = [            # 两块战场（对应 G.bf）
	{ "id": 1, "pU": [], "eU": [], "ctrl": null, "conq_done": false, "standby": null, "card": null },
	{ "id": 2, "pU": [], "eU": [], "ctrl": null, "conq_done": false, "standby": null, "card": null }
]

# ── 战场牌池 ──
var p_bf_pool: Array = []    # 玩家选战场时的候选池
var e_bf_pool: Array = []

# ── 法力 ──
var p_mana: int = 0
var e_mana: int = 0

# ── 符能（法术符文能量，对应 pSch/eSch）──
var p_sch: Dictionary = { "blazing": 0, "radiant": 0, "verdant": 0, "crushing": 0, "chaos": 0, "order": 0 }
var e_sch: Dictionary = { "blazing": 0, "radiant": 0, "verdant": 0, "crushing": 0, "chaos": 0, "order": 0 }

# ── 传奇卡（场上唯一的传奇单位）──
var p_leg: Dictionary = {}   # 空 dict 表示不在场
var e_leg: Dictionary = {}

# ── 英雄卡（英雄区专属位置）──
var p_hero: Dictionary = {}
var e_hero: Dictionary = {}

# ── 回合状态 ──
var round: int = 1
var turn: String = "player"  # "player" 或 "enemy"
var first: String = "player" # 先手方
var phase: String = "init"   # 当前阶段

# ── 首回合标记 ──
var p_first_turn_done: bool = false
var e_first_turn_done: bool = false

# ── 交互状态 ──
var sel_card_from_hero: bool = false
var sel_fail_uid: int = -1
var sel_unit = null          # 已选中的单位 Dictionary
var sel_units: Array = []    # 多选单位（基地联合移动）
var sel_card = null          # 已选中的手牌
var sel_card_idx: int = -1
var pending_deploy = null    # 等待部署的单位
var deploy_choosing: bool = false
var pending_runes: Array = []
var pending_move = null      # { units: Array, to_bf: int }

# ── 法术目标系统 ──
var spell_targeting: bool = false
var spell_target_pool: Array = []
var sel_spell_target_uid: int = -1

# ── 异步交互锁 ──
var prompting: bool = false

# ── 对决系统 ──
var mul_sel: Array = []
var dmg_dealt: Dictionary = { "p": 0, "e": 0 }
var game_over: bool = false
var duel_active: bool = false
var duel_bf = null
var duel_attacker: String = ""
var duel_turn: String = ""
var duel_skips: int = 0
var last_player_spell_cost: int = 0
var last_spell_target_uid: int = -1   ## 最后施放法术的目标 uid（供 negate_spell 检查）

# ── 法术反应窗口（规则 725：反应牌可响应对手法术）──
var reaction_active: bool = false  ## 当前是否处于法术反应窗口
var reaction_turn: String = ""     ## 当前可反应的一方（"player" 或 "enemy"）
var spell_countered: bool = false  ## 当前法术是否被反制

# ── 回合得分追踪 ──
var bf_scored_this_turn: Array = []
var bf_conquered_this_turn: Array = []

# ── 盟友增益追踪 ──
var p_next_ally_buff: int = 0   # 下一个盟友入场时获得的额外增益
var e_next_ally_buff: int = 0
var p_ally_dmg_dealt: int = 0   # 盟友累计造伤
var e_ally_dmg_dealt: int = 0

# ── 本回合出牌计数 ──
var cards_played_this_turn: int = 0

# ── 卡牌锁定（颠覆者·布隆希尔）──
var card_lock_target: String = ""  # "" 表示无锁定

# ── 时间扭曲额外回合 ──
var extra_turn_pending: bool = false

# ── 迎敌号令（本回合单位以活跃状态进场）──
var p_rally_active: bool = false
var e_rally_active: bool = false

# ── 缇亚娜·冕卫在场计数 ──
var p_tiyana_on_field: int = 0
var e_tiyana_on_field: int = 0

# ── 反应窗口 ──
var reaction_window_open: bool = false
var reaction_window_for: String = ""

# ── 回合计时器（秒）──
var turn_timer_seconds: int = 30

# ═══════════════════════════════════════════════
# 工具函数（对应 engine.js 中的全局工具函数）
# ═══════════════════════════════════════════════

## ensure_uid(card) — 确保卡牌有 uid（手牌显示/选中追踪用）
## 原始模板没有 uid，draw 时调用以保证唯一性
func ensure_uid(card: Dictionary) -> void:
	if not card.has("uid") or card.get("uid", -1) <= 0:
		_uid_counter += 1
		card["uid"] = _uid_counter


## mk(template) — 从卡牌模板创建单位实例（对应 JS mk()）
## 注意：currentHp 初始化为 atk 值（非 hp），这与 JS 原版一致
## 传奇的持久 HP 在 main.js 中单独初始化为 hp 字段值
func mk(template: Dictionary) -> Dictionary:
	_uid_counter += 1
	var unit: Dictionary = template.duplicate(true)
	var base_atk: int = template.get("atk", 0)
	unit["uid"] = _uid_counter
	unit["current_hp"] = base_atk      # 与 JS 原版一致：初始化为 atk
	unit["current_atk"] = base_atk
	unit["exhausted"] = false
	unit["stunned"] = false
	unit["tb"] = { "atk": 0 }          # 临时增益（本回合有效）
	unit["buff_token"] = false          # 增益指示物
	unit["attached_equipments"] = []    # 已装配的装备
	return unit

## mk_legend(template) — 创建传奇单位（HP 初始化为 hp 字段，不是 atk）
func mk_legend(template: Dictionary) -> Dictionary:
	var unit: Dictionary = mk(template)
	unit["current_hp"] = template.get("hp", template.get("atk", 0))  # 传奇用 hp
	return unit

## mk_rune(type) — 创建符文实例（对应 JS mkRune()）
func mk_rune(type: String = "blazing") -> Dictionary:
	_uid_counter += 1
	return { "uid": _uid_counter, "tapped": false, "rune_type": type }

## shuffle_array(arr) — 原地随机洗牌（对应 JS shuffle()）
## 使用 Fisher-Yates 算法，与 JS 版本相同
func shuffle_array(arr: Array) -> Array:
	arr.shuffle()
	return arr

## get_atk(unit) — 获取单位当前有效战力（对应 JS atk()）
## 包含临时增益 tb.atk，最低为 1
func get_atk(unit: Dictionary) -> int:
	var base: int = unit.get("current_atk", unit.get("atk", 0))
	var tb_atk: int = unit.get("tb", {}).get("atk", 0)
	return max(1, base + tb_atk)

## is_powerful(unit) — 判断单位是否为【强力】（战力≥5）
func is_powerful(unit: Dictionary) -> bool:
	return get_atk(unit) >= 5

## apply_buff_token(unit) — 给单位施加增益指示物（+1战力）
## 对应 JS applyBuffToken()，无法叠加
func apply_buff_token(unit: Dictionary) -> bool:
	if unit.get("buff_token", false):
		push_warning("GameState.apply_buff_token: " + unit.get("name","?") + " 已有增益指示物，无法叠加")
		return false
	unit["buff_token"] = true
	unit["current_atk"] = unit.get("current_atk", 0) + 1
	unit["current_hp"]  = unit.get("current_hp", 0)  + 1
	return true

## get_all_units(owner) — 获取某方所有单位（基地+所有战场）
## 对应 JS getAllUnits()，排除 equipment 类型
func get_all_units(owner: String) -> Array:
	var result: Array = []
	var base: Array = p_base if owner == "player" else e_base
	for u in base:
		if u.get("type", "") != "equipment":
			result.append(u)
	for b in bf:
		var zone: Array = b["pU"] if owner == "player" else b["eU"]
		result.append_array(zone)
	return result

## get_sch(owner, type) — 获取符能数量（对应 JS getSch()）
## 若 type 为空字符串，返回总符能数
func get_sch(owner: String, type: String = "") -> int:
	var sch: Dictionary = p_sch if owner == "player" else e_sch
	if type == "":
		var total: int = 0
		for v in sch.values():
			total += v
		return total
	return sch.get(type, 0)

## add_sch(owner, type, n) — 增加符能（对应 JS addSch()）
func add_sch(owner: String, type: String, n: int = 1) -> void:
	var sch: Dictionary = p_sch if owner == "player" else e_sch
	sch[type] = sch.get(type, 0) + n

## spend_sch(owner, type, n) — 消耗符能（对应 JS spendSch()）
func spend_sch(owner: String, type: String, n: int = 1) -> void:
	var sch: Dictionary = p_sch if owner == "player" else e_sch
	sch[type] = max(0, sch.get(type, 0) - n)

## reset_sch(owner) — 清空全部符能（对应 JS resetSch()）
func reset_sch(owner: String) -> void:
	var sch: Dictionary = p_sch if owner == "player" else e_sch
	for key in sch.keys():
		sch[key] = 0

## has_keyword(unit, keyword) — 判断单位是否有某关键词
func has_keyword(unit: Dictionary, keyword: String) -> bool:
	var kws: Array = unit.get("keywords", [])
	return keyword in kws

## add_keyword(unit, keyword) — 给单位添加关键词（若不存在）
func add_keyword(unit: Dictionary, keyword: String) -> void:
	var kws: Array = unit.get("keywords", [])
	if not keyword in kws:
		kws.append(keyword)
		unit["keywords"] = kws

## get_bf_of_unit(unit) — 获取单位所在战场（返回战场 dict，找不到返回 null）
func get_bf_of_unit(unit: Dictionary) -> Variant:
	for b in bf:
		for u in b["pU"]:
			if u["uid"] == unit["uid"]:
				return b
		for u in b["eU"]:
			if u["uid"] == unit["uid"]:
				return b
	return null

## get_unit_owner(unit) — 判断单位归属（返回 "player" 或 "enemy"，找不到返回 ""）
func get_unit_owner(unit: Dictionary) -> String:
	var uid_val: int = unit.get("uid", -1)
	for u in p_base:
		if u.get("uid", -1) == uid_val:
			return "player"
	for u in e_base:
		if u.get("uid", -1) == uid_val:
			return "enemy"
	for b in bf:
		for u in b["pU"]:
			if u.get("uid", -1) == uid_val:
				return "player"
		for u in b["eU"]:
			if u.get("uid", -1) == uid_val:
				return "enemy"
	if not p_leg.is_empty() and p_leg.get("uid", -1) == uid_val:
		return "player"
	if not e_leg.is_empty() and e_leg.get("uid", -1) == uid_val:
		return "enemy"
	return ""

## reset_state() — 重置所有游戏状态（新游戏时调用）
func reset_state() -> void:
	_uid_counter = 0
	win_score = 8
	p_score = 0; e_score = 0
	p_deck = []; e_deck = []; p_discard = []; e_discard = []
	p_hand = []; e_hand = []
	p_rune_deck = []; e_rune_deck = []
	p_runes = []; e_runes = []
	p_base = []; e_base = []
	bf = [
		{ "id": 1, "pU": [], "eU": [], "ctrl": null, "conq_done": false, "standby": null, "card": null },
		{ "id": 2, "pU": [], "eU": [], "ctrl": null, "conq_done": false, "standby": null, "card": null }
	]
	p_mana = 0; e_mana = 0
	p_sch = { "blazing": 0, "radiant": 0, "verdant": 0, "crushing": 0, "chaos": 0, "order": 0 }
	e_sch = { "blazing": 0, "radiant": 0, "verdant": 0, "crushing": 0, "chaos": 0, "order": 0 }
	p_leg = {}; e_leg = {}
	p_hero = {}; e_hero = {}
	round = 1; turn = "player"; first = "player"; phase = "init"
	p_first_turn_done = false; e_first_turn_done = false
	game_over = false
	duel_active = false
	reaction_active = false; reaction_turn = ""; spell_countered = false
	last_player_spell_cost = 0; last_spell_target_uid = -1
	cards_played_this_turn = 0
	extra_turn_pending = false
	p_rally_active = false; e_rally_active = false
	p_tiyana_on_field = 0; e_tiyana_on_field = 0
	bf_scored_this_turn = []; bf_conquered_this_turn = []
	p_next_ally_buff = 0; e_next_ally_buff = 0
	p_ally_dmg_dealt = 0; e_ally_dmg_dealt = 0
	card_lock_target = ""
	p_deck_name = ""; e_deck_name = ""
	_game_initialized = false

# ═══════════════════════════════════════════════
# 阶段二：游戏初始化 + 回合流程 + 得分系统
# 对应 engine.js + main.js 的核心逻辑
# ═══════════════════════════════════════════════

# ── 额外状态变量（Phase 2 新增）──
var p_deck_name: String = ""
var e_deck_name: String = ""
var _game_initialized: bool = false

# ─────────────────────────────────────────────
# start_game(player_deck, enemy_deck)
# 对应 main.js startGame() + confirmMulligan() + initGame()
# 参数：deck_name 为 "kaisa" 或 "masteryi"
# ─────────────────────────────────────────────
func start_game(player_deck: String, enemy_deck: String) -> void:
	reset_state()
	p_deck_name = player_deck
	e_deck_name = enemy_deck

	# ── 英雄卡：直接从数据库获取，不经过主牌堆（规则103.2.a）──
	p_hero = mk(CardDatabase.get_hero(player_deck))
	e_hero = mk(CardDatabase.get_hero(enemy_deck))

	# ── 构建玩家主牌堆（40张可抽卡，不含英雄）──
	var p_cards: Array = CardDatabase.get_deck(player_deck)
	p_deck = shuffle_array(p_cards)
	_seed_opening_hand(p_deck)

	# ── 构建敌方主牌堆 ──
	var e_cards: Array = CardDatabase.get_deck(enemy_deck)
	e_deck = shuffle_array(e_cards)

	# ── 传奇（用 mk() 与 JS 原版一致，currentHp = atk）──
	p_leg = mk(CardDatabase.get_legend(player_deck))
	e_leg = mk(CardDatabase.get_legend(enemy_deck))

	# ── 符文牌库 ──
	p_rune_deck = _build_rune_deck(CardDatabase.get_rune_setup(player_deck))
	e_rune_deck = _build_rune_deck(CardDatabase.get_rune_setup(enemy_deck))

	# ── 战场牌池 ──
	var p_bf_ids: Array = CardDatabase.get_bf_ids(player_deck)
	var e_bf_ids: Array = CardDatabase.get_bf_ids(enemy_deck)
	p_bf_pool = []
	e_bf_pool = []
	for b in CardDatabase.BATTLEFIELDS:
		if b["id"] in p_bf_ids:
			p_bf_pool.append(b)
		if b["id"] in e_bf_ids:
			e_bf_pool.append(b)

	# ── 发4张初始手牌 ──
	for i in range(4):
		if p_deck.size() > 0:
			p_hand.append(p_deck.pop_back())
		if e_deck.size() > 0:
			e_hand.append(e_deck.pop_back())

	# ── 初始化战场 ──
	_init_battlefields()

	emit_signal("state_updated")
	_log("游戏开始！玩家: " + player_deck + "  AI: " + enemy_deck, "imp")


## 软加权开局：约 1/3 概率将一张≤2费单位调入初始抽牌区域（对应 main.js seedPlayerOpeningHand）
func _seed_opening_hand(deck: Array) -> void:
	if randf() >= 0.33:
		return
	var deck_len: int = deck.size()
	if deck_len < 5:
		return
	var top4: Array = deck.slice(deck_len - 4)
	for c in top4:
		if c.get("type", "") == "follower" and c.get("cost", 99) <= 2:
			return  # 顶部已有低费单位，不干预
	var candidates: Array = []
	for i in range(deck_len - 4):
		if deck[i].get("type", "") == "follower" and deck[i].get("cost", 99) <= 2:
			candidates.append(i)
	if candidates.is_empty():
		return
	var src: int = candidates[randi() % candidates.size()]
	var dst: int = deck_len - 1 - (randi() % 4)
	var tmp = deck[src]
	deck[src] = deck[dst]
	deck[dst] = tmp


## 构建符文牌库（对应 main.js mkVoidRunes / mkIoniaRunes）
func _build_rune_deck(setup: Dictionary) -> Array:
	var runes: Array = []
	for rune_type in setup:
		for i in range(setup[rune_type]):
			runes.append(mk_rune(rune_type))
	shuffle_array(runes)
	return runes


## 初始化战场（从各方牌池各随机选一张）对应 main.js confirmBFSelect
func _init_battlefields() -> void:
	if bf[0]["card"] != null and bf[1]["card"] != null:
		return  # 已设置过
	var p_shuffled: Array = p_bf_pool.duplicate()
	shuffle_array(p_shuffled)
	var e_shuffled: Array = e_bf_pool.duplicate()
	shuffle_array(e_shuffled)
	if p_shuffled.size() > 0:
		bf[0]["card"] = p_shuffled[0]
	if e_shuffled.size() > 0:
		bf[1]["card"] = e_shuffled[0]


# ─────────────────────────────────────────────
# 留学（换牌）：最多换2张（对应 main.js confirmMulligan）
# ─────────────────────────────────────────────
func do_mulligan(indices_to_swap: Array) -> void:
	# indices_to_swap: 要换掉的手牌下标（最多2个，从大到小排序）
	var sorted: Array = indices_to_swap.duplicate()
	sorted.sort()
	sorted.reverse()
	var shelved: Array = []
	for i in sorted:
		if i < p_hand.size():
			shelved.append(p_hand[i])
			p_hand.remove_at(i)
	# 补充新牌
	for _c in shelved:
		if p_deck.size() > 0:
			p_hand.append(p_deck.pop_back())
	# 放回牌库底
	for c in shelved:
		p_deck.insert(0, c)


# ─────────────────────────────────────────────
# 得分系统（对应 engine.js addScore + checkWin）
# ─────────────────────────────────────────────
## add_score(who, pts, type, bf_id) — 增加得分，含所有特殊规则
## 返回 true 表示得分成功，false 表示被阻止
func add_score(who: String, pts: int, type: String, bf_id: Variant) -> bool:
	# 缇亚娜·冕卫：阻止对手的据守/征服得分
	if type == "hold" or type == "conquer":
		var opponent: String = "enemy" if who == "player" else "player"
		var opp_base: Array  = p_base if opponent == "player" else e_base
		var opp_bf_units: Array = []
		for b in bf:
			opp_bf_units.append_array(b["pU"] if opponent == "player" else b["eU"])
		var has_tiyana: bool = false
		for u in opp_base + opp_bf_units:
			if u.get("id", "") == "tiyana_warden":
				has_tiyana = true
				break
		if has_tiyana:
			_log("缇亚娜·冕卫：阻止了" + ("你" if who == "player" else "AI") + "获得" + str(pts) + "分！", "imp")
			return false

	# 攀圣长阶：据守此战场时额外+1分（规则：【据守】触发，非征服）
	if type == "hold" and bf_id != null:
		var target_bf = _find_bf(bf_id)
		if target_bf != null and target_bf.get("card", null) != null:
			if target_bf["card"].get("id", "") == "ascending_stairs":
				pts += 1
				_log("攀圣长阶：额外+1分！", "imp")

	# 遗忘丰碑：第三回合前无法从此战场得据守分
	if type == "hold" and bf_id != null:
		var target_bf2 = _find_bf(bf_id)
		if target_bf2 != null and target_bf2.get("card", null) != null:
			if target_bf2["card"].get("id", "") == "forgotten_monument" and round < 3:
				_log("遗忘丰碑：第三回合前无法获得此处据守分！", "imp")
				return false

	# 记录本回合已得分的战场
	if bf_id != null and not (bf_id in bf_scored_this_turn):
		bf_scored_this_turn.append(bf_id)

	# 征服：单独追踪（用于第8分限制规则）
	if type == "conquer" and bf_id != null and not (bf_id in bf_conquered_this_turn):
		bf_conquered_this_turn.append(bf_id)

	# 第8分限制：征服得最后1分时，本回合须已征服所有战场
	if type == "conquer":
		var current_score: int = p_score if who == "player" else e_score
		if current_score == win_score - 1:
			var all_bf_ids: Array = []
			for b in bf:
				all_bf_ids.append(b["id"])
			var all_conquered: bool = true
			for bid in all_bf_ids:
				if not (bid in bf_conquered_this_turn):
					all_conquered = false
					break
			if not all_conquered:
				var hand: Array = p_hand if who == "player" else e_hand
				var deck: Array = p_deck if who == "player" else e_deck
				if deck.size() > 0:  # 规则107.6：无手牌上限
					hand.append(deck.pop_back())
				_log("最后1分受限：本回合未在所有战场征服，" + ("你" if who == "player" else "AI") + "改为抽1张牌！", "score")
				emit_signal("state_updated")
				return false

	# 实际加分
	if who == "player":
		p_score += pts
	else:
		e_score += pts

	var scorer: String     = "你" if who == "player" else "AI"
	var type_name: String  = "据守" if type == "hold" else ("征服" if type == "conquer" else "得分")
	var new_total: int     = p_score if who == "player" else e_score
	emit_signal("banner_shown", scorer + " " + type_name + " +" + str(pts) + "分 (" + str(new_total) + "/" + str(win_score) + ")", "score-" + who)
	emit_signal("score_changed", p_score, e_score)
	emit_signal("state_updated")
	check_win()
	return true


## check_win() — 判断游戏结束（对应 engine.js checkWin）
func check_win() -> void:
	if game_over:
		return
	# 传奇 HP 归零
	if not p_leg.is_empty() and p_leg.get("current_hp", 1) <= 0:
		_end_game("player_lose", "你的传奇阵亡！你失败了！")
		return
	if not e_leg.is_empty() and e_leg.get("current_hp", 1) <= 0:
		_end_game("player_win", "AI传奇阵亡！你获胜了！")
		return
	# 双方同时达到上限
	if p_score >= win_score and e_score >= win_score:
		_end_game("draw", "平局！双方同时达到" + str(win_score) + "分！")
		return
	if p_score >= win_score:
		_end_game("player_win", "你赢了！率先获得 " + str(win_score) + " 分！")
		return
	if e_score >= win_score:
		_end_game("player_lose", "AI赢了！率先获得 " + str(win_score) + " 分！")
		return


func _end_game(winner: String, msg: String) -> void:
	game_over = true
	emit_signal("state_updated")
	emit_signal("game_over_signal", winner, msg)
	_log(msg, "imp")


func _find_bf(bf_id) -> Variant:
	for b in bf:
		if b["id"] == bf_id:
			return b
	return null


# ─────────────────────────────────────────────
# 绝念触发（对应 engine.js triggerDeathwish）
# ─────────────────────────────────────────────
func trigger_deathwish(unit: Dictionary, owner: String) -> void:
	var unit_id: String = unit.get("id", "")
	var hand: Array = p_hand if owner == "player" else e_hand
	var deck: Array = p_deck if owner == "player" else e_deck

	match unit_id:
		"alert_sentinel":
			# 绝念：阵亡时抽1张牌（规则107.6：无手牌上限）
			if deck.size() > 0:
				hand.append(deck.pop_back())
				_log("绝念：" + unit.get("name","?") + " 阵亡，" + ("你" if owner=="player" else "AI") + " 抽1张牌！", "imp")

		"wailing_poro":
			# 绝念：被摧毁时，若该处无其他友方单位，则抽1张牌（规则107.6：无手牌上限）
			var zone_allies: int = 0
			var base_arr: Array = p_base if owner == "player" else e_base
			zone_allies += base_arr.filter(func(u): return u.get("uid",-1) != unit.get("uid",-1)).size()
			for b in bf:
				var zone: Array = b["pU"] if owner == "player" else b["eU"]
				if zone.any(func(u): return u.get("uid",-1) == unit.get("uid",-1)):
					zone_allies += zone.filter(func(u): return u.get("uid",-1) != unit.get("uid",-1)).size()
			if zone_allies == 0:
				if deck.size() > 0:
					hand.append(deck.pop_back())
					_log("绝念：" + unit.get("name","?") + " 孤独阵亡，" + ("你" if owner=="player" else "AI") + " 抽1张牌！", "imp")

		"voidling":
			# 绝念：阵亡时手牌创造「碎片」法术（规则107.6：无手牌上限）
			var frag: Dictionary = mk({
				"id": "fragment", "name": "碎片",
				"region": unit.get("region", "void"),
				"type": "spell", "cost": 0,
				"keywords": ["迅捷"],
				"text": "给一个随机盟友+1/+1。",
				"img": "", "effect": "buff_draw", "power": 1, "tough": 1
			})
			hand.append(frag)
			_log("绝念：" + unit.get("name", "?") + " 阵亡，手牌创造「碎片」！", "imp")

		"void_sentinel":
			# 绝念：下一个盟友入场时获得+1/+1
			if owner == "player":
				p_next_ally_buff += 1
			else:
				e_next_ally_buff += 1
			_log("绝念：" + unit.get("name", "?") + " 阵亡，下一个盟友入场时获得+1/+1！", "imp")

		"tiyana_warden":
			# 离场时减少冕卫计数
			if owner == "player":
				p_tiyana_on_field = max(0, p_tiyana_on_field - 1)
			else:
				e_tiyana_on_field = max(0, e_tiyana_on_field - 1)


# ─────────────────────────────────────────────
# 回合流程（对应 engine.js startTurn / runPhase）
# ─────────────────────────────────────────────

## start_turn(who) — 开始新回合（对应 engine.js startTurn）
func start_turn(who: String) -> void:
	if game_over:
		return
	if not _game_initialized:
		_init_battlefields()
		_game_initialized = true

	turn = who
	for b in bf:
		b["conq_done"] = false
	bf_scored_this_turn = []
	bf_conquered_this_turn = []

	emit_signal("banner_shown", "回合 " + str(round) + " · " + ("你的回合" if who == "player" else "AI 回合"), "")
	_log("═══ 回合" + str(round) + " (" + ("玩家" if who == "player" else "AI") + ") ═══", "imp")
	emit_signal("state_updated")
	emit_signal("turn_started", who)

	# 延迟启动唤醒阶段（对应 JS setTimeout 700ms）
	await get_tree().create_timer(0.1).timeout
	await _run_phase("awaken")


## _run_phase(ph) — 运行指定阶段（对应 engine.js runPhase，async）
func _run_phase(ph: String) -> void:
	if game_over:
		return
	phase = ph
	emit_signal("phase_changed", ph)
	emit_signal("state_updated")

	match ph:
		"awaken":
			_do_awaken()
			await get_tree().create_timer(0.3).timeout
			await _run_phase("start")

		"start":
			await _do_start()
			await get_tree().create_timer(0.3).timeout
			await _run_phase("summon")

		"summon":
			_do_summon()
			await get_tree().create_timer(0.3).timeout
			await _run_phase("draw")

		"draw":
			await _do_draw()
			await get_tree().create_timer(0.3).timeout
			await _run_phase("action")

		"action":
			emit_signal("state_updated")
			emit_signal("action_phase_started", turn)
			# UI 层监听 action_phase_started 信号来启用/禁用玩家操作
			# AI 行动由 AIManager 监听此信号后执行


## do_end_phase() — 结束阶段（对应 engine.js doEndPhase，由玩家点击"结束回合"或 AI 完成时调用）
func do_end_phase() -> void:
	phase = "end"
	# 清除所有单位的标记伤害和临时增益
	var all_units: Array = []
	all_units.append_array(p_base)
	all_units.append_array(e_base)
	for b in bf:
		all_units.append_array(b["pU"])
		all_units.append_array(b["eU"])
	for u in all_units:
		u["current_hp"]  = u.get("current_atk", u.get("atk", 0))
		u["tb"]          = { "atk": 0 }
		u["stunned"]     = false

	# 传奇临时增益归零（HP 保留）
	if not p_leg.is_empty():
		p_leg["tb"] = { "atk": 0 }
		p_leg["stunned"] = false
	if not e_leg.is_empty():
		e_leg["tb"] = { "atk": 0 }
		e_leg["stunned"] = false

	p_mana = 0; e_mana = 0
	reset_sch("player"); reset_sch("enemy")
	cards_played_this_turn = 0
	card_lock_target = ""
	p_rally_active = false; e_rally_active = false

	_log("回合结束：清除临时效果，法力清零。", "phase")

	if turn == "player":
		p_first_turn_done = true
	else:
		e_first_turn_done = true

	# 时间扭曲：玩家额外回合
	if turn == "player" and extra_turn_pending:
		extra_turn_pending = false
		_log("时间扭曲：你获得额外的一个回合！", "imp")
		emit_signal("state_updated")
		await get_tree().create_timer(0.3).timeout
		start_turn("player")
		return

	round += 1
	var next: String = "enemy" if turn == "player" else "player"
	emit_signal("state_updated")
	await get_tree().create_timer(0.3).timeout
	start_turn(next)


## player_end_turn() — 玩家点击"结束回合"（对应 engine.js playerEndTurn）
func player_end_turn() -> void:
	if turn != "player" or phase != "action" or game_over:
		return
	_log("─── 玩家结束行动 ───", "phase")
	await do_end_phase()


# ─────────────────────────────────────────────
# 具体阶段实现
# ─────────────────────────────────────────────

## 唤醒阶段（对应 engine.js doAwaken）
func _do_awaken() -> void:
	# 解除己方所有单位的休眠状态
	var my_units: Array = []
	my_units.append_array(p_base if turn == "player" else e_base)
	for b in bf:
		my_units.append_array(b["pU"] if turn == "player" else b["eU"])
	for u in my_units:
		u["exhausted"] = false

	# 传奇重置疲惫
	var leg: Dictionary = p_leg if turn == "player" else e_leg
	if not leg.is_empty():
		leg["exhausted"] = false

	# 重置符文（休眠 → 可用）
	var runes: Array = p_runes if turn == "player" else e_runes
	for r in runes:
		r["tapped"] = false

	# 重置符能、出牌计数、迎敌号令
	if turn == "player":
		reset_sch("player")
		pending_runes = []
		pending_move = null
		p_rally_active = false
	else:
		reset_sch("enemy")
		e_rally_active = false

	cards_played_this_turn = 0
	card_lock_target = ""
	# 重置主动技能每回合使用标记（规则 577.3：每回合开始时重置）
	LegendManager.reset_legend_abilities_for_turn(turn)
	_log("唤醒：解除己方休眠，重置符文。", "phase")


## 开始阶段（对应 engine.js doStart，含据守得分 + 战场特殊能力）
func _do_start() -> void:
	# 规则 728：瞬息单位在控制者回合开始阶段、计分前摧毁
	KeywordManager.check_ephemeral(turn)

	var scored: int = 0
	for b in bf:
		if b["ctrl"] == turn:
			add_score(turn, 1, "hold", b["id"])
			scored += 1
			_log("据守战场" + str(b["id"]) + " +1分", "score")

			# 三相之力：据守时该战场有携带三相之力的单位，额外获得1分
			var bf_units: Array = b["pU"] if turn == "player" else b["eU"]
			for u in bf_units:
				if u.get("trinity_equipped", false):
					add_score(turn, 1, "hold", b["id"])
					_log("三相之力：额外获得1分！", "score")

			# 玩家专属战场据守能力
			if turn == "player" and b.get("card", null) != null:
				await _handle_bf_hold_ability(b)
			# 力量方尖碑：AI首回合额外召出1张符文（两方玩家均适用）
			elif turn == "enemy" and b.get("card", {}).get("id", "") == "strength_obelisk":
				if not e_first_turn_done and e_rune_deck.size() > 0:
					e_runes.append(e_rune_deck.pop_back())
					_log("力量方尖碑 (据守)：AI首回合额外召出1张符文！", "imp")

	if scored == 0:
		_log("开始：无控制战场，0据守分。", "phase")
	else:
		_log("开始：据守得分+" + str(scored) + "。", "phase")
	emit_signal("state_updated")


## 处理战场据守特殊能力（对应 engine.js doStart 中的 if (b.card.id === ...) 分支）
func _handle_bf_hold_ability(b: Dictionary) -> void:
	var card_id: String = b["card"].get("id", "")
	match card_id:
		"altar_unity":
			# 召唤1名1/1新兵到基地
			var recruit: Dictionary = mk({
				"id": "recruit", "name": "新兵", "region": "demacia",
				"type": "follower", "cost": 1, "atk": 1, "hp": 1,
				"keywords": [], "text": "", "img": ""
			})
			recruit["exhausted"] = true
			p_base.append(recruit)
			_log("团结祭坛：自动召唤1名新兵到基地。", "imp")

		"aspirant_climb":
			# 支付1法力给基地单位+1战力
			if p_mana >= 1 and p_base.size() > 0:
				var res = await PromptManager.ask({
					"title": "试炼者之阶 (据守)",
					"msg": "是否支付 1 点法力，使基地的一名单位获得 +1 战力增益？",
					"type": "cards", "cards": p_base, "optional": true
				})
				if res != null:
					p_mana -= 1
					for u in p_base:
						if u.get("uid", -1) == res:
							apply_buff_token(u)
							_log("试炼者之阶：支付 1 法力强化了 " + u.get("name","?") + "。", "imp")
							break

		"bandle_tree":
			# 若场上≥3种地域，获得1法力
			var traits: Dictionary = {}
			for u in get_all_units("player"):
				traits[u.get("region", "")] = true
			if traits.size() >= 3:
				p_mana += 1
				_log("班德尔城神树：场上存在≥3种特性，获得1法力！", "imp")

		"strength_obelisk":
			# 首回合额外召出1张符文（卡图：每名玩家在各自第一个回合开始阶段额外召出1枚符文）
			if not p_first_turn_done and p_rune_deck.size() > 0:
				p_runes.append(p_rune_deck.pop_back())
				_log("力量方尖碑 (据守)：首回合额外召出1张符文！", "imp")

		"star_peak":
			# 召出一枚休眠符文
			if p_rune_deck.size() > 0:
				var res = await PromptManager.ask({
					"title": "星尖峰 (据守)",
					"msg": "是否召出一枚休眠的符文？",
					"type": "confirm"
				})
				if res:
					var r: Dictionary = p_rune_deck.pop_back()
					r["tapped"] = true
					p_runes.append(r)
					_log("星尖峰：据守召出1枚休眠符文！", "imp")


## 召出阶段（对应 engine.js doSummon）
func _do_summon() -> void:
	var is_back_player: bool  = (turn != first)
	var first_turn_done: bool = p_first_turn_done if turn == "player" else e_first_turn_done
	var cnt: int              = 3 if (is_back_player and not first_turn_done) else 2
	var rd: Array             = p_rune_deck if turn == "player" else e_rune_deck
	var rz: Array             = p_runes     if turn == "player" else e_runes

	var got: int = 0
	for i in range(cnt):
		if rd.size() > 0:
			rz.append(rd.pop_back())
			got += 1

	if got < cnt:
		_log("召出：符文牌堆不足，仅召出" + str(got) + "张。", "phase")
	else:
		_log("召出：获得" + str(got) + "张符文" + (" (后手首回合+1)" if cnt == 3 else "") + "（牌堆剩" + str(rd.size()) + "）。", "phase")


## 抽牌阶段（对应 engine.js doDraw）
func _do_draw() -> void:
	# 先见机甲·预知（玩家回合）
	if turn == "player":
		var mechs: Array = get_all_units("player").filter(func(u): return u.get("id","") == "foresight_mech")
		if mechs.size() > 0 and p_deck.size() > 0:
			var top_card: Dictionary = p_deck[p_deck.size() - 1]
			var res = await PromptManager.ask({
				"title": "预知（" + str(mechs.size()) + "台先见机甲在场）",
				"msg": "牌堆顶部是【" + top_card.get("name","?") + "】。是否将其回收至牌库底部？",
				"type": "confirm"
			})
			if res:
				p_deck.pop_back()
				p_deck.insert(0, top_card)
				_log("先见机甲·预知：将【" + top_card.get("name","?") + "】回收至牌库底部。", "imp")

	var deck:    Array = p_deck    if turn == "player" else e_deck
	var discard: Array = p_discard if turn == "player" else e_discard
	var hand:    Array = p_hand    if turn == "player" else e_hand

	# 燃尽：牌库耗尽
	if deck.size() == 0:
		if discard.size() > 0:
			_log("燃尽！废牌堆（" + str(discard.size()) + "张）洗牌后重入牌库。", "phase")
			for u in discard:
				deck.append(u)
			discard.clear()
			shuffle_array(deck)
		else:
			_log("燃尽！废牌堆也为空，无法补充。", "phase")
		var opponent: String = "enemy" if turn == "player" else "player"
		add_score(opponent, 1, "burnout", null)
		_log("燃尽惩罚：" + ("AI" if opponent=="enemy" else "你") + "获得1分！", "score")

	if deck.size() > 0:
		hand.append(deck.pop_back())  # 规则107.6：无手牌上限
		_log("抽牌：抽取1张。", "phase")
	else:
		_log("无牌可抽（废牌堆已耗尽）。", "phase")

	# 法力和符能在抽牌阶段末清空（对应 JS doDraw 末尾）
	p_mana = 0; e_mana = 0
	reset_sch("player"); reset_sch("enemy")
	_log("抽牌阶段结束。", "phase")


## draw_card(owner, n) — 通用摸牌工具（不受当前回合限制，用于法术/绝念/战场能力）
## 对应 JS 中 hand.push(deck.pop()) 的通用抽牌操作
func draw_card(owner: String, n: int = 1) -> void:
	var deck:    Array = p_deck    if owner == "player" else e_deck
	var discard: Array = p_discard if owner == "player" else e_discard
	var hand:    Array = p_hand    if owner == "player" else e_hand
	for _i in n:
		if deck.is_empty():
			if not discard.is_empty():
				_log("燃尽（draw_card）：废牌堆洗牌补充。", "phase")
				for c in discard:
					deck.append(c)
				discard.clear()
				shuffle_array(deck)
			else:
				_log("无牌可抽：牌库和废牌堆均为空。", "phase")
				break
		if not deck.is_empty():
			hand.append(deck.pop_back())  # 规则107.6：无手牌上限


# ═══════════════════════════════════════════════
# 符文操作（Step 2 新增）
# 对应 JS hint.js confirmRunes() 中的单符文执行逻辑
# ═══════════════════════════════════════════════

## 符文中文名称映射（用于日志）
const RUNE_NAMES: Dictionary = {
	"blazing": "炽烈符文",
	"radiant": "灵光符文",
	"verdant": "翠意符文",
	"crushing": "摧破符文",
	"chaos": "混沌符文",
	"order": "序理符文"
}

## tap_rune(owner, rune_uid) — 横置符文获得1法力
## 对应 JS hint.js confirmRunes() 中 action='tap' 分支
## 返回 true=成功，false=符文不存在或已横置
func tap_rune(owner: String, rune_uid: int) -> bool:
	var runes: Array = p_runes if owner == "player" else e_runes
	var mana_ref: String = "player" if owner == "player" else "enemy"
	for r in runes:
		if r.get("uid", -1) == rune_uid:
			if r.get("tapped", false):
				return false  # 已横置
			r["tapped"] = true
			if owner == "player":
				p_mana += 1
				_log("[休眠] 横置%s  +1法力（共%d）" % [RUNE_NAMES.get(r.get("rune_type",""), "符文"), p_mana], "phase")
			else:
				e_mana += 1
				_log("[休眠] AI横置%s  +1法力" % RUNE_NAMES.get(r.get("rune_type",""), "符文"), "phase")
			emit_signal("state_updated")
			return true
	return false  # 未找到


## recycle_rune(owner, rune_uid) — 回收符文获得1点对应符能
## 对应 JS hint.js confirmRunes() 中 action='recycle' 分支
## 回收后符文插入符文牌库底部（unshift 对应 insert(0, ...)）
## 返回 true=成功，false=符文不存在
func recycle_rune(owner: String, rune_uid: int) -> bool:
	var runes: Array     = p_runes     if owner == "player" else e_runes
	var rune_deck: Array = p_rune_deck if owner == "player" else e_rune_deck
	for i in range(runes.size()):
		if runes[i].get("uid", -1) == rune_uid:
			var r: Dictionary = runes[i]
			runes.remove_at(i)
			r["tapped"] = false
			rune_deck.insert(0, r)   # 底部（pop_back = 顶部，insert(0) = 底部）
			var rune_type: String = r.get("rune_type", "")
			add_sch(owner, rune_type, 1)
			var sch_name: String = RUNE_NAMES.get(rune_type, "符文")
			var sch_amount: int = get_sch(owner, rune_type)
			_log("[回收] %s → +1%s符能（共%d）" % [sch_name, sch_name.replace("符文",""), sch_amount], "phase")
			emit_signal("state_updated")
			return true
	return false  # 未找到


# ─────────────────────────────────────────────
# 日志辅助（替代 JS 中的 log() 函数）
# ─────────────────────────────────────────────
func _log(text: String, category: String = "") -> void:
	emit_signal("log_entry", text, category)
	# 开发阶段：同时打印到 Godot 控制台（Phase 7 后可选关闭）
	print("[" + category + "] " + text)
