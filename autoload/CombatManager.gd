extends Node
# ═══════════════════════════════════════════════
# CombatManager.gd — 单位移动、战斗结算、清理、战场能力
# 对应 combat.js 的核心逻辑（无 UI 层）
# 阶段三版本：纯逻辑，无动画/提示/setTimeout
# ═══════════════════════════════════════════════

signal combat_resolved(bf_id: int, result_state: String)
signal unit_moved(unit_uid: int, from_loc: String, to_bf_id: int, side: String)
signal combat_about_to_start(bf_id: int, attacker: String)


# ─────────────────────────────────────────────
# update_bf_control — 根据战场单位实际归属重算控制权
# 规则181：控制权是持续状态，有单位的一方控制；无单位 → null
# 在移动、召回、死亡清理后调用，确保 ctrl 始终准确
# ─────────────────────────────────────────────
func update_bf_control(bf_id: int) -> void:
	var bfield: Dictionary = GameState.bf[bf_id - 1]
	var p_has: bool = bfield["pU"].size() > 0
	var e_has: bool = bfield["eU"].size() > 0
	if p_has and not e_has:
		bfield["ctrl"] = "player"
	elif e_has and not p_has:
		bfield["ctrl"] = "enemy"
	elif not p_has and not e_has:
		bfield["ctrl"] = null
	# 双方均有单位（争夺中）→ 不改变 ctrl，保留战斗前的控制状态


# ─────────────────────────────────────────────
# move_unit — 移动单位到目标战场或基地
# from_loc : "base" 或战场编号字符串 "1"~"9"
# to_bf    : "base" 或整数战场编号 1~9
# side     : "player" 或 "enemy"
# ─────────────────────────────────────────────
func move_unit(unit: Dictionary, from_loc: String, to_bf, side: String, no_trigger: bool = false) -> void:
	# ── 召回基地 ──
	if str(to_bf) == "base":
		if from_loc != "base":
			var fbf: Dictionary = GameState.bf[int(from_loc) - 1]
			if side == "player":
				fbf["pU"] = fbf["pU"].filter(func(u): return u["uid"] != unit["uid"])
			else:
				fbf["eU"] = fbf["eU"].filter(func(u): return u["uid"] != unit["uid"])
			# 规则181：单位离开战场后立即重算控制权
			update_bf_control(int(from_loc))
		unit["exhausted"] = false
		var arr: Array = GameState.p_base if side == "player" else GameState.e_base
		if not arr.any(func(u): return u["uid"] == unit["uid"]):
			arr.append(unit)
		GameState._log(("你" if side == "player" else "AI") + "的【" + unit.get("name", "?") + "】撤回基地", "phase")
		return

	var bf_id: int = int(to_bf)
	var bfield: Dictionary = GameState.bf[bf_id - 1]
	var own_slots: Array = bfield["pU"] if side == "player" else bfield["eU"]
	var already_there: bool = own_slots.any(func(u): return u["uid"] == unit["uid"])
	if not already_there and own_slots.size() >= 2:
		GameState._log("战场%d己方槽位已满（最多2名），%s无法进入！" % [bf_id, unit.get("name", "?")], "imp")
		return

	# ── 暗巷酒吧能力（离开战场时）──
	if from_loc != "base":
		var fbf: Dictionary = GameState.bf[int(from_loc) - 1]
		var fbf_card = fbf.get("card")
		if fbf_card != null and fbf_card.get("id", "") == "back_alley_bar" and side == "player":
			unit["tb"]["atk"] = unit.get("tb", {}).get("atk", 0) + 1
			GameState._log("暗巷酒吧：%s 离开酒馆，本回合战力+1！" % unit.get("name", "?"), "imp")
		if side == "player":
			fbf["pU"] = fbf["pU"].filter(func(u): return u["uid"] != unit["uid"])
		else:
			fbf["eU"] = fbf["eU"].filter(func(u): return u["uid"] != unit["uid"])
		# 规则181：从战场移动到另一战场，离开时也要重算源战场控制权
		update_bf_control(int(from_loc))
	else:
		if side == "player":
			GameState.p_base = GameState.p_base.filter(func(u): return u["uid"] != unit["uid"])
		else:
			GameState.e_base = GameState.e_base.filter(func(u): return u["uid"] != unit["uid"])

	# ── 进入目标战场 ──
	if side == "player":
		bfield["pU"].append(unit)
	else:
		bfield["eU"].append(unit)
	unit["exhausted"] = true
	GameState._log(("你" if side == "player" else "AI") + "的【" + unit.get("name", "?") + "】移动至战场" + str(bf_id), "phase")

	# ── 崔法利战营能力（进入战场时）──
	var bf_card = bfield.get("card")
	if bf_card != null and bf_card.get("id", "") == "trifarian_warcamp" and side == "player":
		GameState.apply_buff_token(unit)
		GameState._log("崔法利战营：%s 抵达战营，获得增益指示物！" % unit.get("name", "?"), "imp")

	if no_trigger:
		return

	var has_enemies: bool = bfield["eU"].size() > 0 if side == "player" else bfield["pU"].size() > 0
	if side == "player" and has_enemies:
		reveal_standby(bf_id)
	# 无论是否有敌方，立即刷新 UI（让单位立刻显示在战场上）
	GameState.emit_signal("state_updated")
	if has_enemies:
		emit_signal("combat_about_to_start", bf_id, side)
	else:
		# 规则 516.5.b / 630：移动到无敌方单位的战场 →
		# 控制权和征服得分由调用方在法术对决结束后处理（trigger_empty_bf_conquer）
		emit_signal("unit_moved", unit["uid"], from_loc, bf_id, side)


