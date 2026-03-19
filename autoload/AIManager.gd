extends Node
# ═══════════════════════════════════════════════
# AIManager.gd — AI 决策系统 (Autoload 单例)
# 对应 ai.js（704行）的核心逻辑移植
#
# 工作原理：
#   监听 GameState.action_phase_started("enemy")
#   → 异步执行完整的 ai_action() 决策循环
#   → 完成后调用 GameState.do_end_phase()
# ═══════════════════════════════════════════════

## 对决响应完成信号（法术对决中 AI 行动后通知 UI）
signal duel_action_done

## AI 行动间隔（秒）：给玩家一点"看到AI思考"的视觉反馈
## 测试时可设为 0.0 跳过延迟
var AI_THINK_DELAY: float = 0.4

## 胜利分数（与 GameState.win_score 保持同步）
var _win_score: int = 8

# ─────────────────────────────────────────────
# 初始化：注册信号监听
# ─────────────────────────────────────────────
func _ready() -> void:
	GameState.action_phase_started.connect(_on_action_phase_started)


func _on_action_phase_started(who: String) -> void:
	if who == "enemy":
		await ai_action()


# ═══════════════════════════════════════════════
# ai_action() — AI 主行动循环
# 对应 JS aiAction()
# ═══════════════════════════════════════════════
func ai_action() -> void:
	if GameState.game_over or GameState.turn != "enemy":
		return

	# 更新本地胜利分数（可能被攀圣长阶修改）
	_win_score = GameState.win_score

	# 统计 AI 手牌中反应牌信息（供后续步骤决策）
	var reactive_min_cost: int = _ai_min_reactive_cost()

	GameState._log("─── AI 开始行动 ───", "phase")

	# ── 1. 横置所有符文以获得法力 ──
	for r in GameState.e_runes.duplicate():
		if not r.get("tapped", false):
			GameState.tap_rune("enemy", r.get("uid", -1))

	# ── 行动循环：反复尝试出牌/移动，直到无事可做 ──
	var iterations: int = 0
	while iterations < 30:  # 安全上限，防止死循环
		iterations += 1

		if GameState.game_over:
			break

		# ── 2. 颠覆者·布隆希尔卡牌锁定检测 ──
		var card_lock: String = GameState.card_lock_target  # "" 表示无锁

		# ── 3. 优先打出「迎敌号令」(rally_call) ──
		var rally = _find_in_hand("enemy", func(c): return c.get("effect","") == "rally_call")
		if rally != null and SpellManager.can_play(rally, "enemy"):
			await _ai_play_card(rally, "enemy")
			continue

		if card_lock != "":
			# 有卡牌锁定时，只能出对应类型的卡（锁定解除前跳过其他步骤）
			var locked_card = _find_in_hand("enemy", func(c):
				return c.get("type","") == card_lock and SpellManager.can_play(c, "enemy"))
			if locked_card != null:
				await _ai_play_card(locked_card, "enemy")
				continue
			# 无法出牌，直接跳到移动步骤
		else:
			# ── 4. 打出「均衡裁决」(balance_resolve) ──
			var bal = _find_in_hand("enemy", func(c): return c.get("effect","") == "balance_resolve")
			if bal != null and SpellManager.can_play(bal, "enemy"):
				await _ai_play_card(bal, "enemy")
				continue

			# ── 5a. 出英雄卡 ──
			if not GameState.e_hero.is_empty():
				var hero: Dictionary = GameState.e_hero
				if SpellManager.can_play(hero, "enemy") and GameState.e_base.size() < 5:
					await _ai_play_hero("enemy")
					continue

			# ── 5b. 召唤随从（保留法力给反应牌）──
			var avail_mana: int = GameState.e_mana
			var mana_to_spend: int = avail_mana - reactive_min_cost if reactive_min_cost > 0 else avail_mana
			mana_to_spend = max(0, mana_to_spend)

			var units: Array = GameState.e_hand.filter(func(c):
				return c.get("type","") != "spell" \
					and c.get("type","") != "equipment" \
					and not GameState.has_keyword(c, "反应") \
					and SpellManager.can_play(c, "enemy") \
					and GameState.e_base.size() < 5
			)
			units.sort_custom(func(a, b): return ai_card_value(b) > ai_card_value(a))

			if units.size() > 0:
				var chosen: Dictionary = {}
				# 尝试在保留法力的条件下出牌
				for u in units:
					if SpellManager.get_effective_cost(u, "enemy") <= mana_to_spend:
						chosen = u
						break
				# 保留不了就出最强的
				if chosen.is_empty():
					chosen = units[0]
				await _ai_play_card(chosen, "enemy")
				continue

			# ── 5c. 部署装备 ──
			var equip = _find_in_hand("enemy", func(c):
				return c.get("type","") == "equipment" \
					and SpellManager.can_play(c, "enemy") \
					and GameState.e_base.size() < 5)
			if equip != null:
				await _ai_play_card(equip, "enemy")
				continue

			# ── 5d. 激活基地中未装配的装备 ──
			var base_equips: Array = GameState.e_base.filter(func(u):
				return u.get("type","") == "equipment" and u.get("effect","") != "death_shield")
			if not base_equips.is_empty():
				var eq: Dictionary = base_equips[0]
				var sch_cost: int   = eq.get("equip_sch_cost", 0)
				var sch_type: String = eq.get("equip_sch_type", "")
				var can_pay: bool = (sch_cost == 0 or GameState.get_sch("enemy", sch_type) >= sch_cost)
				var equip_targets: Array = GameState.e_base.filter(func(u): return u.get("type","") != "equipment")
				if can_pay and not equip_targets.is_empty():
					var target: Dictionary = equip_targets[0]
					if sch_cost > 0:
						GameState.spend_sch("enemy", sch_type, sch_cost)
					var bonus: int = eq.get("atk_bonus", 0)
					if bonus > 0:
						target["current_atk"] = target.get("current_atk",0) + bonus
						target["current_hp"]  = target.get("current_hp",0)  + bonus
						target["atk"]         = target.get("atk",0) + bonus
					if eq.get("effect","") == "trinity_equip":
						target["trinity_equipped"] = true
					elif eq.get("effect","") == "guardian_equip":
						target["guardian_equipped"] = true
					var eq_uid: int = eq.get("uid",-1)
					GameState.e_base = GameState.e_base.filter(func(u): return u.get("uid",-1) != eq_uid)
					if not target.get("attached_equipments"):
						target["attached_equipments"] = []
					target["attached_equipments"].append(eq)
					GameState._log("AI【装配】%s 装备了【%s】，战力+%d！" % [
						target.get("name","?"), eq.get("name","?"), bonus], "imp")
					GameState.emit_signal("state_updated")
					await get_tree().create_timer(AI_THINK_DELAY).timeout
					continue

			# ── 6. 施放法术（排除反应/迅捷牌留给对决） ──
			var spells: Array = GameState.e_hand.filter(func(c):
				return c.get("type","") == "spell" \
					and not GameState.has_keyword(c, "反应") \
					and not GameState.has_keyword(c, "迅捷") \
					and SpellManager.can_play(c, "enemy") \
					and _ai_should_play_spell(c)
			)
			spells.sort_custom(func(a, b): return _ai_spell_priority(b) > _ai_spell_priority(a))

			if spells.size() > 0:
				var sp: Dictionary = spells[0]
				var target_uid: int = _ai_choose_spell_target(sp, "enemy")
				await _ai_play_card(sp, "enemy", target_uid)
				continue

			# ── 7. 传奇主动技能 ──
			if LegendManager.ai_legend_action_phase():
				await get_tree().create_timer(AI_THINK_DELAY).timeout
				continue

		# ── 7b. 从待命区打出牌 ──
		var played_standby: bool = false
		for b in GameState.bf:
			var bf_id: int = b.get("id", -1)
			if KeywordManager.can_play_from_standby(bf_id, "enemy"):
				var sb_card: Dictionary = KeywordManager.play_from_standby(bf_id, "enemy")
				if not sb_card.is_empty():
					sb_card["cost"] = 0  # 待命出牌：无视基础法力费用（规则 723）
					GameState._log("AI 从待命区打出【%s】" % sb_card.get("name","?"), "imp")
					await get_tree().create_timer(AI_THINK_DELAY).timeout
					await SpellManager.play_card(sb_card, "enemy")
					GameState.emit_signal("state_updated")
					played_standby = true
					break
		if played_standby:
			continue

		# ── 8. 移动单位至战场 ──
		var active_units: Array = GameState.e_base.filter(func(u):
			return not u.get("exhausted", false) and not u.get("stunned", false) \
				and u.get("type", "") != "equipment")
		if active_units.size() > 0:
			var plan: Dictionary = _ai_decide_movement(active_units)
			if not plan.is_empty():
				var movers: Array = plan.get("movers", [])
				var target_bf_id: int = plan.get("target_bf_id", 1)
				# 移动前记录目标战场是否无人控制（规则 516.5.b）
				var was_empty: bool = GameState.bf[target_bf_id - 1].get("ctrl") == null
				for i in range(movers.size()):
					var no_trigger: bool = (i < movers.size() - 1)
					CombatManager.move_unit(movers[i], "base", target_bf_id, "enemy", no_trigger)
				await get_tree().create_timer(AI_THINK_DELAY).timeout
				if was_empty:
					# 规则 516.5.b + 630：空战场 → 法术对决 → 征服得分
					await CombatManager.trigger_empty_bf_conquer(target_bf_id, "enemy")
				break  # 移动后结束本次大循环（等待战斗结算）

		# 无事可做，退出循环
		break

	GameState._log("─── AI 结束行动 ───", "phase")
	await get_tree().create_timer(AI_THINK_DELAY).timeout
	if not GameState.game_over:
		await GameState.do_end_phase()


