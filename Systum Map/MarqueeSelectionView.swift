//
//  MarqueeSelectionView.swift
//  Systum Map
//
//  Created by Nguyen Huynh on 12/11/16.
//  Copyright © 2016 nguyenh. All rights reserved.
//

import UIKit

class MarqueeSelectionView: UIView {
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var resizeButton: UIButton!

  override func awakeFromNib() {
    super.awakeFromNib()
    let movingGesture = UIPanGestureRecognizer(target: self, action: #selector(contentViewPan))
    contentView.addGestureRecognizer(movingGesture)

    let resizeGesture = UIPanGestureRecognizer(target: self, action: #selector(resizeButtonPan))
    resizeButton.addGestureRecognizer(resizeGesture)
  }

  func contentViewPan(gesture: UIPanGestureRecognizer) {
    if let gView = gesture.view {
      let center = gView.center
      if gesture.state == .Began || gesture.state == .Changed {
        let translation = gesture.translationInView(self)
        gView.center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        gesture.setTranslation(CGPoint(x: 0, y: 0), inView: self)
      } else if gesture.state == .Ended {
        var adjustedX = center.x + gView.bounds.width / 2 > bounds.width ? bounds.width - gView.bounds.width / 2 : center.x // right
        adjustedX = center.x - gView.bounds.width / 2 < 0 ? gView.bounds.width / 2 : adjustedX // left
        var adjustedY = center.y + gView.bounds.height / 2 > bounds.height ? bounds.height - gView.bounds.height / 2 : center.y // bottom
        adjustedY = center.y - gView.bounds.height / 2 < 0 ? gView.bounds.height / 2 : adjustedY // top

        let adjustedPoint = CGPoint(x: adjustedX, y: adjustedY)
        gView.center = adjustedPoint
        gesture.setTranslation(CGPoint(x: 0, y: 0), inView: self)
      }
    }
  }

  func resizeButtonPan(gesture: UIPanGestureRecognizer) {
    if gesture.state == .Began || gesture.state == .Changed {
      let translation = gesture.translationInView(self)
      gesture.view?.center = CGPoint(x: gesture.view!.center.x + translation.x, y: gesture.view!.center.y + translation.y)
      gesture.setTranslation(CGPoint(x: 0, y: 0), inView: self)
    }
  }
}
