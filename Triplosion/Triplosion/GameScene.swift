//
//  GameScene.swift
//  Triplosion
//
//  Created by 周源坤 on 2022/9/15.
//

import SpriteKit
import GameplayKit

struct TripleSquare {
    var zIndex: Int
    let pos: CGPoint
    let color: SKColor
    var name: String = "front"
}

class TripleManager {
    private var triples: [TripleSquare] = []
    private var squareWidth: CGFloat
    let dense: CGFloat = 150
    
    let colors: [SKColor] = [.red, .cyan, .blue, .green, .yellow, .purple, .brown, .gray]
    
    init(tripleOfSuqare: Int = 12, width: CGFloat = 50) {
        squareWidth = width
        for _ in 0..<tripleOfSuqare {
            let randomColor = colors[Int.random(in: 0..<colors.count)]
            for _ in 0..<3 {
                let pos = randomPos(lbound: -dense, rbound: dense, tbound: dense, bbound: -dense)
                let zIndex = madCheck(pos: pos)
                let tripleSquare = TripleSquare(zIndex: zIndex, pos: pos, color: randomColor)
                triples.append(tripleSquare)
            }
        }
    }
    
    func randomPos(lbound: CGFloat, rbound: CGFloat, tbound: CGFloat, bbound: CGFloat) -> CGPoint {
        return CGPoint(x: CGFloat.random(in: lbound..<rbound), y: CGFloat.random(in: bbound..<tbound))
    }
    
    func squareWithin(pos1: CGPoint, pos2: CGPoint, width: CGFloat) -> Bool {
        return ((pos1.x - pos2.x) > 0 && (pos1.x - pos2.x) < width && (pos1.y - pos2.y) > 0 && (pos1.y - pos2.y) < width) ||
        ((pos2.x - pos1.x) > 0 && (pos2.x - pos1.x) < width && (pos2.y - pos1.y) > 0 && (pos2.y - pos1.y) < width)
    }
    
    func checkBlock(newPos: CGPoint) -> Int{
        var zIndex = 1
        guard triples.count != 0 else {
            return zIndex
        }
        
        
        
        let leftBottom = newPos
        let leftTop = CGPoint(x: newPos.x, y: newPos.y + squareWidth)
        let rightBottom = CGPoint(x: newPos.x + squareWidth, y: newPos.y)
        let rightTop = CGPoint(x: newPos.x + squareWidth, y: newPos.y + squareWidth)
        
        for i in triples.indices {
            if squareWithin(pos1: leftBottom, pos2: triples[i].pos, width: squareWidth) || squareWithin(pos1: leftTop, pos2: triples[i].pos, width: squareWidth) || squareWithin(pos1: rightBottom, pos2: triples[i].pos, width: squareWidth) || squareWithin(pos1: rightTop, pos2: triples[i].pos, width: squareWidth) {
                triples[i].name = "back"
                zIndex = max(triples[i].zIndex, zIndex) + 1
            }
        }
        return zIndex
    }
    
    func madCheck(pos: CGPoint) -> Int {
        var zIndex = 1
        guard triples.count != 0 else {
            return zIndex
        }
        for i in triples.indices {
            if squareInterset(lb1: triples[i].pos, lb2: pos, width: squareWidth) {
                triples[i].name = "back"
                zIndex = max(triples[i].zIndex, zIndex) + 1
            }
        }
        return zIndex
    }
    
    func generatePoses(nums: Int) -> [CGPoint] {
        guard nums % 6 == 0 else {
            return []
        }
        var poses: [CGPoint] = []
        for i in 0..<6 {
            for j in 0..<Int(nums / 6) {
                poses.append(CGPoint(x: -300 + i * 80, y: -300 + j * 80))
            }
        }
        return poses
    }
    
    func getTriples() -> [TripleSquare] {
        return triples
    }
    
    
}

