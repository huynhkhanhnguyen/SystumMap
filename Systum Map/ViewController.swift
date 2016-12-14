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
  var subPolygons: [CustomPolygon] = []
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

  private var selectingRegions = false
  private var marqueeView: MarqueeSelectionView!
  private var overlayDict: [String: [CustomPolygon]] = [:]

  override func viewDidLoad() {
    super.viewDidLoad()
    centerMapAtLocation(initialLocation)
    initializeMapOverlays()
    initializeTapGesture()
  }

  private func initializeMapOverlays() {
    let mapBoundaryParser = CountryJSONParser()
    let supportedCountries = ["England", "Wales", "Scotland", "Northern Ireland", "Isle Of Man", "Canada"]

    for country in supportedCountries {
      let fileName = country.stringByReplacingOccurrencesOfString(" ", withString: "")
      let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(fileName, ofType: "json")!)!
      let polygons = mapBoundaryParser.parseData(data, countryName: country)
      mapView.addOverlays(polygons)
      overlayDict[country] = polygons
    }
    
    //US is a special case with states
    let mapPolygons = usPolygons()
    if let caliPolygons = mapPolygons.filter({ $0.title == "California" }).first {
      caliPolygons.subPolygons = loadCountyPolygonsForState("CA")
    }
    overlayDict["US"] = mapPolygons
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
      updateFrame(marqueeView.contentView.frame)
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

  func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    for item in overlayDict {
      //Remove all polygons
      let subPolygons = item.1.flatMap { $0.subPolygons }
      mapView.removeOverlays(item.1)
      mapView.removeOverlays(subPolygons)

      if mapView.zoomLevel() > 7 {
        //In detail zoom, we add counties polygons
        mapView.addOverlays(subPolygons)
      } else {
        //In futher zoom, we add countries & states polygon
        mapView.addOverlays(item.1)
      }
    }
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

  private func loadCountyPolygonsForState(_: String) -> [CustomPolygon] {
    let counties = ["Los Angeles CA", "Orange CA", "San Diego CA", "Riverside CA", "San Bernardino CA", "Santa Clara CA", "Alameda CA", "Sacramento CA", "Contra Costa CA", "Fresno CA", "Ventura CA", "San Francisco CA", "Kern CA", "San Mateo CA", "San Joaquin CA", "Stanislaus CA", "Sonoma CA", "Tulare CA", "Solano CA", "Monterey CA", "Santa Barbara CA", "Placer CA", "San Luis Obispo CA", "Santa Cruz CA", "Merced CA", "Marin CA", "Butte CA", "Yolo CA", "El Dorado CA", "Shasta CA", "Imperial CA", "Kings CA", "Madera CA", "Napa CA", "Humboldt CA", "Nevada CA", "Sutter CA", "Mendocino CA", "Yuba CA", "Lake CA", "Tehama CA", "Tuolumne CA", "San Benito CA", "Calaveras CA", "Siskiyou CA", "Amador CA", "Lassen CA", "Del Norte CA", "Glenn CA", "Plumas CA", "Colusa CA", "Mariposa CA", "Inyo CA", "Trinity CA", "Mono CA", "Modoc CA", "Sierra CA", "Alpine CA"]
    var polygons: [CustomPolygon] = []

    for county in counties {
      let countyFileName = county.stringByReplacingOccurrencesOfString(" ", withString: "")
      let usStatesJSONPath = NSBundle.mainBundle().pathForResource(countyFileName, ofType: "json")!
      var polygonPoints: [CLLocationCoordinate2D] = []

      if let usStatesData = NSData(contentsOfFile: usStatesJSONPath), parsedJSON = try? NSJSONSerialization.JSONObjectWithData(usStatesData, options: .AllowFragments) {
        if let points = parsedJSON.valueForKeyPath("polygonpoints") as? [[String]] {
          for point in points {
            if point.count == 2 {
              if let lon = Double(point[0]), let lat = Double(point[1]) {
                polygonPoints.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
              }
            }
          }
          let polygon = CustomPolygon(coordinates: &polygonPoints, count: polygonPoints.count)
          polygon.title = county
          polygons.append(polygon)
        }
      }
    }

    return polygons
  }

  private func centerMapAtLocation(location: CLLocation) {
    mapView.centerCoordinate = initialLocation.coordinate
    mapView.setZoomLevel(5)
  }
}