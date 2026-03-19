extends Node
# ═══════════════════════════════════════════════
# CardDatabase.gd — 卡牌数据库 (Autoload 单例)
# 对应 cards.js + engine.js RUNE_DEFS
# 所有卡牌数据以 Dictionary 数组形式存储，与原 JS 结构一一对应
# 图片路径已转换为 res://assets/ 格式
# ═══════════════════════════════════════════════

# ── 符文类型定义（对应 engine.js RUNE_DEFS）──
const RUNE_DEFS: Dictionary = {
	"blazing":  { "id": "blazing",  "name": "炽烈符文", "sch_name": "炽烈", "deck": "void",   "img": "res://assets/runes/OGN-007.png"   },
	"radiant":  { "id": "radiant",  "name": "灵光符文", "sch_name": "灵光", "deck": "void",   "img": "res://assets/runes/OGN-089.png"   },
	"verdant":  { "id": "verdant",  "name": "翠意符文", "sch_name": "翠意", "deck": "ionia",  "img": "res://assets/runes/OGN-042a.png"  },
	"crushing": { "id": "crushing", "name": "摧破符文", "sch_name": "摧破", "deck": "ionia",  "img": "res://assets/runes/OGN-126a.png"  },
	"chaos":    { "id": "chaos",    "name": "混沌符文", "sch_name": "混沌", "deck": "shadow", "img": ""                                  },
	"order":    { "id": "order",    "name": "序理符文", "sch_name": "序理", "deck": "order",  "img": ""                                  },
}

# ── 战场牌库（对应 cards.js BATTLEFIELDS，共 19 张）──
const BATTLEFIELDS: Array = [
	{ "id": "altar_unity",       "name": "团结祭坛",     "type": "battlefield", "text": "【据守】：在你的基地中召唤一个1/1的新兵。",                                                                            "img": "" },
	{ "id": "aspirant_climb",    "name": "试炼者之阶",   "type": "battlefield", "text": "【据守】：你可以支付[1]法力，给基地的一名单位+1战力。",                                                                "img": "" },
	{ "id": "back_alley_bar",    "name": "暗巷酒吧",     "type": "battlefield", "text": "【被动】：己方单位移动离开此处时，本回合获得+1战力。",                                                                "img": "" },
	{ "id": "bandle_tree",       "name": "班德尔城神树", "type": "battlefield", "text": "【据守】：若你场上的单位包含≥3种符能特性，获得1点任意符能。",                                                        "img": "" },
	{ "id": "hirana",            "name": "希拉娜修道院", "type": "battlefield", "text": "【征服】：你可以消耗己方单位的1个增益指示物，抽1张牌。",                                                              "img": "" },
	{ "id": "reaver_row",        "name": "掠夺者之街",   "type": "battlefield", "text": "【征服】：你可以将自己废牌堆中1名费用≤2的单位，以休眠状态召唤至基地。",                                              "img": "" },
	{ "id": "reckoner_arena",    "name": "清算人竞技场", "type": "battlefield", "text": "【被动】：法术对决开始时，此处的【强力】单位(战力≥5)获得【强攻[1]】(进攻方)或【坚守[1]】(防守方)。",              "img": "" },
	{ "id": "dreaming_tree",     "name": "梦幻树",       "type": "battlefield", "text": "【触发】：每回合首次对此处友方单位施放法术时，你抽1张牌。",                                                          "img": "" },
	{ "id": "vile_throat_nest",  "name": "卑鄙之喉的巢穴","type": "battlefield","text": "【限制】：此处的单位无法移动到基地。",                                                                                "img": "" },
	{ "id": "rockfall_path",     "name": "落岩之径",     "type": "battlefield", "text": "【限制】：玩家从手牌打出单位时，不能将此处选为目标区域（只能通过移动进入）。",                                        "img": "" },
	{ "id": "sunken_temple",     "name": "沉没神庙",     "type": "battlefield", "text": "【防守失败】：若你未能成功防守此处，可支付[2]法力抽1张牌。",                                                          "img": "" },
	{ "id": "trifarian_warcamp", "name": "崔法利战营",   "type": "battlefield", "text": "【被动】：你的单位移动进入此处时，立即获得一个增益指示物(+1战力)。",                                                  "img": "" },
	{ "id": "void_gate",         "name": "虚空之门",     "type": "battlefield", "text": "【被动】：此处单位受到法术或技能伤害时，额外受1点伤害。",                                                              "img": "res://assets/cards/ksha/OGN-296.jpg" },
	{ "id": "zaun_undercity",    "name": "祖安地沟",     "type": "battlefield", "text": "【征服】：你可以弃置1张手牌，然后抽1张牌。",                                                                          "img": "" },
	{ "id": "strength_obelisk",  "name": "力量方尖碑",   "type": "battlefield", "text": "每名玩家在各自的第一个回合开始阶段，额外召出一枚符文。",                                      "img": "res://assets/cards/ksha/OGN-284.png" },
	{ "id": "star_peak",         "name": "星尖峰",       "type": "battlefield", "text": "【据守】：你可以选择召出一枚休眠的符文。",                                                                            "img": "res://assets/cards/ksha/OGN-288.png" },
	{ "id": "thunder_rune",      "name": "雷霆之纹",     "type": "battlefield", "text": "【征服】：回收你的一张符文（从场上取回到符文牌库顶）。",                                                              "img": "res://assets/cards/jiansheng/OGN-287.jpg" },
	{ "id": "ascending_stairs",  "name": "攀圣长阶",     "type": "battlefield", "text": "【据守】：使赢得游戏所需的分数上限+1（全局永久）。",                                                                  "img": "res://assets/cards/jiansheng/OGN-276.jpg" },
	{ "id": "forgotten_monument","name": "遗忘丰碑",     "type": "battlefield", "text": "【被动】：各玩家在各自第三回合开始前，无法从此处获得据守分。",                                                        "img": "res://assets/cards/jiansheng/14eff213c1f8d04fcb765333549b834c.png" },
]

