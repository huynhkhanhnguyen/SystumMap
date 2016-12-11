//
//  MapView+Extension.swift
//  Systum Map
//
//  Created by Nguyen Huynh on 12/11/16.
//  Copyright © 2016 nguyenh. All rights reserved.
//

import MapKit

extension MKMapView {
  func zoomLevel() -> Int {
    return Int(log2(360.0 * (Double(frame.size.width/256) / region.span.longitudeDelta))) + 1
  }

  func setZoomLevel(zoomLevel: Int, animated: Bool = false) {
    setCenterCoordinate(centerCoordinate, zoomLevel: zoomLevel, animated: animated)
  }

  func setCenterCoordinate(centerCoordinate: CLLocationCoordinate2D, zoomLevel: Int, animated: Bool) {
    let span = MKCoordinateSpanMake(0.0, 360/pow(2, Double(zoomLevel))*Double(frame.size.width)/256.0)
    setRegion(MKCoordinateRegionMake(centerCoordinate, span), animated: animated)
  }
}
