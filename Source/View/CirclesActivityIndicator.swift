//
//  ActivityIndicatorTrianglePath.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 21.12.2021.
//

import Foundation

fileprivate let activityViewTag: Int = 0123456789

protocol ActivityIndicatorPresentable where Self: UIViewController {
    func startActivityAnimation()
    func stopActivityAnimation()
}

extension ActivityIndicatorPresentable {
    func startActivityAnimation() {
        let dimmView = UIView()
        dimmView.tag = activityViewTag
        view.addSubview(dimmView)
        dimmView.constraintToSides(inside: view)
        dimmView.backgroundColor = .black.withAlphaComponent(0.7)
        dimmView.isUserInteractionEnabled = false
        let indicator = CirclesActivityIndicator().makeActivityIndicator()
        dimmView.addSubview(indicator)
        indicator.center = view.center
        indicator.center.y -= 40.0
    }
    func stopActivityAnimation() {
        DispatchQueue.main.async {
            self.view.subviews.forEach {
                if $0.tag == activityViewTag {
                    $0.removeFromSuperview()
                    return
                }
            }
        }
    }
}

fileprivate class CirclesActivityIndicator {
    func makeActivityIndicator(height: CGFloat = 60.0, color: UIColor = .white) -> UIView {
        let size = CGSize(width: height, height: height)
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        let layer = view.layer
        
        let duration: CFTimeInterval = 1.25
        let beginTime = CACurrentMediaTime()
        let beginTimes = [0, 0.2, 0.4]
        let timingFunction = CAMediaTimingFunction(controlPoints: 0.21, 0.53, 0.56, 0.8)
        /// Scale animation
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.keyTimes = [0, 0.7]
        scaleAnimation.timingFunction = timingFunction
        scaleAnimation.values = [0, 1]
        scaleAnimation.duration = duration
        /// Opacity animation
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.keyTimes = [0, 0.7, 1]
        opacityAnimation.timingFunctions = [timingFunction, timingFunction]
        opacityAnimation.values = [1, 0.7, 0]
        opacityAnimation.duration = duration
        /// Animation
        let animation = CAAnimationGroup()
        animation.animations = [scaleAnimation, opacityAnimation]
        animation.duration = duration
        animation.repeatCount = HUGE
        animation.isRemovedOnCompletion = false
        /// Draw circles
        for i in 0 ..< 3 {
            let circle = layerWithRing(size: size, color: color)
            let frame = CGRect(x: (layer.bounds.size.width - size.width) / 2,
                               y: (layer.bounds.size.height - size.height) / 2,
                               width: size.width,
                               height: size.height)
            animation.beginTime = beginTime + beginTimes[i]
            circle.frame = frame
            circle.add(animation, forKey: "animation")
            layer.addSublayer(circle)
        }
        return view
    }
    
    private func layerWithRing(size: CGSize, color: UIColor) -> CALayer {
        let layer: CAShapeLayer = CAShapeLayer()
        let path: UIBezierPath = UIBezierPath()
        let lineWidth: CGFloat = 2
        path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                    radius: size.width / 2,
                    startAngle: 0,
                    endAngle: CGFloat(2 * Double.pi),
                    clockwise: false)
        layer.fillColor = nil
        layer.strokeColor = color.cgColor
        layer.lineWidth = lineWidth
        layer.backgroundColor = nil
        layer.path = path.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        return layer
    }
}
