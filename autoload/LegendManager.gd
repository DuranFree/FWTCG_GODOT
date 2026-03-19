extends Node
# ═══════════════════════════════════════════════
# LegendManager.gd — 传奇技能系统 (Autoload 单例)
# 对应 JS legend.js
# 三类技能：
#   passive   — 被动：状态检测，check_legend_passives() 中轮询
#   triggered — 触发：挂载事件钩子，trigger_legend_event() 驱动
#   active    — 主动：玩家/AI 手动激活，activate_legend_ability() 执行
# ═══════════════════════════════════════════════


## check_legend_passives(owner) — 检查所有被动技能
## 对应 JS checkLegendPassives()
## 调用时机：单位入场后、战斗结束后
## 注意：仅处理纯被动（无 trigger 字段）；
##       带有 trigger 字段的"被动光环"由 trigger_legend_event() 驱动
func check_legend_passives(p_owner: String) -> void:
	var leg: Dictionary = GameState.p_leg if p_owner == "player" else GameState.e_leg
	if leg.is_empty() or not leg.has("abilities"):
		return
	for ab in leg.get("abilities", []):
		if ab.get("type", "") == "passive" and ab.get("trigger", "") == "":
			_execute_effect(leg, p_owner, ab, {})


## trigger_legend_event(event_type, owner, ctx) — 触发式技能入口
## 对应 JS triggerLegendEvent()
## event_type: "onCombatDefend" | "onSpellCast" | "onSummon" | "onDamageDealt" | ...
func trigger_legend_event(event_type: String, owner: String, ctx: Dictionary = {}) -> void:
	var leg: Dictionary = GameState.p_leg if owner == "player" else GameState.e_leg
	if leg.is_empty() or not leg.has("abilities"):
		return
	for ab in leg.get("abilities", []):
		var ab_type: String = ab.get("type", "")
		var ab_trigger: String = ab.get("trigger", "")
		# 同时支持 type=triggered 和 type=passive 带 trigger 字段的混合式技能
		# （JS 原版将 masteryi_defend_buff 标记为 passive 但附带 trigger 字段）
		if (ab_type == "triggered" or (ab_type == "passive" and ab_trigger != "")) \
				and ab_trigger == event_type:
			_execute_effect(leg, owner, ab, ctx)


## can_use_legend_ability(owner, ab) — 检查主动技能是否可激活
## 对应 JS canUseLegendAbility()
func can_use_legend_ability(owner: String, ab: Dictionary) -> bool:
	if ab.get("type", "") != "active":
		return false
	if ab.get("used_this_turn", false):
		return false
	if GameState.game_over or GameState.prompting:
		return false
	var mana: int = GameState.p_mana if owner == "player" else GameState.e_mana
	if mana < ab.get("cost", 0):
		return false
	var sch_cost: int = ab.get("sch_cost", 0)
	var sch_type: String = ab.get("sch_type", "")
	if sch_cost > 0 and sch_type != "" and GameState.get_sch(owner, sch_type) < sch_cost:
		return false
	# 以"休眠自身"为代价的技能：传奇已经休眠则无法激活
	if ab.get("exhaust", false):
		var leg: Dictionary = GameState.p_leg if owner == "player" else GameState.e_leg
		if not leg.is_empty() and leg.get("exhausted", false):
			return false
	if GameState.duel_active:
		# 对决中：仅迅捷/反应关键词的主动技能可激活，且轮到自己
		if GameState.duel_turn != owner:
			return false
		var kws: Array = ab.get("keywords", [])
		if not ("迅捷" in kws or "反应" in kws):
			return false
	else:
		# 非对决：仅己方行动阶段
		if GameState.turn != owner or GameState.phase != "action":
			return false
	return true


