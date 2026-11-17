# Siri 动画显示问题调查

## 当前目标设备
- iPhone 12 mini（A14，硬件标识 iPhone13,1）
- iOS 27.3 beta 1
- 现象：通过机型伪装启用的灵动岛 / Siri 彩色边缘动画被实体刘海遮挡，右侧和底部也有裁切
- 目标：尽可能让系统动画完整显示；明确禁止使用 TrollStore / 巨魔安装路径

## Erosion 源码结论
Erosion-CN 是普通 SwiftUI 应用，核心修改对象是 MobileGestalt / CacheData。源码检索到的 Siri 相关内容主要涉及 Apple Intelligence 资格、SiriHub 冲突检测和网络分流；未发现 Siri 动画视图、SpringBoard Siri 渲染或系统动画布局实现。

因此，Erosion IPA 自身不能通过普通 SwiftUI 布局代码移动 SpringBoard 中的系统灵动岛。修改 App 自身 Safe Area、屏幕预览或绘制遮罩，只能影响 Erosion 自己的界面，不能改变系统 UI 的坐标。

## 外部实现调查：VisibleIsland
调查了 ethxnn88/VisibleIsland：
- 它通过 Hook `SBSystemApertureWindow -layoutSubviews` 调整系统灵动岛窗口位置。
- 代码中确实包含 `iPhone13,1`（iPhone 12 mini）分支，使用约 `19.5 / scale` 的 Y 坐标。
- 但项目 README 明确标注完整兼容范围为 iOS 16.0–16.6.1；iPhone 12 mini 被列在“Fake offset devices”，不是官方完整支持机型。
- 因此，19.5 这个数值只能作为旧系统上的研究线索，不能直接认定适用于 iOS 27.3 beta 1，更不能直接写入设备。
- 该实现仍然依赖 SpringBoard tweak 注入，不是普通 IPA 可以实现的能力。

参考：
- https://github.com/ethxnn88/VisibleIsland
- https://github.com/ethxnn88/VisibleIsland/blob/main/Tweak.xm

## 非 TrollStore 注入路径核查
- Erosion 作为普通侧载 IPA，不能自行注入 SpringBoard。
- 常见 bootstrap 的官方使用方式通常依赖 TrollStore；且部分 bootstrap 本身不支持 SpringBoard 注入。
- 搜索到的 Troy iOS 27 半越狱项目说明，其依赖的 Cryptex 安装漏洞已被修补，作者声明新版本无法再为设备制作和安装，因此不能作为当前可执行的免 TrollStore 方案。
- 在没有确认可用的系统级注入入口前，不把 Theos tweak 编译成功误当成可在用户设备运行。

参考：
- https://github.com/jakeajames/tr0y
- https://github.com/Baw-Appie/RootHideBootstrap

## 当前分层判断
1. **可由 Erosion IPA 完成：** MobileGestalt 参数管理、备份/恢复、可视区域模拟和诊断信息展示。
2. **不能由普通 Erosion IPA 完成：** 改变 SpringBoard 的系统灵动岛窗口位置、Siri 系统动画视图布局。
3. **理论上可研究但当前未验证：** 对 SpringBoard 的系统级 Hook / 注入。需要与 iOS 27.3 beta 1 匹配的注入环境，并验证目标类、窗口层级和坐标系。
4. **Siri 动画仍需单独定位：** 即使灵动岛窗口偏移成功，也不能假设 Siri 彩色边缘动画使用同一窗口或同一布局容器。

## 下一步实验（不触碰系统配置）
- 在设备上先记录真实硬件型号、系统 build、伪装前后 MobileGestalt 差异和 Siri 动画裁切截图。
- 对比关闭机型伪装 / 恢复原厂 MobileGestalt 后，Siri 动画裁切是否消失，以验证问题是否由伪装触发。
- 如果关闭伪装后问题消失，优先定位触发差异的具体 MobileGestalt 字段；一次只改变一个字段并保留备份。
- 如果关闭伪装后问题仍存在，再把重点转向 Siri 系统动画自身的布局容器，而不是继续猜测灵动岛坐标。

## 安全原则
- 保留原始 MobileGestalt 备份。
- 不写入未经验证的键值，不调整系统分辨率或显示模式作为盲测。
- 不安装依赖 TrollStore 的工具，不推荐巨魔、Bootstrap 或 Dopamine 安装路径。
- 不把未验证的 SpringBoard tweak 安装到主力设备。
- 每次只测试一个变量，并保留可回滚方案。

## 来源
上游项目：Kianuni/Erosion-CN（GPL-3.0）。

## Erosion 当前实现的进一步代码核查（2026-11-17）

已直接检查工作分支中的 `GestaltView.swift` 与 `GestaltStore.swift`：

- “允许修改屏幕子类型”开关只作用于 `ArtworkDeviceSubType`，写入位置是 `CacheExtra["oPeik/9e8lQWMszEjbPzng"]["ArtworkDeviceSubType"]`。
- 机型伪装另行写入 `CacheExtra["h9jDsbgj7xIVeIQ8S3/X3Q"]`（ProductType）；两者是不同字段，不能把它们当成一个“灵动岛偏移量”。
- 灵动岛能力开关使用 `YlEtTtHlNesRBMal1CqRaA`（DeviceSupportsDynamicIsland），它表达能力标记，不是坐标。
- 当前子类型选项中的 2556、2622、2670、2736 等是设备显示/Artwork 子类型预设值；代码没有提供独立的 Y 轴偏移字段，也没有 Siri 动画坐标参数。
- 因此，继续尝试轮换这些 subtype 数值并不能构成有依据的“下移灵动岛”实验；它可能改变系统对屏幕/设备形态的判断，反而引入更多 UI 不匹配。

### 本轮结论与实验优先级

1. 暂停把 `ArtworkDeviceSubType` 当作位置滑块使用；除非有同一 iOS build、同一硬件的实测对照，不新增偏移预设。
2. 先对照原厂备份与当前 MobileGestalt 中的三项：ProductType、ArtworkDeviceSubType、DeviceSupportsDynamicIsland。记录值即可，不先写入。
3. 如果用户已做“关闭机型伪装 / 恢复原厂”A/B，按结果判断；如果尚未做，先完成这一项，因为它能区分“伪装组合导致的布局错误”与“系统动画自身问题”。
4. 当前分支的“灵动岛可视区域模拟”仍只是 Erosion 内的示意工具，不会改变系统窗口。

### 外部版本兼容性补充

公开的 GestaltEdit 项目 README 标注其工具支持 iOS/iPadOS 27 beta 1–beta 4 的特定 build，并明确提醒 MobileGestalt 写入可能破坏系统功能；这只能说明相关 MobileGestalt 编辑工具正在适配该 beta 范围，不能证明某个 subtype 能修复 iPhone 12 mini 的 Siri 动画裁切，也不能证明 SpringBoard 注入可用。参考：https://github.com/therajes/gestaltedit
