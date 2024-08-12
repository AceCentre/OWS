//
//  BluetoothStatusView.swift
//  OWS-Sender
//
//  Created by Will Wade on 12/08/2024.
//

import SwiftUI

struct BluetoothStatusView: View {
    let message: String

    var body: some View {
        Text(message)
            .padding()
            .font(.subheadline)
            .foregroundColor(.gray)
    }
}


#Preview {
    BluetoothStatusView(message: "Sample Bluetooth Status")
}