# ─────────────────────────────────────────────
# trigger_combat — 主战斗结算
# 对应 combat.js triggerCombat()
# Phase 3：完全同步，无动画延迟
# ─────────────────────────────────────────────
func trigger_combat(bf_id: int, attacker: String) -> void:
	# ── 法术对决阶段（先于伤害计算）──
	await _run_duel_phase(bf_id, attacker)
	if GameState.game_over:
		return

	var bfield: Dictionary = GameState.bf[bf_id - 1]
	var atk_us: Array = bfield["pU"] if attacker == "player" else bfield["eU"]
	var def_us: Array = bfield["eU"] if attacker == "player" else bfield["pU"]

	# ── 清算人竞技场：战力≥5的单位分别获得强攻/坚守 ──
	var bf_card = bfield.get("card")
	if bf_card != null and bf_card.get("id", "") == "reckoner_arena":
		for u in atk_us:
			if GameState.get_atk(u) >= 5 and not GameState.has_keyword(u, "强攻"):
				GameState.add_keyword(u, "强攻")
				GameState._log("清算人竞技场：%s(进攻) 获得【强攻】！" % u.get("name", "?"))
		for u in def_us:
			if GameState.get_atk(u) >= 5 and not GameState.has_keyword(u, "坚守"):
				GameState.add_keyword(u, "坚守")
				GameState._log("清算人竞技场：%s(防守) 获得【坚守】！" % u.get("name", "?"))

	# ── 规则 625.1.c：触发"当我防守时"触发式技能（法术对决步骤）──
	# 无极剑圣·独影剑鸣：独守时+2战力
	var defender: String = "enemy" if attacker == "player" else "player"
	LegendManager.trigger_legend_event("onCombatDefend", defender, {"bf_id": bf_id})

	# ── 计算进攻/防守战力（眩晕单位输出强制为0）──
	var atk_pow: int = 0
	for u in atk_us:
		if not u.get("stunned", false):
			atk_pow += _role_atk(u, "attacker")
	var def_pow: int = 0
	for u in def_us:
		if not u.get("stunned", false):
			def_pow += _role_atk(u, "defender")

	GameState._log("战场%d：进攻%d战 vs 防守%d战" % [bf_id, atk_pow, def_pow], "combat")

	# ── 伤害分配（壁垒单位优先受击） ──
	# 先按 current_hp 升序排序，再将壁垒单位提前
	var sorted_def: Array = def_us.duplicate()
	sorted_def.sort_custom(func(a, b): return a.get("current_hp", 0) < b.get("current_hp", 0))
	var sorted_atk: Array = atk_us.duplicate()
	sorted_atk.sort_custom(func(a, b): return a.get("current_hp", 0) < b.get("current_hp", 0))

	var atk_overflow: int = _assign_damage(atk_pow, sorted_def)
	var def_overflow: int = _assign_damage(def_pow, sorted_atk)

	# ── 压制：溢出伤害传递给对方传奇 ──
	if atk_overflow > 0 and atk_us.any(func(u): return GameState.has_keyword(u, "压制")):
		var leg: Dictionary = GameState.e_leg if attacker == "player" else GameState.p_leg
		if not leg.is_empty():
			leg["current_hp"] -= atk_overflow
			GameState.emit_signal("unit_damaged", -1, atk_overflow, true)
			GameState._log("压制：%d溢出伤害传奇" % atk_overflow, "combat")
			if leg["current_hp"] <= 0:
				clean_dead(bf_id)
				GameState._end_game(
					"player_win" if attacker == "player" else "player_lose",
					"AI传奇阵亡！你获胜了！" if attacker == "player" else "你的传奇阵亡！你失败了！"
				)
				return

	if def_overflow > 0 and def_us.any(func(u): return GameState.has_keyword(u, "压制")):
		var leg: Dictionary = GameState.p_leg if attacker == "player" else GameState.e_leg
		if not leg.is_empty():
			leg["current_hp"] -= def_overflow
			GameState.emit_signal("unit_damaged", -1, def_overflow, true)
			GameState._log("压制：%d溢出伤害传奇" % def_overflow, "combat")
			if leg["current_hp"] <= 0:
				clean_dead(bf_id)
				GameState._end_game(
					"player_lose" if attacker == "player" else "player_win",
					"你的传奇阵亡！你失败了！" if attacker == "player" else "AI传奇阵亡！你获胜了！"
				)
				return

	# ── 累计造伤追踪（用于传奇被动条件，如无极升华）──
	GameState.p_ally_dmg_dealt += atk_pow if attacker == "player" else def_pow
	GameState.e_ally_dmg_dealt += atk_pow if attacker == "enemy" else def_pow

	# ── 死亡清理 ──
	clean_dead(bf_id)

	# ── 规则627.5：战斗结束后重置所有存活单位的HP ──
	var all_survivors: Array = []
	all_survivors.append_array(GameState.p_base)
	all_survivors.append_array(GameState.e_base)
	for b in GameState.bf:
		all_survivors.append_array(b["pU"])
		all_survivors.append_array(b["eU"])
	for u in all_survivors:
		if u.get("type", "") == "champion":
			continue  # 传奇有独立 current_hp，不在此处重置
		u["current_hp"] = u["current_atk"]

	# ── 战斗结果判定 ──
	var atk_alive: bool = (bfield["pU"] if attacker == "player" else bfield["eU"]).size() > 0
	var def_alive: bool = (bfield["eU"] if attacker == "player" else bfield["pU"]).size() > 0

	var result: String = ""
	var result_state: String = ""

	if not atk_alive and not def_alive:
		bfield["ctrl"] = null
		result = "双方全灭，无控制方"
	elif atk_alive and not def_alive:
		if bfield["ctrl"] != attacker and not bfield.get("conq_done", false):
			bfield["ctrl"] = attacker
			bfield["conq_done"] = true
			result_state = "conquer"
			var scored: bool = GameState.add_score(attacker, 1, "conquer", bf_id)
			result = "进攻方征服战场！" + ("+1分" if scored else "最后1分受限")
		else:
			bfield["ctrl"] = attacker
			result = "进攻方保持控制"
	elif not atk_alive and def_alive:
		bfield["ctrl"] = "enemy" if attacker == "player" else "player"
		result = "防守方击退进攻"
		result_state = "defend_success"
	else:
		# 双方均存活 → 规则627.2：进攻方召回至己方基地
		result_state = "draw"
		var ret_base: Array = GameState.p_base if attacker == "player" else GameState.e_base
		var ret_units: Array = (bfield["pU"] if attacker == "player" else bfield["eU"]).duplicate()
		for u in ret_units:
			u["exhausted"] = true
			ret_base.append(u)
		if attacker == "player":
			bfield["pU"] = []
		else:
			bfield["eU"] = []
		# 攻方撤回后只剩防守方，用 update_bf_control 准确重算（而非硬编码）
		update_bf_control(bf_id)
		result = "进攻方撤回基地（" + ("防守方" if bfield["ctrl"] != null else "无人") + "控制）"

	GameState._log("结果：" + result, "combat")

	# ── 战后结算 ──
	await _post_combat_full(bf_id, attacker, result_state)
	# 战后再算一次（_post_combat_full 可能移走征服后单位）
	update_bf_control(bf_id)
	GameState.check_win()
	emit_signal("combat_resolved", bf_id, result_state)


