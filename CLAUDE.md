# FWTCG Godot V4 — Claude 项目上下文

## 项目简介
将网页 TCG 游戏从 JavaScript 移植到 Godot 4 的项目。
- **原始项目：** `E:\claudeCode\FWTCG_V3d_V9`（7725行 JS，16个文件）
- **Godot 项目：** `E:\claudeCode\goDOT\FWTCG_GODOT_V4`
- **分辨率：** 1280×720，纯代码构建节点（无 .tscn 编辑器布局）
- **用户：** 不写代码，只负责按 F5 运行游戏并报告 Output 日志

## 架构原则

### Autoload 单例设计
所有游戏逻辑在 `autoload/` 单例，UI 只在 `scenes/GameBoard.gd`

| 单例 | 职责 |
|------|------|
| `GameState` | 全局状态 + 回合流程 + 得分 + 符文操作 |
| `CardDatabase` | 所有卡牌/战场/英雄/传奇/装备数据 |
| `AIManager` | AI 决策（行动/对决/移动） |
| `CombatManager` | 单位移动 + 战斗结算 + 战场能力 |
| `SpellManager` | 法术效果（33种）+ 入场触发（9种）+ 出牌流程 |
| `KeywordManager` | 13个关键词机制 |
| `LegendManager` | 传奇技能（被动/触发/主动） |
| `PromptManager` | 异步玩家选择弹窗 |

### 信号流程
```
GameState.state_updated → GameBoard._refresh()   # 重绘UI
GameState.action_phase_started → AIManager       # AI回合
PromptManager.show_prompt_requested → GameBoard._on_prompt_requested()  # 弹窗
```

## JS → GDScript 移植对照表

| JavaScript | GDScript |
|-----------|---------|
| `G.pScore` | `GameState.p_score` |
| `G.bf[0].pU` | `GameState.bf[0]["pU"]` |
| `mk(card)` | `GameState.mk(card)` |
| `atk(unit)` | `GameState.get_atk(unit)` |
| `getAllUnits(owner)` | `GameState.get_all_units(owner)` |
| `addSch(owner, type)` | `GameState.add_sch(owner, type)` |
| `setTimeout(fn, ms)` | `await get_tree().create_timer(s).timeout` |
| `Promise / async-await` | `await PromptManager.ask(options)` |
| `render()` | `GameState.emit_signal("state_updated")` |

## 重要规则
- **不要** 在 autoload 里引用 GameBoard 节点（单向依赖）
- **不要** 直接修改 unit dict 的 `atk` 字段，用 `current_atk` 和 `tb.atk`
- `PromptManager.ask()` 在 `auto_mode=true` 时跳过弹窗（测试用）
- 所有牌库操作用 `pop_back()`（顶部）/ `insert(0,...)` （底部）
- 手牌无上限（规则107.6）

## 游戏规则速查
- 胜利条件：率先得 8 分（或传奇 HP 归零）
- 每回合阶段：唤醒 → 开始(据守分) → 召出符文 → 抽牌 → 行动 → 结束
- 两块战场，控制方每回合开始得 1 据守分
- 征服战场（清场）得 1 分（规则630：每个战场每回合最多1分）
- 符文横置 → +1 法力；符文回收 → +1 对应符能

---

## 数值字段使用规则（必须遵守，违反会产生战斗数值 bug）

⚠️ 本游戏 **atk = HP**，无独立生命值系统。攻击力就是能承受的伤害上限，高攻打低攻，低攻单位死。

| 场景 | 正确写法（GDScript） | 错误写法 |
|------|---------------------|---------|
| 读单位当前战力（含所有加成） | `GameState.get_atk(u)` | `u["atk"]` 或 `u["current_atk"]` |
| 初始化/重置 current_hp | `u["atk"]`（与 current_atk 一致） | `u.get("hp", u["atk"])`（hp 字段对普通单位无意义）|
| 战后全局 HP 重置 | `u["current_hp"] = u["current_atk"]` | `u["current_hp"] = u.get("hp", u["atk"])` |
| 给单位造成伤害 | `GameState.deal_damage(u, dmg, ...)` | 直接 `u["current_hp"] -= dmg` |
| 永久 +N 战力 | `u["current_atk"] += N; u["atk"] += N; u["current_hp"] = u["current_atk"]` | 单独操作 hp 字段 |
| 战力比较/条件判断 | `GameState.get_atk(u) >= 5` | `u["atk"] >= 5` 或 `u["current_atk"] >= 5` |

