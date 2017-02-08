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
    private var closeButton = UIButton(type: UIButtonType.custom)
    private let deleteWidth: CGFloat = 20
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // Setup close button
        self.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(deleteButtonPressed), for: .touchUpInside)
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        closeButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        closeButton.imageView?.contentMode = .scaleAspectFit
        closeButton.clipsToBounds = true
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(dragging(gesture:)))
        addGestureRecognizer(longPress)
        longPress.delegate = self
        
        let panning = UIPanGestureRecognizer(target: self, action: #selector(dragging(gesture:)))
        addGestureRecognizer(panning)
        panning.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let deleteOffset = deleteWidth/2
        contentView.frame = CGRect(x: deleteOffset, y: deleteOffset, width: bounds.width - deleteOffset, height: bounds.height - deleteOffset)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let point = closeButton.convert(point, from: self)
        if closeButton.bounds.contains(point) {
            return closeButton
        }
        return super.hitTest(point, with: event)
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
    
    fileprivate func showDelete(_ show: Bool) {
        self.bringSubview(toFront: closeButton)
        let width = deleteWidth
        let frame = show ? CGRect(x: 0, y: 0, width: width, height: width) : CGRect.zero
        self.closeButton.frame = frame

        // Add blurEffect
        let blurEffect = UIBlurEffect(style: .prominent)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = frame
        blurView.clipsToBounds = true
        closeButton.insertSubview(blurView, at: 0)
        
        blurView.layer.cornerRadius = width/2
        self.closeButton.layer.cornerRadius = width/2
    }
    
    func deleteButtonPressed() {
        print("Delete pressed.")
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

            // Show delete button
            showDelete(true)
            
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

