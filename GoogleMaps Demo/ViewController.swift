//
//  ViewController.swift
//  GoogleMaps Demo
//
//  Created by Santosh on 13/12/18.
//  Copyright © 2018 sagarsoft. All rights reserved.
//

import UIKit
import GoogleMaps
import  GooglePlaces

class ViewController: UIViewController{
    
    @IBOutlet weak var tfToLocation: UITextField!
    @IBOutlet weak var tfFormLocation: UITextField!
    
    var locationManager = CLLocationManager()
    let marker = GMSMarker()
    var url:String!
    @IBOutlet fileprivate weak var mapView: GMSMapView!
    var city:String? = ""
    var streetName:String? = ""
    var latitude:Double?
    var longitude:Double?
    var camera:GMSCameraPosition!
    var isFirstTf:Bool = true
    var currentTF:UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        cameraPosition(latitude: 17.3850, longitude: 78.4867)
    }
    
    // Pass your source and destination coordinates in this method.
    func getPolylineRoute(){
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(String(describing: tfFormLocation.text!))&destination=\(String(describing: tfToLocation.text!))&sensor=false&mode=driving&key=addyourapikey")!
        
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }else{
                do {
                    if let json : [String:AnyObject] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: AnyObject]{
                        
                        guard let routes = json["routes"] as? [AnyObject] else{
                            return
                        }
                        guard let routesArr = routes[0] as? [String: AnyObject] else{
                            return
                        }
                        guard let overview_polyline = routesArr["overview_polyline"] as? [String: AnyObject] else{
                            return
                        }
                        guard let polyString = overview_polyline["points"] as? String else{
                            return
                        }
                        
                        //Call this method to draw path on map
                        self.showPath(polyStr: polyString)
                    }
                }catch{
                    print("error in JSONSerialization")
                }
            }
        })
        task.resume()
    }
    
    func showPath(polyStr :String){
        DispatchQueue.main.async {
            let path = GMSPath(fromEncodedPath: polyStr)
            let polyline = GMSPolyline(path: path)
            polyline.strokeWidth = 3.0
            polyline.map = self.mapView // Your map view
        }
    }
    
    
    @IBAction func btnSearchAction(_ sender: Any) {
        getPolylineRoute()
        tfToLocation.text = ""
        tfFormLocation.text = ""
    }
    
    func cameraPosition(latitude:Double,longitude:Double){
        camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 10)
        mapView.camera = camera
        //        showMarker(position:camera.target)
    }
    
    func showMarker(position:CLLocationCoordinate2D){
        marker.position = position
        marker.title = city
        marker.snippet = streetName
        marker.isDraggable = true
        marker.map = mapView
    }
    
    func getAddress(latitude:Double,longitude:Double){
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            // Place details
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            self.marker.title = placeMark.locality
            self.marker.snippet = placeMark.subLocality
            
            // Location name
            guard let locationName = placeMark.locality  else{
                print("locationName is empty")
                return
            }
            self.city = locationName
            self.updateUI()
            // Street address
            guard let street = placeMark.thoroughfare else{
                print("street is empty")
                return
            }
//            self.streetName = self.city
            
        })
//        return city!
    }
    func updateUI(){
        currentTF?.text = self.city
        dismiss(animated: true, completion: nil)
    }
}


extension ViewController: GMSMapViewDelegate, CLLocationManagerDelegate{
    
    //Location Manager delegates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        
        let camera = GMSCameraPosition.camera(withLatitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, zoom: 17.0)
        
        self.mapView?.animate(to: camera)
        
        //Finally stop updating location otherwise it will come again and again in this delegate
        self.locationManager.stopUpdatingLocation()
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        print("Info window tapped")
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressInfoWindowOf marker: GMSMarker) {
        print("Long press Info window")
    }
    
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        print("didBeginDragging")
    }
    
    func mapView(_ mapView: GMSMapView, didDrag marker: GMSMarker) {
        print("didDrag")
    }
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        print("didEndDragging")
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("coordinates---%@",coordinate)
        marker.position = coordinate
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        //        getAddress(latitude: latitude!,longitude: longitude!)
        cameraPosition(latitude: latitude!, longitude: longitude!)
    }
}

extension ViewController:UITextFieldDelegate, GMSAutocompleteViewControllerDelegate{
    
    
    //Textfield delegate methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("editing started")
        currentTF = textField
        let autoCompleteController =  GMSAutocompleteViewController()
        autoCompleteController.delegate = self
        present(autoCompleteController, animated: true, completion: nil)
//        if(textField == tfFormLocation){
//            tfFormLocation.text = city
//        }else if(textField == tfToLocation){
//            tfToLocation.text = city
//        }
//        city = ""
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("editing ended")
    }
    
    
    //Google maps auto complete delegate methods
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        latitude = place.coordinate.latitude
        longitude = place.coordinate.longitude
        print("Place details \(place)")
        print("currentTF \(String(describing: currentTF))")
        getAddress(latitude: latitude!, longitude: longitude!)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}
