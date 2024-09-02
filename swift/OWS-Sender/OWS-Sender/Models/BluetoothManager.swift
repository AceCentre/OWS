//
//  BluetoothManager.swift
//  OWS-Sender
//
//  Created by Will Wade on 12/08/2024.
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    
    
    
    private var peripheralManager : CBPeripheralManager!
    
    private let manufacturerId: UInt16 = 65535
    private let pairingPackage: [UInt8] = [0x9c, 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    private var targetMac: String?
    
    private var prevPackageIndex: Int = -1
    private var replayBuffer: [(Int, [UInt8])] = []
    
    private let buttonsHidActions = ["1", "2", "3", "4"]
    private let numberOfButtons = 4
    private var buttonStates: [Int] = [0, 0, 0, 0]
    
    @Published var statusMessage: String = ""
    @Published var receivedData: String = ""

    override init() {
        super.init()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil) // Use the main thread
        print("Create bluetooth manager")
        
    }
    
        
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) { // we want to if the has granted permision or reviditrd irt
        
        
        switch peripheral.state {
        case .unknown:
            print("Bluetooth Device is UNKNOWN")
            statusMessage = "Unknown BLE State"
        case .unsupported:
            print("Bluetooth Device is UNSUPPORTED")
            statusMessage = "Unsupported"
        case .unauthorized:
            print("Bluetooth Device is UNAUTHORIZED")
            statusMessage = "Unauthorised"
        case .resetting:
            print("Bluetooth Device is RESETTING")
            statusMessage = "Reseting"
        case .poweredOff:
            print("Bluetooth Device is POWERED OFF")
            statusMessage = "Powered Off"
        case .poweredOn:
            print("Bluetooth Device is POWERED ON")
            statusMessage = "On and Ready"
        @unknown default:
            print("Unknown State")
            statusMessage = "BLE Unknown State"
        }
    }

    
    func startAdvertising() {
        // Define your service UUID and characteristics here
        let serviceUUID = CBUUID(string: "45B73DF1-2099-481A-8877-2BBD95877880")
        let characteristicUUID = CBUUID(string: "FD80F91A-C0EB-4CD4-A89B-663408E69268")
        
        let characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read, .write],
            value: nil,
            permissions: [.readable, .writeable]
        )
        
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]
        
        peripheralManager?.add(service)
        peripheralManager?.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "OWS-Sender-Name<With SomeData>", // This can be the same as how the manufacturer keyword is used to senbd data, in this case we send it via the name. There are restrictions on  how much data can be sent at  time. 
        ])
        
        print("broadcasting")
    }
    
    // Implement other CBPeripheralManagerDelegate methods as needed
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        // Handle read request
        print("Someone is telling us to read something")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        // Handle write requests
        print("Someone send data, go and look what they wrote.")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        // Handle subscription to characteristic
        print("Someone is listening")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        // Handle unsubscription from characteristic
        print("Someone is no longer listening")
    }



}
