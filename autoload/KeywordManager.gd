extends Node
# ═══════════════════════════════════════════════
# KeywordManager.gd — 关键词引擎 (Autoload 单例)
# 13 关键词：急速/迅捷/强攻/绝念/法盾/游走/待命/鼓舞/反应/坚守/壁垒/瞬息/预知
#
# 已在其他模块实现的关键词（本文件不重复）：
#   强攻 (719)  — CombatManager._role_atk (进攻+bonus)
#   坚守 (726)  — CombatManager._role_atk (防守+bonus)
#   壁垒 (727)  — CombatManager._assign_damage (优先承伤)
#   绝念 (720)  — GameState.trigger_deathwish (阵亡触发)
#
# 本模块负责：急速/迅捷/法盾/游走/待命/鼓舞/反应/瞬息/预知 + 通用时机检查
# ═══════════════════════════════════════════════


# ═══════════════════════════════════════════════
# 通用时机检查
# ═══════════════════════════════════════════════

## can_play_in_timing(card, timing) — 检查该牌在指定时机是否可出
## timing: "normal_action" | "duel" | "time_point" | "closed"
## 对应 JS spell.js isFast / hasPlayableReactionCards
## 规则 718（迅捷）、725（反应）
func can_play_in_timing(card: Dictionary, timing: String) -> bool:
	var kws: Array = card.get("keywords", [])
	match timing:
		"normal_action":
			return true   # 所有牌均可在己方行动阶段出
		"duel":
			# 迅捷/反应均可在对决中出牌（规则 718/725）
			return "迅捷" in kws or "反应" in kws
		"time_point":
			# 反应可在时点处响应（规则 725）
			return "反应" in kws
		"closed":
			# 反应可在闭环状态使用（规则 725）
			return "反应" in kws
		_:
			return false


# ═══════════════════════════════════════════════
# 急速（规则 717）
# 可选额外费用：+1 法力 + 1 匹配符能 → 以活跃状态进场
# ═══════════════════════════════════════════════

## can_pay_haste(unit, owner) — 检查是否有资源支付急速额外费用
func can_pay_haste(unit: Dictionary, owner: String) -> bool:
	if not GameState.has_keyword(unit, "急速"):
		return false
	var mana: int = GameState.p_mana if owner == "player" else GameState.e_mana
	if mana < 1:
		return false
	var sch_type: String = unit.get("schType", "")
	if sch_type != "" and GameState.get_sch(owner, sch_type) < 1:
		return false
	return true


## apply_haste(unit, owner) — 提示玩家是否支付急速额外费用（异步）
## 调用时机：SpellManager 打出单位、exhausted=true 之前
## 返回 true=支付成功，以活跃状态进场；false=放弃/无法支付
func apply_haste(unit: Dictionary, owner: String) -> bool:
	if not can_pay_haste(unit, owner):
		return false
	if owner == "player":
		var sch_type: String = unit.get("schType", "")
		var cost_desc: String = "1点法力" + (" + 1点" + sch_type + "符能" if sch_type != "" else "")
		var res = await PromptManager.ask({
			"title": "急速（可选额外费用）",
			"msg": "额外支付%s，使【%s】以活跃状态进场？" % [cost_desc, unit.get("name", "?")],
			"type": "confirm"
		})
		if res:
			GameState.p_mana -= 1
			if sch_type != "":
				GameState.spend_sch("player", sch_type, 1)
			unit["exhausted"] = false
			GameState._log("支付急速费用，【%s】以活跃状态进场！" % unit.get("name", "?"), "imp")
			GameState.emit_signal("state_updated")
			return true
	else:
		# AI 策略：若本回合还有进攻需求，支付急速
		if can_pay_haste(unit, "enemy"):
			var sch_type: String = unit.get("schType", "")
			GameState.e_mana -= 1
			if sch_type != "":
				GameState.spend_sch("enemy", sch_type, 1)
			unit["exhausted"] = false
			GameState._log("AI支付急速费用，【%s】以活跃状态进场！" % unit.get("name", "?"), "imp")
			GameState.emit_signal("state_updated")
			return true
	return false


# ═══════════════════════════════════════════════
# 法盾（规则 721）
# 对手须额外支付 X 点任意符能才能以法术/技能指定此单位为目标
# ═══════════════════════════════════════════════

## get_spellshield_cost(target) — 读取单位身上所有法盾的合计值
## 格式："法盾"（值为1）或 "法盾X"（值为X）
func get_spellshield_cost(target: Dictionary) -> int:
	var kws: Array = target.get("keywords", [])
	var cost: int = 0
	for kw in kws:
		if kw == "法盾":
			cost += 1
		elif kw.begins_with("法盾") and kw.length() > 2:
			var n_str: String = kw.substr(2)
			if n_str.is_valid_int():
				cost += int(n_str)
	return cost