# ── 卡莎（虚空）牌组 40 张（对应 cards.js KAISA_MAIN）──
# 注意：数组含重复项，重复即为牌组中的多张副本，与 JS 原版完全一致
const KAISA_MAIN: Array = [
	# ── 单位 19 张 ──
	{ "id": "noxus_recruit",    "name": "诺克萨斯新兵",  "region": "noxus",  "type": "follower", "cost": 4, "atk": 4, "hp": 3, "keywords": ["鼓舞"],          "text": "鼓舞：其他盟友入场时，手牌中此牌费用-1（最低0）。",                                                                                "img": "res://assets/cards/ksha/OGN-012.png",                            "effect": "",                   "sch_cost": 0, "sch_type": "" },
	{ "id": "noxus_recruit",    "name": "诺克萨斯新兵",  "region": "noxus",  "type": "follower", "cost": 4, "atk": 4, "hp": 3, "keywords": ["鼓舞"],          "text": "鼓舞：其他盟友入场时，手牌中此牌费用-1（最低0）。",                                                                                "img": "res://assets/cards/ksha/OGN-012.png",                            "effect": "",                   "sch_cost": 0, "sch_type": "" },
	{ "id": "alert_sentinel",   "name": "警觉的哨兵",    "region": "void",   "type": "follower", "cost": 2, "atk": 2, "hp": 1, "keywords": ["绝念"],          "text": "绝念：阵亡时抽1张牌。",                                                                                                              "img": "res://assets/cards/ksha/OGN-096.png",                            "effect": "alert_sentinel_die", "sch_cost": 0, "sch_type": "" },
	{ "id": "alert_sentinel",   "name": "警觉的哨兵",    "region": "void",   "type": "follower", "cost": 2, "atk": 2, "hp": 1, "keywords": ["绝念"],          "text": "绝念：阵亡时抽1张牌。",                                                                                                              "img": "res://assets/cards/ksha/OGN-096.png",                            "effect": "alert_sentinel_die", "sch_cost": 0, "sch_type": "" },
	{ "id": "alert_sentinel",   "name": "警觉的哨兵",    "region": "void",   "type": "follower", "cost": 2, "atk": 2, "hp": 1, "keywords": ["绝念"],          "text": "绝念：阵亡时抽1张牌。",                                                                                                              "img": "res://assets/cards/ksha/OGN-096.png",                            "effect": "alert_sentinel_die", "sch_cost": 0, "sch_type": "" },
	{ "id": "yordel_instructor","name": "约德尔教官",    "region": "bandle", "type": "follower", "cost": 3, "atk": 2, "hp": 2, "keywords": ["壁垒"],          "text": "壁垒（抵挡一次卡牌直接伤害）。入场：抽1张牌。",                                                                                    "img": "res://assets/cards/ksha/63ed0654ba38d470c09a5588e9acfd7d.png",   "effect": "yordel_instructor_enter", "sch_cost": 0, "sch_type": "" },
	{ "id": "yordel_instructor","name": "约德尔教官",    "region": "bandle", "type": "follower", "cost": 3, "atk": 2, "hp": 2, "keywords": ["壁垒"],          "text": "壁垒（抵挡一次卡牌直接伤害）。入场：抽1张牌。",                                                                                    "img": "res://assets/cards/ksha/63ed0654ba38d470c09a5588e9acfd7d.png",   "effect": "yordel_instructor_enter", "sch_cost": 0, "sch_type": "" },
	{ "id": "yordel_instructor","name": "约德尔教官",    "region": "bandle", "type": "follower", "cost": 3, "atk": 2, "hp": 2, "keywords": ["壁垒"],          "text": "壁垒（抵挡一次卡牌直接伤害）。入场：抽1张牌。",                                                                                    "img": "res://assets/cards/ksha/63ed0654ba38d470c09a5588e9acfd7d.png",   "effect": "yordel_instructor_enter", "sch_cost": 0, "sch_type": "" },
	{ "id": "bad_poro",         "name": "坏坏魄罗",      "region": "void",   "type": "follower", "cost": 2, "atk": 2, "hp": 3, "keywords": ["征服"],          "text": "征服：生成1枚休眠状态的【金币】装备指示物。",                                                                                      "img": "res://assets/cards/ksha/cf27269a640f60bca0cd4f9b4c235257.png",   "effect": "bad_poro_conquer",   "sch_cost": 0, "sch_type": "" },
	{ "id": "bad_poro",         "name": "坏坏魄罗",      "region": "void",   "type": "follower", "cost": 2, "atk": 2, "hp": 3, "keywords": ["征服"],          "text": "征服：生成1枚休眠状态的【金币】装备指示物。",                                                                                      "img": "res://assets/cards/ksha/cf27269a640f60bca0cd4f9b4c235257.png",   "effect": "bad_poro_conquer",   "sch_cost": 0, "sch_type": "" },
	{ "id": "rengar",           "name": "雷恩加尔·暴起", "region": "void",   "type": "follower", "cost": 3, "atk": 3, "hp": 3, "keywords": ["反应","强攻"],   "text": "反应。强攻（进攻时战力+2）。需消耗1点炽烈符能打出。",                                                                              "img": "res://assets/cards/ksha/7e82f267463942a42497347255fedcc9.png",   "effect": "",                   "sch_cost": 1, "sch_type": "blazing", "strong_atk_bonus": 2 },
	{ "id": "rengar",           "name": "雷恩加尔·暴起", "region": "void",   "type": "follower", "cost": 3, "atk": 3, "hp": 3, "keywords": ["反应","强攻"],   "text": "反应。强攻（进攻时战力+2）。需消耗1点炽烈符能打出。",                                                                              "img": "res://assets/cards/ksha/7e82f267463942a42497347255fedcc9.png",   "effect": "",                   "sch_cost": 1, "sch_type": "blazing", "strong_atk_bonus": 2 },
	{ "id": "darius",           "name": "德莱厄斯",      "region": "noxus",  "type": "follower", "cost": 5, "atk": 5, "hp": 5, "keywords": [],                "text": "（需1点炽烈符能）。入场：若本回合已出过牌，本回合战力+2，状态重置为Ready。",                                                      "img": "res://assets/cards/ksha/OGN-027a.png",                           "effect": "darius_second_card", "sch_cost": 1, "sch_type": "blazing" },
	{ "id": "darius",           "name": "德莱厄斯",      "region": "noxus",  "type": "follower", "cost": 5, "atk": 5, "hp": 5, "keywords": [],                "text": "（需1点炽烈符能）。入场：若本回合已出过牌，本回合战力+2，状态重置为Ready。",                                                      "img": "res://assets/cards/ksha/OGN-027a.png",                           "effect": "darius_second_card", "sch_cost": 1, "sch_type": "blazing" },
	{ "id": "thousand_tail",    "name": "千尾监视者",    "region": "void",   "type": "follower", "cost": 7, "atk": 7, "hp": 5, "keywords": ["急速"],          "text": "急速。（需1点灵光符能）。入场：所有敌方单位本回合战力-3（最低1）。",                                                              "img": "res://assets/cards/ksha/OGN-116.png",                            "effect": "thousand_tail_enter","sch_cost": 1, "sch_type": "radiant" },
	{ "id": "thousand_tail",    "name": "千尾监视者",    "region": "void",   "type": "follower", "cost": 7, "atk": 7, "hp": 5, "keywords": ["急速"],          "text": "急速。（需1点灵光符能）。入场：所有敌方单位本回合战力-3（最低1）。",                                                              "img": "res://assets/cards/ksha/OGN-116.png",                            "effect": "thousand_tail_enter","sch_cost": 1, "sch_type": "radiant" },
	{ "id": "thousand_tail",    "name": "千尾监视者",    "region": "void",   "type": "follower", "cost": 7, "atk": 7, "hp": 5, "keywords": ["急速"],          "text": "急速。（需1点灵光符能）。入场：所有敌方单位本回合战力-3（最低1）。",                                                              "img": "res://assets/cards/ksha/OGN-116.png",                            "effect": "thousand_tail_enter","sch_cost": 1, "sch_type": "radiant" },
	{ "id": "foresight_mech",   "name": "先见机甲",      "region": "void",   "type": "follower", "cost": 2, "atk": 2, "hp": 3, "keywords": ["预知"],          "text": "预知：入场时查看牌库顶1张牌，可选择回收至牌库底部。",                                                                              "img": "res://assets/cards/ksha/6b3952eb842015548665beedb956616e.png",   "effect": "foresight_mech_enter","sch_cost": 0, "sch_type": "" },
	{ "id": "foresight_mech",   "name": "先见机甲",      "region": "void",   "type": "follower", "cost": 2, "atk": 2, "hp": 3, "keywords": ["预知"],          "text": "预知：入场时查看牌库顶1张牌，可选择回收至牌库底部。",                                                                              "img": "res://assets/cards/ksha/6b3952eb842015548665beedb956616e.png",   "effect": "foresight_mech_enter","sch_cost": 0, "sch_type": "" },
	# ── 法术 21 张 ──
	{ "id": "swindle",          "name": '"敲"诈',        "region": "void",   "type": "spell",    "cost": 1,                   "keywords": ["反应"],          "text": "反应。令1名单位本回合战力-1（最低1），抽1张牌。",                                                                                  "img": "res://assets/cards/ksha/OGN-095.png",                            "effect": "debuff1_draw",       "sch_cost": 0, "sch_type": "" },
	{ "id": "swindle",          "name": '"敲"诈',        "region": "void",   "type": "spell",    "cost": 1,                   "keywords": ["反应"],          "text": "反应。令1名单位本回合战力-1（最低1），抽1张牌。",                                                                                  "img": "res://assets/cards/ksha/OGN-095.png",                            "effect": "debuff1_draw",       "sch_cost": 0, "sch_type": "" },
	{ "id": "swindle",          "name": '"敲"诈',        "region": "void",   "type": "spell",    "cost": 1,                   "keywords": ["反应"],          "text": "反应。令1名单位本回合战力-1（最低1），抽1张牌。",                                                                                  "img": "res://assets/cards/ksha/OGN-095.png",                            "effect": "debuff1_draw",       "sch_cost": 0, "sch_type": "" },
	{ "id": "void_seek",        "name": "虚空索敌",      "region": "void",   "type": "spell",    "cost": 3,                   "keywords": ["迅捷"],          "text": "迅捷（需1点炽烈符能）。对战场上1名单位造成4点伤害，抽1张牌。",                                                                    "img": "res://assets/cards/ksha/OGN-024.jpg",                            "effect": "deal4_draw",         "sch_cost": 1, "sch_type": "blazing" },
	{ "id": "evolve_day",       "name": "进化日",        "region": "void",   "type": "spell",    "cost": 6,                   "keywords": [],                "text": "（需1点灵光符能）。抽4张牌。",                                                                                                      "img": "res://assets/cards/ksha/OGN-114.png",                            "effect": "draw4",              "sch_cost": 1, "sch_type": "radiant" },
	{ "id": "retreat_rune",     "name": "择日再战",      "region": "void",   "type": "spell",    "cost": 1,                   "keywords": ["反应"],          "text": "反应。将1名友方单位返回手牌，然后从符文牌库顶取出1张符文以休眠状态置于场上。",                                                    "img": "res://assets/cards/ksha/OGN-104.png",                            "effect": "recall_unit_rune",   "sch_cost": 0, "sch_type": "" },
	{ "id": "retreat_rune",     "name": "择日再战",      "region": "void",   "type": "spell",    "cost": 1,                   "keywords": ["反应"],          "text": "反应。将1名友方单位返回手牌，然后从符文牌库顶取出1张符文以休眠状态置于场上。",                                                    "img": "res://assets/cards/ksha/OGN-104.png",                            "effect": "recall_unit_rune",   "sch_cost": 0, "sch_type": "" },
	{ "id": "furnace_blast",    "name": "风箱炎息",      "region": "void",   "type": "spell",    "cost": 1,                   "keywords": ["迅捷","回响"],   "text": "迅捷。回响（需1点灵光符能）。对同一位置最多3名单位各造成1点伤害。",                                                              "img": "res://assets/cards/ksha/a4babdeaba1b4f3a28f3df114afad0b8.png",  "effect": "deal1_same_zone",    "sch_cost": 0, "sch_type": "", "echo_sch_cost": 1, "echo_sch_type": "radiant" },
	{ "id": "furnace_blast",    "name": "风箱炎息",      "region": "void",   "type": "spell",    "cost": 1,                   "keywords": ["迅捷","回响"],   "text": "迅捷。回响（需1点灵光符能）。对同一位置最多3名单位各造成1点伤害。",                                                              "img": "res://assets/cards/ksha/a4babdeaba1b4f3a28f3df114afad0b8.png",  "effect": "deal1_same_zone",    "sch_cost": 0, "sch_type": "", "echo_sch_cost": 1, "echo_sch_type": "radiant" },
	{ "id": "guilty_pleasure",  "name": "罪恶快感",      "region": "void",   "type": "spell",    "cost": 2,                   "keywords": ["反应"],          "text": "反应（需1点炽烈符能）。弃置1张手牌，对1名单位造成等同其费用的伤害。",                                                              "img": "res://assets/cards/ksha/OGN-008.png",                            "effect": "discard_deal",       "sch_cost": 1, "sch_type": "blazing" },
	{ "id": "starburst",        "name": "星芒凝汇",      "region": "void",   "type": "spell",    "cost": 6,                   "keywords": [],                "text": "（需2点灵光符能）。对最多2名单位各造成6点伤害。",                                                                                  "img": "res://assets/cards/ksha/OGN-105.png",                            "effect": "deal6_two",          "sch_cost": 2, "sch_type": "radiant" },
	{ "id": "hex_ray",          "name": "海克斯射线",    "region": "void",   "type": "spell",    "cost": 1,                   "keywords": ["迅捷"],          "text": "迅捷（需1点炽烈符能）。对战场上的1名单位造成3点伤害。",                                                                          "img": "res://assets/cards/ksha/OGN-009.png",                            "effect": "deal3",              "sch_cost": 1, "sch_type": "blazing" },
	{ "id": "hex_ray",          "name": "海克斯射线",    "region": "void",   "type": "spell",    "cost": 1,                   "keywords": ["迅捷"],          "text": "迅捷（需1点炽烈符能）。对战场上的1名单位造成3点伤害。",                                                                          "img": "res://assets/cards/ksha/OGN-009.png",                            "effect": "deal3",              "sch_cost": 1, "sch_type": "blazing" },
	{ "id": "time_warp",        "name": "时间扭曲",      "region": "void",   "type": "spell",    "cost": 10,                  "keywords": [],                "text": "（需4点灵光符能）。本回合结束后，你额外进行一个回合。执行后移入放逐区。",                                                          "img": "res://assets/cards/ksha/OGN-122.png",                            "effect": "extra_turn",         "sch_cost": 4, "sch_type": "radiant" },
	{ "id": "time_warp",        "name": "时间扭曲",      "region": "void",   "type": "spell",    "cost": 10,                  "keywords": [],                "text": "（需4点灵光符能）。本回合结束后，你额外进行一个回合。执行后移入放逐区。",                                                          "img": "res://assets/cards/ksha/OGN-122.png",                            "effect": "extra_turn",         "sch_cost": 4, "sch_type": "radiant" },
	{ "id": "stardrop",         "name": "星落",          "region": "void",   "type": "spell",    "cost": 2,                   "keywords": [],                "text": "（需2点炽烈符能）。分2次各对1名单位造成3点伤害（可选同一目标）。",                                                                "img": "res://assets/cards/ksha/OGN-029.png",                            "effect": "deal3_twice",        "sch_cost": 2, "sch_type": "blazing" },
	{ "id": "stardrop",         "name": "星落",          "region": "void",   "type": "spell",    "cost": 2,                   "keywords": [],                "text": "（需2点炽烈符能）。分2次各对1名单位造成3点伤害（可选同一目标）。",                                                                "img": "res://assets/cards/ksha/OGN-029.png",                            "effect": "deal3_twice",        "sch_cost": 2, "sch_type": "blazing" },
	{ "id": "stardrop",         "name": "星落",          "region": "void",   "type": "spell",    "cost": 2,                   "keywords": [],                "text": "（需2点炽烈符能）。分2次各对1名单位造成3点伤害（可选同一目标）。",                                                                "img": "res://assets/cards/ksha/OGN-029.png",                            "effect": "deal3_twice",        "sch_cost": 2, "sch_type": "blazing" },
	{ "id": "smoke_bomb",       "name": "烟幕弹",        "region": "void",   "type": "spell",    "cost": 2,                   "keywords": ["反应"],          "text": "反应。（需1点灵光符能）。令1名单位本回合战力-4（最低1）。",                                                                        "img": "res://assets/cards/ksha/OGN-093.png",                            "effect": "debuff4",            "sch_cost": 1, "sch_type": "radiant" },
	{ "id": "divine_ray",       "name": "透体圣光",      "region": "void",   "type": "spell",    "cost": 2,                   "keywords": ["回响"],          "text": "回响（需2点炽烈符能，可再次施放）。对战场上的1名单位造成2点伤害，然后对最多1名单位造成2点伤害。",                                "img": "res://assets/cards/ksha/6bf1588a987c67803aa7f1837d75bc4b.png",  "effect": "deal2_two",          "sch_cost": 0, "sch_type": "", "echo_sch_cost": 2, "echo_sch_type": "blazing" },
	{ "id": "akasi_storm",      "name": "艾卡西亚暴雨",  "region": "void",   "type": "spell",    "cost": 7,                   "keywords": [],                "text": "（需2点灵光+1点炽烈符能）。进行六次：对一名单位造成2点伤害。",                                                                    "img": "res://assets/cards/ksha/OGN-248.png",                            "effect": "akasi_storm",        "sch_cost": 2, "sch_type": "radiant", "sch_cost2": 1, "sch_type2": "blazing" },
]

