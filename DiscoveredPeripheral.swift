//
//  DiscoveredPeripheral.swift
//  BLEESP32Test
//
//  Created by Carlos Hernandez on 1/15/23.
//

import Foundation
import CoreBluetooth

class DiscoveredPeripheral: Equatable{
    static func == (lhs: DiscoveredPeripheral, rhs: DiscoveredPeripheral) -> Bool {
        if lhs.peripheral.name == rhs.peripheral.name{
            return true
        }
        return false
    }

    var peripheral: CBPeripheral
    var rssi: NSNumber
    var advertismentData: [String: Any]
    
    init(peripheral: CBPeripheral, rssi: NSNumber, advertismentData: [String : Any]) {
        self.peripheral = peripheral
        self.rssi = rssi
        self.advertismentData = advertismentData
    }
}
