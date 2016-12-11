//
//  ViewController.swift
//  Systum Map
//
//  Created by Nguyen Huynh on 12/10/16.
//  Copyright © 2016 nguyenh. All rights reserved.
//

import UIKit
import MapKit

class CustomPolygon: MKPolygon {
  var selected = false
  var fillColor: UIColor {
    get {
      let color = selected ? UIColor.greenColor() : UIColor.cyanColor()
      return color.colorWithAlphaComponent(0.3)
    }
  }
  var strokeColor: UIColor {
    get {
      return UIColor.blueColor().colorWithAlphaComponent(0.7)
    }
  }
}

class ViewController: UIViewController {
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var textView: UITextView!

  private let initialLocation = CLLocation(latitude: 39.0119, longitude: -98.4842)
  private let regionRadius: CLLocationDistance = 4000000 // meters

  private var selectingRegions = false
  private var marqueeView: MarqueeSelectionView!

  override func viewDidLoad() {
    super.viewDidLoad()
    centerMapAtLocation(initialLocation)
    mapView.addOverlays(usPolygons())
    initializeTapGesture()
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    if marqueeView == nil {
      marqueeView = MarqueeSelectionView(frame: mapView.frame)
      marqueeView.delegate = self
    }
  }

  @IBAction func selectButtonPressed(sender: AnyObject) {
    if selectingRegions {
      marqueeView.removeFromSuperview()
      (sender as? UIButton)?.setTitle("Select", forState: .Normal)
    } else {
      view.addSubview(marqueeView)
      (sender as? UIButton)?.setTitle("Done", forState: .Normal)
    }
    selectingRegions = !selectingRegions
  }

  func convertFromRegion(region: MKCoordinateRegion) -> MKMapRect {
    let a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
      region.center.latitude + region.span.latitudeDelta / 2,
      region.center.longitude - region.span.longitudeDelta / 2));
    let b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
      region.center.latitude - region.span.latitudeDelta / 2,
      region.center.longitude + region.span.longitudeDelta / 2));
    return MKMapRectMake(min(a.x,b.x), min(a.y,b.y), abs(a.x-b.x), abs(a.y-b.y));
  }

  func intersect(rect: CGRect) {
    let region = mapView.convertRect(rect, toRegionFromView: mapView)
    let mapRect = convertFromRegion(region)
    var overlaysToUpdate: [MKOverlay] = []
    for overlay in mapView.overlays {
      if let polygonOverlay = overlay as? CustomPolygon {
        polygonOverlay.selected = false
        if polygonOverlay.intersectsMapRect(mapRect) {
          polygonOverlay.selected = true
          overlaysToUpdate.append(polygonOverlay)
        }
      }
    }

    let overlays = mapView.overlays
    //Refresh the overlays without refresh the whole map view
    mapView.removeOverlays(overlays)
    mapView.addOverlays(overlays)
  }

  func handleMapTap(tap: UIGestureRecognizer) {
    let tapPoint = tap.locationInView(mapView)
    let pointCoor2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
    let mapPoint = MKMapPointForCoordinate(pointCoor2D)
    let mapPointAsCGPoint = CGPoint(x: mapPoint.x, y: mapPoint.y)

    for overlay in mapView.overlays {
      if let polygon = overlay as? CustomPolygon {
        let mutablePathRef = CGPathCreateMutable()
        let mkMapPoints = polygon.points()

        for index in 0..<polygon.pointCount {
          let x = CGFloat(mkMapPoints[index].x)
          let y = CGFloat(mkMapPoints[index].y)
          if index == 0 {
            CGPathMoveToPoint(mutablePathRef, nil, x, y)
          } else {
            CGPathAddLineToPoint(mutablePathRef, nil, x, y)
          }
        }

        if CGPathContainsPoint(mutablePathRef, nil, mapPointAsCGPoint, false) {
          textView.text = textView.text + "\n \(polygon.title!)"
          polygon.selected = !polygon.selected
          mapView.removeOverlay(polygon)
          mapView.addOverlay(polygon)
          break
        }
      }
    }
  }
}

extension ViewController: MKMapViewDelegate {
  func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
    if let polygon = overlay as? CustomPolygon {
      let renderer = MKPolygonRenderer(overlay: polygon)
      renderer.strokeColor = polygon.strokeColor
      renderer.fillColor = polygon.fillColor
      renderer.lineWidth = 2
      return renderer
    }
    return MKPolygonRenderer()
  }
}

extension ViewController: MarqueeSelectionViewDelegate {
  func updateFrame(frame: CGRect) {
    intersect(frame)
  }
}

// Utilities
extension ViewController {
  private func initializeTapGesture() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap))
    tap.cancelsTouchesInView = false
    tap.numberOfTapsRequired = 1

    mapView.addGestureRecognizer(tap)
  }

  private func usPolygons() -> [CustomPolygon] {
    //Local file must exist
    var polygons: [CustomPolygon] = []
    let usStatesJSONPath = NSBundle.mainBundle().pathForResource("us_states", ofType: "json")!
    if let usStatesData = NSData(contentsOfFile: usStatesJSONPath), parsedJSON = try? NSJSONSerialization.JSONObjectWithData(usStatesData, options: .AllowFragments) {
      let states = parsedJSON.valueForKeyPath("states") as! NSArray
      var stateCount = 0
      for state in states {
        stateCount += 1

        var polygonPoints: [CLLocationCoordinate2D] = []
        let points = state.valueForKeyPath("point") as! NSArray
        for point in points {
          if let pointDict = point as? NSDictionary {
            let lat = pointDict["latitude"]!.doubleValue!
            let long = pointDict["longitude"]!.doubleValue!
            polygonPoints.append(CLLocationCoordinate2D(latitude: lat, longitude: long))
          }
        }

        let polygon = CustomPolygon(coordinates: &polygonPoints, count: polygonPoints.count)
        polygon.title = state.valueForKeyPath("name") as? String
        polygons.append(polygon)
      }
    }
    return polygons
  }

  private func centerMapAtLocation(location: CLLocation) {
    mapView.centerCoordinate = initialLocation.coordinate
    mapView.setZoomLevel(5)
  }
}