## can_pay_spellshield(target, caster_owner) — 检查施法者是否有足够符能支付法盾
func can_pay_spellshield(target: Dictionary, caster_owner: String) -> bool:
	var cost: int = get_spellshield_cost(target)
	if cost <= 0:
		return true
	return GameState.get_sch(caster_owner) >= cost  # 任意类型总符能


## enforce_spellshield(target, caster_owner) — 扣除法盾费用，返回 true=可继续施法
## 规则 721：若符能不足则无法以该单位为目标
func enforce_spellshield(target: Dictionary, caster_owner: String) -> bool:
	var cost: int = get_spellshield_cost(target)
	if cost <= 0:
		return true  # 无法盾，直接通过
	if GameState.get_sch(caster_owner) < cost:
		GameState._log("【法盾】阻止指定：%s符能不足（需%d），无法以【%s】为目标！" % [
			("你" if caster_owner == "player" else "AI"), cost, target.get("name", "?")], "imp")
		return false
	# 贪心扣除：依次从有存量的符能类型扣除
	var sch_dict: Dictionary = GameState.p_sch if caster_owner == "player" else GameState.e_sch
	var remaining: int = cost
	for sch_type in sch_dict:
		if remaining <= 0:
			break
		var avail: int = sch_dict.get(sch_type, 0)
		if avail > 0:
			var spend: int = mini(avail, remaining)
			GameState.spend_sch(caster_owner, sch_type, spend)
			remaining -= spend
	GameState._log("【法盾】：%s消耗%d点符能，法术继续指定【%s】！" % [
		("你" if caster_owner == "player" else "AI"), cost, target.get("name", "?")], "imp")
	return true


# ═══════════════════════════════════════════════
# 游走（规则 722）
# 单位可向其他战场（非基地）移动
# ═══════════════════════════════════════════════

## can_roam(unit) — 该单位是否拥有游走关键词
func can_roam(unit: Dictionary) -> bool:
	return GameState.has_keyword(unit, "游走")


## get_valid_roam_targets(unit, current_bf_id) — 获取游走可移动到的战场 ID 列表
func get_valid_roam_targets(unit: Dictionary, current_bf_id: int) -> Array:
	if not can_roam(unit):
		return []
	var targets: Array = []
	for b in GameState.bf:
		if b["id"] != current_bf_id:
			var side: String = GameState.get_unit_owner(unit)
			var slots: Array = b["pU"] if side == "player" else b["eU"]
			if slots.size() < 2:  # 战场最多2槽
				targets.append(b["id"])
	return targets


# ═══════════════════════════════════════════════
# 鼓舞（规则 724）
# 如果本回合已打出过其他主牌堆卡牌，则条件满足
# ═══════════════════════════════════════════════

## is_inspire_active(owner) — 本回合是否已打出至少1张卡（鼓舞条件）
func is_inspire_active(_owner: String) -> bool:
	return GameState.cards_played_this_turn > 0


# ═══════════════════════════════════════════════
# 瞬息（规则 728）
# 在控制者回合开始阶段（计分前）摧毁
# ═══════════════════════════════════════════════

## check_ephemeral(owner) — 开始阶段最开始：摧毁场上所有瞬息常驻牌
## 在 GameState._do_start() 计分循环之前调用
func check_ephemeral(owner: String) -> void:
	var base: Array = GameState.p_base if owner == "player" else GameState.e_base
	var discard: Array = GameState.p_discard if owner == "player" else GameState.e_discard
	var found: bool = false

	# 基地中的瞬息单位
	var ephemeral_base: Array = base.filter(func(u): return GameState.has_keyword(u, "瞬息"))
	for u in ephemeral_base:
		if owner == "player":
			GameState.p_base = GameState.p_base.filter(func(x): return x["uid"] != u["uid"])
		else:
			GameState.e_base = GameState.e_base.filter(func(x): return x["uid"] != u["uid"])
		GameState.trigger_deathwish(u, owner)
		discard.append(u)
		GameState._log("瞬息：【%s】在开始阶段被摧毁。" % u.get("name", "?"), "imp")
		found = true

	# 战场上的瞬息单位
	for b in GameState.bf:
		var zone_key: String = "pU" if owner == "player" else "eU"
		var ephemeral_bf: Array = b[zone_key].filter(func(u): return GameState.has_keyword(u, "瞬息"))
		if ephemeral_bf.is_empty():
			continue
		b[zone_key] = b[zone_key].filter(func(u): return not GameState.has_keyword(u, "瞬息"))
		for u in ephemeral_bf:
			GameState.trigger_deathwish(u, owner)
			discard.append(u)
			GameState._log("瞬息：【%s】在开始阶段被摧毁。" % u.get("name", "?"), "imp")
			found = true

	if found:
		GameState.emit_signal("state_updated")


# ═══════════════════════════════════════════════
# 预知（规则 729）
# 常驻牌进场时：查看牌库顶1张，可选回收至底部
# ═══════════════════════════════════════════════