# ── 战后完整结算（战场能力 + 征服召回 + 传奇被动）──
func _post_combat_full(bf_id: int, attacker: String, result_state: String) -> void:
	await post_combat_triggers(bf_id, attacker, result_state)

	# 规则627.3：征服情况下进攻方单位【留在战场】，不召回基地
	# 只有规则627.2"双方均存活"的平局情况才召回
	# 征服后单位留场，维持控制权，可在下回合继续据守得分

	# 传奇被动检查（规则 625.1.b：每次状态变化后检测被动条件）
	LegendManager.check_legend_passives("player")
	LegendManager.check_legend_passives("enemy")


# ─────────────────────────────────────────────
# _role_atk — 计算单位在指定角色下的有效战力
# 含强攻（进攻+bonus）、坚守（防守+bonus）加成
# ─────────────────────────────────────────────
func _role_atk(unit: Dictionary, role: String) -> int:
	var bonus: int = 0
	if role == "attacker" and GameState.has_keyword(unit, "强攻"):
		bonus += unit.get("strong_atk_bonus", 1)
	if role == "defender" and GameState.has_keyword(unit, "坚守"):
		bonus += unit.get("guard_bonus", 1)
	return GameState.get_atk(unit) + bonus


# ─────────────────────────────────────────────
# _assign_damage — 对目标数组分配伤害
# targets 已按 current_hp 升序预排序
# 壁垒单位优先承受伤害（维持排序顺序）
# 返回溢出伤害值
# ─────────────────────────────────────────────
func _assign_damage(dmg_pool: int, targets: Array) -> int:
	# 重排：壁垒且存活的在前，其他在后（各组内保持原有hp排序）
	var barrier_units: Array = []
	var other_units: Array = []
	for u in targets:
		if GameState.has_keyword(u, "壁垒") and u.get("current_hp", 0) > 0:
			barrier_units.append(u)
		else:
			other_units.append(u)
	var ordered: Array = barrier_units + other_units

	for u in ordered:
		if dmg_pool <= 0 or u.get("current_hp", 0) <= 0:
			continue
		var d: int = mini(dmg_pool, u["current_hp"])
		u["current_hp"] -= d
		GameState.emit_signal("unit_damaged", u.get("uid", -1), d, false)
		dmg_pool -= d
	return dmg_pool


