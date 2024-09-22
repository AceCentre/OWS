//
//  BluetoothManager.swift
//  OWS-Sender
//
//  Created by Will Wade on 12/08/2024.
//

import Foundation
import CoreBluetooth
import Combine




struct SenderReceiverConstants
{
    let PairingServiceIdentifierUUIDKey: String = "45B73DF1-2099-481A-8877-2BBD95877880" 
    //let PairingServiceIdentifierCBUUID: CBUUID = CBUUID(string:  "45B73DF1-2099-481A-8877-2BBD95877880")

    let ParingServiceCDummyChacteristicUUIDKey: String = "FD80F91A-C0EB-4CD4-A89B-663408E69268" //dummy dummy service, if

}


class BluetoothManager: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    
    private var peripheralManager : CBPeripheralManager!

    @Published var statusMessage: String = ""
    @Published var receivedData: String = ""

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

        peripheralManager?.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [PairingServiceIdentifierUUIDKey],
            CBAdvertisementDataLocalNameKey: "OWS Switch Name"])  // This can be the same as how the manufacturer keyword is used to senbd data, in this case we send it via the name. There are restrictions on  how much data can be sent at  time.
        
        print("Broadcast pairing")
    }
    
    func advertiseData() {
        // Define your service UUID and characteristics here

        let datetimeData = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)// Data Example broadcast the dste and time
        peripheralManager?.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [DataserviceAppleUUIDKey],
            CBAdvertisementDataLocalNameKey: "Sender:\(datetimeData)", // This can be the same as how the manufacturer keyword is used to senbd data, in this case we send it via the name. There are restrictions on  how much data can be sent at  time.
        ])
        
        print("broadcasting data i.e. \(datetimeData)")
    }
    
    // Implement other CBPeripheralManagerDelegate methods as needed
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        // Handle read request
        print("Someone is telling us to read something") //we won;t njeoing /
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
