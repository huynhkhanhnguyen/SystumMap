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
    if gesture.state == .Began || gesture.state == .Changed {
      let translation = gesture.translationInView(self)
      gesture.view?.center = CGPoint(x: gesture.view!.center.x + translation.x, y: gesture.view!.center.y + translation.y)
      gesture.setTranslation(CGPoint(x: 0, y: 0), inView: self)
    }
  }

  func resizeButtonPan() {

  }
}