# ─────────────────────────────────────────────
# clean_dead — 清理指定战场上死亡的单位
# 对应 combat.js cleanDead()
# 关键：先从战场移除死亡单位，再处理绝念/重置，
#       避免 _reset_unit 复原 HP 后被过滤误判为存活。
# ─────────────────────────────────────────────
func clean_dead(bf_id: int) -> void:
	var bfield: Dictionary = GameState.bf[bf_id - 1]

	for k in ["pU", "eU"]:
		var unit_owner: String = "player" if k == "pU" else "enemy"
		var owner_base: Array    = GameState.p_base    if unit_owner == "player" else GameState.e_base
		var owner_discard: Array = GameState.p_discard if unit_owner == "player" else GameState.e_discard

		# 规则144.3：误入战场的装备牌 → 召回控制者基地
		var misplaced: Array = bfield[k].filter(func(u): return u.get("type", "") == "equipment")
		for u in misplaced:
			owner_base.append(u)
			GameState._log("【%s】（装备）已从战场召回至基地" % u.get("name", "?"), "phase")
		bfield[k] = bfield[k].filter(func(u): return u.get("type", "") != "equipment")

		# 先识别死亡单位，再从战场移除，最后处理效果
		var dead: Array = bfield[k].filter(func(u): return u.get("current_hp", 1) <= 0)
		bfield[k] = bfield[k].filter(func(u): return u.get("current_hp", 1) > 0)  # 先移除！

		for u in dead:
			if _try_death_shield(u, owner_base, owner_discard, "玩家" if unit_owner == "player" else "敌方"):
				pass  # 中娅沙漏救回，已重新入基地
			else:
				GameState._log(u.get("name", "?") + " 阵亡", "combat")
				# 附着装备先单独入废牌堆（原JS逻辑：attachedEquipments.forEach -> discard）
				for eq in u.get("attached_equipments", []):
					owner_discard.append(eq)
				u["attached_equipments"] = []
				GameState.trigger_deathwish(u, unit_owner)
				_reset_unit(u)
				owner_discard.append(u)

	# 处理基地阵亡单位
	_clean_base_dead("player")
	_clean_base_dead("enemy")
	# 规则181：法术/战斗死亡后单位数量变化，重算该战场控制权
	update_bf_control(bf_id)