# ── 卡莎英雄卡（独立于主牌堆，游戏开始时置于英雄区域）──
# 规则103.2.a：选定英雄游戏开始时置于英雄区域，可按正常规则从此处打出
const KAISA_HERO: Dictionary = {
	"id": "kaisa_hero", "name": "卡莎·九死一生", "region": "void",
	"type": "follower", "cost": 4, "atk": 4, "hp": 4,
	"keywords": ["急速", "征服"],
	"text": "急速。征服：本回合再打出1张牌。需消耗1点炽烈符能打出。",
	"img": "res://assets/cards/ksha/OGN-039.png",
	"effect": "", "sch_cost": 1, "sch_type": "blazing", "hero": true
}

# ── 卡莎传奇（对应 cards.js KAISA_LEGEND）──
const KAISA_LEGEND: Dictionary = {
	"id": "kaisa", "name": "虚空之女（卡莎）", "region": "void", "type": "champion",
	"cost": 5, "atk": 5, "hp": 14, "keywords": ["迅捷攻击"],
	"text": "迅捷攻击。进化：盟友集满4关键词后升级，+3/+3。",
	"img": "res://assets/cards/ksha/OGN-247.png",
	"level": 1,
	"abilities": [
		{ "id": "kaisa_void_sense", "name": "虚空感知", "type": "active", "keywords": ["反应"], "cost": 0, "sch_cost": 0, "exhaust": true, "once": false, "text": "反应 — 休眠自身，获得1点符能（仅限打出法术）。不可被反应法术拦截。", "effect": "kaisa_void_sense" },
		{ "id": "kaisa_evolve",     "name": "进化",     "type": "passive","keywords": [],        "text": "场上盟友拥有4种或以上不同关键词时，升级至等级2并获得+3/+3。", "effect": "evolve" }
	]
}