字段语义：
- `u["atk"]` — 基础战力（卡牌定义值，永久 buff 会修改它）
- `u["hp"]` — **CardDatabase 里存在但对普通单位无意义**，不得用于战斗计算
- `u["current_atk"]` — 当前战力（不含回合临时 buff `tb["atk"]`）
- `u["current_hp"]` — 当前生命 = 当前战力（受伤后减少，战斗后重置为 `u["current_atk"]`）
- `GameState.get_atk(u)` — **有效战力** = `max(1, current_atk + tb["atk"])`，战斗/法术伤害计算的唯一正确入口
- 传奇（champion 类型）有独立 `current_hp`/`hp`（如卡莎14血），不经过 `mk()`，单独处理

**⚠️ 传奇字段唯一权威来源（违反必然导致致命 bug）：**

| 操作 | 正确写法 | 错误写法 |
|------|---------|---------|
| 法术/战斗对传奇造成伤害 | `GameState.p_leg["current_hp"] -= dmg`（经由 `deal_damage` 的 is_legend 路径） | `GameState.p_leg["hp"] -= dmg` |
| 判断传奇是否死亡（check_win） | `GameState.p_leg["current_hp"] <= 0` | `GameState.p_leg["hp"] <= 0` |
| 读传奇当前血量显示 | `GameState.p_leg["current_hp"]` | `GameState.p_leg["hp"]` |

`hp` 字段仅用于初始化 `current_hp`。运行期永远操作 `current_hp`，`hp` 不得出现在 `deal_damage` 或 `check_win` 路径上。

---

## 卡牌效果实现强制核对规则

**以下任一情况发生时，必须先读卡图或卡牌 text 字段，才能动代码。无例外。**

触发条件（满足其一即触发）：
- 新增或修改 `SpellManager` 中某个 effect 的目标范围（`get_spell_targets`）
- 新增或修改 `SpellManager.apply_spell` 中某个 effect 的结算逻辑
- 新增或修改 `SpellManager.on_summon` 中的入场效果
- 修改 `CardDatabase` 中卡牌的 `text`/`sch_cost`/`sch_type`/`effect` 字段
- 修改 `LegendManager` 中的传奇技能效果

**强制执行步骤：**

1. 在 `CardDatabase.gd` 找到该卡的 `img` 字段，用 Read 工具读取图片（路径格式：`res://assets/cards/...`）
2. 从图片或 `text` 字段中确认以下三项，并在回复中**逐条引用原文**：
   - 效果文字（如"对战场上的1名单位造成3点伤害"）
   - 目标范围（有无"战场上"限制）
   - 费用类型（法力 cost / 符能 sch_cost）
3. 说明原文 → 代码逻辑的对应关系
4. 以上步骤未完成，**不得写任何代码**

**无卡图时的降级处理：**
若卡牌无 `img` 字段或图片无法读取，改为在回复中明确引用 `CardDatabase.gd` 的 `text` 字段原文，并标注"无卡图，以 text 字段为准"。

---

## 符能类型参考（必须遵守）

**参考图路径：`E:/claudeCode/FWTCG_V3d_V9/tempPic/cards/funeng.webp`**

任何涉及以下情形时，**必须先读取该图确认符能类型**，不得凭记忆判断：
- 判断某张卡消耗的是法术费用（`cost`）还是符能（`sch_cost`/`sch_type`）
- 新增卡牌时填写 `sch_type` 字段
- 修改卡牌文字描述中的符能名称

图中6种符文的中文名与代码键名对应关系：

| 图片显示 | 代码键名（GDScript） | Emoji |
|---------|-------------------|-------|
| 炽烈符文 | `"blazing"` | 🔥 |
| 翠意符文 | `"verdant"` | 🌿 |
| 灵光符文 | `"radiant"` | ✨ |
| 摧破符文 | `"crushing"` | 💥 |
| 混沌符文 | `"chaos"` | 🌀 |
| 序理符文 | `"order"` | ⚜️ |

**卡牌数据自检规则**：每张有符能需求的卡，`text` 字段的中文描述必须与 `sch_cost`（数量）和 `sch_type`（类型）字段完全吻合。装备卡的装配符能成本存在 `equip_sch_cost`/`equip_sch_type`，而非 `sch_cost`。

---

## 任务完成自检规则

每次完成任务后，**必须自己先验证，不能张嘴就说"完成了"**：

1. **读文件验证**：重新读取修改过的文件，确认改动实际存在、逻辑正确
2. **列出证据**：说明哪些具体内容证明任务已完成（引用行号/代码片段）
3. **检查遗漏**：对照任务要求逐条核对，有没有哪条没做到
4. **再下结论**：以上三步通过后，才宣布任务完成

不走这个流程，不得声称任务完成。

