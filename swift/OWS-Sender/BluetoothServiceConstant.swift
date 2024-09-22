//
//  BluetoothServiceConstant.swift
//  OWS-Sender
//
//  Created by Theo S on 21/09/2024.
//

import CoreBluetooth

let PairingServiceIdentifierUUIDKey = "14B53A88-4A9C-46C9-B251-98F7DF0971D7"  // In pairing mode this servce will broadcast, until timeout or databroadcast starts
let ParingServiceDummyChacteristicUUIDKey: String = "FD80F91A-C0EB-4CD4-A89B-663408E69268" //dummy ti :"fool  swift and iOS" service, only needed when  makeing a connection, which don't do use, but without it no service appear/exist.

let DataserviceAppleUUIDKey = "45B73DF1-2099-481A-8877-2BBD95877880" //  if  you this service, then the data will be located in local,Name of the Advertisement Block
let DataServiceAppleDummyChacteristicUUIDKey = "048B62B8-46AC-48CD-A110-C5D526DF522B" //  dummy


let DataserviceAdrinoUUIDKey = "E765151E-EE25-418D-BDF2-F2F5B1BE1220" //  if  you this service, then the data will be located in local,Name of the Advertisement Block





