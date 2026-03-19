extends Node2D
# ═══════════════════════════════════════════════
# Main.gd — 入口场景
# GAME_MODE = true  → 启动 GameBoard 正式游戏界面
# GAME_MODE = false → 运行阶段一~八回归测试
# ═══════════════════════════════════════════════

## 切换为 false 可恢复全量回归测试
const GAME_MODE := true

func _ready() -> void:
	if GAME_MODE:
		_launch_game()
		return

	# ─── 测试模式 ───────────────────────────────
	print("╔══════════════════════════════════════╗")
	print("║  FWTCG Godot 4.6 — 阶段一~八验证    ║")
	print("╚══════════════════════════════════════╝")

	# PromptManager 设为自动模式（测试期间无 UI 弹窗）
	PromptManager.auto_mode = true

	# 连接日志信号（方便查看游戏日志）
	GameState.log_entry.connect(_on_log)
	GameState.score_changed.connect(_on_score)
	GameState.game_over_signal.connect(_on_game_over)
	GameState.phase_changed.connect(_on_phase)

	_test_phase1()
	await _test_phase2()

	await _test_phase3()

	await _test_phase4()

	await _test_phase5()

	await _test_phase6()

	await _test_phase7()

	await _test_phase8()

	print("")
	print("╔══════════════════════════════════════╗")
	print("║  ✓ 阶段一~八全部通过！               ║")
	print("║  可以进入 Step 6（UI基础界面）        ║")
	print("╚══════════════════════════════════════╝")


func _launch_game() -> void:
	# 加载 GameBoard 场景并挂在当前节点下
	var board_scene = load("res://scenes/GameBoard.tscn")
	if board_scene == null:
		push_error("GameBoard.tscn 加载失败，请检查路径")
		return
	var board = board_scene.instantiate()
	add_child(board)


# ── 信号回调（仅在测试时打印关键事件）──
func _on_log(text: String, category: String) -> void:
	if category in ["imp", "score", "combat"]:
		print("  LOG[" + category + "]: " + text)

func _on_score(p: int, e: int) -> void:
	print("  SCORE: 玩家=" + str(p) + " AI=" + str(e))

func _on_game_over(winner: String, msg: String) -> void:
	print("  GAME OVER: " + winner + " — " + msg)

func _on_phase(ph: String) -> void:
	pass  # 阶段切换太频繁，测试时不打印


# ───────────────────────────────────────────────
# 阶段一测试（保留，确认未破坏）
# ───────────────────────────────────────────────
func _test_phase1() -> void:
	print("")
	print("── 阶段一回归测试 ──")
	assert(CardDatabase.BATTLEFIELDS.size() == 19, "战场数量错误")
	assert(CardDatabase.KAISA_MAIN.size()    == 40, "卡莎牌组错误")
	assert(CardDatabase.MASTERYI_MAIN.size() == 40, "易牌组错误")
	assert(CardDatabase.KAISA_LEGEND["hp"]   == 14, "卡莎传奇 HP 错误")
	var unit: Dictionary = GameState.mk(CardDatabase.KAISA_MAIN[0])
	assert(unit.has("uid"), "mk() 缺少 uid")
	print("✓ 阶段一回归测试通过")


# ───────────────────────────────────────────────
# 阶段二测试
# ───────────────────────────────────────────────
func _test_phase2() -> void:
	print("")
	print("── 阶段二测试：游戏初始化 ──")

	# ── 2.1 固定牌组启动游戏 ──
	GameState.start_game("kaisa", "masteryi")

	# 牌组大小：40张可抽卡 - 4手牌 = 36张（英雄卡独立，不占主牌堆）
	assert(GameState.p_deck.size() == 36, "卡莎牌库应为36张（40-4手牌），实际: " + str(GameState.p_deck.size()))
	assert(GameState.e_deck.size() == 36, "易牌库应为36张（40-4手牌），实际: " + str(GameState.e_deck.size()))
	print("✓ 牌库大小: 卡莎=" + str(GameState.p_deck.size()) + " 易=" + str(GameState.e_deck.size()))

	# 初始手牌4张
	assert(GameState.p_hand.size() == 4, "玩家初始手牌应为4张")
	assert(GameState.e_hand.size() == 4, "AI初始手牌应为4张")
	print("✓ 初始手牌: 玩家=" + str(GameState.p_hand.size()) + " AI=" + str(GameState.e_hand.size()))

	# 符文牌库
	assert(GameState.p_rune_deck.size() == 12, "卡莎符文库应为12张(7+5)，实际: " + str(GameState.p_rune_deck.size()))
	assert(GameState.e_rune_deck.size() == 12, "易符文库应为12张(6+6)，实际: " + str(GameState.e_rune_deck.size()))
	print("✓ 符文牌库: 卡莎=" + str(GameState.p_rune_deck.size()) + " 易=" + str(GameState.e_rune_deck.size()))

	# 传奇卡
	assert(not GameState.p_leg.is_empty(), "玩家传奇未初始化")
	assert(not GameState.e_leg.is_empty(), "AI传奇未初始化")
	assert(GameState.p_leg["id"] == "kaisa", "玩家传奇应为卡莎")
	assert(GameState.e_leg["id"] == "masteryi", "AI传奇应为无极剑圣")
	print("✓ 传奇: 玩家=" + GameState.p_leg["name"] + " AI=" + GameState.e_leg["name"])

	# 英雄卡抽出
	assert(not GameState.p_hero.is_empty(), "玩家英雄卡未抽出")
	assert(not GameState.e_hero.is_empty(), "AI英雄卡未抽出")
	print("✓ 英雄卡: 玩家=" + GameState.p_hero.get("name","?") + " AI=" + GameState.e_hero.get("name","?"))

	# 战场已初始化
	assert(GameState.bf[0]["card"] != null, "战场1未初始化")
	assert(GameState.bf[1]["card"] != null, "战场2未初始化")
	print("✓ 战场: BF1=" + GameState.bf[0]["card"]["name"] + " BF2=" + GameState.bf[1]["card"]["name"])

	# BF 来自正确的战场池
	assert(GameState.bf[0]["card"]["id"] in CardDatabase.KAISA_BF_IDS,    "BF1 应来自卡莎战场池")
	assert(GameState.bf[1]["card"]["id"] in CardDatabase.MASTERYI_BF_IDS, "BF2 应来自伊欧尼亚战场池")
	print("✓ 战场来自正确阵营牌池")

	print("")
	print("── 阶段二测试：得分系统 ──")

	# ── 2.2 基础得分 ──
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")

	# 初始得分为 0
	assert(GameState.p_score == 0, "初始得分应为0")
	assert(GameState.e_score == 0, "初始得分应为0")

	# 普通得分
	var result: bool = GameState.add_score("player", 1, "hold", null)
	assert(result == true, "add_score 应返回 true")
	assert(GameState.p_score == 1, "玩家得分应为1")
	print("✓ 基础得分: 玩家=" + str(GameState.p_score))

	# 敌方得分
	GameState.add_score("enemy", 2, "hold", null)
	assert(GameState.e_score == 2, "AI得分应为2")
	print("✓ AI得分: " + str(GameState.e_score))

	# ── 2.3 遗忘丰碑限制（第3回合前）──
	GameState.round = 1
	# 设置战场为遗忘丰碑
	GameState.bf[0]["card"] = { "id": "forgotten_monument", "name": "遗忘丰碑", "type": "battlefield", "text": "" }
	GameState.bf[0]["ctrl"] = "player"
	var blocked: bool = GameState.add_score("player", 1, "hold", 1)
	assert(blocked == false, "遗忘丰碑：第3回合前应阻止据守得分")
	print("✓ 遗忘丰碑：第" + str(GameState.round) + "回合得分被正确阻止")

	# 第3回合后应允许
	GameState.round = 3
	var allowed: bool = GameState.add_score("player", 1, "hold", 1)
	assert(allowed == true, "遗忘丰碑：第3回合后应允许据守得分")
	print("✓ 遗忘丰碑：第3回合后得分正常允许")

	print("")
	print("── 阶段二测试：绝念触发 ──")

	# ── 2.4 绝念触发 ──
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")

	var hand_before: int = GameState.p_hand.size()
	var sentinel_template: Dictionary = {}
	for c in CardDatabase.KAISA_MAIN:
		if c["id"] == "alert_sentinel":
			sentinel_template = c
			break

	var sentinel: Dictionary = GameState.mk(sentinel_template)
	GameState.trigger_deathwish(sentinel, "player")
	assert(GameState.p_hand.size() == hand_before + 1, "警觉的哨兵绝念：应抽1张牌")
	print("✓ 绝念（警觉的哨兵）：手牌从" + str(hand_before) + "→" + str(GameState.p_hand.size()))

	print("")
	print("── 阶段二测试：回合流程（唤醒→召出→抽牌）──")
	print("   (注：行动阶段由 AIManager 处理，Phase 6 实现)")

	# ── 2.5 手动测试各阶段函数 ──
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.first = "player"
	GameState.turn  = "player"
	GameState.round = 1

	# 放几张符文到符文区（模拟已召出状态）
	GameState.p_runes.append(GameState.mk_rune("blazing"))
	GameState.p_runes.append(GameState.mk_rune("radiant"))
	GameState.p_runes[0]["tapped"] = true  # 模拟休眠状态
	GameState.p_runes[1]["tapped"] = true

	# 唤醒阶段：应解除休眠
	GameState._do_awaken()
	assert(GameState.p_runes[0]["tapped"] == false, "唤醒：符文应解除休眠")
	assert(GameState.p_runes[1]["tapped"] == false, "唤醒：符文应解除休眠")
	print("✓ 唤醒阶段：符文解除休眠正常")

	# 召出阶段：玩家先手，第1回合召2张符文
	var rune_before: int = GameState.p_runes.size()
	var rune_deck_before: int = GameState.p_rune_deck.size()
	GameState._do_summon()
	assert(GameState.p_runes.size() == rune_before + 2, "召出：先手第1回合应召2张符文")
	assert(GameState.p_rune_deck.size() == rune_deck_before - 2, "召出：符文牌库应减少2张")
	print("✓ 召出阶段：新增 " + str(GameState.p_runes.size() - rune_before) + " 张符文")

	# 抽牌阶段：手牌应增加1张
	var hand_count_before: int = GameState.p_hand.size()
	await GameState._do_draw()
	assert(GameState.p_hand.size() == hand_count_before + 1, "抽牌：手牌应增加1张")
	print("✓ 抽牌阶段：手牌 " + str(hand_count_before) + "→" + str(GameState.p_hand.size()))

	# 法力应被清空（抽牌阶段末）
	assert(GameState.p_mana == 0, "抽牌阶段末：玩家法力应为0")
	print("✓ 抽牌阶段末：法力已清零")

	# ── 2.6 结束阶段测试 ──
	# 给一个单位加临时增益，结束阶段后应清除
	var test_unit: Dictionary = GameState.mk(CardDatabase.KAISA_MAIN[0])
	test_unit["tb"]["atk"] = 5
	test_unit["stunned"] = true
	GameState.p_base.append(test_unit)

	await GameState.do_end_phase()
	# do_end_phase 会推进到下一回合，不做更多断言
	print("✓ 结束阶段：正常完成，推进到下一回合（round=" + str(GameState.round) + "）")

	print("── 回合流程测试通过 ──")
	print("")
	print("── 阶段二测试：换牌（Mulligan）──")

	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")

	var original_hand: Array = GameState.p_hand.duplicate()
	var original_deck_size: int = GameState.p_deck.size()

	# 换第0和第1张
	GameState.do_mulligan([0, 1])
	assert(GameState.p_hand.size() == 4, "换牌后手牌应仍为4张，实际: " + str(GameState.p_hand.size()))
	assert(GameState.p_deck.size() == original_deck_size, "换牌后牌库大小不变（换入换出抵消）")
	print("✓ 换牌（Mulligan）：手牌=" + str(GameState.p_hand.size()) + "张，牌库=" + str(GameState.p_deck.size()) + "张")


