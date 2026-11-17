import SwiftUI

/// Custom viewport preview only. This does not change the physical display,
/// SpringBoard layout, Siri animation, MobileGestalt, or system resolution.
struct IslandViewportPreview: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("islandPreviewCanvasWidth") private var canvasWidth = 375.0
    @AppStorage("islandPreviewCanvasHeight") private var canvasHeight = 812.0
    @AppStorage("islandPreviewTopMask") private var topMask = 54.0
    @AppStorage("islandPreviewOffset") private var islandOffset = 34.0

    private var safeWidth: CGFloat { CGFloat(min(max(canvasWidth, 240), 600)) }
    private var safeHeight: CGFloat { CGFloat(min(max(canvasHeight, 400), 1300)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("自定义屏幕尺寸")
                            .font(.title2.bold())
                        Text("自由输入宽度和高度，预览区域会按你的数值实时调整。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    devicePreview
                        .frame(maxHeight: 420)
                        .frame(maxWidth: .infinity)

                    GroupBox("画布尺寸（pt）") {
                        VStack(spacing: 14) {
                            dimensionField(title: "宽度", value: $canvasWidth, range: 240...600)
                            dimensionField(title: "高度", value: $canvasHeight, range: 400...1300)
                            Text("预览范围：宽 240–600 pt，高 400–1300 pt。输入值只改变本页模拟画布。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, 6)
                    }

                    GroupBox("刘海与灵动岛模拟") {
                        VStack(alignment: .leading, spacing: 14) {
                            valueSlider(title: "顶部遮挡高度", value: $topMask, range: 0...160, suffix: "pt")
                            valueSlider(title: "灵动岛垂直位置", value: $islandOffset, range: 0...180, suffix: "pt")
                            Text("这些参数仅改变示意图，不会移动真实系统灵动岛或 Siri 动画。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 6)
                    }

                    HStack {
                        Label("仅预览，不写入系统", systemImage: "eye")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Button("恢复默认") {
                            canvasWidth = 375
                            canvasHeight = 812
                            topMask = 54
                            islandOffset = 34
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .padding(14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("尺寸与位置实验")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private func dimensionField(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: value, format: .number.precision(.fractionLength(0)))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 104)
                .onChange(of: value.wrappedValue) { _, newValue in
                    if newValue.isFinite {
                        value.wrappedValue = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                }
            Text("pt")
                .foregroundStyle(.secondary)
        }
    }

    private func valueSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text("\\(Int(value.wrappedValue)) \\(suffix)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 1)
        }
    }

    private var devicePreview: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let scale = width / safeWidth
            let height = safeHeight * scale
            let maskHeight = CGFloat(topMask) * scale
            let islandY = (12 + CGFloat(islandOffset)) * scale
            let corner = min(38 * scale, width * 0.12)

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color(red: 0.07, green: 0.08, blue: 0.10))

                RoundedRectangle(cornerRadius: max(corner - 4, 4))
                    .fill(Color(red: 0.12, green: 0.15, blue: 0.20))
                    .padding(5 * scale)

                VStack(spacing: 0) {
                    Spacer().frame(height: maskHeight)
                    Rectangle().fill(Color.white.opacity(0.035))
                    Spacer(minLength: 0)
                }
                .clipShape(RoundedRectangle(cornerRadius: max(corner - 6, 4)))
                .padding(7 * scale)

                Capsule()
                    .fill(Color.black)
                    .frame(width: min(160 * scale, width * 0.52), height: 34 * scale)
                    .position(x: width / 2, y: 22 * scale)

                Capsule()
                    .fill(Color.black)
                    .frame(width: min(126 * scale, width * 0.44), height: 34 * scale)
                    .overlay {
                        HStack(spacing: 5 * scale) {
                            Circle().fill(Color.green).frame(width: 5 * scale, height: 5 * scale)
                            Text("灵动岛示意")
                                .font(.system(size: max(8, 9 * scale), weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    .position(x: width / 2, y: islandY + 17 * scale)

                Rectangle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(height: maskHeight)
                    .overlay(alignment: .bottom) {
                        Text("顶部遮挡区 · \\(Int(topMask)) pt")
                            .font(.system(size: max(8, 9 * scale), weight: .semibold))
                            .foregroundStyle(.orange)
                            .padding(.bottom, 4 * scale)
                    }
                    .padding(.horizontal, 7 * scale)
                    .offset(y: 7 * scale)

                VStack {
                    Spacer()
                    Text("\\(Int(canvasWidth)) × \\(Int(canvasHeight)) pt")
                        .font(.system(size: max(8, 9 * scale), weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.bottom, 18 * scale)
                }
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: corner))
            .overlay {
                RoundedRectangle(cornerRadius: corner)
                    .stroke(Color.white.opacity(0.18), lineWidth: 2)
            }
        }
        .aspectRatio(safeWidth / safeHeight, contentMode: .fit)
    }
}
