//
//  ContentView.swift
//  OWS-Reciever
//
//  Created by Will Wade on 12/08/2024.
//

import SwiftUI

let broadcasttimeout = 500.0

// Enum to represent segments
enum DataFormat: Int, CaseIterable, Identifiable {
    case Manufacturer
    case ResolveByUUID
    
    // Provide an id for Identifiable conformance (needed for ForEach)
    var id: Int { self.rawValue }
    
    // Optionally, provide a title for each case
    var title: String {
        switch self {
        
        case .Manufacturer:
            return "Use Manufacturer Key"
        case .ResolveByUUID:
            return "UUID Resolve"
        }
    }
}

// View for segmented control
//struct SegmentControlView: View {
//    @Binding var selectedSegment: DataFormat
//    
//    var body: some View {
//        Picker("Select a Segment", selection: $selectedSegment) {
//            // Use enum cases for tags
//            ForEach(DataFormat.allCases) { dataformat in
//                Text(dataformat.title).tag(dataformat)
//            }
//        }
//        .pickerStyle(SegmentedPickerStyle())
//        .padding()
//    }
//}

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    //@State private var selectedSegment: DataFormat = .Manufacturer

    var body: some View {
        VStack {
            Text(bluetoothManager.statusMessage)
                .padding()
                .font(.headline)
            
            Spacer()
            
            Text(bluetoothManager.receivedData)
                .padding()
                .foregroundColor(.green)
                .font(.body)
            
            Spacer()
            
            Button(action: {
                           if bluetoothManager.isScanning {
                               bluetoothManager.stopScanning()
                               // Delay the button state update to avoid immediate restart
                                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                      // Refresh the UI state here if needed
                                  }
                           } else {
                               bluetoothManager.startScanning()
                           }
                       }) {
                           Text(bluetoothManager.isScanning ? "Stop Scanning" : "Start Scanning")
                               .padding()
                               .background(bluetoothManager.isScanning ? Color.red : Color.green)
                               .foregroundColor(.white)
                               .cornerRadius(8)
                       }
            Spacer()
            
            
        }
        .padding()
        HStack {
            Button(action: {
                bluetoothManager.resetPairing()
            }) {
                Text("Reset pairing")
                    .padding()
                    .background(Color.yellow)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        
        Spacer()
        
        
        // Picker with SegmentedPickerStyle
        Picker("", selection:  $bluetoothManager.selectedSegment) {
            ForEach(DataFormat.allCases) { data in
                    Text(data.title).tag(data)
                }
            }
            .pickerStyle(SegmentedPickerStyle()) // Apply segmented control style
            .padding()
            .disabled(bluetoothManager.isScanning)


    }
}


#Preview {
    ContentView()
}