# ───────────────────────────────────────────────
# 阶段三测试：战斗系统
# ───────────────────────────────────────────────
func _test_phase3() -> void:  # 异步（内部使用 await）
	print("")
	print("── 阶段三测试：战斗系统 ──")

	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	# 阶段三只测纯战斗逻辑，清空传奇避免 onCombatDefend 等技能干扰
	GameState.p_leg = {}
	GameState.e_leg = {}
	# 固定战场为空战场（无特殊能力）
	GameState.bf[0]["card"] = { "id": "test_bf", "name": "测试战场", "type": "battlefield", "text": "" }

	# ── 3.1 基础征服：进攻方战力 > 防守方，征服得分 ──
	print("")
	print("  3.1 征服测试：进攻3战 vs 防守2战")
	GameState.bf[0]["pU"] = []
	GameState.bf[0]["eU"] = []
	GameState.bf[0]["ctrl"] = null
	GameState.bf[0]["conq_done"] = false

	var attacker_unit: Dictionary = GameState.mk({ "id": "test_a", "name": "进攻者", "region": "void",
		"type": "follower", "cost": 3, "atk": 3, "hp": 3, "keywords": [], "text": "", "img": "" })
	attacker_unit["current_hp"] = 3
	attacker_unit["current_atk"] = 3
	var defender_unit: Dictionary = GameState.mk({ "id": "test_d", "name": "防守者", "region": "void",
		"type": "follower", "cost": 2, "atk": 2, "hp": 2, "keywords": [], "text": "", "img": "" })
	defender_unit["current_hp"] = 2
	defender_unit["current_atk"] = 2

	GameState.bf[0]["pU"].append(attacker_unit)
	GameState.bf[0]["eU"].append(defender_unit)

	var score_before: int = GameState.p_score
	await CombatManager.trigger_combat(1, "player")

	# 防守者死亡（2HP受3伤），进攻者存活（3HP受2伤→重置后3HP），玩家征服
	assert(GameState.bf[0]["ctrl"] == "player", "征服后战场控制权应为玩家，实际: " + str(GameState.bf[0]["ctrl"]))
	assert(GameState.p_score == score_before + 1, "征服应+1分，实际分数: " + str(GameState.p_score))
	assert(GameState.e_discard.size() > 0, "防守者应进入AI废牌堆")
	print("  ✓ 进攻者征服战场，+1分，防守者入废牌堆")

	# ── 3.2 防守成功：进攻方战力 < 防守方 ──
	print("")
	print("  3.2 防守测试：进攻2战 vs 防守4战")
	GameState.bf[0]["pU"] = []
	GameState.bf[0]["eU"] = []
	GameState.bf[0]["ctrl"] = null
	GameState.bf[0]["conq_done"] = false
	GameState.p_discard = []
	GameState.e_discard = []

	var weak_attacker: Dictionary = GameState.mk({ "id": "test_wa", "name": "弱进攻者", "region": "void",
		"type": "follower", "cost": 2, "atk": 2, "hp": 2, "keywords": [], "text": "", "img": "" })
	weak_attacker["current_hp"] = 2
	weak_attacker["current_atk"] = 2
	var strong_defender: Dictionary = GameState.mk({ "id": "test_sd", "name": "强防守者", "region": "void",
		"type": "follower", "cost": 4, "atk": 4, "hp": 4, "keywords": [], "text": "", "img": "" })
	strong_defender["current_hp"] = 4
	strong_defender["current_atk"] = 4

	GameState.bf[0]["pU"].append(weak_attacker)
	GameState.bf[0]["eU"].append(strong_defender)

	await CombatManager.trigger_combat(1, "player")

	assert(GameState.bf[0]["ctrl"] == "enemy", "防守成功后控制权应为AI，实际: " + str(GameState.bf[0]["ctrl"]))
	assert(GameState.p_discard.size() > 0, "进攻者应进入玩家废牌堆")
	print("  ✓ 防守方（AI）守住战场，进攻者入废牌堆")

	# ── 3.3 双方全灭（平局） ──
	print("")
	print("  3.3 平局测试：进攻2战 vs 防守2战（等战力，双方各受2伤）")
	GameState.bf[0]["pU"] = []
	GameState.bf[0]["eU"] = []
	GameState.bf[0]["ctrl"] = null
	GameState.bf[0]["conq_done"] = false
	GameState.p_discard = []
	GameState.e_discard = []

	var p_unit_draw: Dictionary = GameState.mk({ "id": "test_pd", "name": "玩家2/2", "region": "void",
		"type": "follower", "cost": 2, "atk": 2, "hp": 2, "keywords": [], "text": "", "img": "" })
	p_unit_draw["current_hp"] = 2
	p_unit_draw["current_atk"] = 2
	var e_unit_draw: Dictionary = GameState.mk({ "id": "test_ed", "name": "AI的2/2", "region": "void",
		"type": "follower", "cost": 2, "atk": 2, "hp": 2, "keywords": [], "text": "", "img": "" })
	e_unit_draw["current_hp"] = 2
	e_unit_draw["current_atk"] = 2

	GameState.bf[0]["pU"].append(p_unit_draw)
	GameState.bf[0]["eU"].append(e_unit_draw)

	await CombatManager.trigger_combat(1, "player")

	assert(GameState.bf[0]["ctrl"] == null, "双方全灭后控制权应为null，实际: " + str(GameState.bf[0]["ctrl"]))
	assert(GameState.p_discard.size() > 0, "玩家单位应进入废牌堆")
	assert(GameState.e_discard.size() > 0, "AI单位应进入废牌堆")
	print("  ✓ 双方全灭，控制权null，双方入废牌堆")

	# ── 3.4 壁垒关键词：壁垒单位优先承受伤害 ──
	print("")
	print("  3.4 壁垒测试：1名壁垒单位优先受击")
	GameState.bf[0]["pU"] = []
	GameState.bf[0]["eU"] = []
	GameState.bf[0]["ctrl"] = null
	GameState.bf[0]["conq_done"] = false
	GameState.p_discard = []
	GameState.e_discard = []

	# 进攻方：1名3战力单位
	var barrier_attacker: Dictionary = GameState.mk({ "id": "test_ba", "name": "进攻3战", "region": "void",
		"type": "follower", "cost": 3, "atk": 3, "hp": 3, "keywords": [], "text": "", "img": "" })
	barrier_attacker["current_hp"] = 3; barrier_attacker["current_atk"] = 3
	# 防守方：1名壁垒单位（1战2血）+ 1名普通单位（1战1血）
	var barrier_unit: Dictionary = GameState.mk({ "id": "test_bu", "name": "壁垒单位", "region": "void",
		"type": "follower", "cost": 1, "atk": 1, "hp": 2, "keywords": ["壁垒"], "text": "", "img": "" })
	barrier_unit["current_hp"] = 2; barrier_unit["current_atk"] = 1
	var normal_unit: Dictionary = GameState.mk({ "id": "test_nu", "name": "普通单位", "region": "void",
		"type": "follower", "cost": 1, "atk": 1, "hp": 1, "keywords": [], "text": "", "img": "" })
	normal_unit["current_hp"] = 1; normal_unit["current_atk"] = 1

	GameState.bf[0]["pU"].append(barrier_attacker)
	GameState.bf[0]["eU"].append(barrier_unit)
	GameState.bf[0]["eU"].append(normal_unit)

	# 进攻方3战 vs 防守方2战 (1+1)
	# 壁垒单位先受2伤（2HP归零），普通单位受剩余1伤（1HP归零）
	# 进攻方受2伤（防守方总输出2），进攻者还剩1HP → 存活后重置
	await CombatManager.trigger_combat(1, "player")

	# 两名防守者应都阵亡，进攻者应征服
	assert(GameState.bf[0]["ctrl"] == "player", "壁垒测试：进攻方应征服，实际ctrl=" + str(GameState.bf[0]["ctrl"]))
	print("  ✓ 壁垒单位优先受击，进攻方征服")

	# ── 3.5 绝念：警觉的哨兵死亡时抽牌 ──
	print("")
	print("  3.5 绝念测试：警觉的哨兵死亡抽牌")
	GameState.bf[0]["pU"] = []
	GameState.bf[0]["eU"] = []
	GameState.bf[0]["ctrl"] = null
	GameState.bf[0]["conq_done"] = false
	GameState.p_discard = []
	GameState.e_discard = []

	# 找到警觉的哨兵模板
	var sentinel_tmpl: Dictionary = {}
	for c in CardDatabase.KAISA_MAIN:
		if c["id"] == "alert_sentinel":
			sentinel_tmpl = c; break

	var pw_attacker: Dictionary = GameState.mk({ "id": "test_pw", "name": "进攻者4战", "region": "void",
		"type": "follower", "cost": 4, "atk": 4, "hp": 4, "keywords": [], "text": "", "img": "" })
	pw_attacker["current_hp"] = 4; pw_attacker["current_atk"] = 4
	var the_sentinel: Dictionary = GameState.mk(sentinel_tmpl)
	the_sentinel["current_hp"] = the_sentinel["atk"]
	the_sentinel["current_atk"] = the_sentinel["atk"]

	GameState.bf[0]["pU"].append(pw_attacker)
	GameState.bf[0]["eU"].append(the_sentinel)  # 哨兵在AI方

	var e_hand_before: int = GameState.e_hand.size()
	await CombatManager.trigger_combat(1, "player")  # 玩家进攻，AI方哨兵死亡

	assert(GameState.e_hand.size() == e_hand_before + 1, "哨兵绝念：AI应抽1张牌，实际: " + str(GameState.e_hand.size()))
	print("  ✓ 绝念（警觉的哨兵）：AI抽1张牌，" + str(e_hand_before) + "→" + str(GameState.e_hand.size()))

	# ── 3.6 压制：溢出伤害传递给传奇 ──
	print("")
	print("  3.6 压制测试：溢出伤害传奇")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.bf[0]["card"] = { "id": "test_bf", "name": "测试战场", "type": "battlefield", "text": "" }

	var suppress_unit: Dictionary = GameState.mk({ "id": "test_su", "name": "压制进攻者", "region": "void",
		"type": "follower", "cost": 5, "atk": 5, "hp": 5, "keywords": ["压制"], "text": "", "img": "" })
	suppress_unit["current_hp"] = 5; suppress_unit["current_atk"] = 5
	var weak_def: Dictionary = GameState.mk({ "id": "test_wd", "name": "弱防守2血", "region": "void",
		"type": "follower", "cost": 2, "atk": 2, "hp": 2, "keywords": [], "text": "", "img": "" })
	weak_def["current_hp"] = 2; weak_def["current_atk"] = 2

	GameState.bf[0]["pU"].append(suppress_unit)
	GameState.bf[0]["eU"].append(weak_def)

	var e_leg_hp_before: int = GameState.e_leg.get("current_hp", 0)
	await CombatManager.trigger_combat(1, "player")
	# 5攻 vs 2HP防守 → 3溢出 → AI传奇减3HP
	assert(GameState.e_leg.get("current_hp", 0) == e_leg_hp_before - 3,
		"压制：AI传奇应减3HP，实际HP=" + str(GameState.e_leg.get("current_hp", 0)))
	print("  ✓ 压制：溢出3伤传奇，传奇HP " + str(e_leg_hp_before) + "→" + str(GameState.e_leg.get("current_hp", 0)))

	# ── 3.7 中娅沙漏：死亡护盾救回濒死单位 ──
	print("")
	print("  3.7 中娅沙漏测试：救回濒死单位")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.bf[0]["card"] = { "id": "test_bf", "name": "测试战场", "type": "battlefield", "text": "" }

	var shield_protected: Dictionary = GameState.mk({ "id": "test_sp", "name": "受保护单位", "region": "void",
		"type": "follower", "cost": 2, "atk": 2, "hp": 2, "keywords": [], "text": "", "img": "" })
	shield_protected["current_hp"] = 2; shield_protected["current_atk"] = 2
	var death_shield_equip: Dictionary = { "uid": 9999, "id": "zhonya", "name": "中娅沙漏",
		"type": "equipment", "effect": "death_shield" }

	GameState.bf[0]["eU"].append(shield_protected)
	GameState.e_base.append(death_shield_equip)  # AI基地有中娅沙漏装备

	var killer: Dictionary = GameState.mk({ "id": "test_k", "name": "杀手5战", "region": "void",
		"type": "follower", "cost": 5, "atk": 5, "hp": 5, "keywords": [], "text": "", "img": "" })
	killer["current_hp"] = 5; killer["current_atk"] = 5
	GameState.bf[0]["pU"].append(killer)

	var e_base_before: int = GameState.e_base.size()
	await CombatManager.trigger_combat(1, "player")
	# 受保护单位本应死亡，中娅沙漏应触发救回
	assert(GameState.e_base.size() >= 1, "中娅沙漏：受保护单位应被救回AI基地")
	var saved: bool = GameState.e_base.any(func(u): return u.get("id", "") == "test_sp")
	assert(saved, "中娅沙漏：受保护单位 id=test_sp 应在AI基地中")
	print("  ✓ 中娅沙漏：受保护单位被救回AI基地（休眠状态）")

	print("")
	print("── 阶段三测试全部通过 ──")