func _clean_base_dead(side: String) -> void:
	var base: Array    = GameState.p_base    if side == "player" else GameState.e_base
	var discard: Array = GameState.p_discard if side == "player" else GameState.e_discard

	var dead: Array = base.filter(func(u): return u.get("current_hp", 1) <= 0 and u.get("effect", "") != "death_shield" and u.get("type", "") != "equipment")
	if dead.is_empty():
		return

	# 先从基地移除死亡单位
	var dead_uids: Array = dead.map(func(u): return u["uid"])
	if side == "player":
		GameState.p_base = base.filter(func(u): return not (u["uid"] in dead_uids))
	else:
		GameState.e_base = base.filter(func(u): return not (u["uid"] in dead_uids))

	# 再处理绝念和重置
	for u in dead:
		GameState._log(u.get("name", "?") + " 阵亡", "combat")
		for eq in u.get("attached_equipments", []):
			discard.append(eq)
		u["attached_equipments"] = []
		GameState.trigger_deathwish(u, side)
		_reset_unit(u)
		discard.append(u)


# ── 重置单位状态（入废牌堆前调用）──
func _reset_unit(unit: Dictionary) -> void:
	var base_atk: int = unit.get("atk", 0)
	unit["current_hp"]  = base_atk
	unit["current_atk"] = base_atk
	unit["exhausted"]   = false
	unit["stunned"]     = false
	unit["tb"]          = { "atk": 0 }
	unit["buff_token"]  = false


# ─────────────────────────────────────────────
# _try_death_shield — 尝试用中娅沙漏装备救回濒死单位
# 对应 spell.js tryDeathShield()
# ─────────────────────────────────────────────
func _try_death_shield(dying: Dictionary, owner_base: Array, owner_discard: Array, owner_name: String) -> bool:
	var shield_idx: int = -1
	for i in range(owner_base.size()):
		if owner_base[i].get("effect", "") == "death_shield":
			shield_idx = i
			break
	if shield_idx < 0:
		return false

	var shield: Dictionary = owner_base[shield_idx]
	owner_base.remove_at(shield_idx)
	owner_discard.append(shield)

	dying["current_hp"]  = dying.get("atk", 0)
	dying["current_atk"] = dying.get("atk", 0)
	dying["exhausted"]   = true
	dying["stunned"]     = false
	dying["tb"]          = { "atk": 0 }
	owner_base.append(dying)
	GameState._log("【中娅沙漏】触发！摧毁装备，%s以休眠状态撤回%s基地！" % [dying.get("name", "?"), owner_name], "imp")
	return true