# ─────────────────────────────────────────────
# _ai_play_card — 执行 AI 出牌（带延迟）
# ─────────────────────────────────────────────
func _ai_play_card(card: Dictionary, owner: String, target_uid: int = -1) -> void:
	await get_tree().create_timer(AI_THINK_DELAY).timeout
	await SpellManager.play_card(card, owner, target_uid)
	GameState.emit_signal("state_updated")


# ─────────────────────────────────────────────
# _ai_play_hero — AI 打出英雄卡（从英雄区）
# ─────────────────────────────────────────────
func _ai_play_hero(owner: String) -> void:
	await get_tree().create_timer(AI_THINK_DELAY).timeout
	var hero: Dictionary = GameState.e_hero if owner == "enemy" else GameState.p_hero
	if hero.is_empty():
		return
	await SpellManager.play_card(hero, owner, -1, true)
	GameState.emit_signal("state_updated")


# ═══════════════════════════════════════════════
# ai_duel_action() — AI 法术对决响应
# 对应 JS aiDuelAction()
# ═══════════════════════════════════════════════
func ai_duel_action() -> void:
	if not GameState.duel_active or GameState.game_over:
		return

	var bf_id: int = GameState.duel_bf
	if bf_id < 1 or bf_id > GameState.bf.size():
		_ai_duel_skip()
		return

	var bfield: Dictionary = GameState.bf[bf_id - 1]
	var my_pow: int = 0
	for u in bfield["eU"]:
		if not u.get("stunned", false):
			my_pow += GameState.get_atk(u)
	var their_pow: int = 0
	for u in bfield["pU"]:
		if not u.get("stunned", false):
			their_pow += GameState.get_atk(u)
	var pow_diff: int = my_pow - their_pow

	# 筛选可用的迅捷/反应牌
	var fast_cards: Array = GameState.e_hand.filter(func(c):
		return c.get("type","") != "equipment" \
			and SpellManager.can_play(c, "enemy") \
			and (GameState.has_keyword(c, "迅捷") or GameState.has_keyword(c, "反应"))
	)

	var counter_spells: Array = fast_cards.filter(func(c):
		return c.get("type","") == "spell" \
			and c.get("effect","") in ["counter_cost4", "counter_any", "negate_spell"])
	var buff_spells: Array = fast_cards.filter(func(c):
		return c.get("type","") == "spell" \
			and c.get("effect","") in ["buff1_solo", "buff2_draw", "buff5_manual", "buff7_manual"])
	var stun_spells: Array = fast_cards.filter(func(c):
		return c.get("type","") == "spell" and c.get("effect","") == "stun_manual")
	var other_spells: Array = fast_cards.filter(func(c):
		return c.get("type","") == "spell" \
			and not (c in counter_spells) and not (c in buff_spells) and not (c in stun_spells))
	var fast_units: Array = fast_cards.filter(func(c): return c.get("type","") != "spell")

	# ── 情况0：反制对手法术（最高优先级）──
	if counter_spells.size() > 0 and GameState.last_player_spell_cost > 0:
		for cs in counter_spells:
			var can_counter: bool = false
			match cs.get("effect",""):
				"counter_any", "negate_spell": can_counter = true
				"counter_cost4": can_counter = GameState.last_player_spell_cost <= 4
			if can_counter:
				GameState._log("▶ AI对决反制：【%s】" % cs.get("name","?"), "imp")
				await SpellManager.play_card(cs, "enemy")
				GameState.last_player_spell_cost = 0
				GameState.duel_skips = 0
				GameState.duel_turn = "player"
				GameState.emit_signal("state_updated")
				emit_signal("duel_action_done")
				return

	# ── 情况1：我方战力较弱 ──
	if pow_diff < 0:
		# 尝试眩晕敌方最强单位
		if stun_spells.size() > 0 and bfield["pU"].size() > 0:
			var stun_sp: Dictionary = stun_spells[0]
			var targets: Array = bfield["pU"].filter(func(u): return not u.get("stunned", false))
			targets.sort_custom(func(a, b): return GameState.get_atk(b) > GameState.get_atk(a))
			var t_uid: int = targets[0].get("uid", -1) if targets.size() > 0 else -1
			GameState._log("▶ AI对决响应：【%s】（眩晕）" % stun_sp.get("name","?"), "imp")
			await SpellManager.play_card(stun_sp, "enemy", t_uid)
			GameState.duel_skips = 0; GameState.duel_turn = "player"
			GameState.emit_signal("state_updated"); emit_signal("duel_action_done")
			return

		# 尝试 buff 己方
		if buff_spells.size() > 0 and bfield["eU"].size() > 0:
			buff_spells.sort_custom(func(a, b): return _ai_spell_priority(b) > _ai_spell_priority(a))
			var best_buff: Dictionary = buff_spells[0]
			var t_uid: int = _ai_choose_spell_target(best_buff, "enemy")
			GameState._log("▶ AI对决响应：【%s】（增强战力）" % best_buff.get("name","?"), "imp")
			await SpellManager.play_card(best_buff, "enemy", t_uid)
			GameState.duel_skips = 0; GameState.duel_turn = "player"
			GameState.emit_signal("state_updated"); emit_signal("duel_action_done")
			return

	# ── 情况2：小幅领先时用低费 buff 巩固 ──
	if pow_diff > 0 and pow_diff <= 3 and buff_spells.size() > 0 and bfield["eU"].size() > 0:
		var cheap_buff: Dictionary = {}
		for bs in buff_spells:
			if SpellManager.get_effective_cost(bs, "enemy") <= 2:
				if cheap_buff.is_empty() or SpellManager.get_effective_cost(bs,"enemy") < SpellManager.get_effective_cost(cheap_buff,"enemy"):
					cheap_buff = bs
		if not cheap_buff.is_empty():
			var t_uid: int = _ai_choose_spell_target(cheap_buff, "enemy")
			GameState._log("▶ AI对决响应：【%s】（巩固优势）" % cheap_buff.get("name","?"), "imp")
			await SpellManager.play_card(cheap_buff, "enemy", t_uid)
			GameState.duel_skips = 0; GameState.duel_turn = "player"
			GameState.emit_signal("state_updated"); emit_signal("duel_action_done")
			return

	# ── 情况3：其他迅捷法术 ──
	if other_spells.size() > 0:
		var sp: Dictionary = other_spells[0]
		var t_uid: int = _ai_choose_spell_target(sp, "enemy")
		GameState._log("▶ AI对决响应：【%s】" % sp.get("name","?"), "imp")
		await SpellManager.play_card(sp, "enemy", t_uid)
		GameState.duel_skips = 0; GameState.duel_turn = "player"
		GameState.emit_signal("state_updated"); emit_signal("duel_action_done")
		return

	# ── 情况4：出迅捷单位 ──
	if fast_units.size() > 0 and GameState.e_base.size() < 5:
		var fu: Dictionary = fast_units[0]
		GameState._log("▶ AI迅捷单位入场：【%s】" % fu.get("name","?"), "imp")
		await SpellManager.play_card(fu, "enemy")
		GameState.duel_skips = 0; GameState.duel_turn = "player"
		GameState.emit_signal("state_updated"); emit_signal("duel_action_done")
		return

	# ── 情况5：传奇迅捷技能 ──
	if LegendManager.ai_legend_duel_action():
		emit_signal("duel_action_done")
		return

	# 放弃响应
	_ai_duel_skip()


