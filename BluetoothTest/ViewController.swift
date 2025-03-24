//
//  ViewController.swift
//  BluetoothTest
//
//  Created by Eric Dockery on 1/22/18.
//  Copyright © 2018 Eric Dockery. All rights reserved.
//

import UIKit

class ViewController: UIViewController  {


    @IBOutlet var printerConnectionStatus: UILabel!
    var printManager = PrintManager.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        printManager.connectionDelegate = self
        if printManager.isConnected {
            printerConnectionStatus.text = "Connected"
        } else {
            printerConnectionStatus.text = "Not Connected"
        }
    }

    @IBAction func printTestLabel(_ sender: Any) {
        let queue = DispatchQueue(label: "your bundle identifier")
             queue.async {
                 self.printManager.printBarcode(for: "This is a test")
             DispatchQueue.main.async {
                        // Update the UI here
             }
        }
    }
    
    @IBAction func sendOverHTTP(_ sender: Any) {
        let consumerKey = "XXX"
        let tennantNumber = "XXX"
        let serialNumber = "XXX"
        
        let url = URL(string: "https://api.zebra.com/v2/devices/printers/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "accept")
        request.setValue(consumerKey, forHTTPHeaderField: "apikey")
        request.setValue(tennantNumber, forHTTPHeaderField: "tenant")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add sn field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"sn\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(serialNumber)\r\n".data(using: .utf8)!)

        // Add zpl_file field with string data
        let zplCommand = "^XA^FO50,50^ADN,36,20^FDHello, Zebra!^FS^XZ"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"zpl_file\"; filename=\"packagecontents.zpl\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(zplCommand.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let response = response as? HTTPURLResponse {
                print("Status Code: \(response.statusCode)")
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
        }

        task.resume()
    }
}

extension ViewController: EAAccessoryManagerConnectionStatusDelegate {
    func changeLabelStatus() {
        if printManager.isConnected {
            printerConnectionStatus.text = "Connected"
        } else {
            printerConnectionStatus.text = "Not Connected"
        }
    }
}