# ─────────────────────────────────────────────
# post_combat_triggers — 战后战场特殊能力
# 对应 combat.js postCombatTriggers()
# ─────────────────────────────────────────────
func post_combat_triggers(bf_id: int, attacker: String, result_state: String) -> void:
	var bfield: Dictionary = GameState.bf[bf_id - 1]
	if bfield.get("card") == null:
		return
	var card_id: String = bfield["card"].get("id", "")

	# ── 玩家方征服 ──
	if result_state == "conquer" and attacker == "player":
		match card_id:
			"hirana":
				# 消耗增益指示物 → 抽1张牌
				var buff_units: Array = GameState.get_all_units("player").filter(
					func(u): return u.get("buff_token", false))
				if buff_units.size() > 0:
					var uid = await PromptManager.ask({
						"title": "希拉娜修道院",
						"msg": "消耗1个增益指示物抽1张牌。选择一个单位（可跳过）。",
						"type": "targets", "targets": buff_units, "optional": true
					})
					if uid != null:
						for u in buff_units:
							if u.get("uid") == uid:
								u["buff_token"] = false
								GameState.draw_card("player", 1)
								GameState._log("希拉娜修道院：消耗增益指示物，抽1张牌！", "imp")
								break

			"reaver_row":
				# 从废牌堆召回≤2费单位
				var valid: Array = GameState.p_discard.filter(
					func(c): return c.get("type", "") != "spell" and c.get("cost", 99) <= 2)
				if valid.size() > 0:
					var uid = await PromptManager.ask({
						"title": "掠夺者之街",
						"msg": "从废牌堆召回一名≤2费单位到基地（可跳过）。",
						"type": "cards", "cards": valid, "optional": true
					})
					if uid != null and GameState.p_base.size() < 5:
						for i in GameState.p_discard.size():
							if GameState.p_discard[i].get("uid") == uid:
								var unit = GameState.p_discard.pop_at(i)
								unit["exhausted"] = true
								GameState.p_base.append(unit)
								GameState._log("掠夺者之街：召回【%s】到基地！" % unit.get("name", "?"), "imp")
								break

			"zaun_undercity":
				# 弃1张手牌 → 抽1张牌
				if GameState.p_hand.size() > 0:
					var uid = await PromptManager.ask({
						"title": "祖安地沟",
						"msg": "弃置一张手牌，抽1张牌（可跳过）。",
						"type": "cards", "cards": GameState.p_hand, "optional": true
					})
					if uid != null:
						for i in GameState.p_hand.size():
							if GameState.p_hand[i].get("uid") == uid:
								var discarded = GameState.p_hand.pop_at(i)
								GameState.p_discard.append(discarded)
								GameState.draw_card("player", 1)
								GameState._log("祖安地沟：弃【%s】，抽1张牌！" % discarded.get("name", "?"), "imp")
								break

			"strength_obelisk":
				# 额外获得1张符文（自动）
				if GameState.p_rune_deck.size() > 0:
					GameState.p_runes.append(GameState.p_rune_deck.pop_back())
					GameState._log("力量方尖碑 (征服)：额外获得1张符文！", "imp")

			"thunder_rune":
				# 解除1个已横置符文 + 获得对应符能
				var tapped: Array = GameState.p_runes.filter(func(r): return r.get("tapped", false))
				if tapped.size() > 0:
					var uid = await PromptManager.ask({
						"title": "雷霆之纹",
						"msg": "解除一个已横置符文，获得对应符能（可跳过）。",
						"type": "targets", "targets": tapped, "optional": true
					})
					if uid != null:
						for r in tapped:
							if r.get("uid") == uid:
								r["tapped"] = false
								var sch_type: String = r.get("rune_type", "")
								if sch_type != "":
									GameState.add_sch("player", sch_type, 1)
								GameState._log("雷霆之纹：解除符文，获得1点%s符能！" % sch_type, "imp")
								break

		# 坏坏魄罗：征服时在玩家基地召唤2/2魄罗（自动）
		if bfield["pU"].any(func(u): return u.get("id", "") == "bad_poro") and GameState.p_base.size() < 5:
			var token: Dictionary = GameState.mk({
				"id": "poro_token", "name": "魄罗", "region": "void",
				"type": "follower", "cost": 2, "atk": 2, "hp": 2,
				"keywords": [], "text": "", "img": ""
			})
			token["exhausted"] = true
			GameState.p_base.append(token)
			GameState._log("坏坏魄罗：征服战场，召唤一个2/2魄罗到基地！", "imp")

	# ── AI 方征服 ──
	if result_state == "conquer" and attacker == "enemy":
		match card_id:
			"hirana":
				var buff_units: Array = GameState.get_all_units("enemy").filter(
					func(u): return u.get("buff_token", false))
				if buff_units.size() > 0:
					buff_units[0]["buff_token"] = false
					GameState.draw_card("enemy", 1)
					GameState._log("AI希拉娜修道院：消耗增益指示物，AI抽1张牌！", "imp")

			"reaver_row":
				var valid_idx: int = -1
				for i in GameState.e_discard.size():
					var c = GameState.e_discard[i]
					if c.get("type", "") != "spell" and c.get("cost", 99) <= 2:
						valid_idx = i; break
				if valid_idx >= 0 and GameState.e_base.size() < 5:
					var unit = GameState.e_discard.pop_at(valid_idx)
					unit["exhausted"] = true
					GameState.e_base.append(unit)
					GameState._log("AI掠夺者之街：召回【%s】到AI基地！" % unit.get("name", "?"), "imp")

			"zaun_undercity":
				if GameState.e_hand.size() > 0:
					# AI弃置费用最低的牌
					var worst_idx: int = 0
					var worst_cost: int = 99
					for i in GameState.e_hand.size():
						var c: int = GameState.e_hand[i].get("cost", 99)
						if c < worst_cost:
							worst_cost = c; worst_idx = i
					var discarded = GameState.e_hand.pop_at(worst_idx)
					GameState.e_discard.append(discarded)
					GameState.draw_card("enemy", 1)
					GameState._log("AI祖安地沟：弃【%s】，AI抽1张牌！" % discarded.get("name", "?"), "imp")

			"strength_obelisk":
				if GameState.e_rune_deck.size() > 0:
					GameState.e_runes.append(GameState.e_rune_deck.pop_back())
					GameState._log("AI力量方尖碑 (征服)：AI额外获得1张符文！", "imp")

			"thunder_rune":
				var tapped: Array = GameState.e_runes.filter(func(r): return r.get("tapped", false))
				if tapped.size() > 0:
					tapped[0]["tapped"] = false
					var sch_type: String = tapped[0].get("rune_type", "")
					if sch_type != "":
						GameState.add_sch("enemy", sch_type, 1)
					GameState._log("AI雷霆之纹：解除符文，获得1点%s符能！" % sch_type, "imp")

		# AI坏坏魄罗
		if bfield["eU"].any(func(u): return u.get("id", "") == "bad_poro") and GameState.e_base.size() < 5:
			var token: Dictionary = GameState.mk({
				"id": "poro_token", "name": "魄罗", "region": "void",
				"type": "follower", "cost": 2, "atk": 2, "hp": 2,
				"keywords": [], "text": "", "img": ""
			})
			token["exhausted"] = true
			GameState.e_base.append(token)
			GameState._log("AI坏坏魄罗：征服战场，召唤一个2/2魄罗到AI基地！", "imp")

	# ── AI 征服时：玩家可触发的防守特效 ──
	if result_state == "conquer" and attacker == "enemy":
		if card_id == "sunken_temple" and GameState.p_mana >= 2:
			var ok = await PromptManager.ask({
				"title": "沉没神庙",
				"msg": "支付2法力抽1张牌？",
				"type": "confirm", "optional": true
			})
			if ok:
				GameState.p_mana -= 2
				GameState.draw_card("player", 1)
				GameState._log("沉没神庙：支付2法力，抽1张牌！", "imp")