## activate_legend_ability(owner, ability_id) — 执行主动技能
## 对应 JS activateLegendAbility()
## 返回 true=成功激活，false=无法激活
func activate_legend_ability(owner: String, ability_id: String) -> bool:
	if GameState.game_over:
		return false
	var leg: Dictionary = GameState.p_leg if owner == "player" else GameState.e_leg
	if leg.is_empty() or not leg.has("abilities"):
		return false
	var ab_found: Dictionary = {}
	for ab in leg.get("abilities", []):
		if ab.get("id", "") == ability_id:
			ab_found = ab
			break
	if ab_found.is_empty() or not can_use_legend_ability(owner, ab_found):
		if owner == "player":
			GameState._log("当前无法激活该技能（时机或费用不符）。", "imp")
		return false
	# ── 扣除费用 ──
	var cost: int = ab_found.get("cost", 0)
	var sch_cost: int = ab_found.get("sch_cost", 0)
	var sch_type: String = ab_found.get("sch_type", "")
	if owner == "player":
		GameState.p_mana -= cost
	else:
		GameState.e_mana -= cost
	if sch_cost > 0 and sch_type != "":
		GameState.spend_sch(owner, sch_type, sch_cost)
	# ── 标记已使用（once 默认为 true；若 once === false 则无限使用）──
	if ab_found.get("once", true) != false:
		ab_found["used_this_turn"] = true
	GameState._log("%s 激活主动技能【%s】" % [leg.get("name","?"), ab_found.get("name","?")], "imp")
	_execute_effect(leg, owner, ab_found, {})
	GameState.check_win()
	GameState.emit_signal("state_updated")
	return true


## reset_legend_abilities_for_turn(owner) — 重置每回合使用标记
## 对应 JS resetLegendAbilitiesForTurn()
## 调用时机：唤醒阶段（_do_awaken）
func reset_legend_abilities_for_turn(owner: String) -> void:
	var leg: Dictionary = GameState.p_leg if owner == "player" else GameState.e_leg
	if leg.is_empty() or not leg.has("abilities"):
		return
	for ab in leg.get("abilities", []):
		if ab.get("type", "") == "active":
			ab["used_this_turn"] = false


# ═══════════════════════════════════════════════
# 技能效果分发
# ═══════════════════════════════════════════════

## _execute_effect — 根据 effect_id 分发到对应效果函数
## 对应 JS LEGEND_EFFECTS 注册表
func _execute_effect(leg: Dictionary, owner: String, ab: Dictionary, ctx: Dictionary) -> bool:
	var effect: String = ab.get("effect", "")
	match effect:
		"evolve":
			return _effect_evolve(leg, owner)
		"masteryi_defend_buff":
			return _effect_masteryi_defend_buff(leg, owner, ctx)
		"kaisa_void_sense":
			return _effect_kaisa_void_sense(leg, owner)
		_:
			return false


# ─────────────────────────────────────────────
# 具体技能效果
# ─────────────────────────────────────────────

## ── 卡莎「进化」被动 ──
## 条件：场上盟友拥有 4 种或以上不同关键词
## 效果：传奇升至等级2，永久+3/+3
## 对应 JS legend.js LEGEND_EFFECTS['evolve']
func _effect_evolve(leg: Dictionary, owner: String) -> bool:
	if leg.get("_evolved", false):
		return false   # 只能进化一次
	var allies: Array = GameState.get_all_units(owner)
	var kw_set: Dictionary = {}
	for u in allies:
		for kw in u.get("keywords", []):
			kw_set[kw] = true
	if kw_set.size() < 4:
		return false   # 关键词种类不足
	leg["_evolved"]     = true
	leg["level"]        = 2
	leg["atk"]          = leg.get("atk", 0)          + 3
	leg["current_atk"]  = leg.get("current_atk", 0)  + 3
	leg["hp"]           = leg.get("hp", 0)            + 3
	leg["current_hp"]   = min(leg.get("current_hp", 0) + 3, leg["hp"])
	var kw_list: Array  = kw_set.keys()
	GameState._log("卡莎进化！盟友汇聚 %d 种关键词（%s），升至等级2，+3/+3！" % [
		kw_set.size(), "·".join(kw_list)], "imp")
	GameState.emit_signal("state_updated")
	return true


## ── 无极剑圣「独影剑鸣」触发被动 ──
## 触发时机：onCombatDefend（CombatManager 在伤害计算前调用）
## 条件：该战场上仅有1名友方单位在防守
## 效果：该唯一防守单位本回合战力+2
## 对应 JS legend.js LEGEND_EFFECTS['masteryi_defend_buff']
func _effect_masteryi_defend_buff(_leg: Dictionary, owner: String, ctx: Dictionary) -> bool:
	var bf_id = ctx.get("bf_id", null)
	if bf_id == null:
		return false
	var found_bf: Variant = null
	for b in GameState.bf:
		if b["id"] == bf_id:
			found_bf = b
			break
	if found_bf == null:
		return false
	var defenders: Array = found_bf["pU"] if owner == "player" else found_bf["eU"]
	if defenders.size() != 1:
		return false   # 多于1名防守者时不触发
	var solo: Dictionary = defenders[0]
	var tb: Dictionary = solo.get("tb", {"atk": 0})
	tb["atk"] = tb.get("atk", 0) + 2
	solo["tb"] = tb
	GameState._log("无极剑圣·独影剑鸣：%s 独守此战场，本回合+2战力！" % solo.get("name","?"), "imp")
	GameState.emit_signal("state_updated")
	return true


