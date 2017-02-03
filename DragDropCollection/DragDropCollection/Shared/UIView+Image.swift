//
//  UIView+Image.swift
//  DragDropCollection
//
//  Created by Hari Kunwar on 1/29/17.
//  Copyright © 2017 Learning. All rights reserved.
//

import UIKit

extension UIView {
    func screenShot() -> UIImage? {
        var image: UIImage?
        UIGraphicsBeginImageContext(self.bounds.size)
        if let currentContext = UIGraphicsGetCurrentContext() {
            layer.render(in: currentContext)
            image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return image
    }
}
