extends Node
# ═══════════════════════════════════════════════
# SpellManager.gd — 法术效果、入场触发、目标系统 (Autoload 单例)
# 对应 JS spell.js 中的核心游戏逻辑部分（非 UI 部分）
# Phase 4 / Step 1
# ═══════════════════════════════════════════════

signal spell_applied(spell_name: String, owner: String)
signal unit_summoned(unit: Dictionary, owner: String)

# ═══════════════════════════════════════════════
# get_spell_targets — 获取法术的合法目标 UID 列表
# 对应 JS getSpellTargets()
# 返回值：
#   null      → 无需预选目标（自动/无目标效果）
#   []        → 无合法目标（阻止出牌）
#   [uid...]  → 合法目标 UID 列表
# ═══════════════════════════════════════════════
func get_spell_targets(card: Dictionary, owner: String) -> Variant:
	var opponent: String = "enemy" if owner == "player" else "player"
	var my_units: Array = GameState.get_all_units(owner)
	var en_units: Array = GameState.get_all_units(opponent).filter(
			func(u): return u.get("effect", "") != "untargetable")
	var all_units_pool: Array = GameState.get_all_units("player") + GameState.get_all_units("enemy")

	# 敌方战场单位（不含基地）
	var en_bf_units: Array = []
	var all_bf_units: Array = []
	for b in GameState.bf:
		var en_side: Array = b["eU"] if opponent == "enemy" else b["pU"]
		for u in en_side:
			if u.get("effect", "") != "untargetable":
				en_bf_units.append(u)
		all_bf_units.append_array(b["pU"])
		all_bf_units.append_array(b["eU"])

	var effect: String = card.get("effect", "")
	match effect:
		"buff_ally":
			return my_units.filter(func(u): return not u.get("buff_token", false)).map(
					func(u): return u["uid"])
		"stun", "weaken", "debuff4", "debuff1_draw":
			return en_units.map(func(u): return u["uid"])
		"deal3":
			return en_bf_units.map(func(u): return u["uid"])
		"recall_draw", "buff_draw", "recall_unit_rune", "buff1_solo":
			return my_units.map(func(u): return u["uid"])
		"deal3_twice", "deal6_two", "deal1_repeat", "deal1_same_zone":
			return en_units.map(func(u): return u["uid"])
		"deal4_draw":
			return all_bf_units.map(func(u): return u["uid"])
		"thunder_gal_manual", "buff7_manual", "buff5_manual", "buff2_draw", "ready_unit":
			return all_units_pool.map(func(u): return u["uid"])
		"stun_manual", "discard_deal", "deal2_two":
			var opp_bf: Array = []
			for b in GameState.bf:
				var side: Array = b["eU"] if opponent == "enemy" else b["pU"]
				for u in side:
					if u.get("effect", "") != "untargetable":
						opp_bf.append(u)
			return opp_bf.map(func(u): return u["uid"])
		"force_move":
			return GameState.get_all_units(opponent).filter(
					func(u): return not GameState.has_keyword(u, "法术免疫")).map(
					func(u): return u["uid"])
		# 以下效果无需预选目标
		"akasi_storm", "counter_cost4", "counter_any", "negate_spell", \
		"rally_call", "balance_resolve", \
		"trinity_equip", "guardian_equip", "dorans_equip", \
		"draw1", "draw4", "summon_rune1", "rune_draw", \
		"death_shield":
			return null
		_:
			return null


# ═══════════════════════════════════════════════
# on_summon — 单位入场触发效果
# 对应 JS onSummon()
# ═══════════════════════════════════════════════
func on_summon(unit: Dictionary, owner: String) -> void:
	var hand: Array = GameState.p_hand if owner == "player" else GameState.e_hand
	var base: Array = GameState.p_base if owner == "player" else GameState.e_base
	var deck: Array = GameState.p_deck if owner == "player" else GameState.e_deck
	var rune_deck: Array = GameState.p_rune_deck if owner == "player" else GameState.e_rune_deck
	var my_runes: Array = GameState.p_runes if owner == "player" else GameState.e_runes
	var opponent: String = "enemy" if owner == "player" else "player"

	var effect: String = unit.get("effect", "")
	match effect:
		"yordel_instructor_enter":
			GameState.draw_card(owner, 1)
			GameState._log("约德尔教官：入场抽1张牌", "imp")

		"darius_second_card":
			if GameState.cards_played_this_turn > 1:
				var tb: Dictionary = unit.get("tb", {"atk": 0})
				tb["atk"] = tb.get("atk", 0) + 2
				unit["tb"] = tb
				unit["exhausted"] = false
				GameState._log("德莱厄斯：本回合不是第一张牌，战力+2，状态重置为Ready", "imp")

		"malph_enter":
			var guard_count: int = 0
			for u in base:
				if GameState.has_keyword(u, "坚守"):
					guard_count += 1
			var tb: Dictionary = unit.get("tb", {"atk": 0})
			tb["atk"] = tb.get("atk", 0) + guard_count
			unit["tb"] = tb
			GameState._log("熔岩巨兽：基地有%d名坚守单位，战力+%d" % [guard_count, guard_count], "imp")

		"jax_enter":
			var equips: Array = hand.filter(func(c): return c.get("type", "") == "equipment")
			for c in equips:
				GameState.add_keyword(c, "反应")
			if equips.size() > 0:
				GameState._log("贾克斯：手牌中%d件装备获得【反应】词条！" % equips.size(), "imp")

		"tiyana_enter":
			GameState._log("缇亚娜·冕卫在场：对手无法获得据守分！", "imp")

		"buff_rune1":
			if rune_deck.size() > 0:
				var r: Dictionary = rune_deck.pop_back()
				r["tapped"] = true
				my_runes.append(r)
				GameState._log("%s：入场召出1枚符文（横置状态）" % unit.get("name", "?"), "imp")

		"foresight_mech_enter":
			if deck.is_empty():
				GameState._log("牌库为空，预知失效！", "phase")
			else:
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
					if top_card.get("cost", 0) >= 5:
						deck.pop_back()
						deck.insert(0, top_card)
						GameState._log("AI预知：将【%s】回收至牌库底部" % top_card.get("name", "?"), "imp")
					else:
						GameState._log("AI预知：保留了【%s】在牌库顶" % top_card.get("name", "?"), "imp")

		"thousand_tail_enter":
			var all_enemies: Array = GameState.get_all_units(opponent)
			for u in all_enemies:
				var tb: Dictionary = u.get("tb", {"atk": 0})
				tb["atk"] = tb.get("atk", 0) - 3
				u["tb"] = tb
			GameState._log("千尾监视者：所有敌方单位本回合战力-3（最低1）", "imp")

		"summon_draw1":
			GameState.draw_card(owner, 1)
			GameState._log("%s：入场抽1张牌" % unit.get("name", "?"), "imp")

		_:
			pass  # 无入场效果

	# 规则 729：带【预知】关键词的单位入场时触发（foresight_mech_enter 已单独处理，跳过）
	await KeywordManager.apply_foresight_keyword(unit, owner)

	# 单位入场后检查传奇被动（卡莎「进化」等条件可能满足）
	LegendManager.check_legend_passives("player")
	LegendManager.check_legend_passives("enemy")
	emit_signal("unit_summoned", unit, owner)
	GameState.emit_signal("state_updated")


