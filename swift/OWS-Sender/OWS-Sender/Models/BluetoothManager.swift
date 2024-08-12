//
//  BluetoothManager.swift
//  OWS-Sender
//
//  Created by Will Wade on 12/08/2024.
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager?
    private var targetPeripheral: CBPeripheral?
    
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
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        if let mac = loadMacAddress() {
            targetMac = mac
            statusMessage = "Start receiving from: \(mac)"
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        } else {
            statusMessage = "No button was paired. Run pairing firstly."
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    // MARK: - CBCentralManagerDelegate Methods

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth is powered on"
            startScanning()
        case .poweredOff:
            statusMessage = "Bluetooth is turned off"
        default:
            statusMessage = "Bluetooth is not available"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else { return }
        
        let manufacturerId: UInt16 = manufacturerData.prefix(2).withUnsafeBytes { pointer in
            pointer.load(as: UInt16.self).bigEndian
        }
        
        if manufacturerId == self.manufacturerId {
            if let mac = targetMac, peripheral.identifier.uuidString == mac {
                processAdvertisementData(manufacturerData.suffix(from: 2))
            } else {
                attemptPairing(peripheral, manufacturerData: manufacturerData.suffix(from: 2))
            }
        }
    }
    
    // MARK: - Pairing

    private func attemptPairing(_ peripheral: CBPeripheral, manufacturerData: Data) {
        if manufacturerData.starts(with: pairingPackage) {
            statusMessage = "Got pairing package from: \(peripheral.identifier.uuidString)"
            saveMacAddress(peripheral.identifier.uuidString)
            centralManager?.stopScan()
        } else {
            statusMessage = "Other device: \(peripheral.identifier.uuidString)"
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
}