func _ai_duel_skip() -> void:
	GameState.duel_skips += 1
	GameState._log("AI 放弃响应。", "phase")
	GameState.duel_turn = "player"
	GameState.emit_signal("state_updated")
	emit_signal("duel_action_done")


# ═══════════════════════════════════════════════
# ai_reaction_action() — AI 法术反应窗口决策
# 不同于 ai_duel_action，此函数在法术反应窗口中调用（非战斗对决）
# ═══════════════════════════════════════════════
func ai_reaction_action() -> void:
	if not GameState.reaction_active or GameState.game_over:
		return
	if GameState.reaction_turn != "enemy":
		return
	# 只处理反制逻辑（反应窗口中 AI 只使用反制牌）
	var counter_cards: Array = GameState.e_hand.filter(func(c):
		return c.get("type","") == "spell" \
			and SpellManager.can_play(c, "enemy") \
			and c.get("effect","") in ["counter_cost4", "counter_any", "negate_spell"])
	for cs in counter_cards:
		var can_counter: bool = false
		match cs.get("effect",""):
			"counter_any": can_counter = true
			"negate_spell": can_counter = true
			"counter_cost4": can_counter = GameState.last_player_spell_cost <= 4
		if can_counter:
			GameState._log("▶ AI 反应：【%s】反制玩家法术！" % cs.get("name","?"), "imp")
			await SpellManager.play_card(cs, "enemy")
			GameState.emit_signal("state_updated")
			return
	GameState._log("AI 跳过反应。", "phase")