# ───────────────────────────────────────────────
# 阶段四测试：SpellManager — 法术效果 + 入场触发
# ───────────────────────────────────────────────
func _test_phase4() -> void:
	print("")
	print("── 阶段四测试：SpellManager ──")

	# ── 4.0 准备：重置游戏，auto_mode 确保无 UI 弹窗 ──
	PromptManager.auto_mode = true
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.turn = "player"
	# 给玩家足够法力和符能
	GameState.p_mana = 10
	GameState.p_sch = { "blazing": 5, "radiant": 5, "verdant": 5, "crushing": 5, "chaos": 5, "order": 5 }

	# ── 4.1 get_spell_targets：deal3 → 只返回敌方战场单位 ──
	print("")
	print("  4.1 get_spell_targets")
	# 在敌方战场放一个单位
	var t_unit: Dictionary = GameState.mk(CardDatabase.MASTERYI_MAIN[0])
	GameState.bf[0]["eU"].append(t_unit)
	# 在敌方基地放一个单位
	var base_unit: Dictionary = GameState.mk(CardDatabase.MASTERYI_MAIN[1])
	GameState.e_base.append(base_unit)

	var deal3_card: Dictionary = { "type": "spell", "effect": "deal3", "cost": 3 }
	var targets = SpellManager.get_spell_targets(deal3_card, "player")
	assert(targets != null, "deal3 应返回目标列表（非null）")
	assert(t_unit["uid"] in targets, "deal3 应包含敌方战场单位")
	assert(not (base_unit["uid"] in targets), "deal3 不应包含敌方基地单位")
	print("  ✓ deal3 只返回战场单位（排除基地）")

	# draw1 → 无需目标
	var draw1_card: Dictionary = { "type": "spell", "effect": "draw1", "cost": 1 }
	var draw1_targets = SpellManager.get_spell_targets(draw1_card, "player")
	assert(draw1_targets == null, "draw1 应返回 null（无需目标）")
	print("  ✓ draw1 返回 null（无需目标）")

	# ── 4.2 apply_spell — draw1 ──
	print("")
	print("  4.2 apply_spell(draw1)")
	var hand_before: int = GameState.p_hand.size()
	await SpellManager.apply_spell(draw1_card, "player")
	assert(GameState.p_hand.size() == hand_before + 1,
			"draw1 应使手牌+1，实际: " + str(GameState.p_hand.size()))
	print("  ✓ draw1：手牌从%d→%d" % [hand_before, GameState.p_hand.size()])

	# ── 4.3 apply_spell — deal3（对战场单位造3伤）──
	print("")
	print("  4.3 apply_spell(deal3)")
	var victim_atk: int = t_unit.get("atk", 2)
	t_unit["current_hp"] = victim_atk  # 确保满血
	var hp_before: int = t_unit.get("current_hp", victim_atk)
	await SpellManager.apply_spell(deal3_card, "player", t_unit["uid"])
	# 判断：要么单位受伤（hp减少），要么如果hp≤3则已死亡（清理掉了）
	var still_on_field: bool = false
	for b in GameState.bf:
		for u in b["eU"]:
			if u.get("uid", -1) == t_unit["uid"]:
				still_on_field = true
				assert(u.get("current_hp", 0) == max(0, hp_before - 3),
						"deal3：应造成3伤，剩余hp: " + str(u.get("current_hp", 0)))
	if not still_on_field:
		print("  ✓ deal3：单位（初始战力%d）被3伤直接击杀（已清理）" % victim_atk)
	else:
		print("  ✓ deal3：单位受到3伤，剩余hp=" + str(t_unit.get("current_hp", 0)))

	# ── 4.4 apply_spell — stun ──
	print("")
	print("  4.4 apply_spell(stun)")
	# 放一个新的敌方单位到基地
	var stun_target: Dictionary = GameState.mk(CardDatabase.MASTERYI_MAIN[2])
	stun_target["current_hp"] = stun_target.get("atk", 2)
	GameState.e_base.append(stun_target)
	var stun_card: Dictionary = { "type": "spell", "effect": "stun", "cost": 2 }
	await SpellManager.apply_spell(stun_card, "player", stun_target["uid"])
	assert(stun_target.get("stunned", false) == true, "stun 应使目标进入眩晕状态")
	print("  ✓ stun：【%s】被正确眩晕" % stun_target.get("name","?"))

	# ── 4.5 apply_spell — buff_draw（己方单位临时+1 + 抽牌）──
	print("")
	print("  4.5 apply_spell(buff_draw)")
	# 在己方基地放一个单位
	var ally: Dictionary = GameState.mk(CardDatabase.KAISA_MAIN[0])
	GameState.p_base.append(ally)
	var ally_tb_before: int = ally.get("tb", {}).get("atk", 0)
	var hand_before2: int = GameState.p_hand.size()
	var buff_draw_card: Dictionary = { "type": "spell", "effect": "buff_draw", "cost": 2 }
	await SpellManager.apply_spell(buff_draw_card, "player", ally["uid"])
	assert(ally.get("tb", {}).get("atk", 0) == ally_tb_before + 1,
			"buff_draw：临时战力应+1")
	assert(GameState.p_hand.size() == hand_before2 + 1,
			"buff_draw：手牌应+1")
	print("  ✓ buff_draw：单位临时+1战力，手牌+1")

	# ── 4.6 on_summon — summon_draw1（入场抽牌）──
	print("")
	print("  4.6 on_summon(summon_draw1)")
	var draw_unit_template: Dictionary = { "id": "test_draw", "name": "测试抽牌单位",
		"type": "follower", "cost": 2, "atk": 2, "effect": "summon_draw1" }
	var draw_unit: Dictionary = GameState.mk(draw_unit_template)
	var hand_before3: int = GameState.p_hand.size()
	await SpellManager.on_summon(draw_unit, "player")
	assert(GameState.p_hand.size() == hand_before3 + 1,
			"summon_draw1：入场应抽1张牌，实际手牌: " + str(GameState.p_hand.size()))
	print("  ✓ on_summon(summon_draw1)：手牌从%d→%d" % [hand_before3, GameState.p_hand.size()])

	# ── 4.7 on_summon — thousand_tail_enter（全体敌方-3战力）──
	print("")
	print("  4.7 on_summon(thousand_tail_enter)")
	# 准备2个敌方单位
	var e1: Dictionary = GameState.mk({ "id":"e1","name":"敌1","type":"follower","cost":2,"atk":4 })
	var e2: Dictionary = GameState.mk({ "id":"e2","name":"敌2","type":"follower","cost":3,"atk":5 })
	GameState.e_base.append(e1)
	GameState.e_base.append(e2)
	var tb1_before: int = e1.get("tb", {}).get("atk", 0)
	var tb2_before: int = e2.get("tb", {}).get("atk", 0)
	var thousand_tail: Dictionary = GameState.mk({
		"id": "thousand_tail", "name": "千尾监视者",
		"type": "follower", "cost": 5, "atk": 4,
		"effect": "thousand_tail_enter"
	})
	await SpellManager.on_summon(thousand_tail, "player")
	assert(e1.get("tb", {}).get("atk", 0) == tb1_before - 3,
			"thousand_tail：e1 的 tb.atk 应-3")
	assert(e2.get("tb", {}).get("atk", 0) == tb2_before - 3,
			"thousand_tail：e2 的 tb.atk 应-3")
	print("  ✓ thousand_tail：全体敌方 tb.atk -3（e1=%d e2=%d）" % [
		e1.get("tb",{}).get("atk",0), e2.get("tb",{}).get("atk",0)])

	# ── 4.8 can_play — 法力不足时返回 false ──
	print("")
	print("  4.8 can_play 检查")
	GameState.p_mana = 0
	var expensive_card: Dictionary = { "type": "spell", "effect": "draw1", "cost": 3 }
	assert(SpellManager.can_play(expensive_card, "player") == false,
			"法力为0时，费用3的法术不可出牌")
	print("  ✓ can_play：法力不足时正确返回 false")
	GameState.p_mana = 5
	assert(SpellManager.can_play(expensive_card, "player") == true,
			"法力5时，费用3的法术应可出牌")
	print("  ✓ can_play：法力足够时正确返回 true")

	# ── 4.9 get_effective_cost — 鼓舞减费 ──
	print("")
	print("  4.9 get_effective_cost（鼓舞）")
	var inspire_card: Dictionary = { "type": "spell", "effect": "draw1", "cost": 3,
		"keywords": ["鼓舞"] }
	GameState.cards_played_this_turn = 0
	var cost_before_inspire: int = SpellManager.get_effective_cost(inspire_card, "player")
	assert(cost_before_inspire == 3, "未触发鼓舞时费用应为3")
	GameState.cards_played_this_turn = 1
	var cost_after_inspire: int = SpellManager.get_effective_cost(inspire_card, "player")
	assert(cost_after_inspire == 2, "触发鼓舞后费用应为2")
	print("  ✓ 鼓舞减费：未触发=%d 触发后=%d" % [cost_before_inspire, cost_after_inspire])

	print("")
	print("── 阶段四测试全部通过 ──")


