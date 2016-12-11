//
//  MarqueeSelectionView.swift
//  Systum Map
//
//  Created by Nguyen Huynh on 12/11/16.
//  Copyright © 2016 nguyenh. All rights reserved.
//

import UIKit

class MarqueeSelectionView: UIView {
  private let contentView = UIView()
  private let resizeButton = UIButton()
  private let buttonSize = CGSize(width: 50, height: 50)
  private let mininumContentSize = CGSize(width: 200, height: 200)

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(contentView)
    addSubview(resizeButton)

    contentView.frame = CGRect(origin: center, size: mininumContentSize)
    contentView.alpha = 0.4
    contentView.backgroundColor = UIColor.blackColor()

    resizeButton.setBackgroundImage(UIImage(named: "HandCursor"), forState: .Normal)
    updateResizeButtonFrame()

    let movingGesture = UIPanGestureRecognizer(target: self, action: #selector(contentViewPan))
    contentView.addGestureRecognizer(movingGesture)

    let resizeGesture = UIPanGestureRecognizer(target: self, action: #selector(resizeButtonPan))
    resizeButton.addGestureRecognizer(resizeGesture)
  }

  private func updateResizeButtonFrame() {
    let resizeOrigin = CGPoint(x: contentView.frame.maxX - buttonSize.width + 10, y: contentView.frame.maxY - buttonSize.height - 10)
    resizeButton.frame = CGRect(origin: resizeOrigin, size: buttonSize)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func contentViewPan(gesture: UIPanGestureRecognizer) {
    if let gView = gesture.view {
      let center = gView.center
      if gesture.state == .Began || gesture.state == .Changed {
        let translation = gesture.translationInView(self)
        gView.center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
      } else if gesture.state == .Ended {
        var adjustedX = center.x + gView.bounds.width / 2 > bounds.width ? bounds.width - gView.bounds.width / 2 : center.x // right
        adjustedX = center.x - gView.bounds.width / 2 < 0 ? gView.bounds.width / 2 : adjustedX // left
        var adjustedY = center.y + gView.bounds.height / 2 > bounds.height ? bounds.height - gView.bounds.height / 2 : center.y // bottom
        adjustedY = center.y - gView.bounds.height / 2 < 0 ? gView.bounds.height / 2 : adjustedY // top

        let adjustedPoint = CGPoint(x: adjustedX, y: adjustedY)
        gView.center = adjustedPoint
      }

      gesture.setTranslation(CGPoint(x: 0, y: 0), inView: self)
      updateResizeButtonFrame()
    }
  }

  func resizeButtonPan(gesture: UIPanGestureRecognizer) {
    if gesture.state == .Began || gesture.state == .Changed {
      let translation = gesture.translationInView(self)
      let gFrame = contentView.frame
        contentView.frame.size = CGSize(width: gFrame.width + translation.x, height: gFrame.height + translation.y)

    } else if gesture.state == .Ended {
      if contentView.frame.width < mininumContentSize.width || contentView.frame.height < mininumContentSize.height {
        contentView.frame.size = mininumContentSize
      } else {
        if contentView.frame.maxX > frame.width {
          contentView.frame.size = CGSize(width: frame.maxX - contentView.frame.origin.x, height: contentView.frame.height)
        }

        if contentView.frame.maxY > frame.height {
          contentView.frame.size = CGSize(width: contentView.frame.width, height: frame.maxY - contentView.frame.origin.y - 20)
        }
      }
    }
    updateResizeButtonFrame()
    gesture.setTranslation(CGPoint(x: 0, y: 0), inView: self)
  }
}
