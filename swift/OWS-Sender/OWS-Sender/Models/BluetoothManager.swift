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

    @Published var statusMessage: String = ""
    @Published var sentData: String = ""

    override init() {
        super.init()
        self.createPeripheral()
        print("Create bluetooth manager")
        
    }
    
        
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) { // we want to if the has granted permision or reviditrd irt
        
        
        switch peripheral.state {
        case .unknown:
            print("Bluetooth Device is UNKNOWN")
            statusMessage = "Unknown Bluetooth State"
        case .unsupported:
            print("Bluetooth Device is UNSUPPORTED")
            statusMessage = "Unsupported, can not run Bluetooth"
        case .unauthorized:
            print("Bluetooth Device is UNAUTHORIZED")
            statusMessage = "Bluetooth Unauthorised, try change permissiopn in iPhone Setting"
        case .resetting:
            print("Bluetooth Device is RESETTING")
            statusMessage = "Bluetooth Reseting..."
        case .poweredOff:
            print("Bluetooth Device is POWERED OFF")
            statusMessage = "Bluetooth Powered Off."
        case .poweredOn:
            print("Bluetooth Device is POWERED ON")
            statusMessage = "On and Ready."
        @unknown default:
            print("Unknown State")
            statusMessage = "Unknown Bluetooth State"
        }
    }
    

    private func createPeripheral() {
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil) // Use the main thread
        
        let pairingCharacteristic = CBMutableCharacteristic( // dummy
            type: CBUUID(string: ParingServiceDummyChacteristicUUIDKey),
            properties: [.read, .write],
            value: nil,
            permissions: [.readable, .writeable]
        )
        let pairingService = CBMutableService(type: CBUUID(string:  PairingServiceIdentifierUUIDKey) , primary: true)
        pairingService.characteristics = [pairingCharacteristic]
        peripheralManager?.add(pairingService)
        
        let dataServiceCharacteristic = CBMutableCharacteristic(
            type: CBUUID(string: DataServiceAppleDummyChacteristicUUIDKey),
            properties: [.read, .write],
            value: nil,
            permissions: [.readable, .writeable]
        )
        let dataService = CBMutableService(type: CBUUID(string:  PairingServiceIdentifierUUIDKey) , primary: true)
        dataService.characteristics = [dataServiceCharacteristic]
        
    }

    
    func startAdvertisingPairing() {
        // Define your service UUID and characteristics here

        let pairingPackageData = NSData(bytes: pairingPackage, length: pairingPackage.count)
        peripheralManager?.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: PairingServiceIdentifierUUIDKey)],
            CBAdvertisementDataLocalNameKey: pairingPackageData])  // This can be the same as how the manufacturer keyword is used to senbd data, in this case we send it via the name. There are restrictions on  how much data can be sent at  time.
        
        self.statusMessage = "Broadcasting pairing"
        self.sentData = "\nPairingPackage detail: [\(pairingPackage.map { String(format: "0x%02x", $0) }.joined(separator: ", "))]:"
    }
    
    func advertiseData() {
        // Define your service UUID and characteristics here

        let datetimeData = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)// Data Example broadcast the dste and time
        peripheralManager?.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: DataserviceAppleUUIDKey), CBUUID(string: DataserviceAdrinoUUIDKey)],
           // CBAdvertisementDataIsConnectable : NSNumber(booleanLiteral: false),
            CBAdvertisementDataLocalNameKey: "\(datetimeData)", // This can be the same as how the manufacturer keyword is used to sent data, in this case we send it via the name. There are restrictions on  how much data can be sent at  time.
        ])
        self.statusMessage = "Sending the time."
        self.sentData = "\(datetimeData)"
    }
    
    // Implement other CBPeripheralManagerDelegate methods as needed
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        // Handle read request
        print("Someone is telling us to read something") //we ignore
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
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?) {
        if let error = error {
            self.statusMessage = "Could not broadcast: \(error.localizedDescription)"
        }
        
    }
}
