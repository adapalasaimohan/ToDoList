//
//  LocationViewModel.swift
//  todoList
//
//  Created by perennial on 26/04/23.
//  Copyright © 2023 perennial. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class WeatherViewModel: NSObject,CLLocationManagerDelegate {
    var weather:WeatherFeed?
    let manager = CLLocationManager()
    var coordinates = CLLocationCoordinate2D(latitude: 16.0686, longitude: 80.5482)
    override init() {
        super.init()
        manager.delegate = self
        let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
                if status == CLAuthorizationStatus.notDetermined || status == CLAuthorizationStatus.denied || status == CLAuthorizationStatus.restricted
                {
                    manager.requestAlwaysAuthorization()
                }
        self.getLocation()
    }
   
    
    func fetch(urlString:String)
    {
        if let url = URL(string: urlString){   //unwrap url
            
        URLSession
                .shared
                .dataTask(with: url) { [weak self](data, response,error) in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 400 {
                            if error == nil {
                                let decoder = JSONDecoder() //using json decoder to do the work for us
                                
                                if let data = data,
                                   let feed = try? decoder.decode(WeatherFeed.self, from: data){
                                    self?.weather = feed
                                    
                                    NotificationCenter.default.post(name: Notification.Name("weatherFeedReceived"), object: nil)
                                }else{
                                    print("Failed to decode the Weather JSON")
                                   
                                    //print("failed to decode")
                                }
                                
                            }
                        } else{
                           
                            print(error?.localizedDescription)
                        }
                              }
                   
                    
                    
                    
                }.resume()
        }
        
        
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("location changed")
        
        if #available(iOS 14.0, *) {
            switch manager.authorizationStatus{
            case .notDetermined:
                break
            case .authorizedWhenInUse, .authorizedAlways:
                getLocation()
            default:
                print("Go to settings and allow location services for this app.")
                
            }
        } else {
            // Fallback on earlier versions
        }
        getLocation()
    }
    
    
    func getLocation(){
        guard let loc = manager.location?.coordinate else { return }
        
        coordinates = loc
        
        let date = Date()
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let theDate = dateFormatter.string(from: date)
        
        self.fetch(urlString:"https://api.open-meteo.com/v1/forecast?latitude=\(coordinates.latitude)&longitude=\(coordinates.longitude)&hourly=temperature_2m,rain&start_date=\(theDate)&end_date=\(theDate)")

    }
}