# ───────────────────────────────────────────────
# 阶段五测试：资源系统（tap_rune / recycle_rune / calc_resource_fix / play_card）
# ───────────────────────────────────────────────
func _test_phase5() -> void:
	print("")
	print("── 阶段五测试：资源系统 ──")

	PromptManager.auto_mode = true
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.turn  = "player"
	GameState.phase = "action"

	# start_game 后 p_runes 为空（符文在召出阶段才加入）
	# 手动从 p_rune_deck 取 4 张符文到 p_runes 以模拟已召出状态
	for _i in range(4):
		if GameState.p_rune_deck.size() > 0:
			var r: Dictionary = GameState.p_rune_deck.pop_back()
			r["tapped"] = false
			GameState.p_runes.append(r)
	assert(GameState.p_runes.size() == 4, "手动添加4张符文后 p_runes 应有4张")

	# ── 5.1 tap_rune — 横置符文获得法力 ──
	print("")
	print("  5.1 tap_rune")
	var rune0: Dictionary = GameState.p_runes[0]
	rune0["tapped"] = false
	var mana_before: int = GameState.p_mana
	var ok: bool = GameState.tap_rune("player", rune0["uid"])
	assert(ok == true, "tap_rune 应返回 true")
	assert(GameState.p_mana == mana_before + 1, "横置后法力应+1")
	assert(rune0.get("tapped", false) == true, "横置后符文应标记 tapped=true")
	print("  ✓ tap_rune：法力 %d→%d，符文已横置" % [mana_before, GameState.p_mana])

	# 再次横置同一符文应失败
	var ok2: bool = GameState.tap_rune("player", rune0["uid"])
	assert(ok2 == false, "已横置的符文再次横置应返回 false")
	print("  ✓ 已横置符文重复横置正确返回 false")

	# ── 5.2 recycle_rune — 回收符文获得符能 ──
	print("")
	print("  5.2 recycle_rune")
	# 确保符文区还有至少一张符文
	assert(GameState.p_runes.size() > 0, "符文区应有至少1张符文")
	var rune1: Dictionary = GameState.p_runes[0]
	var rune1_type: String = rune1.get("rune_type", "blazing")
	var rune_deck_before: int = GameState.p_rune_deck.size()
	var sch_before: int = GameState.get_sch("player", rune1_type)
	var runes_before: int = GameState.p_runes.size()
	var rc_ok: bool = GameState.recycle_rune("player", rune1["uid"])
	assert(rc_ok == true, "recycle_rune 应返回 true")
	assert(GameState.p_runes.size() == runes_before - 1, "回收后符文区应减1")
	assert(GameState.get_sch("player", rune1_type) == sch_before + 1, "回收后对应符能应+1")
	assert(GameState.p_rune_deck.size() == rune_deck_before + 1, "回收后符文牌库应+1")
	# 回收的符文应在牌库底部（index 0）
	assert(GameState.p_rune_deck[0].get("uid", -1) == rune1["uid"], "回收的符文应在牌库底部")
	print("  ✓ recycle_rune：符能+1，符文入库底，符文区-1")

	# ── 5.3 calc_resource_fix — 法力不足时建议横置 ──
	print("")
	print("  5.3 calc_resource_fix（法力不足）")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.turn  = "player"
	GameState.phase = "action"
	GameState.p_mana = 0
	# 手动添加5张未横置符文（需要3张横置来补3法力）
	for _i in range(5):
		if GameState.p_rune_deck.size() > 0:
			var r: Dictionary = GameState.p_rune_deck.pop_back()
			r["tapped"] = false
			GameState.p_runes.append(r)
	var need3_card: Dictionary = { "type": "spell", "effect": "draw1", "cost": 3 }
	var fix = SpellManager.calc_resource_fix(need3_card, "player")
	assert(fix != null, "法力不足时 calc_resource_fix 应返回补足方案")
	assert(fix.get("tap_uids", []).size() == 3, "应横置3个符文以补足3法力")
	print("  ✓ calc_resource_fix：建议横置 %d 个符文" % fix.get("tap_uids",[]).size())

	# ── 5.4 calc_resource_fix — 资源已足够时返回 null ──
	print("")
	print("  5.4 calc_resource_fix（资源足够）")
	GameState.p_mana = 5
	var fix_null = SpellManager.calc_resource_fix(need3_card, "player")
	assert(fix_null == null, "资源足够时 calc_resource_fix 应返回 null")
	print("  ✓ 资源足够时正确返回 null")

	# ── 5.5 apply_resource_fix — 实际执行横置 ──
	print("")
	print("  5.5 apply_resource_fix")
	GameState.p_mana = 0
	for r in GameState.p_runes:  # reset all to untapped
		r["tapped"] = false
	var fix2 = SpellManager.calc_resource_fix(need3_card, "player")
	assert(fix2 != null, "应得到补足方案")
	var mana_pre: int = GameState.p_mana
	SpellManager.apply_resource_fix(fix2, "player")
	assert(GameState.p_mana == mana_pre + fix2.get("tap_uids",[]).size(),
			"apply_resource_fix：法力应按横置数量增加")
	print("  ✓ apply_resource_fix：法力 %d→%d" % [mana_pre, GameState.p_mana])

	# ── 5.6 play_card — 出法术牌（draw1）──
	print("")
	print("  5.6 play_card(spell draw1)")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.turn  = "player"
	GameState.phase = "action"
	GameState.p_mana = 5
	# 创建一张 draw1 法术牌并放入手牌
	var draw1_spell: Dictionary = GameState.mk({
		"id": "test_draw1", "name": "测试法术", "type": "spell",
		"cost": 1, "effect": "draw1"
	})
	GameState.p_hand.append(draw1_spell)
	var hand_size_before: int = GameState.p_hand.size()
	var cards_played_before: int = GameState.cards_played_this_turn
	var discard_before: int = GameState.p_discard.size()
	var mana_pre2: int = GameState.p_mana
	var played: bool = await SpellManager.play_card(draw1_spell, "player")
	assert(played == true, "play_card 应返回 true")
	assert(GameState.p_mana == mana_pre2 - 1, "出牌后法力应-1（费用1）")
	# 法术进废牌堆
	assert(GameState.p_discard.size() == discard_before + 1, "法术应进入废牌堆")
	# 出牌计数+1
	assert(GameState.cards_played_this_turn == cards_played_before + 1, "出牌计数应+1")
	# draw1 使手牌+1，再减去打出的1张 = 净变化 0
	# 手牌：hand_size_before（包含刚加的draw1_spell）-1（打出）+1（draw效果）= hand_size_before
	assert(GameState.p_hand.size() == hand_size_before, "draw1 效果：打出1抽1，手牌数不变")
	print("  ✓ play_card(spell)：法力-1，法术入废牌堆，手牌±0（打出1+抽1），计数+1")

	# ── 5.7 play_card — 出单位牌 ──
	print("")
	print("  5.7 play_card(follower)")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.turn  = "player"
	GameState.phase = "action"
	GameState.p_mana = 5
	# 用自定义简单随从模板（无入场效果，无急速）
	var follower_tpl: Dictionary = {
		"id": "test_follower", "name": "测试随从", "type": "follower",
		"cost": 2, "atk": 2, "effect": "", "keywords": []
	}
	var follower_inst: Dictionary = GameState.mk(follower_tpl)
	GameState.p_hand.append(follower_inst)
	var base_before: int = GameState.p_base.size()
	var mana_pre3: int = GameState.p_mana
	var played2: bool = await SpellManager.play_card(follower_inst, "player")
	assert(played2 == true, "随从出牌应成功")
	assert(GameState.p_mana == mana_pre3 - 2, "随从出牌后法力应-2（费用2）")
	assert(GameState.p_base.size() == base_before + 1, "随从应进入基地")
	# 验证单位以休眠状态入场（无急速）
	var new_unit: Dictionary = GameState.p_base[GameState.p_base.size() - 1]
	assert(new_unit.get("exhausted", false) == true, "普通随从应以休眠状态入场")
	print("  ✓ play_card(follower)：单位进入基地，休眠状态入场")

	print("")
	print("── 阶段五测试全部通过 ──")