# ── 伊欧尼亚（易）牌组（对应 cards.js MASTERYI_MAIN）──
const MASTERYI_MAIN: Array = [
	# ── 单位 10 张 ──
	{ "id": "jax",                "name": "贾克斯·万般皆武","region": "ionia",  "type": "follower",  "cost": 5, "atk": 5, "hp": 5, "keywords": ["法盾"],         "text": "法盾。入场：手牌中的装备获得【反应】词条。需消耗1点翠意符能打出。",                                                                "img": "res://assets/cards/jiansheng/e519a7660073c27bdae3b95d442a85b3.png", "effect": "jax_enter", "sch_cost": 1, "sch_type": "verdant" },
	{ "id": "jax",                "name": "贾克斯·万般皆武","region": "ionia",  "type": "follower",  "cost": 5, "atk": 5, "hp": 5, "keywords": ["法盾"],         "text": "法盾。入场：手牌中的装备获得【反应】词条。需消耗1点翠意符能打出。",                                                                "img": "res://assets/cards/jiansheng/e519a7660073c27bdae3b95d442a85b3.png", "effect": "jax_enter", "sch_cost": 1, "sch_type": "verdant" },
	{ "id": "tiyana_warden",      "name": "缇亚娜·冕卫",  "region": "ionia",   "type": "follower",  "cost": 7, "atk": 4, "hp": 5, "keywords": ["法盾"],         "text": "法盾。在场时对手无法获得据守分。需消耗2点翠意符能打出。",                                                                          "img": "res://assets/cards/jiansheng/863d9bc2f7ece270f7bd9bfee0d9a9c7.png", "effect": "tiyana_enter","sch_cost": 2, "sch_type": "verdant" },
	{ "id": "tiyana_warden",      "name": "缇亚娜·冕卫",  "region": "ionia",   "type": "follower",  "cost": 7, "atk": 4, "hp": 5, "keywords": ["法盾"],         "text": "法盾。在场时对手无法获得据守分。需消耗2点翠意符能打出。",                                                                          "img": "res://assets/cards/jiansheng/863d9bc2f7ece270f7bd9bfee0d9a9c7.png", "effect": "tiyana_enter","sch_cost": 2, "sch_type": "verdant" },
	{ "id": "wailing_poro",       "name": "哀哀魄罗",      "region": "ionia",   "type": "follower",  "cost": 2, "atk": 2, "hp": 2, "keywords": ["绝念"],         "text": "绝念：被摧毁时，若该处无其他友方单位，则抽1张牌。",                                                                                "img": "res://assets/cards/jiansheng/dd5eaf315bcfef1d67ccda6e8a1d7f52.png", "effect": "",          "sch_cost": 0, "sch_type": "" },
	{ "id": "wailing_poro",       "name": "哀哀魄罗",      "region": "ionia",   "type": "follower",  "cost": 2, "atk": 2, "hp": 2, "keywords": ["绝念"],         "text": "绝念：被摧毁时，若该处无其他友方单位，则抽1张牌。",                                                                                "img": "res://assets/cards/jiansheng/dd5eaf315bcfef1d67ccda6e8a1d7f52.png", "effect": "",          "sch_cost": 0, "sch_type": "" },
	{ "id": "wailing_poro",       "name": "哀哀魄罗",      "region": "ionia",   "type": "follower",  "cost": 2, "atk": 2, "hp": 2, "keywords": ["绝念"],         "text": "绝念：被摧毁时，若该处无其他友方单位，则抽1张牌。",                                                                                "img": "res://assets/cards/jiansheng/dd5eaf315bcfef1d67ccda6e8a1d7f52.png", "effect": "",          "sch_cost": 0, "sch_type": "" },
	{ "id": "sandshoal_deserter", "name": "沙塔啸匪",      "region": "shurima", "type": "follower",  "cost": 6, "atk": 5, "hp": 5, "keywords": [],               "text": "敌方法术和技能无法将我选作目标。",                                                                                                    "img": "res://assets/cards/jiansheng/896b0c45d8a3c7843acd205ce9b909a5.png", "effect": "untargetable","sch_cost": 0, "sch_type": "" },
	{ "id": "sandshoal_deserter", "name": "沙塔啸匪",      "region": "shurima", "type": "follower",  "cost": 6, "atk": 5, "hp": 5, "keywords": [],               "text": "敌方法术和技能无法将我选作目标。",                                                                                                    "img": "res://assets/cards/jiansheng/896b0c45d8a3c7843acd205ce9b909a5.png", "effect": "untargetable","sch_cost": 0, "sch_type": "" },
	{ "id": "sandshoal_deserter", "name": "沙塔啸匪",      "region": "shurima", "type": "follower",  "cost": 6, "atk": 5, "hp": 5, "keywords": [],               "text": "敌方法术和技能无法将我选作目标。",                                                                                                    "img": "res://assets/cards/jiansheng/896b0c45d8a3c7843acd205ce9b909a5.png", "effect": "untargetable","sch_cost": 0, "sch_type": "" },
	# ── 法术 22 张 ──
	{ "id": "scoff",              "name": "蔑视",          "region": "ionia",   "type": "spell",     "cost": 1,                   "keywords": ["反应"],         "text": "反应（需1点翠意符能）。无效化1个法术，该法术费用不得高于4，也不得高于当前可用法力。",                                              "img": "res://assets/cards/jiansheng/OGN-045.png",                          "effect": "counter_cost4","sch_cost": 1, "sch_type": "verdant" },
	{ "id": "scoff",              "name": "蔑视",          "region": "ionia",   "type": "spell",     "cost": 1,                   "keywords": ["反应"],         "text": "反应（需1点翠意符能）。无效化1个法术，该法术费用不得高于4，也不得高于当前可用法力。",                                              "img": "res://assets/cards/jiansheng/OGN-045.png",                          "effect": "counter_cost4","sch_cost": 1, "sch_type": "verdant" },
	{ "id": "scoff",              "name": "蔑视",          "region": "ionia",   "type": "spell",     "cost": 1,                   "keywords": ["反应"],         "text": "反应（需1点翠意符能）。无效化1个法术，该法术费用不得高于4，也不得高于当前可用法力。",                                              "img": "res://assets/cards/jiansheng/OGN-045.png",                          "effect": "counter_cost4","sch_cost": 1, "sch_type": "verdant" },
	{ "id": "duel_stance",        "name": "决斗架势",      "region": "ionia",   "type": "spell",     "cost": 1,                   "keywords": ["反应"],         "text": "反应。选定1名友方单位，战力+1；若其是所在战区唯一友方单位，额外+1战力。",                                                          "img": "res://assets/cards/jiansheng/OGN-046.png",                          "effect": "buff1_solo",  "sch_cost": 0, "sch_type": "" },
	{ "id": "duel_stance",        "name": "决斗架势",      "region": "ionia",   "type": "spell",     "cost": 1,                   "keywords": ["反应"],         "text": "反应。选定1名友方单位，战力+1；若其是所在战区唯一友方单位，额外+1战力。",                                                          "img": "res://assets/cards/jiansheng/OGN-046.png",                          "effect": "buff1_solo",  "sch_cost": 0, "sch_type": "" },
	{ "id": "well_trained",       "name": "训练有素",      "region": "ionia",   "type": "spell",     "cost": 2,                   "keywords": ["反应"],         "text": "反应。选定1名单位，战力+2，抽1张牌。",                                                                                                "img": "res://assets/cards/jiansheng/OGN-058.png",                          "effect": "buff2_draw",  "sch_cost": 0, "sch_type": "" },
	{ "id": "well_trained",       "name": "训练有素",      "region": "ionia",   "type": "spell",     "cost": 2,                   "keywords": ["反应"],         "text": "反应。选定1名单位，战力+2，抽1张牌。",                                                                                                "img": "res://assets/cards/jiansheng/OGN-058.png",                          "effect": "buff2_draw",  "sch_cost": 0, "sch_type": "" },
	{ "id": "well_trained",       "name": "训练有素",      "region": "ionia",   "type": "spell",     "cost": 2,                   "keywords": ["反应"],         "text": "反应。选定1名单位，战力+2，抽1张牌。",                                                                                                "img": "res://assets/cards/jiansheng/OGN-058.png",                          "effect": "buff2_draw",  "sch_cost": 0, "sch_type": "" },
	{ "id": "wind_wall",          "name": "风之障壁",      "region": "ionia",   "type": "spell",     "cost": 3,                   "keywords": ["反应"],         "text": "反应（需2点翠意符能）。无效化1个法术（无费用限制）。",                                                                                "img": "res://assets/cards/jiansheng/OGN-064.png",                          "effect": "counter_any", "sch_cost": 2, "sch_type": "verdant" },
	{ "id": "wind_wall",          "name": "风之障壁",      "region": "ionia",   "type": "spell",     "cost": 3,                   "keywords": ["反应"],         "text": "反应（需2点翠意符能）。无效化1个法术（无费用限制）。",                                                                                "img": "res://assets/cards/jiansheng/OGN-064.png",                          "effect": "counter_any", "sch_cost": 2, "sch_type": "verdant" },
	{ "id": "rally_call",         "name": "迎敌号令",      "region": "ionia",   "type": "spell",     "cost": 2,                   "keywords": ["迅捷"],         "text": "迅捷。本回合内你打出的所有单位以活跃状态进场。抽1张牌。",                                                                            "img": "res://assets/cards/jiansheng/OGN-129.png",                          "effect": "rally_call",  "sch_cost": 0, "sch_type": "" },
	{ "id": "rally_call",         "name": "迎敌号令",      "region": "ionia",   "type": "spell",     "cost": 2,                   "keywords": ["迅捷"],         "text": "迅捷。本回合内你打出的所有单位以活跃状态进场。抽1张牌。",                                                                            "img": "res://assets/cards/jiansheng/OGN-129.png",                          "effect": "rally_call",  "sch_cost": 0, "sch_type": "" },
	{ "id": "rally_call",         "name": "迎敌号令",      "region": "ionia",   "type": "spell",     "cost": 2,                   "keywords": ["迅捷"],         "text": "迅捷。本回合内你打出的所有单位以活跃状态进场。抽1张牌。",                                                                            "img": "res://assets/cards/jiansheng/OGN-129.png",                          "effect": "rally_call",  "sch_cost": 0, "sch_type": "" },
	{ "id": "balance_resolve",    "name": "御衡守念",      "region": "ionia",   "type": "spell",     "cost": 3,                   "keywords": ["迅捷"],         "text": "迅捷。若对手得分距离胜利不超过3分，此法术费用-2。抽1张牌，召出1枚休眠符文。",                                                      "img": "res://assets/cards/jiansheng/OGN-047.png",                          "effect": "balance_resolve","sch_cost": 0, "sch_type": "" },
	{ "id": "balance_resolve",    "name": "御衡守念",      "region": "ionia",   "type": "spell",     "cost": 3,                   "keywords": ["迅捷"],         "text": "迅捷。若对手得分距离胜利不超过3分，此法术费用-2。抽1张牌，召出1枚休眠符文。",                                                      "img": "res://assets/cards/jiansheng/OGN-047.png",                          "effect": "balance_resolve","sch_cost": 0, "sch_type": "" },
	{ "id": "balance_resolve",    "name": "御衡守念",      "region": "ionia",   "type": "spell",     "cost": 3,                   "keywords": ["迅捷"],         "text": "迅捷。若对手得分距离胜利不超过3分，此法术费用-2。抽1张牌，召出1枚休眠符文。",                                                      "img": "res://assets/cards/jiansheng/OGN-047.png",                          "effect": "balance_resolve","sch_cost": 0, "sch_type": "" },
	{ "id": "flash_counter",      "name": "极速反制",      "region": "ionia",   "type": "spell",     "cost": 2,                   "keywords": ["反应"],         "text": "反应（需1点翠意符能）。无效化1个将友方单位或装备选为目标的敌方法术或技能。",                                                      "img": "res://assets/cards/jiansheng/8939ea12cc51f1f5f40a7249fc842c83.png", "effect": "negate_spell","sch_cost": 1, "sch_type": "verdant" },
	{ "id": "flash_counter",      "name": "极速反制",      "region": "ionia",   "type": "spell",     "cost": 2,                   "keywords": ["反应"],         "text": "反应（需1点翠意符能）。无效化1个将友方单位或装备选为目标的敌方法术或技能。",                                                      "img": "res://assets/cards/jiansheng/8939ea12cc51f1f5f40a7249fc842c83.png", "effect": "negate_spell","sch_cost": 1, "sch_type": "verdant" },
	{ "id": "slam",               "name": "扑咚！",        "region": "ionia",   "type": "spell",     "cost": 2,                   "keywords": ["迅捷","回响"],  "text": "迅捷。回响（支付2法力可再次施放）。眩晕1名进攻方单位（本回合无法造成战斗伤害）。",                                                "img": "res://assets/cards/jiansheng/7d5448422bef5eca5ed729cd25a37381.png", "effect": "stun_manual", "sch_cost": 0, "sch_type": "", "echo_mana_cost": 2 },
	{ "id": "slam",               "name": "扑咚！",        "region": "ionia",   "type": "spell",     "cost": 2,                   "keywords": ["迅捷","回响"],  "text": "迅捷。回响（支付2法力可再次施放）。眩晕1名进攻方单位（本回合无法造成战斗伤害）。",                                                "img": "res://assets/cards/jiansheng/7d5448422bef5eca5ed729cd25a37381.png", "effect": "stun_manual", "sch_cost": 0, "sch_type": "", "echo_mana_cost": 2 },
	{ "id": "strike_ask_later",   "name": "先打再问",      "region": "ionia",   "type": "spell",     "cost": 1,                   "keywords": ["迅捷"],         "text": "迅捷（需2点摧破符能）。选定1名单位，本回合战力+5。",                                                                                "img": "res://assets/cards/jiansheng/9e49b7d03df8a4741178ba8ebbb886ec.png", "effect": "buff5_manual","sch_cost": 2, "sch_type": "crushing" },
	{ "id": "strike_ask_later",   "name": "先打再问",      "region": "ionia",   "type": "spell",     "cost": 1,                   "keywords": ["迅捷"],         "text": "迅捷（需2点摧破符能）。选定1名单位，本回合战力+5。",                                                                                "img": "res://assets/cards/jiansheng/9e49b7d03df8a4741178ba8ebbb886ec.png", "effect": "buff5_manual","sch_cost": 2, "sch_type": "crushing" },
	# ── 装备 8 张 ──
	{ "id": "zhonya",             "name": "中娅沙漏",      "region": "ionia",   "type": "equipment", "cost": 2,                   "keywords": ["待命"],         "text": "待命（可盖放，之后0费作为反应打出）。当友方单位将被摧毁时，摧毁此装备代替，使单位以休眠状态撤回基地。",                            "img": "res://assets/cards/jiansheng/OGN-077.png",                          "effect": "death_shield","sch_cost": 0, "sch_type": "" },
	{ "id": "trinity_force",      "name": "三相之力",      "region": "ionia",   "type": "equipment", "cost": 4,                   "keywords": [],               "text": "装配（支付1摧破符能）。当装备单位据守战场时，额外获得1分。属性加成：战力+2。",                                                      "img": "res://assets/cards/jiansheng/e8e40a9fd575e57366dc036e78097887.png", "effect": "trinity_equip","sch_cost": 0, "sch_type": "", "atk_bonus": 2, "equip_sch_cost": 1, "equip_sch_type": "crushing" },
	{ "id": "trinity_force",      "name": "三相之力",      "region": "ionia",   "type": "equipment", "cost": 4,                   "keywords": [],               "text": "装配（支付1摧破符能）。当装备单位据守战场时，额外获得1分。属性加成：战力+2。",                                                      "img": "res://assets/cards/jiansheng/e8e40a9fd575e57366dc036e78097887.png", "effect": "trinity_equip","sch_cost": 0, "sch_type": "", "atk_bonus": 2, "equip_sch_cost": 1, "equip_sch_type": "crushing" },
	{ "id": "guardian_angel",     "name": "守护天使",      "region": "ionia",   "type": "equipment", "cost": 2,                   "keywords": [],               "text": "装配（支付1翠意符能）。当装备单位将被摧毁时，摧毁此装备代替，移除其所有伤害，以休眠状态撤回基地。属性加成：战力+1。",              "img": "res://assets/cards/jiansheng/a1fadf48792b23b1c801ecb7650c5246.png", "effect": "guardian_equip","sch_cost": 0, "sch_type": "", "atk_bonus": 1, "equip_sch_cost": 1, "equip_sch_type": "verdant" },
	{ "id": "guardian_angel",     "name": "守护天使",      "region": "ionia",   "type": "equipment", "cost": 2,                   "keywords": [],               "text": "装配（支付1翠意符能）。当装备单位将被摧毁时，摧毁此装备代替，移除其所有伤害，以休眠状态撤回基地。属性加成：战力+1。",              "img": "res://assets/cards/jiansheng/a1fadf48792b23b1c801ecb7650c5246.png", "effect": "guardian_equip","sch_cost": 0, "sch_type": "", "atk_bonus": 1, "equip_sch_cost": 1, "equip_sch_type": "verdant" },
	{ "id": "dorans_blade",       "name": "多兰之刃",      "region": "ionia",   "type": "equipment", "cost": 2,                   "keywords": [],               "text": "装配（支付1摧破符能）。属性加成：战力+2。",                                                                                          "img": "res://assets/cards/jiansheng/905f91c9d6c10d27fc654480753d225e.png", "effect": "dorans_equip","sch_cost": 0, "sch_type": "", "atk_bonus": 2, "equip_sch_cost": 1, "equip_sch_type": "crushing" },
	{ "id": "dorans_blade",       "name": "多兰之刃",      "region": "ionia",   "type": "equipment", "cost": 2,                   "keywords": [],               "text": "装配（支付1摧破符能）。属性加成：战力+2。",                                                                                          "img": "res://assets/cards/jiansheng/905f91c9d6c10d27fc654480753d225e.png", "effect": "dorans_equip","sch_cost": 0, "sch_type": "", "atk_bonus": 2, "equip_sch_cost": 1, "equip_sch_type": "crushing" },
	{ "id": "dorans_blade",       "name": "多兰之刃",      "region": "ionia",   "type": "equipment", "cost": 2,                   "keywords": [],               "text": "装配（支付1摧破符能）。属性加成：战力+2。",                                                                                          "img": "res://assets/cards/jiansheng/905f91c9d6c10d27fc654480753d225e.png", "effect": "dorans_equip","sch_cost": 0, "sch_type": "", "atk_bonus": 2, "equip_sch_cost": 1, "equip_sch_type": "crushing" },
]

