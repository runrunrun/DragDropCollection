//
//  DragDropCollectionViewCell.swift
//  DragDropCollection
//
//  Created by Hari Kunwar on 2/3/17.
//  Copyright © 2017 Learning. All rights reserved.
//

import UIKit

protocol DragDropCollectionViewCellDelegate: class {
    func willBeginDragging(cell: DragDropCollectionViewCell)
    func didEndDragging(cell: DragDropCollectionViewCell)
    func didDrag(cell: DragDropCollectionViewCell, to center: CGPoint)
}

class DragDropCollectionViewCell: UICollectionViewCell {
    fileprivate let vibrateAnimationKey = "vibrate"
    fileprivate var initialCenter: CGPoint?
    fileprivate var gestureDistanceFromCenter: CGSize?
    
    weak var delegate: DragDropCollectionViewCellDelegate?
    
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(dragging(gesture:)))
        addGestureRecognizer(longPress)
        longPress.delegate = self
        
        let panning = UIPanGestureRecognizer(target: self, action: #selector(dragging(gesture:)))
        addGestureRecognizer(panning)
        panning.delegate = self
    }
    
    var isEditing: Bool = false {
        didSet {
            vibrate(isEditing)
        }
    }
    
    fileprivate func vibrate(_ start: Bool) {
        if start {
            let isVibrating = layer.animation(forKey: vibrateAnimationKey) != nil
            if !isVibrating {
                // Vibrate
                let angle = Float.pi/72 // 2.5 degree
                let vibrate = CABasicAnimation(keyPath: "transform.rotation")
                vibrate.beginTime = CACurrentMediaTime()
                vibrate.duration = 0.15
                vibrate.fromValue = -angle
                vibrate.toValue = angle
                vibrate.autoreverses = true
                vibrate.repeatCount = .infinity
                layer.add(vibrate, forKey: vibrateAnimationKey)
            }
        }
        else {
            layer.removeAnimation(forKey: vibrateAnimationKey)
        }
    }
}

extension DragDropCollectionViewCell: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var shouldBegin = true
        if let _ = gestureRecognizer as? UIPanGestureRecognizer {
            shouldBegin = isEditing
        }
        return shouldBegin
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func dragging(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            guard let view = gesture.view else {
                return
            }
            
            delegate?.willBeginDragging(cell: self)
            
            // Stop vibrating
            vibrate(false)
            
            let gesturePosition = gesture.location(in: view.superview)
            let distanceFromCenterX = view.center.x - gesturePosition.x
            let distanceFromCenterY = view.center.y - gesturePosition.y
            //
            gestureDistanceFromCenter = CGSize(width: distanceFromCenterX, height: distanceFromCenterY)
        }
        else if gesture.state == .changed {
            guard let distanceFromCenter = gestureDistanceFromCenter else {
                return
            }
            
            guard let view = gesture.view else {
                return
            }
            
            let point = gesture.location(in: view.superview)
            
            // Calculate new center position
            let centerX = point.x + distanceFromCenter.width;
            let centerY = point.y + distanceFromCenter.height;
            let newCenter = CGPoint(x: centerX, y: centerY)
            
            // Notify delegate
            delegate?.didDrag(cell: self, to: newCenter)
        }
        else if gesture.state == .ended {
            delegate?.didEndDragging(cell: self)
            // Start vibrating
            vibrate(true)
        }
    }
    
}