# ───────────────────────────────────────────────
# 阶段六测试：传奇技能（LegendManager）
# ───────────────────────────────────────────────
func _test_phase6() -> void:
	print("")
	print("── 阶段六测试：传奇技能 ──")

	# ── 共用准备 ──
	PromptManager.auto_mode = true

	# ─────────────────────────────────────────
	# 6.1 卡莎「进化」被动 — ≥4种关键词时升级
	# ─────────────────────────────────────────
	print("")
	print("  6.1 卡莎「进化」被动（≥4种关键词）")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.turn  = "player"
	GameState.phase = "action"

	var leg_before_atk: int = GameState.p_leg.get("current_atk", 0)
	var leg_before_hp:  int = GameState.p_leg.get("current_hp",  0)

	# 在玩家基地放置覆盖4种关键词的盟友
	var u_kw1: Dictionary = GameState.mk({"id":"t1","name":"急速单位","type":"follower","cost":1,"atk":1,"keywords":["急速"]})
	var u_kw2: Dictionary = GameState.mk({"id":"t2","name":"壁垒单位","type":"follower","cost":1,"atk":1,"keywords":["壁垒"]})
	var u_kw3: Dictionary = GameState.mk({"id":"t3","name":"法盾单位","type":"follower","cost":1,"atk":1,"keywords":["法盾"]})
	var u_kw4: Dictionary = GameState.mk({"id":"t4","name":"绝念单位","type":"follower","cost":1,"atk":1,"keywords":["绝念"]})
	GameState.p_base.append(u_kw1)
	GameState.p_base.append(u_kw2)
	GameState.p_base.append(u_kw3)
	GameState.p_base.append(u_kw4)

	LegendManager.check_legend_passives("player")

	assert(GameState.p_leg.get("_evolved", false)  == true,  "进化：传奇应标记 _evolved=true")
	assert(GameState.p_leg.get("level", 1)          == 2,    "进化：传奇应升至 level=2")
	assert(GameState.p_leg.get("current_atk", 0)    == leg_before_atk + 3, "进化：current_atk 应+3")
	assert(GameState.p_leg.get("current_hp", 0)     == leg_before_hp  + 3, "进化：current_hp 应+3")
	print("  ✓ 进化触发：level=%d，atk %d→%d，hp %d→%d" % [
		GameState.p_leg.get("level",1),
		leg_before_atk, GameState.p_leg.get("current_atk",0),
		leg_before_hp,  GameState.p_leg.get("current_hp",0)])

	# ─────────────────────────────────────────
	# 6.2 卡莎「进化」被动 — 不足4种关键词时不触发
	# ─────────────────────────────────────────
	print("")
	print("  6.2 卡莎「进化」（关键词不足时不触发）")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.turn  = "player"
	GameState.phase = "action"

	var leg2_atk: int = GameState.p_leg.get("current_atk", 0)
	# 只放3种关键词
	GameState.p_base.append(GameState.mk({"id":"t1","name":"a","type":"follower","cost":1,"atk":1,"keywords":["急速"]}))
	GameState.p_base.append(GameState.mk({"id":"t2","name":"b","type":"follower","cost":1,"atk":1,"keywords":["壁垒"]}))
	GameState.p_base.append(GameState.mk({"id":"t3","name":"c","type":"follower","cost":1,"atk":1,"keywords":["法盾"]}))

	LegendManager.check_legend_passives("player")
	assert(GameState.p_leg.get("_evolved", false) == false, "进化：3种关键词不应触发进化")
	assert(GameState.p_leg.get("current_atk", 0)  == leg2_atk, "进化：未进化时 atk 不应变化")
	print("  ✓ 3种关键词：进化未触发（atk=%d 不变）" % GameState.p_leg.get("current_atk",0))

	# ─────────────────────────────────────────
	# 6.3 无极剑圣「独影剑鸣」— 1名防守者时+2战力
	# ─────────────────────────────────────────
	print("")
	print("  6.3 无极剑圣「独影剑鸣」（独守+2战力）")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.turn  = "player"
	GameState.phase = "action"

	var solo_defender: Dictionary = GameState.mk({
		"id":"solo_def","name":"独守单位","type":"follower","cost":3,"atk":3,"keywords":[]})
	GameState.bf[0]["eU"].append(solo_defender)
	var tb_before: int = solo_defender.get("tb", {}).get("atk", 0)

	# 模拟 CombatManager 调用触发钩子（AI方为防守方）
	LegendManager.trigger_legend_event("onCombatDefend", "enemy", {"bf_id": 1})

	assert(solo_defender.get("tb", {}).get("atk", 0) == tb_before + 2,
		"独影剑鸣：独守单位 tb.atk 应+2，实际=%d" % solo_defender.get("tb",{}).get("atk",0))
	print("  ✓ 独影剑鸣：独守单位 tb.atk %d→%d（+2）" % [tb_before, solo_defender.get("tb",{}).get("atk",0)])

	# ─────────────────────────────────────────
	# 6.4 无极剑圣「独影剑鸣」— 多于1名防守者时不触发
	# ─────────────────────────────────────────
	print("")
	print("  6.4 无极剑圣「独影剑鸣」（多名防守者不触发）")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.turn  = "player"
	GameState.phase = "action"

	var def_a: Dictionary = GameState.mk({"id":"da","name":"防守者A","type":"follower","cost":2,"atk":2,"keywords":[]})
	var def_b: Dictionary = GameState.mk({"id":"db","name":"防守者B","type":"follower","cost":2,"atk":2,"keywords":[]})
	GameState.bf[0]["eU"].append(def_a)
	GameState.bf[0]["eU"].append(def_b)
	var tb_a_before: int = def_a.get("tb", {}).get("atk", 0)

	LegendManager.trigger_legend_event("onCombatDefend", "enemy", {"bf_id": 1})
	assert(def_a.get("tb", {}).get("atk", 0) == tb_a_before, "多名防守者时独影剑鸣不应触发")
	print("  ✓ 2名防守者：独影剑鸣未触发（tb.atk=%d 不变）" % def_a.get("tb",{}).get("atk",0))

	# ─────────────────────────────────────────
	# 6.5 卡莎「虚空感知」主动技能
	# ─────────────────────────────────────────
	print("")
	print("  6.5 卡莎「虚空感知」主动技能")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.turn  = "player"
	GameState.phase = "action"

	# 确认传奇未休眠
	GameState.p_leg["exhausted"] = false
	var blazing_before: int = GameState.get_sch("player", "blazing")

	var activated: bool = LegendManager.activate_legend_ability("player", "kaisa_void_sense")
	assert(activated == true, "虚空感知：应成功激活")
	assert(GameState.p_leg.get("exhausted", false) == true,
		"虚空感知：传奇应进入休眠状态")
	assert(GameState.get_sch("player", "blazing") == blazing_before + 1,
		"虚空感知：炽烈符能应+1，实际=%d" % GameState.get_sch("player","blazing"))
	print("  ✓ 虚空感知：传奇=休眠，炽烈符能 %d→%d" % [blazing_before, GameState.get_sch("player","blazing")])

	# 再次激活应失败（传奇已休眠）
	var activated2: bool = LegendManager.activate_legend_ability("player", "kaisa_void_sense")
	assert(activated2 == false, "虚空感知：传奇已休眠时再次激活应返回 false")
	print("  ✓ 传奇已休眠：重复激活返回 false")

	# ─────────────────────────────────────────
	# 6.6 can_use_legend_ability — 时机检查
	# ─────────────────────────────────────────
	print("")
	print("  6.6 can_use_legend_ability 时机检查")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.turn  = "player"

	# 找到虚空感知技能 dict（从传奇 abilities 数组中取）
	var void_sense_ab: Dictionary = {}
	for ab in GameState.p_leg.get("abilities", []):
		if ab.get("id", "") == "kaisa_void_sense":
			void_sense_ab = ab
			break
	assert(not void_sense_ab.is_empty(), "应能找到 kaisa_void_sense 技能")

	# 非 action 阶段 → false
	GameState.phase = "draw"
	assert(LegendManager.can_use_legend_ability("player", void_sense_ab) == false,
		"非行动阶段应返回 false")
	print("  ✓ 非行动阶段（draw）→ can_use=false")

	# action 阶段 + 传奇未休眠 → true
	GameState.phase = "action"
	GameState.p_leg["exhausted"] = false
	void_sense_ab["used_this_turn"] = false
	assert(LegendManager.can_use_legend_ability("player", void_sense_ab) == true,
		"行动阶段且传奇未休眠应返回 true")
	print("  ✓ 行动阶段 + 未休眠 → can_use=true")

	# ─────────────────────────────────────────
	# 6.7 reset_legend_abilities_for_turn — 重置每回合标记
	# ─────────────────────────────────────────
	print("")
	print("  6.7 reset_legend_abilities_for_turn")
	# 标记虚空感知为已使用
	void_sense_ab["used_this_turn"] = true
	assert(LegendManager.can_use_legend_ability("player", void_sense_ab) == false,
		"已使用技能不应可激活")
	# 重置后应恢复可用
	LegendManager.reset_legend_abilities_for_turn("player")
	assert(void_sense_ab.get("used_this_turn", false) == false,
		"重置后 used_this_turn 应为 false")
	assert(LegendManager.can_use_legend_ability("player", void_sense_ab) == true,
		"重置后技能应恢复可激活")
	print("  ✓ 标记已使用→重置→恢复可用（used_this_turn=false）")

	# ─────────────────────────────────────────
	# 6.8 独影剑鸣 + 完整战斗集成（战斗中实际触发+2）
	# ─────────────────────────────────────────
	print("")
	print("  6.8 独影剑鸣 + 战斗集成（独守单位实际+2战力参与战斗）")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.bf[0]["card"] = {"id":"test_bf","name":"测试战场","type":"battlefield","text":""}

	# 进攻方：4战力（玩家）
	var attacker_4: Dictionary = GameState.mk({
		"id":"atk4","name":"进攻者4战","type":"follower","cost":4,"atk":4,"hp":4,"keywords":[]})
	attacker_4["current_hp"] = 4; attacker_4["current_atk"] = 4
	# 防守方：2战力（AI，易的传奇技能应给+2 → 实际4战力 → 平局）
	var solo_2: Dictionary = GameState.mk({
		"id":"def2","name":"防守者2战","type":"follower","cost":2,"atk":2,"hp":2,"keywords":[]})
	solo_2["current_hp"] = 2; solo_2["current_atk"] = 2
	GameState.bf[0]["pU"].append(attacker_4)
	GameState.bf[0]["eU"].append(solo_2)

	# 触发战斗：独影剑鸣应在伤害前给防守者+2 → 变4战
	# 结果：4 vs 4+2(buff=2)=4 → 进攻者4HP受4伤=0 / 防守者2HP受4伤（被摧毁）
	# 注意：独影剑鸣给的是 tb.atk=+2（临时），get_atk()=2+2=4
	# 进攻方4 vs 防守方(2+2)=4 → 双方均死 → ctrl=null
	await CombatManager.trigger_combat(1, "player")
	assert(GameState.bf[0]["ctrl"] == null,
		"独影剑鸣+战斗：4 vs (2+2)=4 双方全灭，ctrl 应为 null，实际=%s" % str(GameState.bf[0]["ctrl"]))
	print("  ✓ 独影剑鸣+战斗集成：进攻4战 vs 防守2战(+2)=4战 → 双方全灭，ctrl=null")

	print("")
	print("── 阶段六测试全部通过 ──")


