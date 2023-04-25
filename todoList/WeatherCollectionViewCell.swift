//
//  WeatherCollectionViewCell.swift
//  todoList
//
//  Created by perennial on 24/04/23.
//  Copyright © 2023 perennial. All rights reserved.
//

import UIKit

class WeatherCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = String(describing:WeatherCollectionViewCell.self)
    
    @IBOutlet var timeLabel: UILabel!
    
    
    @IBOutlet var temperaturelabel: UILabel!
    
    func convertDateFormater(date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        
        guard let date = dateFormatter.date(from: date) else {
            assert(false, "no date from string")
            return ""
        }
        
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        let timeStamp = dateFormatter.string(from: date)
        
        return timeStamp
    }
    
    func setupWeather(time:String,weather:Float){
     
        
        self.timeLabel.text = self.convertDateFormater(date: time)
        self.temperaturelabel.text = String(weather) + " C"
    }
    
}
