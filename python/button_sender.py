import bluetooth._bluetooth as bt
import keyboard

def send_advertisement():
    # Prepare the packet data similar to the Arduino code
    packet_data = [0x02, 0x01, 0x06, 0x03, 0x03, 0xAA, 0xFE, 0x0F, 0x16, 0xAA, 0xFE, 0x10, 0x00, 0x02, 0x71, 0x03, 0x00, 0x00, 0x00]
    
    # Open Bluetooth device
    sock = bt.hci_open_dev(0)
    
    # Send the raw Bluetooth packet
    # OGF = 0x08, OCF = 0x0008 are for LE Set Advertising Data command
    cmd_pkt = bytearray(packet_data)
    bt.hci_send_cmd(sock, 0x08, 0x0008, cmd_pkt)
    
    print("Advertisement sent!")

# Listen for a specific keystroke, e.g., 'a'
keyboard.on_press_key('a', lambda _: send_advertisement())

# Keep the program running
keyboard.wait()
