import SceneKit
import SwiftUI
import UIKit

/// キャンバスの厚みと額縁を、指で回して見る3D。紙と木枠の落ち着いた色だけを使う。
struct Canvas3DView: View {
    let longMm: Int
    let shortMm: Int
    /// 梱包後の厚み（ミリ）。
    let thicknessMm: Double
    let framed: Bool

    /// 横の回転（ラジアン）。
    @State private var yaw: Double = 0.85
    /// 縦の傾き（ラジアン）。
    @State private var pitch: Double = 0.28
    @State private var baseYaw: Double = 0.85
    @State private var basePitch: Double = 0.28

    var body: some View {
        CanvasSceneView(longMm: longMm,
                        shortMm: shortMm,
                        thicknessMm: thicknessMm,
                        framed: framed,
                        yaw: yaw,
                        pitch: pitch)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        yaw = baseYaw + Double(value.translation.width) * 0.011
                        pitch = min(max(basePitch + Double(value.translation.height) * 0.008, -0.40), 0.95)
                    }
                    .onEnded { _ in
                        baseYaw = yaw
                        basePitch = pitch
                    }
            )
            .accessibilityLabel("キャンバスの3D表示。指で回せます。")
    }
}

/// SceneKit のビュー。回転だけを SwiftUI 側から受け取り、拡大縮小はしない。
struct CanvasSceneView: UIViewRepresentable {
    let longMm: Int
    let shortMm: Int
    let thicknessMm: Double
    let framed: Bool
    let yaw: Double
    let pitch: Double

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = UIColor(Theme.paper)
        view.antialiasingMode = .multisampling4X
        view.isUserInteractionEnabled = false
        view.isJitteringEnabled = false
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.render(in: view,
                                   longMm: longMm,
                                   shortMm: shortMm,
                                   thicknessMm: thicknessMm,
                                   framed: framed,
                                   yaw: yaw,
                                   pitch: pitch)
    }

    final class Coordinator {
        private let content = SCNNode()
        private let cameraNode = SCNNode()
        private var builtKey = ""

        init() {
            let camera = SCNCamera()
            camera.fieldOfView = 34
            camera.zNear = 0.05
            camera.zFar = 60
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(0, 0.32, 3.2)
            cameraNode.look(at: SCNVector3Zero)
            content.name = "content"
        }

        func render(in view: SCNView,
                    longMm: Int,
                    shortMm: Int,
                    thicknessMm: Double,
                    framed: Bool,
                    yaw: Double,
                    pitch: Double) {
            let key = "\(longMm)|\(shortMm)|\(Int(thicknessMm.rounded()))|\(framed)"
            if view.scene == nil || key != builtKey {
                builtKey = key
                view.scene = makeScene(longMm: longMm,
                                       shortMm: shortMm,
                                       thicknessMm: thicknessMm,
                                       framed: framed)
                view.pointOfView = cameraNode
            }
            content.eulerAngles = SCNVector3(Float(pitch), Float(yaw), 0)
            view.setNeedsDisplay()
        }

        // MARK: - 組み立て

        private func makeScene(longMm: Int, shortMm: Int, thicknessMm: Double, framed: Bool) -> SCNScene {
            let scene = SCNScene()
            content.removeFromParentNode()
            content.childNodes.forEach { $0.removeFromParentNode() }

            // 長辺が 1.45 になるように揃える。寸法の比は変えない。
            let scale = 1.45 / Float(max(longMm, shortMm))
            let width = Float(longMm) * scale
            let height = Float(shortMm) * scale
            let depth = max(Float(thicknessMm), 4) * scale
            let border = framed ? 15 * scale : 0
            let frameDepth = framed ? depth + 20 * scale : 0

            let paper = material(Theme.paperDeep, roughness: 0.95)
            let back = material(Theme.paper, roughness: 0.95)
            let side = material(Theme.woodDeep, roughness: 0.85)
            let frameWood = material(Theme.wood, roughness: 0.80)

            // キャンバス本体。前面は紙、側面は木枠の色。
            let board = SCNBox(width: CGFloat(width),
                               height: CGFloat(height),
                               length: CGFloat(depth),
                               chamferRadius: CGFloat(depth * 0.12))
            board.materials = [paper, side, back, side, side, side]
            let boardNode = SCNNode(geometry: board)
            if framed {
                let lip = max(2 * scale, 0.003)
                boardNode.position = SCNVector3(0, 0, -(lip + depth / 2))
            } else {
                boardNode.position = SCNVector3(0, 0, -depth / 2)
            }
            content.addChildNode(boardNode)

            if framed {
                let outerWidth = width + border * 2
                let outerHeight = height + border * 2
                let z = -frameDepth / 2

                for y in [outerHeight / 2 - border / 2, -(outerHeight / 2 - border / 2)] {
                    let bar = SCNBox(width: CGFloat(outerWidth),
                                     height: CGFloat(border),
                                     length: CGFloat(frameDepth),
                                     chamferRadius: CGFloat(border * 0.15))
                    bar.materials = [frameWood]
                    let node = SCNNode(geometry: bar)
                    node.position = SCNVector3(0, y, z)
                    content.addChildNode(node)
                }

                for x in [outerWidth / 2 - border / 2, -(outerWidth / 2 - border / 2)] {
                    let bar = SCNBox(width: CGFloat(border),
                                     height: CGFloat(height),
                                     length: CGFloat(frameDepth),
                                     chamferRadius: CGFloat(border * 0.15))
                    bar.materials = [frameWood]
                    let node = SCNNode(geometry: bar)
                    node.position = SCNVector3(x, 0, z)
                    content.addChildNode(node)
                }
            }

            scene.rootNode.addChildNode(content)

            let ambient = SCNLight()
            ambient.type = .ambient
            ambient.intensity = 520
            ambient.color = UIColor.white
            let ambientNode = SCNNode()
            ambientNode.light = ambient
            scene.rootNode.addChildNode(ambientNode)

            let keyLight = SCNLight()
            keyLight.type = .directional
            keyLight.intensity = 700
            keyLight.color = UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1)
            let keyNode = SCNNode()
            keyNode.light = keyLight
            keyNode.eulerAngles = SCNVector3(-0.95, 0.75, 0)
            scene.rootNode.addChildNode(keyNode)

            let fillLight = SCNLight()
            fillLight.type = .directional
            fillLight.intensity = 260
            fillLight.color = UIColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 1)
            let fillNode = SCNNode()
            fillNode.light = fillLight
            fillNode.eulerAngles = SCNVector3(-0.30, -1.10, 0)
            scene.rootNode.addChildNode(fillNode)

            scene.rootNode.addChildNode(cameraNode)
            return scene
        }

        private func material(_ color: Color, roughness: CGFloat) -> SCNMaterial {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(color)
            material.roughness.contents = roughness
            material.metalness.contents = 0
            material.lightingModel = .physicallyBased
            return material
        }
    }
}