# ═══════════════════════════════════════════════
# _ai_decide_movement — AI 移动决策
# 对应 JS aiDecideMovement()
# 返回 { movers: Array, target_bf_id: int } 或 {}
# ═══════════════════════════════════════════════
func _ai_decide_movement(active: Array) -> Dictionary:
	var sorted: Array = active.duplicate()
	sorted.sort_custom(func(a, b): return GameState.get_atk(b) > GameState.get_atk(a))

	var score_diff: int = GameState.e_score - GameState.p_score
	var my_score: int = GameState.e_score
	var opp_score: int = GameState.p_score
	var board_adv: float = _ai_board_score()

	var best_plan: Dictionary = {}
	var best_plan_score: float = -999.0

	for i in range(GameState.bf.size()):
		var b: Dictionary = GameState.bf[i]
		var ev: Dictionary = _ai_eval_battlefield(i)
		var max_slots: int = 2 - ev.get("my_count", 0)
		if max_slots <= 0:
			continue

		for count in range(1, min(sorted.size(), max_slots) + 1):
			var movers: Array = sorted.slice(0, count)
			var sim: Dictionary = _ai_simulate_combat(movers, i)
			var plan_score: float = 0.0

			if ev.get("their_count", 0) == 0:
				# 空战场
				if b.get("ctrl") != "enemy":
					plan_score = 15.0
					if b.get("card") != null and b["card"].get("id","") == "ascending_stairs":
						plan_score += 5.0
					if count > 1:
						plan_score -= 2.0
				else:
					plan_score = 2.0  # 防守己方已控战场
			else:
				# 有敌方
				if sim.get("will_win", false):
					plan_score = 12.0 + sim.get("margin", 0.0)
					if b.get("ctrl") != "enemy":
						plan_score += 3.0
					if b.get("card") != null and b["card"].get("id","") == "ascending_stairs":
						plan_score += 5.0
				elif sim.get("my_total", 0) == ev.get("their_pow", 0):
					plan_score = 1.0
					if b.get("ctrl") == "player" and score_diff < 0:
						plan_score += 5.0
				else:
					# 会输
					plan_score = -3.0
					if board_adv < -3.0 or score_diff <= -3:
						plan_score += 6.0
					if board_adv > 5.0:
						plan_score -= 3.0
					if opp_score >= _win_score - 2 and b.get("ctrl") == "player":
						plan_score += 8.0

			# 接近胜利的紧迫感
			if my_score >= _win_score - 2:
				plan_score += 3.0
			if opp_score >= _win_score - 2 and b.get("ctrl") == "player" and ev.get("their_count",0) > 0:
				plan_score += 5.0

			# 独影剑鸣加成（己方独守且Master Yi传奇在场）
			if ev.get("my_count", 0) == 1 and ev.get("their_count", 0) > 0:
				if not GameState.e_leg.is_empty() and GameState.e_leg.get("id","") == "masteryi":
					plan_score += 2.0

			# 战场特效加成
			if b.get("card") != null:
				var bc_id: String = b["card"].get("id","")
				if bc_id == "trifarian_warcamp":
					plan_score += 2.0
				if bc_id == "forgotten_monument" and GameState.round < 3:
					plan_score -= 2.0

			# 均衡考虑（避免倾巢出动）
			if GameState.bf.size() > 1:
				var other_b: Dictionary = GameState.bf[1 - i]
				var other_e_empty: bool = other_b.get("eU", []).size() == 0
				var other_p_empty: bool = other_b.get("pU", []).size() == 0
				if other_b.get("ctrl") != "enemy" and other_e_empty and other_p_empty:
					if count == sorted.size() and sorted.size() >= 2:
						plan_score -= 3.0

			if plan_score > best_plan_score:
				best_plan_score = plan_score
				best_plan = { "movers": movers, "target_bf_id": b.get("id", i + 1) }

	# 分兵策略：两个空战场各派1个
	if sorted.size() >= 2 and GameState.bf.size() >= 2:
		var b0: Dictionary = GameState.bf[0]
		var b1: Dictionary = GameState.bf[1]
		var ev0: Dictionary = _ai_eval_battlefield(0)
		var ev1: Dictionary = _ai_eval_battlefield(1)
		if ev0.get("their_count",0) == 0 and ev1.get("their_count",0) == 0 \
				and b0.get("ctrl") != "enemy" and b1.get("ctrl") != "enemy" \
				and ev0.get("my_count",0) < 2 and ev1.get("my_count",0) < 2:
			if 25.0 > best_plan_score:
				best_plan = { "movers": [sorted[0]], "target_bf_id": b0.get("id", 1) }

	return best_plan