# ── 易英雄卡（独立于主牌堆，游戏开始时置于英雄区域）──
const MASTERYI_HERO: Dictionary = {
	"id": "yi_hero", "name": "易·锋芒毕现", "region": "ionia",
	"type": "follower", "cost": 7, "atk": 6, "hp": 5,
	"keywords": ["游走", "急速"],
	"text": "游走（可向其他战场移动）。急速。需消耗1点摧破符能打出。",
	"img": "res://assets/cards/jiansheng/0d52fc2f224cd039153ecafeaac56671.png",
	"effect": "", "sch_cost": 1, "sch_type": "crushing", "hero": true
}

# ── 易传奇（对应 cards.js MASTERYI_LEGEND）──
const MASTERYI_LEGEND: Dictionary = {
	"id": "masteryi", "name": "无极剑圣（易）", "region": "ionia", "type": "champion",
	"cost": 5, "atk": 5, "hp": 12, "keywords": [],
	"text": "被动光环：当此战场仅有1名友方单位防守时，该单位战力+2。",
	"img": "res://assets/cards/jiansheng/OGS-019.png",
	"level": 1,
	"abilities": [
		{ "id": "masteryi_defend_buff", "name": "独影剑鸣", "type": "passive", "keywords": [], "trigger": "onCombatDefend", "text": "被动：此战场仅有1名友方单位防守时，该单位本回合战力+2。", "effect": "masteryi_defend_buff" }
	]
}

