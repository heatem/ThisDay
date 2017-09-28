//
//  WeatherPeekViewController.swift
//  ThisDay
//
//  Created by Heather Mason on 9/8/17.
//  Copyright © 2017 HApps. All rights reserved.
//

import UIKit

class WeatherPeekViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let defaults:UserDefaults = UserDefaults.standard
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var highTempLabel: UILabel!
    @IBOutlet weak var lowTempLabel: UILabel!
    @IBOutlet weak var weatherDescriptionLabel: UILabel!
    @IBOutlet weak var precipitationChanceLabel: UILabel!
    
    var dailyHighTemp = ""
    var dailyLowTemp = ""
    var weatherDescription = ""
    var precipitationChance = ""

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "Cell"
        
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: cellIdentifier)
        }
        
        var weekday = ""
        var dailyHigh = ""
        var dailyLow = ""
        var precipChance = ""
        
        if let time = (((weatherData["daily"] as? NSDictionary)?["data"] as? NSArray)?[indexPath.row + 1] as? NSDictionary)?["time"] as? Int {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            dateFormatter.string(from: Date() as Date)
            
            weekday = dateFormatter.string(from: NSDate(timeIntervalSince1970: TimeInterval(time)) as Date)
        }
        
        if let precipChanceDouble = (((weatherData["daily"] as? NSDictionary)?["data"] as? NSArray)?[indexPath.row + 1] as? NSDictionary)?["precipProbability"] as? Double,
            let high = (((weatherData["daily"] as? NSDictionary)?["data"] as? NSArray)?[indexPath.row + 1] as? NSDictionary)?["temperatureHigh"] as? Double,
            let low = (((weatherData["daily"] as? NSDictionary)?["data"] as? NSArray)?[indexPath.row + 1] as? NSDictionary)?["temperatureLow"] as? Double {
            
            precipChance = String(Int(round(precipChanceDouble * 100)))
            dailyHigh = String(Int(round(high)))
            dailyLow = String(Int(round(low)))
            
        }
        
        cell?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        cell?.textLabel?.textColor = UIColor.white
        cell?.textLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 14.00, weight: 1.00)
        cell?.detailTextLabel?.textColor = UIColor.white
        cell?.detailTextLabel?.font = UIFont.monospacedDigitSystemFont(ofSize: 14.00, weight: 1.00)
        
        cell?.textLabel?.textAlignment = .left
        cell?.textLabel?.text = weekday
        
     
        
        cell?.detailTextLabel?.textAlignment = .right
        let precipIcon = NSMutableAttributedString(string: "\(dailyHigh)°F | \(dailyLow)°F | r: \(precipChance)%")
        precipIcon.addAttribute(NSFontAttributeName, value: UIFont(name: "ThisDay", size: 14)!, range: NSMakeRange(0,precipIcon.length))
        cell?.detailTextLabel?.attributedText = precipIcon
        
        return cell!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let savedImageData:Data = defaults.data(forKey: "backgroundImageData") {
            backgroundImage.image = UIImage(data: savedImageData as Data)
        }
        
        
        if let dailyHigh = (((weatherData["daily"] as? NSDictionary)?["data"] as? NSArray)?[0] as? NSDictionary)?["temperatureHigh"] as? Double,
            let dailyLow = (((weatherData["daily"] as? NSDictionary)?["data"] as? NSArray)?[0] as? NSDictionary)?["temperatureLow"] as? Double,
            let weatherDesc = (((weatherData["daily"] as? NSDictionary)?["data"] as? NSArray)?[0] as? NSDictionary)?["summary"] as? String,
            let precipChance = (((weatherData["daily"] as? NSDictionary)?["data"] as? NSArray)?[0] as? NSDictionary)?["precipProbability"] as? Double {
            dailyHighTemp = String(Int(round(dailyHigh)))
            dailyLowTemp = String(Int(round(dailyLow)))
            weatherDescription = weatherDesc
            precipitationChance = String(Int(precipChance * 100))
        }

        highTempLabel.text = "\(dailyHighTemp)°F"
        lowTempLabel.text = "\(dailyLowTemp)°F"
        weatherDescriptionLabel.text = weatherDescription
        precipitationChanceLabel.text = "Precipitation: \(precipitationChance)%"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
