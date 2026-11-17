import SwiftUI

/// Safe visual prototype only. It does not alter display modes, resolution,
/// SpringBoard, MobileGestalt, or any system configuration.
struct IslandViewportPreview: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("islandPreviewTopMask") private var topMask: Double = 54
    @AppStorage("islandPreviewOffset") private var islandOffset: Double = 34

    private let referenceWidth: CGFloat = 375
    private let referenceHeight: CGFloat = 812

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("可视区域模拟")
                            .font(.title2.bold())
                        Text("仅用于预览刘海遮挡区与灵动岛目标位置，不会修改系统屏幕。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    devicePreview
                        .frame(maxWidth: 280)
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("顶部遮挡高度")
                            Spacer()
                            Text("\(Int(topMask)) pt")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $topMask, in: 0...120, step: 1)
                        Text("模拟把刘海所在的顶部区域排除在可视内容之外。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("灵动岛向下偏移")
                            Spacer()
                            Text("\(Int(islandOffset)) pt")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $islandOffset, in: 0...100, step: 1)
                        Text("只改变上方示意图中的灵动岛位置，不会移动真实系统灵动岛。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("仅预览", systemImage: "eye")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Button("恢复默认") {
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
            .navigationTitle("灵动岛位置实验")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private var devicePreview: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let scale = width / referenceWidth
            let height = referenceHeight * scale
            let maskHeight = topMask * scale
            let islandY = (12 + islandOffset) * scale

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 38)
                    .fill(Color(red: 0.07, green: 0.08, blue: 0.10))

                RoundedRectangle(cornerRadius: 34)
                    .fill(Color(red: 0.12, green: 0.15, blue: 0.20))
                    .padding(5)

                VStack(spacing: 0) {
                    Spacer().frame(height: maskHeight)
                    Rectangle()
                        .fill(Color.white.opacity(0.035))
                    Spacer().frame(height: 90 * scale)
                }
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .padding(7)

                // Physical notch reference; this is a diagram, not a live overlay.
                Capsule()
                    .fill(Color.black)
                    .frame(width: 160 * scale, height: 34 * scale)
                    .position(x: width / 2, y: 22 * scale)

                // Target island position is drawn independently from the notch mask.
                Capsule()
                    .fill(Color.black)
                    .frame(width: 126 * scale, height: 34 * scale)
                    .overlay {
                        HStack(spacing: 5) {
                            Circle().fill(Color.green).frame(width: 5 * scale, height: 5 * scale)
                            Text("灵动岛示意")
                                .font(.system(size: 9 * scale, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    .position(x: width / 2, y: islandY + 17 * scale)

                Rectangle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(height: maskHeight)
                    .overlay(alignment: .bottom) {
                        Text("顶部遮挡区 · \(Int(topMask)) pt")
                            .font(.system(size: 9 * scale, weight: .semibold))
                            .foregroundStyle(.orange)
                            .padding(.bottom, 4 * scale)
                    }
                    .padding(.horizontal, 7)
                    .offset(y: 7)

                VStack {
                    Spacer()
                    Text("375 × 812 pt 示意比例")
                        .font(.system(size: 9 * scale, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.bottom, 18 * scale)
                }
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 38))
            .overlay {
                RoundedRectangle(cornerRadius: 38)
                    .stroke(Color.white.opacity(0.18), lineWidth: 2)
            }
        }
        .aspectRatio(referenceWidth / referenceHeight, contentMode: .fit)
    }
}
