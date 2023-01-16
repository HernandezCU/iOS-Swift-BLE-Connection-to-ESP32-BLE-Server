//
//  ViewController.swift
//  SensorESP32
//
//  Created by Carlos Hernandez on 1/16/23.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var by_label: UILabel!
    
    @IBOutlet weak var d_label: UILabel!
    
    
    var manager: CBCentralManager!
    var discoveredPeripherals = [DiscoveredPeripheral]()
    var connectedPeripheral: CBPeripheral?
    var onDiscovered: (() -> Void)?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager = CBCentralManager(delegate: self, queue: nil)
        onDiscovered = { [self] in
            for i in discoveredPeripherals{
                print("-=-=-=-=-=-=-=-=-")
                print(i.peripheral.identifier.uuidString)
                print(i.peripheral.description)
                print(i.peripheral.name ?? "NULL NAME")
                print("-=-=-=-=-=-=-=-=-")
                
                if i.peripheral.name == "ESP32-BLE-Server"{
                    let idx = discoveredPeripherals.firstIndex(of: i)
                    connect(at: idx!)
                }
            }
            
            
        }
        //discoveredPeripheral.peripheral.identifier.uuidString
        // Do any additional setup after loading the view.
    }
    
    
//    var manager: CBCentralManager!
//    var discoveredPeripherals = [DiscoveredPeripheral]()
//    var connectedPeripheral: CBPeripheral?
//    var onDiscovered: (() -> Void)?
//    var onDataUpdated: ((info) -> Void)?
//    var onConnected: (() -> Void)?
//    override init(){
//        super.init()
//        manager = CBCentralManager(delegate: self, queue: nil)
//    }
    
    
    func scanForPeripherals(){
        let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        manager.scanForPeripherals(withServices: nil, options: options)
    }
    
    func connect(at index: Int){
        guard index >= 0, index < discoveredPeripherals.count else { return }
        manager.stopScan()
        manager.connect(discoveredPeripherals[index].peripheral, options: nil)
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Central is powered on.")
            scanForPeripherals()
        }
        else{
            print("Central is unavailable: \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let existingPeripheral = discoveredPeripherals.first(where: {$0.peripheral == peripheral}){
            existingPeripheral.advertismentData = advertisementData
            existingPeripheral.rssi = RSSI
        }
        else{
            discoveredPeripherals.append(DiscoveredPeripheral(peripheral: peripheral, rssi: RSSI, advertismentData: advertisementData))
        }
        onDiscovered?()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected Successfully!")
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        connectedPeripheral?.discoverServices([CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")])
        //onConnected?()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to Connect!")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("error: \(error.localizedDescription)")
        }else{
            peripheral.services?.forEach({ (service) in
                print("Service Discovered: \(service)")
                peripheral.discoverCharacteristics([CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")], for: service)
                
            })
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("failed to discover characteristics: \(error.localizedDescription)")
        }
        else{
            service.characteristics?.forEach({ (characteristic) in
                print("Characteristic Discovered: \(characteristic)")
                if characteristic.properties.contains(.notify){
                    peripheral.setNotifyValue(true, for: characteristic)
                }else if characteristic.properties.contains(.read){
                    peripheral.readValue(for: characteristic)
                }
                peripheral.discoverDescriptors(for: characteristic)
                
            })
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed to discover descriptor: \(error.localizedDescription)")
        }
        else{
            characteristic.descriptors?.forEach({ (descriptor) in
                print("Descriptor Discovered: \(descriptor)")
                peripheral.readValue(for: characteristic)
            })
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error {
            print("peripheral error updating value for characteristic: \(error.localizedDescription)")
        }else{
            print("characteristic value updated: \(characteristic)")
            print(characteristic.value!)
            print(characteristic.value!.description)

            if let string = String(bytes: characteristic.value!, encoding: .utf8) {
                print(string)
                
                DispatchQueue.main.async { [self] in
                    by_label.text = characteristic.value?.description
                    d_label.text = string
                }
                
                //let i = info(d: characteristic.value!, value: string)
//                newest_data = i
                //print()
                //onDataUpdated?(i)
                
            } else {
                print("not a valid UTF-8 sequence")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        if let error = error {
            print("peripheral error updating value for descriptor: \(error.localizedDescription)")
        }else{
            print("descriptor value updated: \(descriptor)")
        }
    }

}

