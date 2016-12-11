//
//  UIView+Extension.swift
//  Systum Map
//
//  Created by Nguyen Huynh on 12/11/16.
//  Copyright © 2016 nguyenh. All rights reserved.
//

import UIKit

extension UIView {
  class func initFromNib() -> UIView {
    let mainBundle = NSBundle.mainBundle()
    let className  = NSStringFromClass(self).componentsSeparatedByString(".").last ?? ""
    if ( mainBundle.pathForResource(className, ofType: "nib") != nil ) {
      let objects = mainBundle.loadNibNamed(className, owner: self, options: [:])
      for object in objects {
        if let view = object as? UIView {
          return view
        }
      }
    }
    return UIView(frame: CGRectZero)
  }
}