# ─────────────────────────────────────────────
# reveal_standby — 翻开待命区伏兵
# 对应 combat.js revealStandby()
# ─────────────────────────────────────────────
func reveal_standby(bf_id: int) -> bool:
	var bfield: Dictionary = GameState.bf[bf_id - 1]
	var standby = bfield.get("standby")
	if standby == null or not standby is Dictionary or standby.is_empty():
		return false
	var card: Dictionary = standby.get("card", {})
	if card.is_empty():
		return false
	bfield["standby"] = null
	card["exhausted"] = true
	bfield["pU"].append(card)
	GameState._log("待命牌翻开！【%s】加入战场%d！" % [card.get("name", "?"), bf_id], "imp")
	return true


# ─────────────────────────────────────────────
# _run_duel_phase — 法术对决（伤害计算前的迅捷/反应窗口）
# 对应 JS spellDuel()
# 双方轮流出牌，连续两次跳过时对决结束
# ─────────────────────────────────────────────
func _run_duel_phase(bf_id: int, attacker: String) -> void:
	# 检查双方是否有可用的迅捷/反应牌；若均无，跳过对决
	var p_has_fast: bool = GameState.p_hand.any(
		func(c): return KeywordManager.can_play_in_timing(c, "duel") and SpellManager.can_play(c, "player"))
	var e_has_fast: bool = GameState.e_hand.any(
		func(c): return KeywordManager.can_play_in_timing(c, "duel") and SpellManager.can_play(c, "enemy"))
	if not p_has_fast and not e_has_fast:
		return

	GameState.duel_active = true
	GameState.duel_bf = bf_id
	GameState.duel_attacker = attacker
	GameState.duel_turn = attacker  # 进攻方先
	GameState.duel_skips = 0
	GameState._log("⚔ 法术对决开始！（战场%d，进攻方：%s）" % [bf_id, "你" if attacker == "player" else "AI"], "phase")
	GameState.emit_signal("banner_shown", "⚔ 法术对决", "score-" + attacker)
	GameState.emit_signal("state_updated")

	while GameState.duel_skips < 2 and not GameState.game_over:
		if GameState.duel_turn == "player":
			# 等待玩家行动（GameBoard 通过按钮或出牌 emit duel_player_acted）
			await GameState.duel_player_acted
		else:
			# AI 自动决策
			await get_tree().create_timer(0.5).timeout
			await AIManager.ai_duel_action()

	GameState.duel_active = false
	GameState._log("⚔ 法术对决结束，开始战斗结算", "phase")
	GameState.emit_signal("state_updated")


