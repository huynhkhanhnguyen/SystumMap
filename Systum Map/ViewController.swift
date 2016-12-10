//
//  ViewController.swift
//  Systum Map
//
//  Created by Nguyen Huynh on 12/10/16.
//  Copyright © 2016 nguyenh. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
  private let initialLocation = CLLocation(latitude: 39.0119, longitude: -98.4842)
  private let regionRadius: CLLocationDistance = 4000000 // meters
  @IBOutlet weak var mapView: MKMapView!

  override func viewDidLoad() {
    super.viewDidLoad()
    centerMapAtLocation(initialLocation)
    mapView.addOverlays(usMKPolygons())
  }

  private func usMKPolygons() -> [MKPolygon] {
    //Local file must exist
    var mkPolygons: [MKPolygon] = []
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

        let mkPolygon = MKPolygon(coordinates: &polygonPoints, count: polygonPoints.count)
        mkPolygon.title = state.valueForKeyPath("name") as? String
        mkPolygons.append(mkPolygon)
      }
    }
    return mkPolygons
  }

  private func centerMapAtLocation(location: CLLocation) {
    let region = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, regionRadius, regionRadius)
    mapView.setRegion(region, animated: true)
  }

  func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
    if let polygon = overlay as? MKPolygon {
      let renderer = MKPolygonRenderer(overlay: polygon)
      renderer.strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.7)
      renderer.fillColor = UIColor.cyanColor().colorWithAlphaComponent(0.3)
      renderer.lineWidth = 2
      return renderer
    }
    return MKPolygonRenderer()
  }
}

