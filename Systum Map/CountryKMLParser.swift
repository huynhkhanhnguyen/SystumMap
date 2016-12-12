//
//  CountryKMLParser.swift
//  Systum Map
//
//  Created by Nguyen Huynh on 12/12/16.
//  Copyright © 2016 nguyenh. All rights reserved.
//

import MapKit

protocol CountryKMLParserDelegate: class {
  func parsedPolygons(polygons: [CustomPolygon])
}

class CountryKMLParser: NSObject {
  weak var delegate: CountryKMLParserDelegate?
  
  private var nsXMLParser: NSXMLParser!
  private var element = ""
  private var superElement = ""
  private var countryName = ""

  private var polygons: [CustomPolygon] = []
  private var polygonPoints: [CLLocationCoordinate2D] = []

  private let countriesXMLPath = NSBundle.mainBundle().pathForResource("countries", ofType: ".kml")!

  override init() {
    super.init()
    nsXMLParser = NSXMLParser(contentsOfURL: NSURL(fileURLWithPath: countriesXMLPath))!
    nsXMLParser.delegate = self
  }

  func parse() {
    nsXMLParser.parse()
  }
}

extension CountryKMLParser: NSXMLParserDelegate {
  @objc func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
    superElement = element
    element = elementName
    if element == "Placemark" {
      polygonPoints = []
      countryName = ""
    }
  }

  @objc func parser(parser: NSXMLParser, foundCDATA CDATABlock: NSData) {
    if element == "name" {
      if let dataString = NSString(data: CDATABlock, encoding: NSUTF8StringEncoding) {
        //<NAME></NAME> = 14 chars
        let range = NSRange(location: 6, length: dataString.length - 14)
        countryName = dataString.substringWithRange(range)

      }
    }
  }

  @objc func parser(parser: NSXMLParser, foundCharacters string: String) {
    if element == "coordinates" && superElement == "LinearRing" {
      let coordinateStrs = string.componentsSeparatedByString(" ")
      for coordinateStr in coordinateStrs {
        let pair = coordinateStr.componentsSeparatedByString(",")

        if pair.count == 2 {
          if let longitude = Double(pair[0]), latitude = Double(pair[1]) {
            polygonPoints.append(CLLocationCoordinate2DMake(latitude, longitude))
          }
        }
      }
    }
  }

  @objc func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    let polygon = CustomPolygon(coordinates: &polygonPoints, count: polygonPoints.count)
    polygon.title = countryName
    polygons.append(polygon)
  }

  func parserDidEndDocument(parser: NSXMLParser) {
    delegate?.parsedPolygons(polygons)
  }
}
