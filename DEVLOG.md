# FWTCG Godot V4 — 开发日志

> ✅已完成 | 🔧修复 | ⚠️待验证 | 📌待做

## 当前完成度（2026-03-19）

| 系统 | 完成度 |
|------|--------|
| GameState | ~100% |
| CardDatabase | 100% |
| AIManager | ~98% |
| CombatManager | ~98% |
| SpellManager | ~98% |
| KeywordManager | ~95% |
| LegendManager | ~100% |
| PromptManager | ~80% |
| GameBoard UI | ~97% |

**总体：约 97%**

---

## 2026-03-18（续）

### ✅ 基础系统（本轮前已完成）
- 8大 Autoload 单例全部移植完成
- 33种法术效果 + 9种入场触发 + 13个关键词 + 传奇技能 100%

### ✅ [M1] 硬币先后手 + Mulligan 换牌界面
- `_show_coin_flip()`：Tween Y轴翻转动画
- `_show_mulligan()`：全屏覆盖 + 卡牌选中高亮 + await confirm_btn.pressed

### ✅ [M2] 贴图资源整合
- ksha×34 + jiansheng×24 + runes×4 + coins + bgm.m4a 就位

### ✅ [M3] Log 面板 + 折叠
- RichTextLabel 彩色分类 + 折叠/展开按钮
- 折叠时 panel 完全滑出屏幕右侧（position:x = 1280），右边缘出现 `_log_tab_btn`（◀记录）展开 Tab

### ✅ [M5] 动画系统
- `_anim_enter()`：单位入场缩放弹入(TRANS_BACK) + 淡入 + 金色CPUParticles爆破
- `_on_combat_start()`：攻击方金色闪 / 防御方红色闪
- `_on_score_changed()`：得分圆圈弹跳scale + 颜色粒子爆破（绿/红区分玩家/AI）
- `_flash_node()`：通用 modulate 闪烁工具函数

### ✅ [M7] BGM 系统
- `_start_bgm()`：加载 res://assets/bgm.m4a，volume -14dB，自动循环播放

### ✅ 积分轨道优化
- `_refresh_score_track()` 改为累积高亮：已得分段（绿色/红色渐变）+ 当前分位（最亮+font_size:15）+ 未得分（暗色）
- 视觉效果更直观，不再只亮当前位置

### ⚠️ [M4] 拖拽出牌（已实现基础架构，待验证）
- 手牌卡 `node.set_drag_forwarding()` → `_hand_get_drag()` 提供拖拽数据 + 幽灵预览
- drop_zone 移至 `_build_board()` 第一个子节点（先于按钮添加），改为 `MOUSE_FILTER_PASS`
  - 按钮（后加，处于上层）优先获取普通点击；drop_zone 接收拖拽释放事件
- `_can_drop_play()` 验证是否可出牌，`_drop_play_card()` 执行打出

### ✅ 移动模式视觉反馈
- `_bf_panels[]` 数组记录战场面板根节点
- `_refresh_battlefields()` 中：`_move_mode` 为真时战场面板 modulate → 绿色高亮
- 玩家点击基地单位后，战场区域自动发绿光提示可点击位置

---

---

## 2026-03-19

### ✅ 符文多选交互重构
- 去掉独立确认浮层 `_rune_confirm_bar`
- 左键多选横置（`_rune_tap_uids[]`）、右键多选回收（`_rune_recycle_uids[]`），各自独立列表
- 再点已选同张同操作 → 取消；同一张不能同时横置+回收
- `_btn_tap_all` 复用为确定按钮，显示 `✓ 确定（横置×N  回收×M）`

### ✅ 2026-03-19 逻辑审查修复
- **CombatManager**：战后 HP 重置 `u["current_hp"] = u["current_atk"]`，传奇跳过
- **SpellManager**：force_move 新增玩家战场选择弹窗 + AI智能选目标战场
- **PromptManager**：新增30秒超时保护，超时自动 resolve(null)

### 🔧 BUG 修复记录

| ID | 问题 | 原因 | 修复 | 文件 |
|----|------|------|------|------|
| 001 | Mulligan 确认后无反应 | lambda 闭包 bool 值拷贝 | await confirm_btn.pressed | GameBoard._show_mulligan() |
| 002 | 所有游戏按钮无法点击 ✅ | drop_zone MOUSE_FILTER_PASS 截断兄弟节点事件 | 改为 MOUSE_FILTER_IGNORE→已改为先加入节点树底层+PASS | GameBoard._build_board() |
| 003 | Log 折叠后仍有残留 + 无展开按钮 ✅ | panel 只滑到x=1256；展开按钮被遮 | panel 滑至x=1280（屏外）+ 独立 _log_tab_btn | GameBoard._toggle_log() |
| 004 | 粒子系统乱爆 ✅ | `Array[String]` 不能存 int UID，`not in` 永远 true | 改为 `Array`（无类型） | GameBoard（_prev_bf_uids） |
| 005 | 积分轨道只亮当前位 ✅ | active=只等于当前分值 | 累积：val<=ps 全亮，当前位最亮 | GameBoard._refresh_score_track() |
| 006 | 移动到战场无视觉提示 ✅ | 无反馈 | _move_mode 时战场面板绿色高亮 | GameBoard._refresh_battlefields() |

---

## 待办（优先级顺序）

| # | 功能 | 状态 |
|---|------|------|
| M4 | 拖拽出牌验证 | ⚠️ 待验证 |
| M6 | 法术施放/单位死亡粒子扩充 | 📌 待做 |
| M5-d | 法术飞行轨迹动画 | 📌 待做 |
| M3-b | 游戏区折叠日志后居中 | 📌 待做（架构复杂，延后） |
| UI | 整体布局美化（间距/字体/配色）| 📌 待做 |

---

## 架构备忘

- 分辨率：1280×720（viewport + window，勿改）
- BOARD_W=1000 | LOG_X=1000 | ACTION_Y=562 | HAND_Y=608
- `drop_zone`：第一个子节点（先于按钮），`MOUSE_FILTER_PASS` → 按钮在上层拦截普通点击，drop_zone 接拖放
- autoload 不得引用 GameBoard（单向依赖）
- `_prev_bf_uids`：每次 _refresh() 末尾更新，用于判断新入场单位触发动画，必须用 `Array`（无类型）否则 int UID 存入 Array[String] 导致永远触发
- `_prev_p_score / _prev_e_score`：跟踪得分变化，只在得分时触发弹跳动画
- `_bf_panels[]`：战场面板根节点列表，在 `_build_bf_slot()` 中追加，供移动模式高亮