# ═══════════════════════════════════════════════
# 评估函数
# ═══════════════════════════════════════════════

## ai_card_value — 卡牌价值评分（对应 JS aiCardValue）
func ai_card_value(card: Dictionary) -> float:
	var cost: int = max(1, card.get("cost", 1))
	var atk_val: int = card.get("atk", 0)
	var score: float = float(atk_val) / float(cost) * 10.0

	var kws: Array = card.get("keywords", [])
	if "急速" in kws: score += 4.0
	if "壁垒" in kws: score += 3.0
	if "强攻" in kws: score += 2.0
	if "绝念" in kws: score += 2.0
	if "鼓舞" in kws: score += 1.0
	return score


## _ai_board_score — 全局棋盘评分（正=AI领先，负=落后）
## 对应 JS aiBoardScore()
func _ai_board_score() -> float:
	var score_diff: float = float(GameState.e_score - GameState.p_score) * 3.0
	var hand_diff: float = float(GameState.e_hand.size() - GameState.p_hand.size()) * 0.5
	var bf_ctrl: float = 0.0
	var unit_pow: float = 0.0
	for b in GameState.bf:
		if b.get("ctrl") == "enemy":
			bf_ctrl += 2.0
		elif b.get("ctrl") == "player":
			bf_ctrl -= 2.0
		for u in b.get("eU", []):
			unit_pow += GameState.get_atk(u) * 0.3
		for u in b.get("pU", []):
			unit_pow -= GameState.get_atk(u) * 0.3
	return score_diff + hand_diff + bf_ctrl + unit_pow