# ── 符文牌组配置（各牌组初始符文数量）──
const KAISA_RUNE_SETUP: Dictionary  = { "blazing": 7, "radiant": 5 }
const MASTERYI_RUNE_SETUP: Dictionary = { "verdant": 6, "crushing": 6 }

# ── 辅助函数 ──

## 根据 id 从全部卡牌中查找一张（返回第一个匹配的模板，不是实例）
func get_card_template(id: String) -> Dictionary:
	for card in KAISA_MAIN:
		if card["id"] == id:
			return card
	for card in MASTERYI_MAIN:
		if card["id"] == id:
			return card
	if KAISA_LEGEND["id"] == id:
		return KAISA_LEGEND
	if MASTERYI_LEGEND["id"] == id:
		return MASTERYI_LEGEND
	if KAISA_HERO["id"] == id:
		return KAISA_HERO
	if MASTERYI_HERO["id"] == id:
		return MASTERYI_HERO
	for bf in BATTLEFIELDS:
		if bf["id"] == id:
			return bf
	push_error("CardDatabase: 找不到 id=" + id + " 的卡牌模板")
	return {}

## 根据牌组名称返回该牌组的完整牌组数组副本（可直接洗牌用作游戏牌堆）
func get_deck(deck_name: String) -> Array:
	match deck_name:
		"kaisa":
			return KAISA_MAIN.duplicate(true)
		"masteryi":
			return MASTERYI_MAIN.duplicate(true)
		_:
			push_error("CardDatabase: 未知牌组名称: " + deck_name)
			return []