class LogicManager {
    var slots: [CGPoint] = []
    var used: Int = 0
    var colors: [SKColor] = []
    
    init() {
        for i in 0..<6 {
            slots.append(CGPoint(x: -225 + i * 75, y: -375))
        }
    }
    
    func nextSlot(for color: SKColor) -> CGPoint? {
        guard used < 6 else {
            return nil
        }
        defer {
            used += 1
            colors.append(color)
            
        }
        return slots[used]
        
    }
    
    func checkTriple() -> SKColor? {
        var dic: [SKColor : Int] = [:]
        for color in colors {
            if let cnt = dic[color] {
                dic[color] = cnt + 1
            } else {
                dic[color] = 1
            }
        }
        return dic.first(where: { color, count in
            count == 3
        })?.key
        
    }
    
    func restore() {
        guard let color = checkTriple() else {
            return
        }
        used -= 3
        colors.removeAll(where: {$0 == color})
    }
}

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    private var button: SKShapeNode?
    private var buttonText: SKLabelNode?
    private var squareNodes: Set<SKShapeNode> = Set<SKShapeNode>()
    private var selectedNodes: Array<SKShapeNode> = Array<SKShapeNode>()
    private var tripleManager: TripleManager?
    private var logicManager: LogicManager?
    
    var lastUpdateTime: TimeInterval = 0
    
    var gameRestart: Bool = false
    
    func restart() {
        self.removeAllChildren()
        squareNodes.removeAll()
        selectedNodes.removeAll()
        
        self.label = SKLabelNode(text: "v1.0.0")
        if let label = self.label {
            label.position = CGPoint(x: 300, y:300)
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
            addChild(label)
            
        }
        
        self.button = SKShapeNode(rect: CGRect(x: 350, y: 150, width: 150, height: 50))
        if let button = self.button {
            button.fillColor = .clear
            button.strokeColor = .white
            button.lineWidth = 2
            addChild(button)
        }
        
        self.buttonText = SKLabelNode(text: "重新开始")
        if let label = self.buttonText {
             
            label.position = CGPoint(x: self.button!.frame.midX, y: self.button!.frame.midY - self.button!.frame.height / 4)
            addChild(label)
        }
        //print(button!.frame.origin)
        
        // Create shape node to use during mouse interaction
        tripleManager = TripleManager(tripleOfSuqare: 12)
        logicManager = LogicManager()
        guard let tripleManager = tripleManager else {
            fatalError("could not start")
        }
        
        let tripleSquares = tripleManager.getTriples()
        for tripleSquare in tripleSquares {
            let squareNode = SKShapeNode(rect: CGRect(origin: tripleSquare.pos, size: CGSize(width: 50, height: 50)))
            squareNode.fillColor = tripleSquare.color
            squareNode.zPosition = CGFloat(tripleSquare.zIndex)
            if tripleSquare.name == "front" {
                squareNode.name = tripleSquare.name
                squareNode.lineWidth = 2
                squareNode.strokeColor = .white
            } else {
                squareNode.name = tripleSquare.name
                squareNode.strokeColor = .black
            }

            
            
            addChild(squareNode)
            squareNodes.insert(squareNode)
        }
        
        for slot in logicManager!.slots {
            let slotNode = SKShapeNode(rect: CGRect(origin: slot, size: CGSize(width: 50, height: 50)))
            slotNode.strokeColor = .white
            slotNode.lineWidth = 5
            slotNode.name = "slot"
            addChild(slotNode)
        }
        
        gameRestart = false
        
    }
    
    override func didMove(to view: SKView) {
        
        // Get label node from scene and store it for use later
        //self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        self.label = SKLabelNode(text: "v1.0.0")
        if let label = self.label {
            label.position = CGPoint(x: 300, y:300)
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
            addChild(label)
            
        }
        
        self.button = SKShapeNode(rect: CGRect(x: 350, y: 150, width: 150, height: 50))
        if let button = self.button {
            button.fillColor = .clear
            button.strokeColor = .white
            button.lineWidth = 2
            addChild(button)
        }
        
        self.buttonText = SKLabelNode(text: "重新开始")
        if let label = self.buttonText {
             
            label.position = CGPoint(x: self.button!.frame.midX, y: self.button!.frame.midY - self.button!.frame.height / 4)
            addChild(label)
        }
        //print(button!.frame.origin)
        
        // Create shape node to use during mouse interaction
        tripleManager = TripleManager(tripleOfSuqare: 12)
        logicManager = LogicManager()
        guard let tripleManager = tripleManager else {
            fatalError("could not start")
        }
        
        let tripleSquares = tripleManager.getTriples()
        for tripleSquare in tripleSquares {
            let squareNode = SKShapeNode(rect: CGRect(origin: tripleSquare.pos, size: CGSize(width: 50, height: 50)))
            squareNode.fillColor = tripleSquare.color
            squareNode.zPosition = CGFloat(tripleSquare.zIndex)
            if tripleSquare.name == "front" {
                squareNode.name = tripleSquare.name
                squareNode.lineWidth = 2
                squareNode.strokeColor = .white
            } else {
                squareNode.name = tripleSquare.name
                squareNode.strokeColor = .black
            }

            
            
            addChild(squareNode)
            squareNodes.insert(squareNode)
        }
        
        for slot in logicManager!.slots {
            let slotNode = SKShapeNode(rect: CGRect(origin: slot, size: CGSize(width: 50, height: 50)))
            slotNode.strokeColor = .white
            slotNode.lineWidth = 5
            slotNode.name = "slot"
            addChild(slotNode)
        }
    }
    
    func getSquareNode(at pos: CGPoint) -> SKShapeNode? {

        let frontNodes = squareNodes.filter {$0.name == "front"}
        return frontNodes.first { (pos.x - $0.frame.minX) < 50 && (pos.x - $0.frame.minX) > 0 && (pos.y - $0.frame.minY) < 50 && (pos.y - $0.frame.minY) > 0}
       
    }
    
    
    func fixSurroundingNodes(at pos: CGPoint)  {
        let backNodes = squareNodes.filter {$0.name == "back"}
        let surrondings = backNodes.filter { (pos.x - $0.frame.midX) < 100 && (pos.x - $0.frame.midX) > -100 && (pos.y - $0.frame.midY) < 100 && (pos.y - $0.frame.midY) > -100}
        
//        for surronding in surrondings {
//            if squareInterset(lb1: surronding.frame.origin, lb2: pos, width: 50) {
//
//            } else {
//                surronding.name = "front"
//                surronding.lineWidth = 2
//                surronding.strokeColor = .white
//            }
//            if !squareInterset(lb1: surronding.frame.origin, lb2: pos, width: 50){
//                surronding.name = "front"
//                surronding.lineWidth = 2
//                surronding.strokeColor = .white
//            }
//        }
        
        
        for surronding in surrondings {
            let leftBottom = CGPoint(x: surronding.frame.origin.x, y: surronding.frame.origin.y)
            let leftTop = CGPoint(x: surronding.frame.origin.x, y: surronding.frame.origin.y + surronding.frame.height)
            let rightBottom = CGPoint(x: surronding.frame.origin.x + surronding.frame.width, y: surronding.frame.origin.y)
            let rightTop = CGPoint(x: surronding.frame.origin.x + surronding.frame.width, y: surronding.frame.origin.y + surronding.frame.height)
            //print("\(leftBottom),\(leftTop),\(rightBottom),\(rightTop)")

            if getSquareNode(at: leftBottom) == nil && getSquareNode(at: leftTop) == nil && getSquareNode(at: rightBottom) == nil && getSquareNode(at: rightTop) == nil {
                //print("front for, \(surronding.fillColor)")
                surronding.name = "front"
                surronding.lineWidth = 2
                surronding.strokeColor = .white
            } else {
                //print("no front for, \(surronding.fillColor)")

            }
        }
    }
    
    func resort(pos: CGPoint){
        for i in squareNodes.indices {
            squareNodes[i].name = "front"
            if squareInterset(lb1: squareNodes[i].frame.origin, lb2: pos, width: 50) {
                squareNodes[i].name = "back"
            }
            
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        
        guard !gameRestart else {
            return
        }
        
        if button!.contains(pos){
            gameRestart = true
            restart()
            return
        }
        
        guard let node = getSquareNode(at: pos) else {
            label!.text = "无法使用"
            return
        }
        
        guard let nextSlotPos = logicManager!.nextSlot(for: node.fillColor) else {
            label!.text = "游戏结束，请重新开始"
            return
        }
        
        label!.text = "游戏中"
        
        node.run(SKAction.move(by: CGVector(dx: nextSlotPos.x - node.frame.minX, dy: nextSlotPos.y - node.frame.minY), duration: 0.2)) {
            self.squareNodes.remove(node)
            self.selectedNodes.append(node)
            self.fixSurroundingNodes(at: pos)
            //self.resort(pos: node.frame.origin)
            node.zPosition = 0
            guard let colorTriple = self.logicManager!.checkTriple() else {
                //self.label!.text = "no triple"
                return
            }
            var count = 0
            for node in self.selectedNodes {
                if node.fillColor == colorTriple {
                    
                    self.selectedNodes.remove(at: self.selectedNodes.firstIndex {$0.fillColor == colorTriple}!)
                    node.removeFromParent()
                    count += 1
                } else {
                    node.run(SKAction.moveBy(x: CGFloat(-75 * count), y: 0, duration: 0.5))
                }
            }
            self.logicManager!.restore()
            
            if self.squareNodes.count == 0 {
                self.label!.text = "你成功了"
            }
        }
        
        
        
    }
    
    
    
    override func mouseDown(with event: NSEvent) {
        self.touchDown(atPoint: event.location(in: self))
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 0x31:
            if let label = self.label {
                label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
            }
        default:
            print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        
    }
}