## _ai_eval_battlefield — 评估单个战场的双方状态
## 对应 JS aiEvalBattlefield()
func _ai_eval_battlefield(bf_index: int) -> Dictionary:
	if bf_index < 0 or bf_index >= GameState.bf.size():
		return { "my_pow": 0, "their_pow": 0, "my_count": 0, "their_count": 0, "ctrl": null }
	var b: Dictionary = GameState.bf[bf_index]
	var my_pow: int = 0
	for u in b.get("eU", []):
		if not u.get("stunned", false):
			my_pow += GameState.get_atk(u)
	var their_pow: int = 0
	for u in b.get("pU", []):
		if not u.get("stunned", false):
			their_pow += GameState.get_atk(u)
	return {
		"my_pow": my_pow,
		"their_pow": their_pow,
		"my_count": b.get("eU", []).size(),
		"their_count": b.get("pU", []).size(),
		"ctrl": b.get("ctrl"),
		"bf": b
	}


## _ai_simulate_combat — 模拟战斗结果
## 对应 JS aiSimulateCombat()
func _ai_simulate_combat(movers: Array, bf_index: int) -> Dictionary:
	var ev: Dictionary = _ai_eval_battlefield(bf_index)
	var my_total: int = ev.get("my_pow", 0)
	for u in movers:
		my_total += GameState.get_atk(u)
	var their_pow: int = ev.get("their_pow", 0)
	return {
		"will_win": my_total > their_pow,
		"my_total": my_total,
		"their_pow": their_pow,
		"margin": my_total - their_pow
	}


