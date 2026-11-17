# Siri 动画显示问题调查

## 当前目标设备
- iPhone 12 mini（A14）
- iOS 27.3 beta 1
- 现象：Siri 彩色边缘动画右侧和底部被裁切

## 源码初步结论
本仓库 Erosion-CN 是 SwiftUI 应用，核心修改对象是 MobileGestalt / CacheData。源码检索到的 Siri 相关内容主要涉及 Apple Intelligence 资格、SiriHub 冲突检测和网络分流；未发现 Siri 动画视图、SpringBoard Siri 渲染或系统动画布局实现。

因此，当前不能把动画裁切归因于某个 MobileGestalt 键，也不应盲目修改 Safe Area 或设备型号参数。下一步应先确认动画裁切是否由机型伪装引起，再研究系统 Siri UI 所属进程/框架及其布局参数。若确认问题在系统 UI 层，修复可能需要独立的系统级补丁，而不是修改 Erosion App 本身。

## 安全原则
- 保留原始 MobileGestalt 备份。
- 不写入未经验证的键值。
- 每次只测试一个变量，并保留可回滚方案。

## 来源
上游项目：Kianuni/Erosion-CN（GPL-3.0）。
