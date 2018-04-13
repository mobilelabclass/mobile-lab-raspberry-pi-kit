//
//  ViewController.swift
//  HelloRaspberryPi
//
//  Created by Sebastian Buys on 4/11/18.
//  Copyright © 2018 mobilelab. All rights reserved.
//

import UIKit
import CoreBluetooth


// Unique identifier for your BLE Peripheral, Service(s), and Characteristic(s)
// Change these values
// Make sure they match the values on your BLE device (Raspberry Pi)
let PERIPHERAL_NAME = "My Awesome Servo"
let PERIPHERAL_UUID_STRING = "269e0082-be19-4e59-9f77-af341b57e1bf"
let SERVICE_UUID_STRING = "e853db91-e787-4eeb-ae7c-536d689f5741";
let CHARACTERISTIC_UUID_STRING = "01ad6336-32b5-499c-9130-3f989684044c";

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    
    // Store references to the CoreBluetooth objects here as we discover them.
    var myPi: CBPeripheral?
    var myServoService: CBService?
    var myServoPositionCharacteristic: CBCharacteristic?
    
    @IBOutlet weak var positionSlider: UISlider!
    
    // Action method is called whenever the slider value has updated.
    @IBAction func didChangePositionValue(_ sender: UISlider) {
        // print("Slider value: ", sender.value)
        
        // Make sure we already have a reference to our pi
        guard let pi = myPi else {
            return
        }
        
        // Make sure we already have a reference to the servo position characteristic
        guard let posCharacteristic = myServoPositionCharacteristic else {
            return
        }
        
        // Instead of sending a float value to our pi, we simplify by converting to a float (0-100)
        var sliderValue = Int(sender.value * 100)
        
        // Convert the Int to Data
        let data = Data(bytes: &sliderValue, count: MemoryLayout.size(ofValue: sliderValue))
        
        print(">>> Sending write request to raspberry pi:", sliderValue)
        
        // Write the characteristic value
        pi.writeValue(data, for: posCharacteristic, type: .withResponse)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Set the slider to only update after user has finished interacting, not everytime they move
        // This is to prevent spamming the raspberry pi with requests.
        // May not be necessary to throttle like this.
        self.positionSlider.isContinuous = false
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("central manager did update state:", central)
        if (central.state == .poweredOn) {
            print("Manager is powered on! Scanning  for peripherals...")

            // Just scan for our Raspberry Pi
            // central.scanForPeripherals(withServices: serviceIds, options: nil)
            
            // Scan for all peripherals
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
    }
    
    
    // MARK: CBCentralManager delegate methods

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if (peripheral.name == PERIPHERAL_NAME) {
            print(">>> Found our BLE peripheral:", PERIPHERAL_NAME)
            myPi = peripheral
            
            // Connect to the peripheral
            centralManager?.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print(">>> Connected to our peripheral:", peripheral.identifier.uuidString)
        
        // Assign ourselves as the delegate of the peripheral and search for our servo service
        // As the delegate, we receive messages from the peripheral when we implement methods in the CBPeripheralDelegate protocol
        // https://developer.apple.com/documentation/corebluetooth/cbperipheraldelegate
        
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: SERVICE_UUID_STRING)])
        
        // Passing nil will search for all services.
        // peripheral.discoverServices(nil)
    }
    
    
    // MARK: CBPeripheralDelegate methods
    // Called when a peripheral for which we are the delegate (peripheral.delegate) discovers services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }

        // print(">>> Discovered services:", peripheral.services)
        
        // Look for our servo service by uuid. If we don't find it, exit.
        guard let servoService = peripheral.services?.first(where: { service -> Bool in
            service.uuid == CBUUID(string: SERVICE_UUID_STRING)
        }) else {
            return
        }
        
        // Store reference to the servo we just found
        myServoService = servoService
        
        // Search for characteristics of the service
        peripheral.discoverCharacteristics([CBUUID(string: CHARACTERISTIC_UUID_STRING)], for: servoService)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {
            print("Error discovering characteristics: \(error!.localizedDescription)")
            return
        }
        
        // print(">>> Discovered characteristics:", service.characteristics)
        
        // Look for our servo position characteristic by uuid. If we don't find it, exit.
        guard let servoPositionCharacteristic = service.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == CBUUID(string: CHARACTERISTIC_UUID_STRING)
        }) else {
            return
        }
        // Store reference
        myServoPositionCharacteristic = servoPositionCharacteristic
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