# ═══════════════════════════════════════════════
# apply_spell — 法术效果实际结算
# 对应 JS applySpell()
# ═══════════════════════════════════════════════
func apply_spell(spell: Dictionary, owner: String, target_uid: int = -1, options: Dictionary = {}) -> void:
	var is_echo: bool = options.get("is_echo", false)
	if not is_echo:
		emit_signal("spell_applied", spell.get("name", "?"), owner)
		# 在效果执行前记录法术费用和目标（供对手反应窗口判断）
		if owner == "player":
			GameState.last_player_spell_cost = spell.get("cost", 0)
		else:
			GameState.last_player_spell_cost = 0  # AI法术：玩家侧反应时通过不同逻辑判断
		GameState.last_spell_target_uid = target_uid

	var opponent: String = "enemy" if owner == "player" else "player"
	var hand: Array    = GameState.p_hand    if owner == "player" else GameState.e_hand
	var base: Array    = GameState.p_base    if owner == "player" else GameState.e_base
	var op_base: Array = GameState.p_base    if opponent == "player" else GameState.e_base
	var op_leg: Dictionary = GameState.p_leg if opponent == "player" else GameState.e_leg
	var my_leg: Dictionary = GameState.p_leg if owner == "player" else GameState.e_leg
	var my_runes: Array    = GameState.p_runes     if owner == "player" else GameState.e_runes
	var deck: Array        = GameState.p_deck      if owner == "player" else GameState.e_deck
	var discard: Array     = GameState.p_discard   if owner == "player" else GameState.e_discard
	var rune_deck: Array   = GameState.p_rune_deck if owner == "player" else GameState.e_rune_deck
	var who_name: String = "你" if owner == "player" else "AI"

	# ── 法盾检查（规则721）──
	if spell.get("type", "") == "spell" and target_uid >= 0:
		var all_units: Array = GameState.get_all_units("player") + GameState.get_all_units("enemy")
		var shield_target = _find_unit_by_uid(all_units, target_uid)
		if shield_target != null and GameState.has_keyword(shield_target, "法盾"):
			var total_sch: int = GameState.get_sch(owner, "")
			if total_sch <= 0:
				GameState._log("【法盾】阻止指定：%s符能不足，无法以【%s】为目标！" % [
						who_name, shield_target.get("name", "?")], "imp")
				return
			# 消耗1点任意符能
			var sch: Dictionary = GameState.p_sch if owner == "player" else GameState.e_sch
			for k in sch:
				if sch[k] > 0:
					GameState.spend_sch(owner, k, 1)
					GameState._log("【法盾】：%s消耗1点%s符能，法术继续！" % [who_name, k], "imp")
					break

	# ── 法术效果主体 ──
	var effect: String = spell.get("effect", "")
	match effect:
		"draw1":
			GameState.draw_card(owner, 1)
			GameState._log("%s抽1张牌" % who_name, "imp")

		"draw4":
			GameState.draw_card(owner, 4)
			GameState._log("%s抽4张牌" % who_name, "imp")

		"summon_rune1":
			if rune_deck.size() > 0:
				var r: Dictionary = rune_deck.pop_back()
				r["tapped"] = true
				my_runes.append(r)
				GameState._log("%s召出1枚符文（横置状态）" % who_name, "imp")

		"rune_draw":
			if rune_deck.size() > 0:
				var r: Dictionary = rune_deck.pop_back()
				r["tapped"] = true
				my_runes.append(r)
				GameState._log("%s召出1枚符文" % who_name, "imp")
			GameState.draw_card(owner, 1)
			GameState._log("%s抽1张牌" % who_name, "imp")

		"buff_ally":
			# 永久+1战力（修改 atk 基础值）
			var target = _find_unit_by_uid(GameState.get_all_units(owner), target_uid)
			if target == null:
				return
			target["atk"]         = target.get("atk", 0) + 1
			target["current_atk"] = target.get("current_atk", 0) + 1
			target["current_hp"]  = target.get("current_atk", 0)
			GameState._log("%s获得永久+1战力（当前%d）" % [target.get("name","?"), target.get("current_atk",0)], "imp")

		"stun":
			var target = _find_unit_by_uid(GameState.get_all_units(opponent), target_uid)
			if target != null:
				target["stunned"] = true
				GameState._log("%s被眩晕（本回合无法造成战斗伤害）" % target.get("name","?"), "imp")

		"weaken":
			var target = _find_unit_by_uid(GameState.get_all_units(opponent), target_uid)
			if target == null:
				return
			if not op_leg.is_empty() and target.get("uid", -1) == op_leg.get("uid", -1):
				deal_damage(target, 2, opponent, true)
			else:
				var tb: Dictionary = target.get("tb", {"atk": 0})
				tb["atk"] = tb.get("atk", 0) - 2
				target["tb"] = tb
				GameState._log("%s本回合战力-2（最低1）" % target.get("name","?"), "imp")

		"deal3":
			var bf_units: Array = []
			for b in GameState.bf:
				bf_units.append_array(b["eU"] if opponent == "enemy" else b["pU"])
			var target = _find_unit_by_uid(bf_units, target_uid)
			if target != null:
				deal_damage(target, 3, opponent,
						not op_leg.is_empty() and target.get("uid",-1) == op_leg.get("uid",-1))

		"debuff4":
			var target = _find_unit_by_uid(GameState.get_all_units(opponent), target_uid)
			if target == null:
				return
			if not op_leg.is_empty() and target.get("uid", -1) == op_leg.get("uid", -1):
				deal_damage(target, 4, opponent, true)
			else:
				var tb: Dictionary = target.get("tb", {"atk": 0})
				tb["atk"] = tb.get("atk", 0) - 4
				target["tb"] = tb
				GameState._log("%s本回合战力-4（最低1）" % target.get("name","?"), "imp")

		"recall_draw":
			var target = _find_unit_by_uid(GameState.get_all_units(owner), target_uid)
			if target == null:
				return
			remove_unit_from_field(target, owner)
			hand.append(target)
			GameState._log("%s召回【%s】到手牌" % [who_name, target.get("name","?")], "imp")
			GameState.draw_card(owner, 1)
			GameState._log("%s抽1张牌" % who_name, "imp")

		"buff_draw":
			var target = _find_unit_by_uid(GameState.get_all_units(owner), target_uid)
			if target != null:
				var tb: Dictionary = target.get("tb", {"atk": 0})
				tb["atk"] = tb.get("atk", 0) + 1
				target["tb"] = tb
				GameState._log("%s本回合战力+1" % target.get("name","?"), "imp")
			GameState.draw_card(owner, 1)
			GameState._log("%s抽1张牌" % who_name, "imp")

		"recall_unit_rune":
			var target = _find_unit_by_uid(GameState.get_all_units(owner), target_uid)
			if target == null:
				return
			if not my_leg.is_empty() and target.get("uid", -1) == my_leg.get("uid", -1):
				GameState._log("传奇无法被召回！", "phase")
				return
			remove_unit_from_field(target, owner)
			hand.append(target)
			GameState._log("%s召回【%s】到手牌" % [who_name, target.get("name","?")], "imp")
			if rune_deck.size() > 0:
				var r: Dictionary = rune_deck.pop_back()
				r["tapped"] = true
				my_runes.append(r)
				GameState._log("%s召出1枚符文（横置状态）" % who_name, "imp")

		"deal3_twice":
			# 第一击：使用预选 target_uid
			var all_enemies: Array = GameState.get_all_units(opponent)
			var t1 = _find_unit_by_uid(all_enemies, target_uid)
			if t1 != null:
				deal_damage(t1, 3, opponent,
						not op_leg.is_empty() and t1.get("uid",-1) == op_leg.get("uid",-1))
			# 第二击：提示选择
			var remaining: Array = GameState.get_all_units(opponent)
			if not remaining.is_empty():
				var t2_uid = await PromptManager.ask({
					"title": "星落·第二击", "msg": "选择第二个目标",
					"type": "targets", "targets": remaining
				})
				if t2_uid != null:
					var t2 = _find_unit_by_uid(remaining, t2_uid)
					if t2 != null:
						deal_damage(t2, 3, opponent,
								not op_leg.is_empty() and t2.get("uid",-1) == op_leg.get("uid",-1))

		"deal6_two":
			var all_enemies: Array = GameState.get_all_units(opponent)
			var t1 = _find_unit_by_uid(all_enemies, target_uid)
			if t1 != null:
				deal_damage(t1, 6, opponent,
						not op_leg.is_empty() and t1.get("uid",-1) == op_leg.get("uid",-1))
			var remaining: Array = GameState.get_all_units(opponent)
			if not remaining.is_empty():
				var t2_uid = await PromptManager.ask({
					"title": "星芒融汇·第二击", "msg": "选择第二个目标",
					"type": "targets", "targets": remaining
				})
				if t2_uid != null:
					var t2 = _find_unit_by_uid(remaining, t2_uid)
					if t2 != null:
						deal_damage(t2, 6, opponent,
								not op_leg.is_empty() and t2.get("uid",-1) == op_leg.get("uid",-1))

		"deal1_repeat":
			for i in range(5):
				var remaining: Array = GameState.get_all_units(opponent)
				if remaining.is_empty():
					break
				var t_uid = await PromptManager.ask({
					"title": "风箱炎息·第%d次" % (i + 1),
					"msg": "选择目标", "type": "targets", "targets": remaining
				})
				if t_uid != null:
					var t = _find_unit_by_uid(remaining, t_uid)
					if t != null:
						deal_damage(t, 1, opponent,
								not op_leg.is_empty() and t.get("uid",-1) == op_leg.get("uid",-1))

		"deal4_draw":
			var all_bf: Array = []
			for b in GameState.bf:
				all_bf.append_array(b["pU"])
				all_bf.append_array(b["eU"])
			if all_bf.is_empty():
				GameState._log("战场无单位，法术失效！", "phase")
				return
			var target = _find_unit_by_uid(all_bf, target_uid)
			if target == null:
				GameState._log("目标消失，法术失效！", "phase")
				return
			var t_owner: String = GameState.get_unit_owner(target)
			var is_leg: bool = _is_legend(target)
			deal_damage(target, 4, t_owner, is_leg)
			GameState.draw_card(owner, 1)
			GameState._log("%s抽1张牌" % who_name, "imp")

		"thunder_gal_manual":
			var pool: Array = GameState.get_all_units("player") + GameState.get_all_units("enemy")
			var target = _find_unit_by_uid(pool, target_uid)
			if target == null:
				return
			var t_owner: String = GameState.get_unit_owner(target)
			var is_leg: bool = _is_legend(target)
			var dmg: int = GameState.get_atk(target)
			deal_damage(target, dmg, t_owner, is_leg)
			GameState._log("雷霆加尔：对【%s】造成%d点伤害" % [target.get("name","?"), dmg], "imp")

		"buff7_manual", "buff5_manual":
			var val: int = 7 if effect == "buff7_manual" else 5
			var pool: Array = GameState.get_all_units("player") + GameState.get_all_units("enemy")
			var target = _find_unit_by_uid(pool, target_uid)
			if target != null:
				var tb: Dictionary = target.get("tb", {"atk": 0})
				tb["atk"] = tb.get("atk", 0) + val
				target["tb"] = tb
				GameState._log("%s本回合战力+%d" % [target.get("name","?"), val], "imp")

		"stun_manual":
			var opp_bf: Array = []
			for b in GameState.bf:
				opp_bf.append_array(b["eU"] if opponent == "enemy" else b["pU"])
			var target = _find_unit_by_uid(opp_bf, target_uid)
			if target != null:
				target["stunned"] = true
				GameState._log("%s被眩晕（本回合无法造成战斗伤害）" % target.get("name","?"), "imp")

		"buff2_draw":
			var pool: Array = GameState.get_all_units("player") + GameState.get_all_units("enemy")
			var target = _find_unit_by_uid(pool, target_uid)
			if target != null:
				var tb: Dictionary = target.get("tb", {"atk": 0})
				tb["atk"] = tb.get("atk", 0) + 2
				target["tb"] = tb
				GameState._log("%s本回合战力+2" % target.get("name","?"), "imp")
			GameState.draw_card(owner, 1)
			GameState._log("%s抽1张牌" % who_name, "imp")

		"buff1_solo":
			var target = _find_unit_by_uid(GameState.get_all_units(owner), target_uid)
			if target == null:
				return
			var bonus: int = 1
			var bf_found = GameState.get_bf_of_unit(target)
			if bf_found != null:
				var my_side: Array = bf_found["pU"] if owner == "player" else bf_found["eU"]
				var op_side: Array = bf_found["eU"] if owner == "player" else bf_found["pU"]
				if my_side.size() == 1 and my_side[0]["uid"] == target["uid"] and op_side.size() > 0:
					bonus = 2
			var tb: Dictionary = target.get("tb", {"atk": 0})
			tb["atk"] = tb.get("atk", 0) + bonus
			target["tb"] = tb
			GameState._log("%s本回合战力+%d%s" % [
					target.get("name","?"), bonus,
					"（独守战场，额外+1！）" if bonus == 2 else ""], "imp")

		"force_move":
			var target = _find_unit_by_uid(GameState.get_all_units(opponent), target_uid)
			if target == null:
				return
			var bf_options: Array = []
			for i in range(GameState.bf.size()):
				var b = GameState.bf[i]
				var op_side: Array = b["pU"] if opponent == "player" else b["eU"]
				if op_side.size() < 2:
					bf_options.append(i)
			if bf_options.is_empty():
				GameState._log("战场无空位，法术失效！", "phase")
				return
				# AI 随机选，玩家通过 cards UI 选战场
			var bf_idx: int = bf_options[randi() % bf_options.size()]
			if owner == "player":
				var bf_cards: Array = []
				for idx in bf_options:
					var bname: String = GameState.bf[idx].get("card", {}).get("name", "战场%d" % (idx + 1)) \
						if GameState.bf[idx].get("card") != null else "战场%d" % (idx + 1)
					bf_cards.append({"uid": idx, "name": bname, "cost": 0, "text": "移入此战场", "type": "spell", "img": ""})
				var sel = await PromptManager.ask({
					"title": "魅惑妖术",
					"msg": "选择将【%s】强制移入哪个战场？" % target.get("name","?"),
					"type": "cards", "cards": bf_cards, "optional": false
				})
				if sel != null:
					bf_idx = sel
			remove_unit_from_field(target, opponent)
			var op_dest: Array = GameState.bf[bf_idx]["pU"] if opponent == "player" else GameState.bf[bf_idx]["eU"]
			op_dest.append(target)
			GameState._log("【%s】被强制移动至战场%d" % [target.get("name","?"), bf_idx + 1], "imp")

		"ready_unit":
			var pool: Array = GameState.get_all_units("player") + GameState.get_all_units("enemy")
			var target = _find_unit_by_uid(pool, target_uid)
			if target != null:
				target["exhausted"] = false
				GameState._log("【%s】状态重置为活跃（Ready）" % target.get("name","?"), "imp")

		"discard_deal":
			var opp_bf: Array = []
			for b in GameState.bf:
				opp_bf.append_array(b["eU"] if opponent == "enemy" else b["pU"])
			var target = _find_unit_by_uid(opp_bf, target_uid)
			if target == null:
				return
			if hand.is_empty():
				GameState._log("手牌为空，无法弃置！", "phase")
				return
			var card_discard = null
			if owner == "player":
				var sel = await PromptManager.ask({
					"title": "罪恶快感", "msg": "选择弃置1张手牌",
					"type": "cards", "cards": hand.duplicate()
				})
				if sel == null:
					return
				card_discard = _find_unit_by_uid(hand, sel)
			else:
				card_discard = hand[randi() % hand.size()]
			if card_discard != null:
				var idx: int = hand.find(card_discard)
				if idx >= 0:
					hand.remove_at(idx)
				discard.append(card_discard)
				var dmg: int = card_discard.get("cost", 0)
				GameState._log("%s弃置【%s】" % [who_name, card_discard.get("name","?")], "imp")
				deal_damage(target, dmg, opponent,
						not op_leg.is_empty() and target.get("uid",-1) == op_leg.get("uid",-1))

		"deal2_two":
			# 第一击：战场上的目标（使用预选）
			var opp_bf: Array = []
			for b in GameState.bf:
				opp_bf.append_array(b["eU"] if opponent == "enemy" else b["pU"])
			var t1 = _find_unit_by_uid(opp_bf, target_uid)
			if t1 != null:
				deal_damage(t1, 2, opponent,
						not op_leg.is_empty() and t1.get("uid",-1) == op_leg.get("uid",-1))
			# 第二击：任意敌方单位
			var remaining: Array = GameState.get_all_units(opponent)
			if not remaining.is_empty():
				var t2_uid = await PromptManager.ask({
					"title": "透体圣光·第二击", "msg": "选择第二个目标",
					"type": "targets", "targets": remaining
				})
				if t2_uid != null:
					var t2 = _find_unit_by_uid(remaining, t2_uid)
					if t2 != null:
						deal_damage(t2, 2, opponent,
								not op_leg.is_empty() and t2.get("uid",-1) == op_leg.get("uid",-1))

		"deal1_same_zone":
			var target = _find_unit_by_uid(GameState.get_all_units(opponent), target_uid)
			if target == null:
				return
			var zone_pool: Array = []
			if not op_leg.is_empty() and target.get("uid", -1) == op_leg.get("uid", -1):
				zone_pool = [op_leg]
			else:
				var found_in_bf: bool = false
				for b in GameState.bf:
					var side: Array = b["pU"] if opponent == "player" else b["eU"]
					for u in side:
						if u.get("uid", -1) == target.get("uid", -1):
							zone_pool = side.duplicate()
							found_in_bf = true
							break
					if found_in_bf:
						break
				if not found_in_bf:
					if target in op_base:
						zone_pool = op_base.duplicate()
			zone_pool = zone_pool.slice(0, 3)
			for u in zone_pool:
				deal_damage(u, 1, opponent,
						not op_leg.is_empty() and u.get("uid",-1) == op_leg.get("uid",-1))

		"akasi_storm":
			for _i in range(6):
				var remaining: Array = GameState.get_all_units(opponent)
				if remaining.is_empty():
					break
				var t = remaining[randi() % remaining.size()]
				deal_damage(t, 2, opponent,
						not op_leg.is_empty() and t.get("uid",-1) == op_leg.get("uid",-1))

		"counter_cost4", "counter_any":
			GameState.spell_countered = true
			GameState._log("%s发动反制法术！对手的法术被无效化！" % who_name, "imp")

		"negate_spell":
			# 极速反制：仅无效化以友方单位或装备为目标的法术
			var my_units: Array = GameState.get_all_units(owner) + (
					GameState.p_base if owner == "player" else GameState.e_base)
			var target_is_ally: bool = my_units.any(func(u): return u.get("uid",-1) == GameState.last_spell_target_uid)
			if target_is_ally:
				GameState.spell_countered = true
				GameState._log("%s极速反制！保护了友方目标，法术被无效化！" % who_name, "imp")
			else:
				GameState._log("%s极速反制：目标不是友方单位，无法无效化。" % who_name, "imp")

		"rally_call":
			if owner == "player":
				GameState.p_rally_active = true
			else:
				GameState.e_rally_active = true
			GameState._log("%s激活【迎敌号令】，本回合打出的单位活跃入场！" % who_name, "imp")
			GameState.draw_card(owner, 1)
			GameState._log("%s抽1张牌" % who_name, "imp")

		"balance_resolve":
			GameState.draw_card(owner, 1)
			GameState._log("%s抽1张牌" % who_name, "imp")
			if rune_deck.size() > 0:
				var r: Dictionary = rune_deck.pop_back()
				r["tapped"] = true
				my_runes.append(r)
				GameState._log("%s召出1枚符文（横置状态）" % who_name, "imp")

		"debuff1_draw":
			var target = _find_unit_by_uid(GameState.get_all_units(opponent), target_uid)
			if target == null:
				return
			if not op_leg.is_empty() and target.get("uid", -1) == op_leg.get("uid", -1):
				deal_damage(target, 1, opponent, true)
				GameState._log("对传奇【%s】造成1点伤害" % target.get("name","?"), "imp")
			else:
				var tb: Dictionary = target.get("tb", {"atk": 0})
				tb["atk"] = tb.get("atk", 0) - 1
				target["tb"] = tb
				GameState._log("%s本回合战力-1（最低1）" % target.get("name","?"), "imp")
			GameState.draw_card(owner, 1)
			GameState._log("%s抽1张牌" % who_name, "imp")

		"trinity_equip", "guardian_equip", "dorans_equip":
			var eq_candidates: Array = base.filter(func(u): return u.get("type", "") != "equipment")
			var eq_target: Dictionary = {}
			if not eq_candidates.is_empty():
				if owner == "player":
					var chosen_uid = await PromptManager.ask({
						"title": "装配目标",
						"msg": "选择一个友方基地单位装配【%s】" % spell.get("name", "?"),
						"type": "cards",
						"cards": eq_candidates,
						"optional": false
					})
					for u in eq_candidates:
						if u.get("uid", -1) == chosen_uid:
							eq_target = u
							break
					if eq_target.is_empty():
						eq_target = eq_candidates[0]  # 若未选择则默认第一个
				else:
					eq_target = eq_candidates[randi() % eq_candidates.size()]
			if not eq_target.is_empty():
				var bonus: int = spell.get("atk_bonus", 0)
				if bonus > 0:
					eq_target["atk"]         = eq_target.get("atk", 0) + bonus
					eq_target["current_atk"] = eq_target.get("current_atk", 0) + bonus
					eq_target["current_hp"]  = eq_target.get("current_atk", 0)
				if effect == "trinity_equip":
					eq_target["trinity_equipped"] = true
				if not eq_target.get("attached_equipments"):
					eq_target["attached_equipments"] = []
				# 规则144.5.a: 从基地找到并移除刚打出的装备实体，将其附着到目标单位
				# （play_card已将mk(card)放入base；此处取出而非重新创建，避免重复）
				var equip_in_base_idx: int = -1
				for i in range(base.size()):
					if base[i].get("id", "") == spell.get("id", "") and base[i].get("type", "") == "equipment":
						equip_in_base_idx = i
						break
				var equip_instance: Dictionary = {}
				if equip_in_base_idx >= 0:
					equip_instance = base.pop_at(equip_in_base_idx)
				else:
					equip_instance = GameState.mk(spell)
				eq_target["attached_equipments"].append(equip_instance)
				GameState._log("【装配】%s获得+%d战力！" % [eq_target.get("name","?"), bonus], "imp")

		"death_shield":
			GameState._log("【中娅沙漏】已部署——当友方单位将被摧毁时，可摧毁此装备代替", "imp")

		_:
			GameState._log("未定义的法术效果: %s" % effect, "phase")

	# ── 回响检查（规则：法术有回响关键词 + 非回响状态施放）──
	if spell.get("type", "") == "spell" and GameState.has_keyword(spell, "回响") and not is_echo:
		var echo_mana: int  = spell.get("echo_mana_cost", 0)
		var echo_sch_cost: int = spell.get("echo_sch_cost", 0)
		var echo_sch_type: String = spell.get("echo_sch_type", "")
		var my_mana: int = GameState.p_mana if owner == "player" else GameState.e_mana
		var can_echo: bool = (my_mana >= echo_mana) and \
				(echo_sch_cost == 0 or GameState.get_sch(owner, echo_sch_type) >= echo_sch_cost)
		if can_echo:
			var do_echo: bool = false
			if owner == "player":
				do_echo = await PromptManager.ask({
					"title": "回响",
					"msg": "【回响】再施放一次%s（%d法力%s）？" % [
						spell.get("name","?"), echo_mana,
						"+%d%s符能" % [echo_sch_cost, echo_sch_type] if echo_sch_type != "" else ""],
					"type": "confirm"
				})
			else:
				do_echo = true
			if do_echo:
				if owner == "player":
					GameState.p_mana -= echo_mana
				else:
					GameState.e_mana -= echo_mana
				if echo_sch_cost > 0 and echo_sch_type != "":
					GameState.spend_sch(owner, echo_sch_type, echo_sch_cost)
				GameState._log("【回响】再次施放【%s】！" % spell.get("name","?"), "imp")
				await apply_spell(spell, owner, target_uid, {"is_echo": true})
		else:
			GameState._log("回响费用不足，无法施放！", "phase")

	GameState.emit_signal("state_updated")


