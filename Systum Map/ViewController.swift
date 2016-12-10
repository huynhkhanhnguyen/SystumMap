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

class ViewController: UIViewController, MKMapViewDelegate {
  private let initialLocation = CLLocation(latitude: 39.0119, longitude: -98.4842)
  private let regionRadius: CLLocationDistance = 4000000 // meters
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var textView: UITextView!

  override func viewDidLoad() {
    super.viewDidLoad()
    centerMapAtLocation(initialLocation)
    mapView.addOverlays(usPolygons())
    initializeTapGesture()
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
    let region = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, regionRadius, regionRadius)
    mapView.setRegion(region, animated: true)
  }

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