## 返回英雄卡（独立区域，不在主牌堆内，规则103.2.a）
func get_hero(deck_name: String) -> Dictionary:
	match deck_name:
		"kaisa":
			return KAISA_HERO.duplicate(true)
		"masteryi":
			return MASTERYI_HERO.duplicate(true)
		_:
			push_error("CardDatabase: 未知英雄名称: " + deck_name)
			return {}

## 返回传奇卡
func get_legend(deck_name: String) -> Dictionary:
	match deck_name:
		"kaisa":
			return KAISA_LEGEND.duplicate(true)
		"masteryi":
			return MASTERYI_LEGEND.duplicate(true)
		_:
			push_error("CardDatabase: 未知传奇名称: " + deck_name)
			return {}

# ── 各阵营战场牌 ID 池（对应 main.js KAISA_BF_IDS / MASTERYI_BF_IDS）──
const KAISA_BF_IDS: Array    = ["star_peak", "void_gate", "strength_obelisk"]
const MASTERYI_BF_IDS: Array = ["thunder_rune", "ascending_stairs", "forgotten_monument"]

## 返回该牌组的战场 ID 列表
func get_bf_ids(deck_name: String) -> Array:
	match deck_name:
		"kaisa":    return KAISA_BF_IDS.duplicate()
		"masteryi": return MASTERYI_BF_IDS.duplicate()
		_: return []

## 返回该牌组的符文配置
func get_rune_setup(deck_name: String) -> Dictionary:
	match deck_name:
		"kaisa":
			return KAISA_RUNE_SETUP.duplicate()
		"masteryi":
			return MASTERYI_RUNE_SETUP.duplicate()
		_:
			return {}
