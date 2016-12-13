//
//  CountryJSONParser.swift
//  Systum Map
//
//  Created by Nguyen Huynh on 12/13/16.
//  Copyright © 2016 nguyenh. All rights reserved.
//

import MapKit

class CountryJSONParser {
  func parseData(data: NSData, countryName: String) -> [CustomPolygon] {
    var result: [CustomPolygon] = []
    if let dataJSON = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments), dataDict = dataJSON as? NSDictionary {
      if let coordinates = ((dataDict["footprints"] as? NSArray)?[0]["geometry"])?["coordinates"] as? NSArray {
        for coordinate in coordinates {
          if let coordinate = coordinate as? NSArray where coordinate.count > 0 {
            for coordinateSubArr in coordinate {
              if let longLatPairs = coordinateSubArr as? [[Double]] {
                var polygonPoints: [CLLocationCoordinate2D] = []
                for pair in longLatPairs {
                  if pair.count == 2 {
                    polygonPoints.append(CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0]))
                  }
                }
                let polygon = CustomPolygon(coordinates: &polygonPoints, count: polygonPoints.count)
                polygon.title = countryName
                result.append(polygon)
              }
            }
          }
        }
      }
    }

    return result
  }
}
