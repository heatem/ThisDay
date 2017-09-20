//
//  ViewController.swift
//  ThisDay
//
//  Created by Heather Mason on 7/28/17.
//  Copyright © 2017 HApps. All rights reserved.
//

import UIKit
import CoreLocation

var weatherData:AnyObject = {} as AnyObject

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let defaults:UserDefaults = UserDefaults.standard
    
    @IBOutlet weak var xCenterConstraint: NSLayoutConstraint!
    
    var locationManager = CLLocationManager()
    var latitude: CLLocationDegrees = 0.00
    var longitude: CLLocationDegrees = 0.00
    @IBOutlet weak var cityLabel: UILabel!
    
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBOutlet weak var darkSkyLabel: UIButton!
    @IBAction func goToDarkSky(_ sender: Any) {
        let url = URL(string: "https://darksky.net/poweredby/")
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
    }
    
    @IBOutlet weak var backgroundImage: UIImageView!
    var imageRetrievedDate:String = ""
    
    
    @IBOutlet weak var photoCredStartLabel: UILabel!
    @IBOutlet weak var photoCredDividerLabel: UILabel!
    @IBOutlet weak var photoCredEndLabel: UILabel!
    
    @IBOutlet weak var unsplashButtonLabel: UIButton!
    @IBAction func unsplashLinkButton(_ sender: Any) {
        let url = URL(string: "https://unsplash.com/?utm_source=ThisDay&utm_medium=referral&utm_campaign=api-credit")
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
    }
    @IBOutlet weak var photoIconLabel: UILabel!
    var photographerProfile = ""
    @IBOutlet weak var photographerButtonLabel: UIButton!
    @IBAction func photographerLinkButton(_ sender: Any) {
        if let photographerLink = defaults.string(forKey: "photographerUrl") {
            photographerProfile = photographerLink
        }
        let url = URL(string: "\(photographerProfile)/?utm_source=ThisDay&utm_medium=referral&utm_campaign=api-credit")
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
    }
    
    @IBOutlet weak var timeLabel: UILabel!
    let dateFormatter = DateFormatter()
    @IBOutlet weak var dateLabel: UILabel!
    let date = Date()
    let calendar = Calendar.current
    
    @IBOutlet weak var checkboxIcon: UIButton!
    @IBOutlet weak var mainFocusLabel: UILabel!
    @IBOutlet weak var mainFocusField: UITextField!
    var focus: String = ""
    
    @IBAction func checkboxButton(_ sender: Any) {
        if mainFocusField.isHidden {
            checkboxIcon.isSelected = true
            let completedFocus = NSMutableAttributedString(string: focus)
            completedFocus.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, completedFocus.length))
            mainFocusLabel.attributedText = completedFocus
            
            UIView.animate(withDuration: 1, animations: {
                self.checkboxIcon.alpha = 0
                self.mainFocusLabel.alpha = 0
                self.focus = ""
                self.defaults.removeObject(forKey: "primaryFocus")
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                self.checkboxIcon.isSelected = false
                self.checkboxIcon.alpha = 1
                self.mainFocusField.text = self.focus
                self.mainFocusField.placeholder = "Enter your focus"
                self.mainFocusField.isHidden = false
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        mainFocusField.delegate = self
        
        darkSkyLabel.isHidden = true
        temperatureLabel.alpha = 0
        cityLabel.alpha = 0
        
        photographerButtonLabel.isHidden = true
        unsplashButtonLabel.isHidden = true
        
        if let savedImageData:Data = defaults.data(forKey: "backgroundImageData") {
            if let storedDateForImage = defaults.string(forKey: "imageRetrievedOn") {
                if getDate() == storedDateForImage {
                    backgroundImage.image = UIImage(data: savedImageData as Data)
                    if let photographer = defaults.string(forKey: "photographer") {
                        photographerButtonLabel.setTitle(photographer, for: [])
                        photographerButtonLabel.isHidden = false
                        unsplashButtonLabel.isHidden = false
                        photoCredStartLabel.alpha = 0.5
                        photoCredDividerLabel.alpha = 0.5
                        photoCredEndLabel.alpha = 0.5
                        photoIconLabel.alpha = 0.5
                    }
                    if let photographerUrl = defaults.string(forKey: "photographerProfile") {
                        photographerProfile = photographerUrl
                    }
                } else {
                    getImage()
                }
            } else {
                getImage()
            }
        } else {
            getImage()
        }
        
        // TODO: enable switching between time remaining in the day
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.displayTime), userInfo: nil, repeats: true)
        
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.displayDate), userInfo: nil, repeats: true)

        if let savedFocus:String = defaults.string(forKey: "primaryFocus") {
            focus = savedFocus
        }
        
        if focus == "" {
            mainFocusLabel.isHidden = true
            mainFocusField.isHidden = false
        } else {
            mainFocusLabel.isHidden = false
            mainFocusLabel.text = focus
            mainFocusField.isHidden = true
        }
        
        // TODO: Store completed tasks in an array
        // TODO: Add an option to delete without marking complete (long press to see a menu with option to delete?)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        
        // Peek
        if traitCollection.forceTouchCapability == UIForceTouchCapability.available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("Force Touch not available.")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        updateWeather()
        
    }
    
    func applicationDidBecomeActive(notification: NSNotification) {
        locationManager.requestLocation()
    }
    
    func getImage() {
        if let url = URL(string: "https://api.unsplash.com/photos/random?client_id=\(UNSPLASH_KEY)&query=landscapes") {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error == nil {
                    if let urlContent = data {
                        do {
                            let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
                            
                            
                            if let imageInfoName = (jsonResult["user"] as? NSDictionary)?["name"] as? String {
                                DispatchQueue.main.async {
                                    self.photographerButtonLabel.setTitle(imageInfoName, for: [])
                                    self.photographerButtonLabel.isHidden = false
                                    self.unsplashButtonLabel.isHidden = false
                                    self.photoCredStartLabel.alpha = 0.5
                                    self.photoCredDividerLabel.alpha = 0.5
                                    self.photoCredEndLabel.alpha = 0.5
                                    self.photoIconLabel.alpha = 0.5
                                }
                                self.defaults.set(imageInfoName, forKey: "photographer")
                            } else {
                                DispatchQueue.main.async {
                                    self.photographerButtonLabel.setTitle("", for: [])
                                    self.photographerButtonLabel.isHidden = false
                                }
                            }
                            
                            if let photographerUrl = ((jsonResult["user"] as? NSDictionary)?["links"] as? NSDictionary)?["html"] as? String {
                                self.photographerProfile = photographerUrl
                                self.defaults.set(photographerUrl, forKey: "photographerProfile")
                            }
                            
                            if let unsplashImageUrlString = (jsonResult["urls"] as? NSDictionary)?["regular"] as? String {
                                if let unsplashImageUrl = NSURL(string: unsplashImageUrlString) {
                                    if let data = NSData(contentsOf: unsplashImageUrl as URL) {
                                        if let unsplashImage = UIImage(data: data as Data) {
                                            DispatchQueue.main.async {
                                                self.backgroundImage.image = unsplashImage
                                            }
                                            self.defaults.set(data, forKey: "backgroundImageData")

                                            self.dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
                                            self.imageRetrievedDate = self.dateFormatter.string(from: Date() as Date)
                                            self.defaults.set(self.imageRetrievedDate, forKey: "imageRetrievedOn")
                                        }
                                    }
                                }
                            } else {
                                self.view.backgroundColor = .black
                                self.photoIconLabel.isHidden = true
                            }
                        } catch {
                            
                        }
                    }
                }
            }
            task.resume()
        } else {
            view.backgroundColor = .black
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if (notification.userInfo != nil) {
            self.xCenterConstraint.constant -= 100
            UIView.animate(withDuration: 0.25, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if (notification.userInfo != nil) {
            self.xCenterConstraint.constant = 0
            UIView.animate(withDuration: 0.25, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation: CLLocation = locations[0]
        latitude = userLocation.coordinate.latitude
        longitude = userLocation.coordinate.longitude
        
        if locations.first != nil {
            CLGeocoder().reverseGeocodeLocation(userLocation) { (placemarks, error) in
                if error == nil {
                    if let placemark = placemarks?[0] {
                        var city = ""
                        
                        if placemark.subAdministrativeArea != nil {
                            city = placemark.subAdministrativeArea!
                        }
                        
                        self.cityLabel.text = city
                        self.cityLabel.alpha = 1
                    }
                }
            }
        }
        updateWeather()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    
    func updateWeather() {
        if latitude != 0.00 {
            if let url = URL(string: "https://api.darksky.net/forecast/\(DARKSKY_KEY)/\(latitude),\(longitude)?exclude=minutely,flags") {
                print(url)
                let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                    if let urlContent = data, error == nil {
                            do {
                                let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
//                                print(jsonResult)
                                weatherData = jsonResult
                                if
                                    let currentWeather = jsonResult["currently"] as? [String: Any],
                                    let temperature = currentWeather["temperature"] as? Double {
                                        let temp = String(Int(round(temperature)))
                                        if temp != "" {
                                            DispatchQueue.main.async {
                                                self.temperatureLabel.text = temp + "°F"
                                                self.temperatureLabel.alpha = 1
                                                self.darkSkyLabel.isHidden = false
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                self.temperatureLabel.text = "--°F"
                                                self.temperatureLabel.alpha = 1
                                            }
                                        }
                                    }
                                
                                // trying to figure out how to get the daily high/low here.
//                                if let dailyHigh = (((jsonResult["daily"] as? NSDictionary)?["data"] as? NSArray)?[0] as? NSDictionary)?["temperatureHigh"] as? Double,
//                                let dailyLow = (((jsonResult["daily"] as? NSDictionary)?["data"] as? NSArray)?[0] as? NSDictionary)?["temperatureLow"] as? Double,
//                                    let weatherDesc = (((jsonResult["daily"] as? NSDictionary)?["data"] as? NSArray)?[0] as? NSDictionary)?["summary"] as? String,
//                                let precipChance = (((jsonResult["daily"] as? NSDictionary)?["data"] as? NSArray)?[0] as? NSDictionary)?["precipProbability"] as? Int {
//                                    
//                                    dailyHighTemp = String(Int(round(dailyHigh)))
//                                    dailyLowTemp = String(Int(round(dailyLow)))
//                                    weatherDescription = weatherDesc
//                                    precipitationChance = String(precipChance)
//                                    print(dailyHighTemp)
//                                    print(dailyLowTemp)
//                                    print(weatherDescription)
//                                    print(precipitationChance)
//                                }
                                
                                // end trying to get daily high/low
                            } catch {
                                print("error getting temp")
                            }
                        }
                }
                task.resume()
            }
        }
    }

    func displayTime() {
        dateFormatter.timeStyle = .short
        let time = dateFormatter.string(from: Date() as Date)
        timeLabel.text = time
    }
    
    func getDate() -> String {
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        return dateFormatter.string(from: Date() as Date)
    }
    
    func displayDate() {
        dateLabel.text = getDate()
    }
    
        
    func setFocus() {
        if mainFocusField.text != "" {
            if let mainFocus = mainFocusField.text {
                focus = mainFocus
                mainFocusLabel.text = focus
                mainFocusLabel.isHidden = false
                mainFocusLabel.alpha = 1
                mainFocusField.isHidden = true
                defaults.set(focus, forKey: "primaryFocus")
            }
            self.view.endEditing(true)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        setFocus()
        resignFirstResponder()
        self.view.endEditing(true)
        return true
    }
}

extension ViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let weatherPeekViewController = storyboard?.instantiateViewController(withIdentifier: "weatherPeekViewController") as? WeatherPeekViewController
        
        return weatherPeekViewController
    }
    
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
    }
    
}