# ═══════════════════════════════════════════════
# can_play — 检查卡牌在当前资源状态下是否可出
# 对应 JS canPlay() 核心部分
# ═══════════════════════════════════════════════
func can_play(card: Dictionary, owner: String) -> bool:
	var mana: int = GameState.p_mana if owner == "player" else GameState.e_mana
	var cost: int = get_effective_cost(card, owner)
	if mana < cost:
		return false
	var sch_cost: int = card.get("sch_cost", 0)
	var sch_type: String = card.get("sch_type", "")
	if sch_cost > 0 and sch_type != "" and GameState.get_sch(owner, sch_type) < sch_cost:
		return false
	# 如果法术需要目标，检查是否有合法目标
	if card.get("type", "") == "spell":
		var targets = get_spell_targets(card, owner)
		if targets != null and targets.is_empty():
			return false
	return true


# ═══════════════════════════════════════════════
# get_effective_cost — 计算卡牌实际费用（含鼓舞减费）
# 对应 JS getEffectiveCost()
# ═══════════════════════════════════════════════
func get_effective_cost(card: Dictionary, owner: String) -> int:
	var cost: int = card.get("cost", 0)
	# 鼓舞（Inspire）：本回合已打出过其他牌时，费用-1（最低0）
	if GameState.has_keyword(card, "鼓舞") and GameState.cards_played_this_turn > 0:
		cost = max(0, cost - 1)
	return cost