## apply_foresight_keyword(unit, owner) — 处理带【预知】关键词的单位入场效果
## 调用时机：SpellManager.on_summon() 之后
## 注意：若单位 effect = "foresight_mech_enter"，SpellManager 已处理过，此处跳过
func apply_foresight_keyword(unit: Dictionary, owner: String) -> void:
	if not GameState.has_keyword(unit, "预知"):
		return
	# foresight_mech_enter 已由 SpellManager 处理，避免重复触发
	if unit.get("effect", "") == "foresight_mech_enter":
		return
	var deck: Array = GameState.p_deck if owner == "player" else GameState.e_deck
	if deck.is_empty():
		GameState._log("牌库为空，预知失效！", "phase")
		return
	var top_card: Dictionary = deck[deck.size() - 1]
	if owner == "player":
		var choice = await PromptManager.ask({
			"title": "预知",
			"msg": "查看牌库顶【%s】（费用%d），是否回收至牌库底部？" % [
				top_card.get("name", "?"), top_card.get("cost", 0)],
			"type": "confirm"
		})
		if choice:
			deck.pop_back()
			deck.insert(0, top_card)
			GameState._log("预知：将【%s】回收至牌库底部" % top_card.get("name", "?"), "imp")
		else:
			GameState._log("预知：保留了【%s】在牌库顶" % top_card.get("name", "?"), "imp")
	else:
		# AI：高费牌回收，低费牌保留
		if top_card.get("cost", 0) >= 5:
			deck.pop_back()
			deck.insert(0, top_card)
			GameState._log("AI预知：将【%s】回收至牌库底部" % top_card.get("name", "?"), "imp")
		else:
			GameState._log("AI预知：保留了【%s】在牌库顶" % top_card.get("name", "?"), "imp")


# ═══════════════════════════════════════════════
# 待命（规则 723）
# 可选择以正面朝下的方式部署到己方控制的战场
# 下一名玩家回合后可打出（忽略基础费用）
# ═══════════════════════════════════════════════

## can_deploy_standby(card, bf_id, owner) — 检查是否能以待命方式部署此牌
func can_deploy_standby(card: Dictionary, bf_id: int, owner: String) -> bool:
	if not GameState.has_keyword(card, "待命"):
		return false
	var target_bf: Variant = GameState._find_bf(bf_id)
	if target_bf == null:
		return false
	# 该战场必须由己方控制
	if target_bf.get("ctrl", null) != owner:
		return false
	# 该战场不能已有待命牌
	if target_bf.get("standby", null) != null:
		return false
	# 须支付 [C] = 1点任意符能（规则723）
	return GameState.get_sch(owner) >= 1


## deploy_standby(card, bf_id, owner) — 将牌正面朝下部署到战场待命槽
## 规则 723：部署不属于"打出"，不开启结算链
## 返回 true=成功，false=条件不满足
func deploy_standby(card: Dictionary, bf_id: int, owner: String) -> bool:
	if not can_deploy_standby(card, bf_id, owner):
		return false
	var target_bf = GameState._find_bf(bf_id)
	if target_bf == null:
		return false
	# 扣除 [C] = 1点符能（规则723：从拥有存量的类型中贪心扣除1点）
	var sch_dict: Dictionary = GameState.p_sch if owner == "player" else GameState.e_sch
	for sch_type in sch_dict:
		if sch_dict.get(sch_type, 0) > 0:
			GameState.spend_sch(owner, sch_type, 1)
			GameState._log("待命部署费用：消耗1点%s符能（规则723）" % sch_type, "phase")
			break
	# 记录部署信息到待命槽
	target_bf["standby"] = {
		"card": card.duplicate(true),
		"owner": owner,
		"deployed_round": GameState.round
	}
	GameState._log("【%s】以待命方式部署到战场%d。" % [card.get("name", "?"), bf_id], "phase")
	GameState.emit_signal("state_updated")
	return true


## can_play_from_standby(bf_id, owner) — 检查是否可从待命区打出该牌
## 规则 723：从下一名玩家回合开始可打出，无视基础费用
func can_play_from_standby(bf_id: int, owner: String) -> bool:
	var target_bf = GameState._find_bf(bf_id)
	if target_bf == null:
		return false
	var standby: Variant = target_bf.get("standby", null)
	if standby == null:
		return false
	if standby.get("owner", "") != owner:
		return false
	# 下一名玩家回合：即部署时回合结束后（下一个 turn 中）
	return standby.get("deployed_round", -1) < GameState.round


## play_from_standby(bf_id, owner) — 从待命区打出牌（忽略基础费用）
## 返回打出的卡 dict，若失败返回 {}
func play_from_standby(bf_id: int, owner: String) -> Dictionary:
	if not can_play_from_standby(bf_id, owner):
		return {}
	var target_bf = GameState._find_bf(bf_id)
	var standby: Dictionary = target_bf.get("standby", {})
	var card: Dictionary = standby.get("card", {})
	if card.is_empty():
		return {}
	target_bf["standby"] = null  # 清空待命槽
	GameState._log("从待命区打出【%s】（忽略基础费用）！" % card.get("name", "?"), "imp")
	GameState.emit_signal("state_updated")
	return card
