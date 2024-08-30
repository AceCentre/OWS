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
    
    @Published var statusMessage: String = "Waiting for data..."
    @Published var receivedData: String = ""

    override init() {
        super.init()
        
    }
    
    func startbroadcasting() {
        
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil) // Use the main thread
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) { // we want to if the has granted permiision or revijed irt
        
        
        switch peripheral.state {
        case .unknown:
            print("Bluetooth Device is UNKNOWN")
            statusMessage = "UNKNOWN"
        case .unsupported:
            print("Bluetooth Device is UNSUPPORTED")
            statusMessage = "UNSUPPORTED"
        case .unauthorized:
            print("Bluetooth Device is UNAUTHORIZED")
            statusMessage = "UNAUTHORIZED"
        case .resetting:
            print("Bluetooth Device is RESETTING")
            statusMessage = "RESETTING"
        case .poweredOff:
            print("Bluetooth Device is POWERED OFF")
            statusMessage = "POWERED OFF"
        case .poweredOn:
            print("Bluetooth Device is POWERED ON")
            statusMessage = "POWERED ON"
            createServices()
        @unknown default:
            print("Unknown State")
            statusMessage = "Unknown State"
        }
    }

    
    private var service: CBUUID!
    private let value = "EF14F506-59C9-4A4F-BA5D-7B5F64172B44"
    func createServices() {        let valueData = value.data(using: .utf8)
         // create the main service
         // 1. Create instance of CBMutableCharcateristic
        let myChar1 = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()), properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])
        let myChar2 = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()), properties: [.read], value: valueData, permissions: [.readable])
        // 2. Create instance of CBMutableService
        service = CBUUID(nsuuid: UUID())
        let myService = CBMutableService(type: service, primary: true)
        // 3. Add characteristics to the service
        myService.characteristics = [myChar1, myChar2]
        // 4. Add service to peripheralManager
        peripheralManager.add(myService)
        // 5. Start advertising
        startAdvertising()
    }
    func startAdvertising() {
        
//        let bighEndianValue = manufacturerId.bigEndian
//        let manufacturerIddata = withUnsafeBytes(of: bighEndianValue) { Data($0) }
        
        let broadCastData =  [CBAdvertisementDataLocalNameKey: "OWSSendApp",
                           CBAdvertisementDataServiceUUIDsKey: [service]] as [String : Any]//use a UUID Manufactirr cide id
        
        print(broadCastData)
        peripheralManager.startAdvertising(broadCastData)
        
    }
    
//    func startScanning() {
//        if let mac = loadMacAddress() {
//            targetMac = mac
//            statusMessage = "Start receiving from: \(mac)"
//            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
//        } else {
//            statusMessage = "No button was paired. Run pairing firstly."
//            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
//        }
//    }
//    
//    
   
    private func processAdvertisementData(_ data: Data) {
        guard data.count >= 2 else { return }
        let packageIndex = Int(data[0])
        
        if prevPackageIndex != packageIndex {
            let advPackage = [UInt8](data.dropFirst())
            handleReplay(packageIndex: packageIndex, advPackage: advPackage)
            prevPackageIndex = packageIndex
        }
    }
    
    private func handleReplay(packageIndex: Int, advPackage: [UInt8]) {
        let packageDiff = (packageIndex - prevPackageIndex + 256) % 256
        var current = false
        for i in stride(from: packageDiff - 1, through: 0, by: -1) {
            current = i == 0
            var replayPack = [UInt8]()
            for j in 0..<numberOfButtons {
                replayPack.append(advPackage[i * 4 + j])
            }
            replayBuffer.append((packageIndex - i, replayPack))
            updateReceivedData(replayPack, current: current)
        }
    }

    // MARK: - UI Update Logic

    private func updateReceivedData(_ replayPack: [UInt8], current: Bool) {
        var states = [String]()
        for i in 0..<numberOfButtons {
            let receivedState = replayPack[i] & 1
            if receivedState == 1 {
                if buttonStates[i] == 0 || buttonStates[i] > 20 {
                    states.append("Button \(buttonsHidActions[i]): Pressed")
                }
                buttonStates[i] += 1
            } else {
                states.append("Button \(buttonsHidActions[i]): Released")
                buttonStates[i] = 0
            }
        }
        DispatchQueue.main.async {
            self.receivedData = states.joined(separator: ", ")
        }
    }

    // MARK: - Utility Methods
    
    

    private func loadMacAddress() -> String? {
        return UserDefaults.standard.string(forKey: "targetMac")
    }

    private func saveMacAddress(_ mac: String) {
        UserDefaults.standard.setValue(mac, forKey: "targetMac")
        targetMac = mac
    }
}