# ───────────────────────────────────────────────
# 阶段七测试：关键词引擎（KeywordManager）
# ───────────────────────────────────────────────
func _test_phase7() -> void:
	print("")
	print("── 阶段七测试：关键词引擎 ──")
	PromptManager.auto_mode = true

	# ─────────────────────────────────────────
	# 7.1 迅捷/反应 时机检查
	# ─────────────────────────────────────────
	print("")
	print("  7.1 迅捷/反应时机检查")
	var fast_card: Dictionary = {"id": "tc_fast", "name": "迅捷牌", "type": "spell",
		"cost": 1, "keywords": ["迅捷"], "text": ""}
	var react_card: Dictionary = {"id": "tc_react", "name": "反应牌", "type": "spell",
		"cost": 1, "keywords": ["反应"], "text": ""}
	var normal_card: Dictionary = {"id": "tc_normal", "name": "普通牌", "type": "spell",
		"cost": 1, "keywords": [], "text": ""}

	# 普通牌：只能在 normal_action
	assert(KeywordManager.can_play_in_timing(normal_card, "normal_action") == true)
	assert(KeywordManager.can_play_in_timing(normal_card, "duel") == false)
	assert(KeywordManager.can_play_in_timing(normal_card, "time_point") == false)
	# 迅捷：normal_action + duel，但非 time_point
	assert(KeywordManager.can_play_in_timing(fast_card, "normal_action") == true)
	assert(KeywordManager.can_play_in_timing(fast_card, "duel") == true)
	assert(KeywordManager.can_play_in_timing(fast_card, "time_point") == false)
	# 反应：所有时机均可
	assert(KeywordManager.can_play_in_timing(react_card, "normal_action") == true)
	assert(KeywordManager.can_play_in_timing(react_card, "duel") == true)
	assert(KeywordManager.can_play_in_timing(react_card, "time_point") == true)
	assert(KeywordManager.can_play_in_timing(react_card, "closed") == true)
	print("  ✓ 迅捷: normal+duel=true, time_point=false")
	print("  ✓ 反应: normal+duel+time_point+closed=true")
	print("  ✓ 普通: 仅 normal_action=true")

	# ─────────────────────────────────────────
	# 7.2 急速 — 额外费用检查与扣除
	# ─────────────────────────────────────────
	print("")
	print("  7.2 急速（额外费用进场）")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.turn  = "player"
	GameState.phase = "action"
	GameState.p_leg = {}; GameState.e_leg = {}

	var haste_unit: Dictionary = GameState.mk({
		"id": "haste_test", "name": "急速测试", "type": "follower",
		"cost": 2, "atk": 2, "hp": 2, "keywords": ["急速"], "text": "", "img": ""})

	# ① 同步检查：法力不足时不可支付
	GameState.p_mana = 0
	assert(KeywordManager.can_pay_haste(haste_unit, "player") == false,
		"急速：法力为0时不应可支付")
	# ② 同步检查：法力充足时可支付
	GameState.p_mana = 3
	assert(KeywordManager.can_pay_haste(haste_unit, "player") == true,
		"急速：法力充足时应可支付")
	print("  ✓ 急速 can_pay_haste：法力不足→false，充足→true")

	# ③ 异步执行：使用 AI(enemy) 路径，不走 PromptManager（AI 路径无弹窗）
	var haste_unit_ai: Dictionary = GameState.mk({
		"id": "haste_ai", "name": "急速AI测试", "type": "follower",
		"cost": 2, "atk": 2, "hp": 2, "keywords": ["急速"], "text": "", "img": ""})
	GameState.e_mana = 2
	haste_unit_ai["exhausted"] = true
	var paid_ai: bool = await KeywordManager.apply_haste(haste_unit_ai, "enemy")
	assert(paid_ai == true, "急速(AI)：能支付时应返回 true")
	assert(haste_unit_ai.get("exhausted", true) == false, "急速(AI)：单位应为活跃状态")
	assert(GameState.e_mana == 1, "急速(AI)：法力应减1，实际=%d" % GameState.e_mana)
	print("  ✓ 急速 apply_haste(AI)：支付→活跃进场，法力-1")

	# ─────────────────────────────────────────
	# 7.3 法盾 — 目标费用计算与强制扣除
	# ─────────────────────────────────────────
	print("")
	print("  7.3 法盾（施法额外符能费用）")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.p_leg = {}; GameState.e_leg = {}

	var shield_unit: Dictionary = GameState.mk({
		"id": "shield_test", "name": "法盾单位", "type": "follower",
		"cost": 2, "atk": 2, "hp": 2, "keywords": ["法盾"], "text": "", "img": ""})
	var shield2_unit: Dictionary = GameState.mk({
		"id": "shield2_test", "name": "法盾2单位", "type": "follower",
		"cost": 2, "atk": 2, "hp": 2, "keywords": ["法盾2"], "text": "", "img": ""})
	var no_shield: Dictionary = GameState.mk({
		"id": "noshield_test", "name": "无法盾", "type": "follower",
		"cost": 2, "atk": 2, "hp": 2, "keywords": [], "text": "", "img": ""})

	assert(KeywordManager.get_spellshield_cost(shield_unit) == 1, "法盾：应返回1")
	assert(KeywordManager.get_spellshield_cost(shield2_unit) == 2, "法盾2：应返回2")
	assert(KeywordManager.get_spellshield_cost(no_shield) == 0, "无法盾：应返回0")

	# 符能充足时可以强制扣除
	GameState.add_sch("player", "blazing", 3)
	var sch_before: int = GameState.get_sch("player")
	var ok: bool = KeywordManager.enforce_spellshield(shield_unit, "player")
	assert(ok == true, "法盾：符能充足时应返回 true")
	assert(GameState.get_sch("player") == sch_before - 1, "法盾：应扣1点符能")

	# 符能不足时无法指定
	GameState.reset_sch("player")
	var blocked: bool = KeywordManager.enforce_spellshield(shield_unit, "player")
	assert(blocked == false, "法盾：符能不足时应返回 false")
	print("  ✓ 法盾：get_cost=1/2/0，充足→扣除，不足→阻止")

	# ─────────────────────────────────────────
	# 7.4 游走 — can_roam 检查
	# ─────────────────────────────────────────
	print("")
	print("  7.4 游走（can_roam）")
	var roam_unit: Dictionary = GameState.mk({
		"id": "roam_test", "name": "游走单位", "type": "follower",
		"cost": 2, "atk": 2, "hp": 2, "keywords": ["游走"], "text": "", "img": ""})
	var no_roam: Dictionary = GameState.mk({
		"id": "noroam_test", "name": "无游走", "type": "follower",
		"cost": 2, "atk": 2, "hp": 2, "keywords": [], "text": "", "img": ""})

	assert(KeywordManager.can_roam(roam_unit) == true, "游走：有游走关键词应返回 true")
	assert(KeywordManager.can_roam(no_roam) == false, "游走：无游走关键词应返回 false")
	print("  ✓ 游走：has_keyword=true→true，无→false")

	# ─────────────────────────────────────────
	# 7.5 鼓舞 — is_inspire_active 检查
	# ─────────────────────────────────────────
	print("")
	print("  7.5 鼓舞（is_inspire_active）")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.p_leg = {}; GameState.e_leg = {}

	GameState.cards_played_this_turn = 0
	assert(KeywordManager.is_inspire_active("player") == false,
		"鼓舞：未出牌时应返回 false")
	GameState.cards_played_this_turn = 1
	assert(KeywordManager.is_inspire_active("player") == true,
		"鼓舞：已出1张牌应返回 true")
	GameState.cards_played_this_turn = 3
	assert(KeywordManager.is_inspire_active("player") == true,
		"鼓舞：已出多张牌应返回 true")
	print("  ✓ 鼓舞：cards_played=0→false，≥1→true")

	# ─────────────────────────────────────────
	# 7.6 瞬息 — 开始阶段摧毁
	# ─────────────────────────────────────────
	print("")
	print("  7.6 瞬息（check_ephemeral）")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.p_leg = {}; GameState.e_leg = {}
	GameState.turn = "player"

	var ephemeral_unit: Dictionary = GameState.mk({
		"id": "eph_test", "name": "瞬息单位", "type": "follower",
		"cost": 2, "atk": 2, "hp": 2, "keywords": ["瞬息"], "text": "", "img": ""})
	var permanent_unit: Dictionary = GameState.mk({
		"id": "perm_test", "name": "常驻单位", "type": "follower",
		"cost": 2, "atk": 2, "hp": 2, "keywords": [], "text": "", "img": ""})

	# 瞬息放基地，常驻放战场
	GameState.p_base.append(ephemeral_unit)
	GameState.bf[0]["pU"].append(permanent_unit)

	var discard_before: int = GameState.p_discard.size()
	KeywordManager.check_ephemeral("player")

	assert(not GameState.p_base.any(func(u): return u["uid"] == ephemeral_unit["uid"]),
		"瞬息：基地中的瞬息单位应被移除")
	assert(GameState.p_discard.any(func(u): return u["uid"] == ephemeral_unit["uid"]),
		"瞬息：瞬息单位应进入废牌堆")
	assert(GameState.bf[0]["pU"].any(func(u): return u["uid"] == permanent_unit["uid"]),
		"瞬息：常驻单位不应受影响")
	assert(GameState.p_discard.size() == discard_before + 1, "瞬息：废牌堆应+1")
	print("  ✓ 瞬息：基地瞬息单位→废牌堆；常驻单位不受影响")

	# ─────────────────────────────────────────
	# 7.7 预知 — 入场关键词触发
	# ─────────────────────────────────────────
	print("")
	print("  7.7 预知（apply_foresight_keyword）")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.p_leg = {}; GameState.e_leg = {}

	# 确保牌库有至少1张牌
	assert(GameState.p_deck.size() > 0, "预知测试：牌库不应为空")
	var deck_top_name: String = GameState.p_deck[GameState.p_deck.size() - 1].get("name", "?")
	var deck_before: int = GameState.p_deck.size()

	# auto_mode=true → PromptManager.ask(confirm) 返回 false（不回收）
	var foresight_unit: Dictionary = GameState.mk({
		"id": "foresight_test", "name": "预知单位", "type": "follower",
		"cost": 2, "atk": 2, "hp": 2, "keywords": ["预知"], "text": "", "img": ""})

	await KeywordManager.apply_foresight_keyword(foresight_unit, "player")
	# auto_mode 下不回收 → 牌库顶不变
	assert(GameState.p_deck.size() == deck_before, "预知：牌库大小不应改变")
	assert(GameState.p_deck[GameState.p_deck.size() - 1].get("name", "?") == deck_top_name,
		"预知：auto_mode(不回收)时牌库顶不变")
	print("  ✓ 预知：auto_mode→不回收，牌库顶=%s，大小不变" % deck_top_name)

	# ─────────────────────────────────────────
	# 7.8 待命 — 部署与打出
	# ─────────────────────────────────────────
	print("")
	print("  7.8 待命（deploy_standby / play_from_standby）")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.p_leg = {}; GameState.e_leg = {}
	GameState.turn  = "player"
	GameState.phase = "action"
	GameState.p_mana = 5

	# 玩家控制战场1
	GameState.bf[0]["ctrl"] = "player"

	var standby_card: Dictionary = {
		"id": "standby_test", "name": "待命测试牌", "type": "follower",
		"cost": 3, "atk": 3, "hp": 3, "keywords": ["待命"], "text": "", "img": ""}

	# 战场1无待命牌时可部署
	assert(KeywordManager.can_deploy_standby(standby_card, 1, "player") == true,
		"待命：控制战场且无待命牌时应可部署")
	var mana_before_standby: int = GameState.p_mana
	var deployed: bool = KeywordManager.deploy_standby(standby_card, 1, "player")
	assert(deployed == true, "待命：deploy_standby 应返回 true")
	assert(GameState.p_mana == mana_before_standby - 1, "待命：部署消耗1法力")
	assert(GameState.bf[0].get("standby", null) != null, "待命：战场待命槽应不为空")
	assert(GameState.bf[0]["standby"]["owner"] == "player", "待命：owner 应为 player")

	# 同一战场重复部署应失败
	assert(KeywordManager.can_deploy_standby(standby_card, 1, "player") == false,
		"待命：已有待命牌时不可重复部署")

	# 当前回合不可打出（同回合部署）
	assert(KeywordManager.can_play_from_standby(1, "player") == false,
		"待命：当前回合不可打出")

	# 下一回合可打出（推进 round）
	GameState.round += 1
	assert(KeywordManager.can_play_from_standby(1, "player") == true,
		"待命：下一回合应可打出")

	# 打出待命牌
	var played_card: Dictionary = KeywordManager.play_from_standby(1, "player")
	assert(not played_card.is_empty(), "待命：play_from_standby 应返回卡牌")
	assert(played_card.get("id", "") == "standby_test", "待命：应返回部署的卡牌")
	assert(GameState.bf[0].get("standby", null) == null, "待命：打出后待命槽应清空")
	print("  ✓ 待命：deploy(扣法力+填槽)，同回合不可出，下回合可出，play_from_standby清空槽")

	print("")
	print("── 阶段七测试全部通过 ──")


