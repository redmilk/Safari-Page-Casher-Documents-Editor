//
//  ParticleEmitterView.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 10.12.2021.
//

import Foundation

class ParticleEmitterView: UIView {
    
    var particleImage = UIImage(named: "button-delete-state-unchecked")!
    
    override class var layerClass:AnyClass {
        return CAEmitterLayer.self
    }
    
    func makeEmmiterCell(color: UIColor, velocity: CGFloat, scale: CGFloat) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 6
        cell.lifetime = 30.0
        cell.lifetimeRange = 0
        cell.velocity = velocity
        cell.velocityRange = velocity / 100
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 8
        cell.scale = 0.02
        cell.scaleRange = 0.02 / 2
        cell.contents = particleImage.cgImage
        return cell
    }
    
    override func layoutSubviews() {
        let emitter = self.layer as! CAEmitterLayer
        emitter.masksToBounds = true
        emitter.emitterShape = .cuboid
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterSize = CGSize(width: bounds.size.width, height: bounds.size.height)
        
        let near = makeEmmiterCell(color: UIColor(white: 1, alpha: 0.4), velocity: 1, scale: 0.04)
        let middle = makeEmmiterCell(color: UIColor(white: 1, alpha: 0.66), velocity: 4, scale: 0.05)
        let far = makeEmmiterCell(color: UIColor(white: 1, alpha: 0.33), velocity: 200, scale: 0.07)
        
        emitter.emitterCells = [near, middle, far]
    }
    
}