# ─────────────────────────────────────────────
# trigger_empty_bf_conquer
# 规则 516.5.b + 630：单位移动至无人控制战场时
#   1. 运行法术对决（双方均无迅捷/反应牌时自动跳过）
#   2. 对决结束后确立控制权
#   3. 若移动方仍控制该战场且本回合未得过分 → 征服得分
#   4. 触发战场征服特殊能力
# ─────────────────────────────────────────────
func trigger_empty_bf_conquer(bf_id: int, side: String) -> void:
	await _run_duel_phase(bf_id, side)
	if GameState.game_over:
		return
	# 对决后重新确立控制权
	update_bf_control(bf_id)
	var bfield: Dictionary = GameState.bf[bf_id - 1]
	# 若移动方仍有单位在场且未征服过
	if bfield.get("ctrl") == side and not bfield.get("conq_done", false):
		bfield["conq_done"] = true
		var scored: bool = GameState.add_score(side, 1, "conquer", bf_id)
		var who: String = "你" if side == "player" else "AI"
		GameState._log(who + "占领战场%d，征服！%s" % [bf_id, "+1分" if scored else "（最后1分受限，抽1张牌代替）"], "score")
		GameState.emit_signal("banner_shown", "★ 征服", "score-" + side)
		# 触发战场征服特殊能力（与战斗征服共用）
		await post_combat_triggers(bf_id, side, "conquer")
	GameState.emit_signal("state_updated")


# ─────────────────────────────────────────────
# check_legend_passives — 传奇被动能力检查（委托给 LegendManager）
# ─────────────────────────────────────────────
func check_legend_passives(owner: String) -> void:
	LegendManager.check_legend_passives(owner)
