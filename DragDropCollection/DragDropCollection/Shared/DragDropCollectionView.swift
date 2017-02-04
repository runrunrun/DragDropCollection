//
//  DragDropCollectionView.swift
//  DragDropCollection
//
//  Created by Hari Kunwar on 2/3/17.
//  Copyright © 2017 Learning. All rights reserved.
//

import UIKit

class DragDropCollectionView: UICollectionView {
    fileprivate var isEditingCells = false
    fileprivate var cellScreenShot = UIImageView()
    fileprivate let scaleValue = 1.2
    fileprivate let scaleDuration = 0.1

    override func didMoveToWindow() {
        super.didMoveToWindow()
     
        cellScreenShot.contentMode = .scaleToFill
        self.addSubview(cellScreenShot)
        
        let tapping = UITapGestureRecognizer(target: self, action: #selector(tapping(gesture:)))
        self.addGestureRecognizer(tapping)
    }
    
    override func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! DragDropCollectionViewCell
        cell.isEditing = isEditingCells
        cell.delegate = self
        return cell
    }
}

extension DragDropCollectionView: DragDropCollectionViewCellDelegate {
    func willBeginDragging(cell: DragDropCollectionViewCell) {
        isEditingCells = true
        
        // Disable Scrolling
        self.isScrollEnabled = false
        
        // Replace cell with screenshot
        cellScreenShot.alpha = 1.0
        cellScreenShot.image = cell.screenShot()
        cellScreenShot.frame = cell.frame
        self.bringSubview(toFront: cellScreenShot)
        
        // Hide cell
        cell.isHidden = true
        
        // Scale up screenshot
        let scaleUp = CABasicAnimation(keyPath: "transform.scale")
        scaleUp.fromValue = 1.0
        scaleUp.toValue = 1.2
        scaleUp.duration = 0.1
        scaleUp.fillMode = kCAFillModeForwards
        scaleUp.isRemovedOnCompletion = false
        cellScreenShot.layer.add(scaleUp, forKey: "scalingUp")
        
        // Change visible cells state.
        updateEditState(isEditingCells)
    }
    
    func didEndDragging(cell: DragDropCollectionViewCell) {
        // Scale Down
        let scaleDown = CABasicAnimation(keyPath: "transform.scale")
        scaleDown.fromValue = scaleValue
        scaleDown.toValue = 1.0
        scaleDown.duration = scaleDuration
        cellScreenShot.layer.add(scaleDown, forKey: "scalingDown")
        cellScreenShot.layer.removeAnimation(forKey: "scalingUp")
        
        // Show cell and hide cell screenshot.
        UIView.animate(withDuration: 0.3, delay: scaleDuration, animations: {
            self.cellScreenShot.center = cell.center
        }, completion: { (done) in
            self.cellScreenShot.alpha = 0.0
            cell.isHidden = false
        })
    }
    
    func didDrag(cell: DragDropCollectionViewCell, to center: CGPoint) {
        // Move cell screenshot
        cellScreenShot.center = center
        
        // Scroll Screen if needed
        var scrollRect = cellScreenShot.frame
        scrollRect.size.height += 100
        scrollRect.origin.y -= scrollRect.height/2
        self.scrollRectToVisible(scrollRect, animated: false)
        
        // Detect cell to move
        var movingCellIndex: IndexPath?
        // Find the cell that intersects moving screenshot
        for cell in self.visibleCells {
            let intersectionSize = cell.frame.intersection(cellScreenShot.frame).size
            let screenshotSize = cellScreenShot.bounds.size
            
            if intersectionSize.width > screenshotSize.width/2 && intersectionSize.height > screenshotSize.height/2 {
                movingCellIndex = self.indexPath(for: cell)
                break
            }
        }
        
        // Move cell
        if let movingCellIndex = movingCellIndex {
            if let indexPath = self.indexPath(for: cell) {
                self.performBatchUpdates({
                    self.moveItem(at: indexPath, to: movingCellIndex)
                }) { (done) in
                    
                }
            }
        }
    }
    
    // Update UI for edit state
    func updateEditState(_ edit: Bool) {
        for cell in self.visibleCells {
            if let cell = cell as? DragDropCollectionViewCell {
                cell.isEditing = edit
            }
        }
    }
}

extension DragDropCollectionView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func tapping(gesture: UIGestureRecognizer) {
        isEditingCells = false
        updateEditState(isEditingCells)
    }
}