### 触发式技能新增自检（防止"写完但从不运行"）

每当新增一个带有触发条件的传奇技能（被动/触发型），**必须逐条验证以下调用链完整性**，缺任何一环该技能永远静默失效：

1. **LegendManager.gd** — 技能函数已实现，逻辑正确 ✓
2. **调用点** — 对应游戏事件（战斗、回合开始、出牌等）**实际调用了** `LegendManager.trigger_legend_event(event, owner, ctx)` 或 `LegendManager.check_legend_passives(owner)`
3. **事件名匹配** — `trigger_legend_event` 里 match 的 case 字符串 与 调用处传入的 event_name **完全一致**
4. **时机正确** — 调用发生在该技能应生效的时机（伤害前/后、进场时等）

验证方式：Grep 搜索 `trigger_legend_event` 所有调用点，确认事件名存在对应 case，并检查是否在正确的函数/阶段内被调用。

### 死亡 / 效果结算类改动专项自检

凡涉及以下代码路径，必须逐条对照：

1. **clean_dead / _clean_base_dead 清理** — 过滤条件是否同时排除了 `type == "equipment"`？
   装备 `current_hp` 可能为 0，不加守卫会导致被召回后立即"阵亡"。

2. **apply_spell / deal_damage 后的 _log()** — deal_damage 内部已打印伤害日志，
   case 代码不得再重复 log 同一条信息，否则会在死亡清理后产生"死后受伤"假象。

3. **多段伤害法术（如 deal3_twice）** — 第二击的目标列表是否在第一击 deal_damage
   （含 clean_dead）之后重新获取？确保不会对已死亡目标再次造成伤害。

4. **attached_equipments 清理** — 单位死亡时，必须将 `u.get("attached_equipments", [])` 中的装备逐一追加到对应 discard，然后清空 `u["attached_equipments"] = []`，再将单位本体加入 discard。

### 拖拽/覆盖陷阱检查规则

排查"拖拽/放置区高亮显示不对"类 bug 时：

1. 确认是哪个节点/函数造成了错误的视觉效果
2. 确认是否有信号/函数被重复连接导致覆盖（Godot 中 `connect` 默认不去重）
3. 检查 `MOUSE_FILTER_STOP` 是否阻断了底层节点的 `gui_input`
4. 拖拽逻辑只在 `GameBoard.gd` 中实现，不在 autoload 单例中

---

## Rules Reference（开发前必读）

实现任何涉及规则的机制、bug修复、或新功能前，**先读 `E:/claudeCode/FWTCG_V3d_V9/docs/rules/` 对应文件**。

**判断口诀：**「这个改动涉及对游戏数据含义的解读吗？」是 → 先读 rules。

具体场景：
- 决定某个字段该不该显示 → 先查规则
- 决定某个数值的来源/计算方式 → 先查规则
- 修改 tooltip / 描述文字中的数值 → 先查规则
- 即使只改 UI 布局，但涉及"这个数据代表什么" → 先查规则

| 文件 | 内容 |
|------|------|
| `01_core_rules.md` | 胜负条件、积分、基本概念 |
| `01a_golden_silver_rules.md` | 黄金/白银法则、信息隐私、区域转移状态重置 |
| `01b_deck_building_setup.md` | 卡组构筑规则、准备流程（规则 101-118） |
| `01c_card_types_control.md` | 游戏物体、卡牌类型（单位/装备/法术/战场/传奇）、控制权规则 |
| `02_zones.md` | 区域定义（基地、战场、手牌等） |
| `03_turn_structure.md` | 回合结构、阶段顺序 |
| `04_stack_priority.md` | 结算栈、优先权 |
| `05_card_play.md` | 出牌规则、费用、时机 |
| `06_combat.md` | 战斗流程、伤害计算、空战场占领、得分、召回 |
| `07_effects.md` | 效果结算、替换效果 |
| `08_abilities.md` | 异能类型（持续、触发、启动） |
| `09_actions.md` | 玩家可采取的动作 |
| `10_economy_equipment.md` | 法力/符文经济、装备规则 |
| `11_keywords.md` | 全部14个关键词的精确定义 |
| `12_game_modes.md` | 1v1 游戏模式规则 |

### Rules 更新维护规则

**每当用户告知 rules 有新增或修改时，必须立即执行以下操作：**

1. 用 Glob 列出 `E:/claudeCode/FWTCG_V3d_V9/docs/rules/` 当前所有规则文件
2. 对比上表，找出新增的文件
3. 读取新增文件，提炼一句话摘要
4. 将新文件追加到上方表格中
5. 不得遗漏，不得等用户第二次提醒
