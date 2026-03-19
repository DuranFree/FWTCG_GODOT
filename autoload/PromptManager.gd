extends Node
# ═══════════════════════════════════════════════
# PromptManager.gd — 异步选择系统 (Autoload 单例)
# 对应 engine.js 中的 askPrompt() Promise 系统
#
# 工作原理：
#   - 玩家回合：弹出 UI 等待选择，await choice_made 信号
#   - AI 回合：立即返回 AI 自动选择，不弹 UI
#   - auto_mode=true：所有 prompt 自动返回 null（用于逻辑测试）
# ═══════════════════════════════════════════════

## 当需要展示 UI 提示框时发出（Phase 7+ UI 层监听此信号）
signal show_prompt_requested(options: Dictionary)

## 当玩家做出选择时发出（UI 层点击按钮后调用 resolve()）
signal choice_made(value)

## 自动模式：true 时所有 prompt 立即返回 null（用于 Phase 2 逻辑测试）
var auto_mode: bool = false

## 当前是否正在等待一个 prompt 响应
var _waiting: bool = false

# ─────────────────────────────────────────────
# 主接口：ask()
# 对应 JS:  const result = await askPrompt({ title, msg, type, cards, optional })
# 用法:     var result = await PromptManager.ask(options)
#
# options 字段（与 JS 版本对应）：
#   "title"    : String  — 弹窗标题
#   "msg"      : String  — 提示文本
#   "type"     : String  — "confirm" / "cards" / "targets"
#   "cards"    : Array   — type="cards" 时的候选卡牌列表
#   "targets"  : Array   — type="targets" 时的候选目标列表
#   "optional" : bool    — true 表示可以跳过（不选）
# ─────────────────────────────────────────────
func ask(options: Dictionary) -> Variant:
	# 自动模式：直接返回 null（跳过所有选择）
	if auto_mode:
		return null

	# AI 回合：自动选择
	if GameState.turn == "enemy":
		return _ai_auto_choose(options)

	# 玩家回合：发出信号，等待 UI 响应
	_waiting = true
	emit_signal("show_prompt_requested", options)
	var result = await choice_made
	_waiting = false
	return result


## resolve(value) — UI 层点击后调用此函数来结束 await
## 对应 JS 中 Promise 的 resolve()
func resolve(value) -> void:
	if _waiting:
		emit_signal("choice_made", value)
	else:
		push_warning("PromptManager.resolve: 当前没有等待中的 prompt")


## cancel() — 取消当前 prompt（相当于用户选择 null/skip）
func cancel() -> void:
	resolve(null)


# ─────────────────────────────────────────────
# AI 自动选择逻辑
# ─────────────────────────────────────────────
func _ai_auto_choose(options: Dictionary) -> Variant:
	var opt_type: String = options.get("type", "confirm")
	var optional: bool   = options.get("optional", false)

	match opt_type:
		"confirm":
			# AI 保守策略：可选的情况下有 60% 概率接受
			if optional:
				return randf() < 0.6
			return true

		"cards":
			var cards: Array = options.get("cards", [])
			if cards.is_empty():
				return null
			# AI 选第一张（最简单策略，后续 Phase 6 会替换为智能 AI）
			return cards[0].get("uid", null)

		"targets":
			var targets: Array = options.get("targets", [])
			if targets.is_empty():
				return null
			return targets[0].get("uid", null)

		_:
			return null
