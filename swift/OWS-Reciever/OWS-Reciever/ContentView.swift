//
//  ContentView.swift
//  OWS-Reciever
//
//  Created by Will Wade on 12/08/2024.
//

import SwiftUI

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
            
            HStack {
                Button(action: {
                    bluetoothManager.startScanning()
                }) {
                    Text("Start Scanning")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    bluetoothManager.startScanning() // Simplified for now, can be extended to differentiate actions
                }) {
                    Text("Pair")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}


#Preview {
    ContentView()
}