## ── 卡莎「虚空感知」主动·反应 ──
## 代价：休眠自身（exhaust=true）；效果：获得1点炽烈符能
## 不可被反应法术拦截（进入闭环时绝对优先）
## 对应 JS legend.js LEGEND_EFFECTS['kaisa_void_sense']
func _effect_kaisa_void_sense(leg: Dictionary, owner: String) -> bool:
	if leg.get("exhausted", false):
		GameState._log("卡莎·虚空感知：自身已处于休眠状态，无法激活。", "imp")
		return false
	leg["exhausted"] = true
	GameState.add_sch(owner, "blazing", 1)
	var sch_amount: int = GameState.get_sch(owner, "blazing")
	if owner == "player":
		GameState._log("卡莎·虚空感知：休眠自身，获得1点炽烈符能！（当前%d点）" % sch_amount, "imp")
	else:
		GameState._log("AI卡莎·虚空感知：休眠自身，获得1点炽烈符能！", "imp")
	GameState.emit_signal("state_updated")
	return true


# ═══════════════════════════════════════════════
# AI 辅助函数
# ═══════════════════════════════════════════════

## ai_legend_ability_priority(ab) — 技能优先级评分
## 对应 JS aiLegendAbilityPriority()
func ai_legend_ability_priority(ab: Dictionary) -> int:
	var effect: String = ab.get("effect", "")
	# 有直接战场效果的技能优先
	if "stun" in effect or "buff" in effect or "debuff" in effect or \
			"damage" in effect or "deal" in effect:
		return 3
	# 迅捷/反应类（对决期间可用）
	var kws: Array = ab.get("keywords", [])
	if "迅捷" in kws or "反应" in kws:
		return 2
	# 经济型（+符能/+法力/+抽牌）
	if "sch" in effect or "mana" in effect or "draw" in effect or "sense" in effect:
		return 1
	return 0


## ai_legend_duel_action — AI 对决中传奇迅捷技能决策
## 对应 JS aiLegendDuelAction()
## 返回 true 表示 AI 使用了技能
func ai_legend_duel_action() -> bool:
	var leg: Dictionary = GameState.e_leg
	if leg.is_empty() or not leg.has("abilities"):
		return false
	var fast_abs: Array = leg.get("abilities", []).filter(
		func(ab): return can_use_legend_ability("enemy", ab))
	if fast_abs.is_empty():
		return false
	fast_abs.sort_custom(func(a, b): return ai_legend_ability_priority(a) > ai_legend_ability_priority(b))
	var ab: Dictionary = fast_abs[0]
	GameState._log("AI 传奇【%s】使用迅捷技能【%s】" % [leg.get("name","?"), ab.get("name","?")], "imp")
	activate_legend_ability("enemy", ab.get("id", ""))
	return true


## ai_legend_action_phase — AI 行动阶段传奇主动技能决策
## 对应 JS aiLegendActionPhase()
## 返回 true 表示 AI 使用了技能
func ai_legend_action_phase() -> bool:
	var leg: Dictionary = GameState.e_leg
	if leg.is_empty() or not leg.has("abilities"):
		return false
	var usable_abs: Array = leg.get("abilities", []).filter(
		func(ab): return can_use_legend_ability("enemy", ab))
	if usable_abs.is_empty():
		return false
	usable_abs.sort_custom(func(a, b): return ai_legend_ability_priority(a) > ai_legend_ability_priority(b))
	var ab: Dictionary = usable_abs[0]
	GameState._log("▶ AI 传奇【%s】使用主动技能【%s】" % [leg.get("name","?"), ab.get("name","?")], "imp")
	activate_legend_ability("enemy", ab.get("id", ""))
	return true