# ═══════════════════════════════════════════════
# 法术决策辅助
# ═══════════════════════════════════════════════

## _ai_should_play_spell — 判断是否应该在行动阶段施放此法术
## 对应 JS aiShouldPlaySpell()
func _ai_should_play_spell(spell: Dictionary) -> bool:
	var eff: String = spell.get("effect", "")

	# 反应/迅捷牌留到对决
	if GameState.has_keyword(spell, "反应") or GameState.has_keyword(spell, "迅捷"):
		return false

	# 反制类法术只在对决中使用
	if eff in ["counter_cost4", "counter_any", "negate_spell"]:
		return false

	# 验证目标存在（SpellManager.can_play 已经做了这个检查，这里再做一次业务层过滤）
	return true


## _ai_spell_priority — 法术优先级评分
## 对应 JS aiSpellPriority()
func _ai_spell_priority(spell: Dictionary) -> int:
	var eff: String = spell.get("effect", "")
	match eff:
		"rally_call": return 100
		"balance_resolve": return 90
		"stun", "stun_manual": return 80
		"buff7_manual": return 75
		"buff5_manual": return 70
		"buff2_draw": return 65
		"buff1_solo": return 60
		_: return 50


## _ai_choose_spell_target — 智能选择法术目标 UID
## 对应 JS aiChooseSpellTarget()
func _ai_choose_spell_target(spell: Dictionary, owner: String) -> int:
	var opponent: String = "enemy" if owner == "player" else "player"
	var eff: String = spell.get("effect", "")

	var en_units: Array = GameState.get_all_units(opponent).filter(
		func(u): return not u.get("stunned", false))
	var my_units: Array = GameState.get_all_units(owner).filter(
		func(u): return not u.get("stunned", false))

	# 敌方战场单位（不含基地）
	var en_bf_units: Array = []
	for b in GameState.bf:
		var side: Array = b["eU"] if opponent == "enemy" else b["pU"]
		en_bf_units.append_array(side.filter(func(u): return not u.get("stunned", false)))

	# 己方战场单位
	var my_bf_units: Array = []
	for b in GameState.bf:
		var side: Array = b["eU"] if owner == "enemy" else b["pU"]
		my_bf_units.append_array(side)

	match eff:
		# 伤害/眩晕类：选最强敌方单位
		"deal3", "deal3_twice", "deal4_draw", "deal6_two", "deal1_repeat", "deal1_same_zone", \
		"stun", "stun_manual", "weaken", "debuff1_draw", "debuff4", "discard_deal", "deal2_two":
			if en_units.size() > 0:
				en_units.sort_custom(func(a, b_): return GameState.get_atk(b_) > GameState.get_atk(a))
				return en_units[0].get("uid", -1)
			if en_bf_units.size() > 0:
				return en_bf_units[0].get("uid", -1)

		# buff 类：选己方最强战场单位
		"buff_ally", "buff1_solo", "buff2_draw", "buff5_manual", "buff7_manual", \
		"buff_draw", "thunder_gal_manual", "ready_unit":
			if my_bf_units.size() > 0:
				my_bf_units.sort_custom(func(a, b_): return GameState.get_atk(b_) > GameState.get_atk(a))
				return my_bf_units[0].get("uid", -1)
			if my_units.size() > 0:
				my_units.sort_custom(func(a, b_): return GameState.get_atk(b_) > GameState.get_atk(a))
				return my_units[0].get("uid", -1)

		# recall 类：选己方最弱单位（换血）
		"recall_draw", "recall_unit_rune":
			if my_units.size() > 0:
				my_units.sort_custom(func(a, b_): return GameState.get_atk(a) > GameState.get_atk(b_))
				return my_units[0].get("uid", -1)

		# deal4_draw：选对战场中最强单位（包括己方）
		"deal4_draw":
			var all_bf: Array = []
			for b in GameState.bf:
				all_bf.append_array(b["eU"])
				all_bf.append_array(b["pU"])
			if all_bf.size() > 0:
				all_bf.sort_custom(func(a, b_): return GameState.get_atk(b_) > GameState.get_atk(a))
				# AI优先目标：敌方最强单位
				for u in all_bf:
					if _unit_owner(u) == opponent:
						return u.get("uid", -1)
				return all_bf[0].get("uid", -1)

		# force_move：选最弱敌方单位（移出战场）
		"force_move":
			if en_units.size() > 0:
				en_units.sort_custom(func(a, b_): return GameState.get_atk(a) > GameState.get_atk(b_))
				return en_units[0].get("uid", -1)

	return -1


