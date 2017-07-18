//
//  ViewController.swift
//  Amble
//
//  Created by Virginia Cook on 6/30/17.
//  Copyright © 2017 VirgLabs. All rights reserved.
//

import UIKit
import GooglePlaces
import Alamofire

class ViewController: UIViewController {

    @IBOutlet var startField: UITextField!
    @IBOutlet var endField: UITextField!
    @IBOutlet var date: UIDatePicker!
    var directions:[Directions] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func pressedGo(_ sender: Any) {
        let latlng = latLngFromAddres(address: "79-81 Hammersmith Rd, London W14 8UZ")
        tubeFromLatLng(latLng: latlng)
    }
    
    func latLngFromAddres(address:String)->LatLng {
        var lat = 0.0
        var long = 0.0
        let parameters1: Parameters = [
            "address":"79-81 Hammersmith Rd, London W14 8UZ",
            "key":"AIzaSyDyLC1WtaNXV_NljCMiUc2AbcSnmLt0-iw"
        ]
        let parameters2: Parameters = [
            "address":address,
            "key":"AIzaSyDyLC1WtaNXV_NljCMiUc2AbcSnmLt0-iw"
        ]
        Alamofire.request("https://maps.googleapis.com/maps/api/geocode/json",parameters: parameters1,encoding: URLEncoding.default).responseJSON { response in
//            print("Request: \(String(describing: response.request))")   // original url request
//            print("Response: \(String(describing: response.response))") // http url response
//            print("Result: \(response.result)")                         // response serialization result
            if let json = response.result.value {
                // print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                //print("Data: \(utf8Text)") // original server data as UTF8 string
            }
            if let json = response.result.value as? [String:Any]{
                if let location1 = (json["results"] as? [[String:Any]]){
                    if let results = location1.first {
                        if let geo = results["geometry"] as? [String:Any]{
                            if let locy = geo["location"] as? [String:Any] {
                                let lat1 = locy["lat"] as? Double
                                if let lat1 = lat1 {
                                    lat = lat1
                                }
                                let long1 = locy["lng"] as? Double
                                if let long1 = long1 {
                                    long = long1
                                }
                                print(lat)
                                print(long)
                            }
                        }
                    }
                }
                print("tube results")
                //self.tubeFromLatLng(latLng: LatLng(setLat:lat,setLong:long))
                self.googleTubes(latLng: LatLng(setLat:lat,setLong:long),latLng2: LatLng(setLat:51.5081,setLong:-0.0972))
                //self.tubes(latLng: LatLng(setLat:lat,setLong:long))
            }
        }
        return LatLng(setLat:lat,setLong:long)
    }
    func googleTubes(latLng:LatLng, latLng2:LatLng) {
        // important info to return
        var line = ""
        var departureStation = ""
        var arrivalStation = ""
        var stops = 0
        
        //let dateString = NSTimeIntervalSince1970(date.date)
        
        let dateString = date.date
        let dateStringString = String(describing: dateString)
        print("datestring")
        print(dateString)
        print(dateString.timeIntervalSince1970)
        
        var latLngString = ""
        latLngString.append(String(latLng.lat))
        latLngString.append(",")
        latLngString.append(String(latLng.long))
        
        var latLngString2 = ""
        latLngString2.append(String(latLng2.lat))
        latLngString2.append(",")
        latLngString2.append(String(latLng2.long))
        
        let parameters: Parameters = [
            "origin": latLngString,
            "destination":latLngString2,
            "mode":"transit",
            "transit_mode":"subway",
            "arrival_time": dateString.timeIntervalSince1970,
            "key":"AIzaSyDP9sJnVUX5bAbPeXGIqiinCW4544TAsM8"
        ]
        Alamofire.request("https://maps.googleapis.com/maps/api/directions/json",parameters: parameters,encoding: URLEncoding.default).responseJSON { response in
//            print("Request: \(String(describing: response.request))")   // original url request
//            print("Response: \(String(describing: response.response))") // http url response
//            print("Result: \(response.result)")                         // response serialization result
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                //print("Data: \(utf8Text)") // original server data as UTF8 string
            }
            // get proper tube line
            if let json = response.result.value as? [String:Any]{
                if let routes = json["routes"] as? [[String:Any]]{
                    if let firstRoute = routes.first {
                        if let legs = firstRoute["legs"] as? [[String:Any]] {
                            if let steps = legs.first?["steps"] as? [[String:Any]] {
                                // TODO: fix hard coding
                                for transitLeg in steps{
                                if let transitLeg = transitLeg as? [String:Any]{
                                    if let transitDetails = transitLeg["transit_details"] as? [String: Any] {
                                        if let tube = transitDetails["line"] as? [String: Any] {
                                            if let tubeName = tube["short_name"] as? String {
                                                line = tubeName
                                            }
                                        }
                                        if let departureStop = transitDetails["departure_stop"] as? [String:Any] {
                                            if let departureName = departureStop["name"] as? String {
                                                departureStation = departureName
                                            }
                                        }
                                        if let arrivalStop = transitDetails["arrival_stop"] as? [String:Any] {
                                            if let arrivalName = arrivalStop["name"] as? String {
                                                arrivalStation = arrivalName
                                            }
                                        }
                                        if let numStops = transitDetails["num_stops"] as? Int {
                                            stops = numStops
                                        }
                                    }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            let route = Tube(setL: line, setD: departureStation, setA: arrivalStation, setS: stops)
            
            self.routeCalculator(tube: route)
            
            // send over to route calculator
        }
    }
    func directionTimesFromTube(tube: String) {
        // figure out how long tube takes to get to destination
        let dateString = date.date
        let dateStringString = String(describing: dateString)
        print("datestring")
        print(dateString)
        print(dateString.timeIntervalSince1970)
        print(tube)
        let newDate = dateString.timeIntervalSince1970+3600
        
        let parameters: Parameters = [
            "origin": tube,
            "destination":"51.5081,-0.0972",
            "mode":"transit",
            "transit_mode":"subway",
            "arrival_time": newDate,
            "key":"AIzaSyDP9sJnVUX5bAbPeXGIqiinCW4544TAsM8"
        ]
        Alamofire.request("https://maps.googleapis.com/maps/api/directions/json",parameters: parameters,encoding: URLEncoding.default).responseJSON { response in
//            print("Request: \(String(describing: response.request))")   // original url request
//            print("Response: \(String(describing: response.response))") // http url response
//            print("Result: \(response.result)")                         // response serialization result
            if let json = response.result.value {
                // print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                //print("Data: \(utf8Text)") // original server data as UTF8 string
            }
            // get proper tube line
            if let json = response.result.value as? [String:Any]{
                // TODO: this
                if let routes = json["routes"] as? [[String:Any]]{
                    if let firstRoute = routes.first {
                        if let legs = firstRoute["legs"] as? [[String:Any]] {
                            if let firstLeg = legs.first {
                                if let departureTime = firstLeg["departure_time"] as? [String:Any] {
                                    print(departureTime["text"])
                                    if let time = departureTime["value"] as? Int {
                                        print(time)
                                        self.walkTimeToTube(tube: tube, datestring: time)
                                    }
                                }
                                if let distance = firstLeg["distance"] as? [String:Any] {
                                    print(distance["text"])
                                    print(distance["value"])
                                }
                                if let duration = firstLeg["duration"] as? [String:Any] {
                                    print(duration["text"])
                                    print(duration["value"])
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    func walkTimeToTube(tube: String, datestring: Int) {
        // figure out how long tube takes to get to destination
        //let dateString = date.date
        //let dateStringString = String(describing: dateString)
        //print("datestring")
        //print(dateString)
        //print(dateString.timeIntervalSince1970)
        
        // TODO: info needed
        let parameters: Parameters = [
            "origin": "51.4950,-0.2112",
            "destination":tube,
            "mode":"walking",
            "key":"AIzaSyDP9sJnVUX5bAbPeXGIqiinCW4544TAsM8"
        ]
        Alamofire.request("https://maps.googleapis.com/maps/api/directions/json",parameters: parameters,encoding: URLEncoding.default).responseJSON { response in
//            print("Request: \(String(describing: response.request))")   // original url request
//            print("Response: \(String(describing: response.response))") // http url response
//            print("Result: \(response.result)")                         // response serialization result
            print(tube)
            if let json = response.result.value {
                //print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                //print("Data: \(utf8Text)") // original server data as UTF8 string
            }
            // get proper tube line
            if let json = response.result.value as? [String:Any]{
                // TODO: this
                if let routes = json["routes"] as? [[String:Any]]{
                    if let firstRoute = routes.first {
                        if let legs = firstRoute["legs"] as? [[String:Any]] {
                            if let firstLeg = legs.first {
                                if let distance = firstLeg["distance"] as? [String:Any] {
                                    // keep, but not as important in calculation
                                    print(distance["text"])
                                    print(distance["value"])
                                }
                                if let duration = firstLeg["duration"] as? [String:Any] {
                                    print(duration["text"])
                                    print(duration["value"])
                                    if let duration = duration["value"] as? Int {
                                        let departureTime = datestring-duration-120
                                        let newDate = Date(timeIntervalSince1970: Double(departureTime))
                                        print(newDate)
                                        Directions(setStation: tube, setDepartureTime: newDate)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // ehhhh
    func routeCalculator(tube: Tube) {
        var tubeUrl = "https://api.tfl.gov.uk/line/"
        tubeUrl.append(tube.line)
        print(tube.line)
        tubeUrl.append("/stoppoints")
        Alamofire.request(tubeUrl,encoding: URLEncoding.default).responseJSON { response in
//            print("Request: \(String(describing: response.request))")   // original url request
//            print("Response: \(String(describing: response.response))") // http url response
//            print("Result: \(response.result)")                         // response serialization result
            if let json = response.result.value {
                //print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                //print("Data: \(utf8Text)") // original server data as UTF8 string
            }
            if let json = response.result.value as? [[String:Any]]{
                for item in json {
                    if let item = item as? [String:Any] {
                        if let commonName = item["commonName"] as? String {
                            // stop points on line, see google maps times on all of them
                            // find departure time for each and find ones that are less than original distance
                            // then return walking distance to each
                            print(commonName)
                            self.directionTimesFromTube(tube: commonName)
                            //self.walkTimeToTube(tube: commonName)
                        }
                    }
                }
            }
        }
    }
    func tubeFromLatLng(latLng:LatLng) {
        // get tube stop closest to first location
        var latLngString = ""
        latLngString.append(String(latLng.lat))
        latLngString.append(",")
        latLngString.append(String(latLng.long))
        print(latLngString)
        let parameters: Parameters = [
            "location": latLngString,
            "radius":"800",
            "keyword":"tube station",
            "key":"AIzaSyDP9sJnVUX5bAbPeXGIqiinCW4544TAsM8"
        ]
        Alamofire.request("https://maps.googleapis.com/maps/api/place/nearbysearch/json",parameters: parameters,encoding: URLEncoding.default).responseJSON { response in
//            print("Request: \(String(describing: response.request))")   // original url request
//            print("Response: \(String(describing: response.response))") // http url response
//            print("Result: \(response.result)")                         // response serialization result

            if let json = response.result.value {
                // print("JSON: \(json)") // serialized json response
            }

            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                // print("Data: \(utf8Text)") // original server data as UTF8 string
            }
            
        }
    }
    func tubes(latLng:LatLng) {
        Alamofire.request("https://api.tfl.gov.uk/journey/journeyresults/51.501,-0.123/to/n225nb",encoding: URLEncoding.default).responseJSON { response in
//            print("Request: \(String(describing: response.request))")   // original url request
//            print("Response: \(String(describing: response.response))") // http url response
//            print("Result: \(response.result)")                         // response serialization result
            if let json = response.result.value {
//                print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                //print("Data: \(utf8Text)") // original server data as UTF8 string
            }
        }
    }

}
class LatLng {
    var lat:Double
    var long:Double
    init(setLat:Double, setLong:Double) {
        lat = setLat
        long = setLong
    }
}
class Tube {
    var line:String
    var depart:String
    var arrive:String
    var stops: Int
    init(setL:String,setD:String,setA:String, setS: Int) {
        line = setL
        depart = setD
        arrive = setA
        stops = setS
    }
}