# ═══════════════════════════════════════════════
# deal_damage — 对单位或传奇造成伤害
# 对应 JS dealDamage()
# ═══════════════════════════════════════════════
func deal_damage(target: Dictionary, dmg: int, owner: String, is_legend: bool = false) -> void:
	# 虚空之门：此处单位受到法术/技能伤害时额外+1（每段伤害都+1）
	if not is_legend:
		var target_bf = GameState.get_bf_of_unit(target)
		if target_bf != null and target_bf.get("card", {}).get("id", "") == "void_gate":
			dmg += 1
			GameState._log("虚空之门：额外+1点伤害！", "imp")
	if is_legend:
		var leg: Dictionary = GameState.p_leg if owner == "player" else GameState.e_leg
		if leg.is_empty():
			return
		leg["current_hp"] = max(0, leg.get("current_hp", 0) - dmg)
		GameState._log("对%s传奇造成%d点伤害，剩余：%d" % [
				"玩家" if owner == "player" else "敌方",
				dmg, leg.get("current_hp", 0)], "imp")
	else:
		target["current_hp"] = max(0, target.get("current_hp", target.get("atk", 0)) - dmg)
		GameState._log("对【%s】造成%d点伤害，剩余：%d" % [
				target.get("name", "?"), dmg, target.get("current_hp", 0)], "imp")
	# 伤害视觉反馈（供 GameBoard 生成浮动伤害数字）
	GameState.emit_signal("unit_damaged", -1 if is_legend else target.get("uid", -1), dmg, is_legend)
	clean_dead_all()
	GameState.emit_signal("state_updated")