## _unit_owner — 判断单位属于哪方（通过扫描所有区域）
func _unit_owner(unit: Dictionary) -> String:
	var uid: int = unit.get("uid", -1)
	for u in GameState.p_base:
		if u.get("uid",-1) == uid: return "player"
	for u in GameState.e_base:
		if u.get("uid",-1) == uid: return "enemy"
	for b in GameState.bf:
		for u in b.get("pU",[]):
			if u.get("uid",-1) == uid: return "player"
		for u in b.get("eU",[]):
			if u.get("uid",-1) == uid: return "enemy"
	return "unknown"


# ═══════════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════════

## _find_in_hand — 在手牌中查找满足条件的第一张牌
func _find_in_hand(owner: String, predicate: Callable) -> Variant:
	var hand: Array = GameState.e_hand if owner == "enemy" else GameState.p_hand
	for c in hand:
		if predicate.call(c):
			return c
	return null


## _ai_min_reactive_cost — 手牌中最便宜的反应/迅捷牌费用（无则返回0）
## 对应 JS aiMinReactiveCost()
func _ai_min_reactive_cost() -> int:
	var min_cost: int = 0
	for c in GameState.e_hand:
		if GameState.has_keyword(c, "反应") or GameState.has_keyword(c, "迅捷"):
			var cost: int = SpellManager.get_effective_cost(c, "enemy")
			if min_cost == 0 or cost < min_cost:
				min_cost = cost
	return min_cost
