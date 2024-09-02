//
//  ContentView.swift
//  OWS-Sender
//
//  Created by Will Wade on 12/08/2024.
//

import SwiftUI
import UIKit
import CoreBluetooth

struct ContentView: View {
    @ObservedObject var bluetoothManager = BluetoothManager()

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
                bluetoothManager.startAdvertising()
            }) {
                Text("Broadcast")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