# ═══════════════════════════════════════════════
# remove_unit_from_field — 从场上移除单位（不摧毁，仅移位）
# 对应 JS removeUnitFromField()
# ═══════════════════════════════════════════════
func remove_unit_from_field(unit: Dictionary, owner: String) -> void:
	var uid: int = unit.get("uid", -1)
	var base: Array = GameState.p_base if owner == "player" else GameState.e_base
	for i in range(base.size()):
		if base[i].get("uid", -1) == uid:
			base.remove_at(i)
			return
	for b in GameState.bf:
		var slots: Array = b["pU"] if owner == "player" else b["eU"]
		for i in range(slots.size()):
			if slots[i].get("uid", -1) == uid:
				slots.remove_at(i)
				return


# ═══════════════════════════════════════════════
# clean_dead_all — 全局死亡清理（所有战场+基地）
# 对应 JS cleanDeadAll()
# ═══════════════════════════════════════════════
func clean_dead_all() -> void:
	# clean_dead 内部已调用 _clean_base_dead，所以按战场逐一清理即可
	for b in GameState.bf:
		CombatManager.clean_dead(b["id"])


# ─────────────────────────────────────────────
# 私有辅助函数
# ─────────────────────────────────────────────

# ═══════════════════════════════════════════════
# calc_resource_fix — 计算资源补足方案
# 对应 JS spell.js calcResourceFix()
# 返回值：
#   null → 资源已足够或无法修复
#   { tap_uids: [], recycle_entries: [{uid, rune_type}...], lines: [] }
# ═══════════════════════════════════════════════
func calc_resource_fix(card: Dictionary, owner: String) -> Variant:
	# 仅在玩家回合行动阶段处理（AI路径由AIManager直接处理资源）
	if owner != "player":
		return null
	if GameState.p_deck.is_empty() and GameState.p_runes.is_empty():
		return null

	# 法术类检查：需有合法目标
	if card.get("type", "") == "spell":
		var tgt = get_spell_targets(card, owner)
		if tgt != null and tgt.is_empty():
			return null

	var eff_cost: int = get_effective_cost(card, owner)
	var mana_need: int  = max(0, eff_cost - GameState.p_mana)
	var sch_need1: int  = 0
	var sch_type1: String = card.get("sch_type", "")
	if sch_type1 != "":
		sch_need1 = max(0, card.get("sch_cost", 0) - GameState.get_sch(owner, sch_type1))
	var sch_need2: int  = 0
	var sch_type2: String = card.get("sch_type2", "")
	if sch_type2 != "":
		sch_need2 = max(0, card.get("sch_cost2", 0) - GameState.get_sch(owner, sch_type2))

	if mana_need == 0 and sch_need1 == 0 and sch_need2 == 0:
		return null  # 资源已足够

	var used_uids: Array = []
	var recycle_entries: Array = []

	# 步骤1：为 sch_cost1 挑选回收符文（优先已横置）
	if sch_need1 > 0 and sch_type1 != "":
		var tapped_r: Array   = GameState.p_runes.filter(func(r): return r.get("rune_type","") == sch_type1 and r.get("tapped", false))
		var untapped_r: Array = GameState.p_runes.filter(func(r): return r.get("rune_type","") == sch_type1 and not r.get("tapped", false))
		var cands: Array = tapped_r + untapped_r
		if cands.size() < sch_need1:
			return null  # 符文不够
		for k in range(sch_need1):
			recycle_entries.append({ "uid": cands[k]["uid"], "rune_type": sch_type1 })
			used_uids.append(cands[k]["uid"])

	# 步骤2：为 sch_cost2 挑选回收符文（排除已选）
	if sch_need2 > 0 and sch_type2 != "":
		var tapped_r2: Array   = GameState.p_runes.filter(func(r): return r.get("rune_type","") == sch_type2 and r.get("tapped", false) and not (r["uid"] in used_uids))
		var untapped_r2: Array = GameState.p_runes.filter(func(r): return r.get("rune_type","") == sch_type2 and not r.get("tapped", false) and not (r["uid"] in used_uids))
		var cands2: Array = tapped_r2 + untapped_r2
		if cands2.size() < sch_need2:
			return null
		for k in range(sch_need2):
			recycle_entries.append({ "uid": cands2[k]["uid"], "rune_type": sch_type2 })
			used_uids.append(cands2[k]["uid"])

	# 步骤3：为法力挑选横置符文（未横置且未被回收占用）
	var tap_uids: Array = []
	if mana_need > 0:
		var avail: Array = GameState.p_runes.filter(func(r): return not r.get("tapped", false) and not (r["uid"] in used_uids))
		if avail.size() < mana_need:
			return null
		for k in range(mana_need):
			tap_uids.append(avail[k]["uid"])

	# 构建描述文字
	var lines: Array = []
	if tap_uids.size() > 0:
		lines.append("横置 %d 个符文（+%d法力）" % [tap_uids.size(), tap_uids.size()])
	if sch_need1 > 0:
		lines.append("回收 %d 个%s（+%d符能）" % [sch_need1, sch_type1, sch_need1])
	if sch_need2 > 0:
		lines.append("回收 %d 个%s（+%d符能）" % [sch_need2, sch_type2, sch_need2])
	return { "tap_uids": tap_uids, "recycle_entries": recycle_entries, "lines": lines }