extension SKColor {
    var back: SKColor {
        return SKColor(calibratedHue: self.hueComponent, saturation: self.saturationComponent / 2, brightness: self.brightnessComponent / 2, alpha: 1)
    }
    var front: SKColor {
        return SKColor(calibratedHue: self.hueComponent, saturation: self.saturationComponent * 2, brightness: self.brightnessComponent * 2, alpha: 1)
    }
}



func squareInterset(lb1: CGPoint, lb2: CGPoint, width: CGFloat) -> Bool {
    let x1 = pointInSquare(pos: lb1, squarelb: lb2, width: width) || pointInSquare(pos: CGPoint(x: lb1.x + width, y: lb1.y), squarelb: lb2, width: width) || pointInSquare(pos: CGPoint(x: lb1.x, y: lb1.y + width), squarelb: lb2, width: width) && pointInSquare(pos: CGPoint(x: lb1.x + width, y: lb1.y + width), squarelb: lb2, width: width)
    let x2 = pointInSquare(pos: lb2, squarelb: lb1, width: width) || pointInSquare(pos: CGPoint(x: lb2.x + width, y: lb2.y), squarelb: lb1, width: width) || pointInSquare(pos: CGPoint(x: lb2.x, y: lb2.y + width), squarelb: lb1, width: width) && pointInSquare(pos: CGPoint(x: lb2.x + width, y: lb2.y + width), squarelb: lb1, width: width)
    return x1 || x2
}

func pointInSquare(pos: CGPoint, squarelb: CGPoint, width: CGFloat) -> Bool {
    let lx = squarelb.x
    let rx = squarelb.x + width
    let by = squarelb.y
    let ty = squarelb.y + width
    return pos.x > lx && pos.x < rx && pos.y > by && pos.y < ty
}
