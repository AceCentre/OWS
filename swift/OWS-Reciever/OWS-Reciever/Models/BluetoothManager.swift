//
//  BluetoothManager.swift
//  OWS-Reciever
//
//  Created by Will Wade on 12/08/2024.
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    
    @Published var selectedSegment: DataFormat = .Manufacturer
    @Published var isScanning: Bool = false // Manually track scanning state
    private var targetMac: String?
    

    private var prevPackageIndex: Int = -1
    private var replayBuffer: [(Int, [UInt8])] = []
    
    private let buttonsHidActions = ["1", "2", "3", "4"]
    private let numberOfButtons = 4
    private var buttonStates: [Int] = [0, 0, 0, 0]
    
    @Published var statusMessage: String = "Waiting for data..."
    @Published var receivedData: String = ""
    
//    private func setDataExchangeMethod(_ dataFormat: DataFormat) {
//        UserDefaults.standard.setValue(dataFormat.rawValue, forKey: "DataExchangeMethod")
//    }
    
    // default value is UUID
    // get the value via this proxy
    private func getDataExchangeMethod() -> DataFormat {
        //let dataexchangeMethod = DataFormat(rawValue: UserDefaults.standard.integer(forKey: "DataExchangeMethod")) ?? DataFormat.ResolveByUUID
        let dataexchangeMethod = self.selectedSegment
        
        return dataexchangeMethod
    }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    func startScanning() {
        if let mac = loadMacAddress() {
            targetMac = mac
            
            isScanning = true
            switch getDataExchangeMethod() {
            case .Manufacturer:
                statusMessage = "scanning (man) to be receiving from: \(mac) "
                centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            case .ResolveByUUID:
                self.startScanningForData(mac)
            }
        } else {
            isScanning = true
            
            switch getDataExchangeMethod() {
            case .Manufacturer:
                statusMessage = "Scanning for devices (man) to pair..."
                centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            case .ResolveByUUID:
                self.startScanningInPairedMode()
            }
        }
    }
    
    private func startScanningInPairedMode() { // looking for deviuces that want to pair, ignore the rest
        statusMessage = "Scanning for devices (uuid) to pair..."
        centralManager?.scanForPeripherals(withServices: [CBUUID(string: PairingServiceIdentifierUUIDKey)], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    private func startScanningForData(_ pairedMac: String) { // looking for devices that send data
        statusMessage = "Scanning for devices (uuid) for data from \(pairedMac)..."
        centralManager?.scanForPeripherals(withServices: [CBUUID(string: DataserviceAppleUUIDKey), CBUUID(string: DataserviceAdrinoUUIDKey)], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false, CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScanning() {
        self.centralManager.stopScan()
        isScanning = false
        self.statusMessage = "Scanning has stopped."
    }
    
   
    // MARK: - CBCentralManagerDelegate Methods

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth is powered on"
        case .poweredOff:
            statusMessage = "Bluetooth is turned off"
        default:
            statusMessage = "Bluetooth is not available"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("advertising data= \(advertisementData)")
        var messageData:Data?=nil
        switch self.getDataExchangeMethod() {
        case .Manufacturer:
            messageData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        case .ResolveByUUID:
            messageData = advertisementData[CBAdvertisementDataLocalNameKey] as? Data
        }
        
        guard let messageData = messageData else {
            return
        }
        
        
        if let mac = targetMac { // We are paired, so  hopefully be a data message for us
            if mac == peripheral.identifier.uuidString { // Our buddy send us a message
                self.processAdvertisementData(messageData)
            }
        } else { // otherwise because we not paired, hopefull this will be a pairing messaage
            self.attemptPairing(peripheral, manufacturerData: messageData as NSData)
        }
    }
    
    // MARK: - Pairing
     func resetPairing() {
        self.stopScanning()
        self.clearMacAddress()
        
    }

    private func attemptPairing(_ peripheral: CBPeripheral, manufacturerData: NSData) {
        let dataLength  = manufacturerData.length
        var packageReceived = [UInt8](repeating: 0, count: dataLength)
        manufacturerData.getBytes(&packageReceived, length: dataLength)
        if (packageReceived == pairingPackage) {
            statusMessage = "Got pairing package from: \(peripheral.identifier.uuidString)"
            saveMacAddress(peripheral.identifier.uuidString)
            statusMessage = "Paired with device: \(peripheral.identifier.uuidString)"
            switch self.getDataExchangeMethod() {
            case .Manufacturer: break
                // keep on scanning as aways
            case .ResolveByUUID:
                self.startScanningForData("\(peripheral.identifier.uuidString)") // scan for  data
            }
        } else {
            statusMessage = "Other device found: \(peripheral.identifier.uuidString)"
        }
    }
    
    // MARK: - Data Processing

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
    
    private func clearMacAddress() {
        UserDefaults.standard.setValue(nil, forKey: "targetMac")
    }
}