# ═══════════════════════════════════════════════
# apply_resource_fix — 执行资源补足方案
# 对应 JS spell.js applyResourceFix()
# ═══════════════════════════════════════════════
func apply_resource_fix(fix: Dictionary, owner: String) -> void:
	# 先执行回收（获得符能）
	for entry in fix.get("recycle_entries", []):
		GameState.recycle_rune(owner, entry["uid"])
	# 再执行横置（获得法力）
	for uid in fix.get("tap_uids", []):
		GameState.tap_rune(owner, uid)


# ═══════════════════════════════════════════════
# _run_spell_reaction_window — 法术结算前反应窗口
# 对应 JS 中 showReactionWindow / hasReactionCards
# 对手若有反应牌，可在此窗口中出牌（含反制）
# ═══════════════════════════════════════════════
func _run_spell_reaction_window(spell: Dictionary, owner: String, target_uid: int) -> void:
	var opponent: String = "enemy" if owner == "player" else "player"
	var opp_hand: Array = GameState.e_hand if opponent == "enemy" else GameState.p_hand
	# 仅反应/迅捷牌可在此时机出牌
	var has_reaction := opp_hand.any(func(c):
		return KeywordManager.can_play_in_timing(c, "time_point") and can_play(c, opponent))
	if not has_reaction:
		return
	GameState.reaction_active = true
	GameState.reaction_turn = opponent
	GameState.spell_countered = false
	GameState.emit_signal("state_updated")
	if opponent == "enemy":
		# AI 反应：短暂延迟后调用专用反应函数
		await get_tree().create_timer(0.5).timeout
		if not GameState.game_over:
			await AIManager.ai_reaction_action()
	else:
		# 玩家反应：等待玩家在 GameBoard 中出牌或点击「跳过反应」
		await GameState.reaction_player_acted
	GameState.reaction_active = false
	GameState.reaction_turn = ""
	GameState.emit_signal("state_updated")


