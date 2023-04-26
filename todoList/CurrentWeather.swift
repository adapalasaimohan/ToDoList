//
//  CurrentWeather.swift
//  todoList
//
//  Created by perennial on 24/04/23.
//  Copyright © 2023 perennial. All rights reserved.
//


import Foundation


struct WeatherFeed: Codable{

    var latitude:Float = 0
    var longitude:Float = 0
    var generationtime_ms:Float = 0
    var utc_offset_seconds:Int = 0
    var timezone:String = ""
    var timezone_abbreviation:String = ""
    var elevation:Float = 0
    var hourly_units:HourlyUnit
    var hourly:Hourly
    
}

struct Hourly: Codable{
    
    var time:[String] = [""]
    var temperature_2m:[Float] = [0]
    var rain:[Float] = [0]
    
}

struct HourlyUnit: Codable{
    
    var time:String = ""
    var temperature_2m:String = ""
    var rain:String = ""
    
}