# ═══════════════════════════════════════════════
# Phase 8 — AI 决策系统测试
# ═══════════════════════════════════════════════
func _test_phase8() -> void:
	print("")
	print("── 阶段八测试：AIManager 决策系统 ──")
	PromptManager.auto_mode = true

	# ─────────────────────────────────────────
	# 8.1 ai_card_value — 卡牌价值评分
	# ─────────────────────────────────────────
	print("")
	print("  8.1 ai_card_value 评分")
	var unit_2_1: Dictionary = {"id": "t1", "name": "2费1攻", "type": "follower",
		"cost": 2, "atk": 1, "keywords": []}
	var unit_2_2: Dictionary = {"id": "t2", "name": "2费2攻", "type": "follower",
		"cost": 2, "atk": 2, "keywords": []}
	var unit_haste: Dictionary = {"id": "t3", "name": "2费2攻急速", "type": "follower",
		"cost": 2, "atk": 2, "keywords": ["急速"]}
	var unit_barrier: Dictionary = {"id": "t4", "name": "2费2攻壁垒", "type": "follower",
		"cost": 2, "atk": 2, "keywords": ["壁垒"]}

	var v1: float = AIManager.ai_card_value(unit_2_1)
	var v2: float = AIManager.ai_card_value(unit_2_2)
	var v3: float = AIManager.ai_card_value(unit_haste)
	var v4: float = AIManager.ai_card_value(unit_barrier)
	assert(v2 > v1, "2攻应比1攻分高")
	assert(v3 > v2, "急速应加分")
	assert(v4 > v2, "壁垒应加分")
	assert(v3 > v4, "急速(+4)应比壁垒(+3)分高")
	print("  ✓ ai_card_value：高攻>低攻，急速>壁垒>无关键词")

	# ─────────────────────────────────────────
	# 8.2 _ai_min_reactive_cost — 反应牌最低费用
	# ─────────────────────────────────────────
	print("")
	print("  8.2 _ai_min_reactive_cost")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.p_leg = {}; GameState.e_leg = {}

	# 手牌为空时应返回0
	GameState.e_hand.clear()
	assert(AIManager._ai_min_reactive_cost() == 0, "空手牌：反应牌最低费用应为0")

	# 加入2张反应牌（费用不同）
	GameState.e_hand.append({"id": "r1", "name": "反应1", "type": "spell",
		"cost": 3, "keywords": ["反应"], "effect": ""})
	GameState.e_hand.append({"id": "r2", "name": "反应2", "type": "spell",
		"cost": 1, "keywords": ["反应"], "effect": ""})
	GameState.e_hand.append({"id": "n1", "name": "普通", "type": "spell",
		"cost": 2, "keywords": [], "effect": ""})
	assert(AIManager._ai_min_reactive_cost() == 1, "最低反应牌费用应为1")
	print("  ✓ _ai_min_reactive_cost：空→0，有反应牌→最低费用")

	# ─────────────────────────────────────────
	# 8.3 _ai_eval_battlefield — 战场评估
	# ─────────────────────────────────────────
	print("")
	print("  8.3 _ai_eval_battlefield 战场评估")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.p_leg = {}; GameState.e_leg = {}

	# 放置单位到战场
	var ai_unit: Dictionary = GameState.mk({
		"id": "ai_u", "name": "AI单位", "type": "follower",
		"cost": 2, "atk": 3, "hp": 3, "keywords": [], "text": "", "img": ""})
	var pl_unit: Dictionary = GameState.mk({
		"id": "pl_u", "name": "玩家单位", "type": "follower",
		"cost": 2, "atk": 2, "hp": 2, "keywords": [], "text": "", "img": ""})
	GameState.bf[0]["eU"].append(ai_unit)
	GameState.bf[0]["pU"].append(pl_unit)

	var ev: Dictionary = AIManager._ai_eval_battlefield(0)
	assert(ev.get("my_pow") == 3, "AI战力应为3，实际=%d" % ev.get("my_pow",0))
	assert(ev.get("their_pow") == 2, "玩家战力应为2，实际=%d" % ev.get("their_pow",0))
	assert(ev.get("my_count") == 1, "AI单位数应为1")
	assert(ev.get("their_count") == 1, "玩家单位数应为1")
	print("  ✓ _ai_eval_battlefield：my_pow=3, their_pow=2, count各1")

	# ─────────────────────────────────────────
	# 8.4 _ai_simulate_combat — 模拟战斗
	# ─────────────────────────────────────────
	print("")
	print("  8.4 _ai_simulate_combat 战斗模拟")
	# 战场0：AI单位(3) vs 玩家单位(2) → AI胜
	var mover: Dictionary = GameState.mk({
		"id": "mv", "name": "移动单位", "type": "follower",
		"cost": 1, "atk": 2, "hp": 2, "keywords": [], "text": "", "img": ""})
	var sim_win: Dictionary = AIManager._ai_simulate_combat([mover], 0)
	# AI战场已有3力，加上移动单位2力=5 > 玩家2力
	assert(sim_win.get("will_win") == true, "模拟：AI总力5>玩家2应为必胜，实际will_win=%s" % sim_win.get("will_win"))
	assert(sim_win.get("margin") == 3, "模拟：优势差应为3，实际=%d" % sim_win.get("margin",0))

	# 战场1（空）：移动1个1力单位 vs 无人防守 → 胜
	var weak_mover: Dictionary = GameState.mk({
		"id": "wm", "name": "弱单位", "type": "follower",
		"cost": 1, "atk": 1, "hp": 1, "keywords": [], "text": "", "img": ""})
	var sim_empty: Dictionary = AIManager._ai_simulate_combat([weak_mover], 1)
	assert(sim_empty.get("will_win") == true, "模拟：攻空战场应为胜利")
	print("  ✓ _ai_simulate_combat：有敌方→正确计算，空战场→胜利")

	# ─────────────────────────────────────────
	# 8.5 _ai_spell_priority — 法术优先级
	# ─────────────────────────────────────────
	print("")
	print("  8.5 _ai_spell_priority 法术优先级")
	var sp_rally: Dictionary = {"id": "rc", "name": "迎敌号令", "effect": "rally_call", "keywords": []}
	var sp_stun: Dictionary  = {"id": "st", "name": "眩晕", "effect": "stun_manual", "keywords": []}
	var sp_buff1: Dictionary = {"id": "b1", "name": "增强1", "effect": "buff1_solo", "keywords": []}
	var sp_other: Dictionary = {"id": "ot", "name": "其他", "effect": "draw1", "keywords": []}

	assert(AIManager._ai_spell_priority(sp_rally) == 100, "rally_call 应为100")
	assert(AIManager._ai_spell_priority(sp_stun)  == 80,  "stun_manual 应为80")
	assert(AIManager._ai_spell_priority(sp_buff1) == 60,  "buff1_solo 应为60")
	assert(AIManager._ai_spell_priority(sp_other) == 50,  "其他应为50")
	assert(AIManager._ai_spell_priority(sp_rally) > AIManager._ai_spell_priority(sp_stun),
		"迎敌号令优先级应高于眩晕")
	print("  ✓ _ai_spell_priority：rally=100 > stun=80 > buff1=60 > other=50")

	# ─────────────────────────────────────────
	# 8.6 _ai_should_play_spell — 法术行动阶段过滤
	# ─────────────────────────────────────────
	print("")
	print("  8.6 _ai_should_play_spell 法术过滤")
	var sp_react: Dictionary   = {"id": "rsp", "name": "反应法术", "type": "spell",
		"effect": "buff1_solo", "keywords": ["反应"]}
	var sp_fast: Dictionary    = {"id": "fsp", "name": "迅捷法术", "type": "spell",
		"effect": "buff1_solo", "keywords": ["迅捷"]}
	var sp_counter: Dictionary = {"id": "cnt", "name": "反制", "type": "spell",
		"effect": "counter_cost4", "keywords": []}
	var sp_normal: Dictionary  = {"id": "nsp", "name": "普通法术", "type": "spell",
		"effect": "draw1", "keywords": []}

	assert(AIManager._ai_should_play_spell(sp_react)   == false, "反应法术应被过滤")
	assert(AIManager._ai_should_play_spell(sp_fast)    == false, "迅捷法术应被过滤")
	assert(AIManager._ai_should_play_spell(sp_counter) == false, "反制法术应被过滤")
	assert(AIManager._ai_should_play_spell(sp_normal)  == true,  "普通法术应通过")
	print("  ✓ _ai_should_play_spell：反应/迅捷/反制→过滤，普通→通过")

	# ─────────────────────────────────────────
	# 8.7 _ai_decide_movement — 移动决策
	# ─────────────────────────────────────────
	print("")
	print("  8.7 _ai_decide_movement 移动决策")
	GameState.reset_state()
	GameState.start_game("kaisa", "masteryi")
	GameState.p_leg = {}; GameState.e_leg = {}

	# 给 AI 基地一个活跃单位
	var mover2: Dictionary = GameState.mk({
		"id": "mv2", "name": "移动者", "type": "follower",
		"cost": 2, "atk": 3, "hp": 3, "keywords": [], "text": "", "img": ""})
	mover2["exhausted"] = false
	GameState.e_base.append(mover2)

	# 两个战场均为空且未被控制
	GameState.bf[0]["ctrl"] = null
	GameState.bf[1]["ctrl"] = null
	GameState.bf[0]["pU"].clear(); GameState.bf[0]["eU"].clear()
	GameState.bf[1]["pU"].clear(); GameState.bf[1]["eU"].clear()

	var active: Array = GameState.e_base.filter(func(u): return not u.get("exhausted", false))
	var plan: Dictionary = AIManager._ai_decide_movement(active)
	assert(not plan.is_empty(), "有活跃单位+空战场：应产生移动计划")
	assert(plan.has("movers"), "移动计划应包含 movers 字段")
	assert(plan.has("target_bf_id"), "移动计划应包含 target_bf_id 字段")
	assert(plan["movers"].size() > 0, "movers 不应为空")
	print("  ✓ _ai_decide_movement：空战场+活跃单位→产生移动计划（bf_id=%d）" % plan.get("target_bf_id",0))

	# 无活跃单位时应返回空计划
	var empty_plan: Dictionary = AIManager._ai_decide_movement([])
	assert(empty_plan.is_empty(), "无活跃单位：应返回空计划")
	print("  ✓ _ai_decide_movement：无活跃单位→空计划")

	# ─────────────────────────────────────────
	# 8.8 AI 完整回合执行（不崩溃验证）
	# ─────────────────────────────────────────
	print("")
	print("  8.8 AI 完整回合执行（enemy turn）")
	# 注意：前面的 start_game 调用会在后台启动异步阶段管线（定时器约 1.0s 后触发
	#       _do_draw → e_mana = 0），若 ai_action 有 0.4s 延迟则会被干扰。
	# 解决：测试时把 AI_THINK_DELAY 设为 0，让 ai_action 在后台定时器触发前跑完。
	AIManager.AI_THINK_DELAY = 0.0

	GameState.reset_state()
	# 不调用 start_game（避免再启动新的后台管线）
	# 手动初始化本测试所需的最小状态
	GameState.turn  = "enemy"
	GameState.phase = "action"
	GameState.win_score = 8

	# 给 AI 准备 5 点法力和 1 张手牌
	GameState.e_mana = 5
	GameState.e_hand.clear()
	# 用 mk 创建手牌实例（mk 会分配 uid，供 play_card 定位）
	var ai_card_tmpl: Dictionary = GameState.mk({
		"id": "ai_unit_test", "name": "AI测试单位", "type": "follower",
		"cost": 2, "atk": 2, "hp": 2, "keywords": [], "text": "", "img": "",
		"sch_cost": 0, "sch_type": "", "sch_cost2": 0, "sch_type2": ""})
	GameState.e_hand.append(ai_card_tmpl)

	# 直接调用 ai_action()（不走信号，直接测试函数本身）
	await AIManager.ai_action()

	# 恢复 AI 思考延迟（不影响后续运行）
	AIManager.AI_THINK_DELAY = 0.4

	# 验证不崩溃 + 出牌结果
	assert(GameState.e_hand.size() == 0,
		"AI完整回合：手牌应已全部出完（实际=%d）" % GameState.e_hand.size())
	assert(GameState.e_base.size() >= 1,
		"AI完整回合：基地应有单位（实际=%d）" % GameState.e_base.size())
	# do_end_phase 已被调用：法力归零
	assert(GameState.e_mana == 0,
		"AI完整回合：do_end_phase 后法力应为0（实际=%d）" % GameState.e_mana)
	print("  ✓ AI完整回合：出牌成功（手牌=0，基地单位≥1，法力归零）")

	print("")
	print("── 阶段八测试全部通过 ──")