# ═══════════════════════════════════════════════
# play_card — 完整出牌执行
# 对应 JS spell.js confirmPlay() / deployToBase() / deployToBF()
# 参数：
#   card        — 要出的卡牌 dict（来自手牌或英雄区）
#   owner       — "player" 或 "enemy"
#   target_uid  — 法术目标 uid（-1 表示无目标）
#   from_hero   — true 表示从英雄区打出
# 返回 true=成功出牌，false=出牌条件不满足
# ═══════════════════════════════════════════════
func play_card(card: Dictionary, owner: String, target_uid: int = -1, from_hero: bool = false) -> bool:
	if not can_play(card, owner):
		return false

	var hand: Array    = GameState.p_hand    if owner == "player" else GameState.e_hand
	var base: Array    = GameState.p_base    if owner == "player" else GameState.e_base
	var discard: Array = GameState.p_discard if owner == "player" else GameState.e_discard

	# ── 扣除资源 ──
	var cost: int = get_effective_cost(card, owner)
	if owner == "player":
		GameState.p_mana -= cost
	else:
		GameState.e_mana -= cost

	var sch_type: String  = card.get("sch_type", "")
	var sch_cost: int     = card.get("sch_cost", 0)
	if sch_cost > 0 and sch_type != "":
		GameState.spend_sch(owner, sch_type, sch_cost)

	var sch_type2: String = card.get("sch_type2", "")
	var sch_cost2: int    = card.get("sch_cost2", 0)
	if sch_cost2 > 0 and sch_type2 != "":
		GameState.spend_sch(owner, sch_type2, sch_cost2)

	# ── 从手牌或英雄区移除 ──
	if from_hero:
		if owner == "player":
			GameState.p_hero = {}
		else:
			GameState.e_hero = {}
	else:
		var idx: int = -1
		for i in range(hand.size()):
			if hand[i].get("uid", -1) == card.get("uid", -2):
				idx = i
				break
		if idx >= 0:
			hand.remove_at(idx)

	GameState.cards_played_this_turn += 1

	# ── 按牌型执行效果 ──
	var card_type: String = card.get("type", "")
	match card_type:
		"spell":
			# 反应类/迅捷类法术本身不触发反应窗口（规则 725）
			var kws: Array = card.get("keywords", [])
			var is_fast_or_reaction := "迅捷" in kws or "反应" in kws
			if not is_fast_or_reaction and not GameState.duel_active and not GameState.reaction_active:
				# 普通法术：开放对手的反应窗口
				GameState.last_spell_target_uid = target_uid
				await _run_spell_reaction_window(card, owner, target_uid)
			# 检查法术是否被反制
			if GameState.spell_countered:
				GameState.spell_countered = false
				GameState._log("【%s】被反制，效果取消！" % card.get("name","?"), "imp")
				discard.append(card)
			else:
				# 法术：执行效果后进废牌堆
				await apply_spell(card, owner, target_uid)
				GameState._log("施放法术【%s】并置入废牌堆" % card.get("name","?"), "imp")
				discard.append(card)

		"equipment":
			# 装备：以活跃状态进基地（规则144）
			# 不自动附着——玩家点击基地装备再选择单位，并支付装配符能费
			var unit: Dictionary = GameState.mk(card)
			unit["exhausted"] = false
			base.append(unit)
			GameState._log("装备【%s】已进入基地，点击它选择单位装配（需支付装配符能费）" % card.get("name","?"), "imp")

		_:  # follower / hero
			var unit: Dictionary = GameState.mk(card)
			var enter_active: bool = (GameState.p_rally_active if owner == "player" else GameState.e_rally_active)

			# 急速（规则717）：可选额外支付[1]法力+[1]匹配符能，以活跃状态进场
			if not enter_active and GameState.has_keyword(unit, "急速"):
				var extra_sch_type: String = unit.get("sch_type", "")
				var my_mana: int = GameState.p_mana if owner == "player" else GameState.e_mana
				var can_pay_extra: bool = my_mana >= 1 and \
						(extra_sch_type == "" or GameState.get_sch(owner, extra_sch_type) >= 1)
				if can_pay_extra:
					var do_rush = await PromptManager.ask({
						"title": "急速（可选额外费用）",
						"msg": "额外支付[1]法力%s，使【%s】以活跃状态进场？" % [
							"+[1]%s符能" % extra_sch_type if extra_sch_type != "" else "",
							unit.get("name","?")],
						"type": "confirm"
					})
					if do_rush:
						if owner == "player": GameState.p_mana -= 1
						else:                 GameState.e_mana  -= 1
						if extra_sch_type != "":
							GameState.spend_sch(owner, extra_sch_type, 1)
						enter_active = true
						GameState._log("支付急速费用，【%s】以活跃状态进场！" % unit.get("name","?"), "imp")

			unit["exhausted"] = not enter_active
			base.append(unit)
			await on_summon(unit, owner)
			GameState._log("召唤【%s】进入基地%s" % [
					unit.get("name","?"),
					"（活跃）" if not unit.get("exhausted", true) else ""], "imp")

	GameState.emit_signal("state_updated")
	return true


## _find_unit_by_uid — 在数组中按 uid 查找单位，找不到返回 null
func _find_unit_by_uid(units: Array, uid: int) -> Variant:
	if uid < 0:
		return null
	for u in units:
		if u.get("uid", -1) == uid:
			return u
	return null


## _is_legend — 判断单位是否为任意一方的传奇
func _is_legend(unit: Dictionary) -> bool:
	var uid: int = unit.get("uid", -1)
	if not GameState.p_leg.is_empty() and GameState.p_leg.get("uid", -1) == uid:
		return true
	if not GameState.e_leg.is_empty() and GameState.e_leg.get("uid", -1) == uid:
		return true
	return false
