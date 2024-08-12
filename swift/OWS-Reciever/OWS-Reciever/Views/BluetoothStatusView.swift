//
//  BluetoothStatusView.swift
//  OWS-Reciever
//
//  Created by Will Wade on 12/08/2024.
//

import SwiftUI

struct BluetoothStatusView: View {
    let statusMessage: String
    let receivedData: String

    var body: some View {
        VStack {
            Text(statusMessage)
                .padding()
                .font(.headline)

            Spacer()

            Text(receivedData)
                .padding()
                .foregroundColor(.green)
                .font(.body)

            Spacer()
        }
    }
}

#Preview {
    BluetoothStatusView(statusMessage: "Bluetooth is powered on", receivedData: "No data received yet.")
}
