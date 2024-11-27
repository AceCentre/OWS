import sys 
import pathlib
import time

import asyncio
from bleak import BleakScanner
from bleak.backends.scanner import AdvertisementData

from pynput.keyboard import Key, Controller

n_buttons = 4                              # number of buttons to receive
buttons_hid_actions = ["1", "2", "3", "4"] # hid action for each button that will be emulated
keyboard_repeat = True                     # handle long presses

MANUFACTURER_ID = 65535

button_filepath = pathlib.Path(__file__).parent.resolve() / "button_mac"

target_mac = None

prev_package_i = -1

# Add Target UUIDs for filtering
TARGET_UUIDS = [
    "14B53A88-4A9C-46C9-B251-98F7DF0971D7",  # Pairing Service UUID
    "45B73DF1-2099-481A-8877-2BBD95877880",  # Data Service (Apple)
    "E765151E-EE25-418D-BDF2-F2F5B1BE1220"   # Data Service (Arduino)
]


pairing_package = b'\x9c|\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'

scan_stop_event = asyncio.Event()

package_size = 8
replay_interval = 0.03 # in seconds          
replay_buffer = asyncio.Queue()
button_states = [0,0,0,0]

keyboard = Controller()

def load_mac():
    global target_mac

    if button_filepath.exists():
        with open(button_filepath, "r") as f:
            target_mac = f.read()
            return True
    else:
        return False

def save_mac(mac):
    global target_mac

    print("saving mac: ", mac)
    with open(button_filepath, "w") as f:
        target_mac = f.write(mac)

async def replay():
    while True:
        replay_i, replay_values, current = await replay_buffer.get()
        if replay_i is None:  # Exit signal
            break

        for j in range(n_buttons):
            state = replay_values[j] & 1
            if state == 1 and button_states[j] == 0:
                await asyncio.to_thread(keyboard.press, buttons_hid_actions[j])
                button_states[j] = 1
            elif state == 0:
                await asyncio.to_thread(keyboard.release, buttons_hid_actions[j])
                button_states[j] = 0

def receive_button_data(device, advertisement_data):
    global replay_buffer, prev_package_i

    # Ensure the device matches the expected MAC and advertises the target UUID
    if device.address != target_mac or TARGET_UUIDS[1] not in (advertisement_data.service_uuids or []):
        return
    
    if MANUFACTURER_ID not in advertisement_data.manufacturer_data:
        print("No valid manufacturer data from:", device.address)
        return

    data = advertisement_data.manufacturer_data[MANUFACTURER_ID]
    package_i = data[0]
    
    if prev_package_i == package_i:
        return  # Skip duplicate packages

    adv_package = data[1:]
    if len(adv_package) < n_buttons * package_size:
        print("Invalid data length:", len(adv_package))
        return

    package_diff = (package_i - prev_package_i + 256) % 256
    for i in range(min(package_diff, 4)):
        replay_buffer.put_nowait((package_i - i, adv_package[i * n_buttons:(i + 1) * n_buttons], i == 0))
    
    prev_package_i = package_i

def pair(device, advertisement_data):
    dev_mac = device.address
    adv_package = advertisement_data.manufacturer_data.get(MANUFACTURER_ID)
    
    # Check if UUID matches the pairing service
    if TARGET_UUIDS[0] not in (advertisement_data.service_uuids or []):  # Pairing UUID
        print(f"Unrecognized device: {dev_mac}")
        return
    
    if adv_package is None or len(adv_package) != len(pairing_package):
        print(f"Device does not match pairing package: {dev_mac}")
        return
    
    if pairing_package == adv_package:
        print("Pairing successful with:", dev_mac)
        save_mac(dev_mac)
        scan_stop_event.set()
    else:
        print("Device does not match pairing package:", dev_mac)

async def scan(callback_fun):
    async with BleakScanner(callback_fun, scanning_mode="active") as scanner:
        await scan_stop_event.wait()

async def main():
    n_args = len(sys.argv)
    
    if n_args == 1:
        # No arguments provided, show help message
        print("\nUsage: python script_name.py [pair]\n")
        print("Options:")
        print("  pair          Initiate the pairing process with the switch device.")
        print("\nIf no arguments are provided:")
        print("  The script will attempt to load the previously paired device and start receiving data.")
        print("\nExample:")
        print("  python script_name.py pair   # Start pairing")
        print("  python script_name.py         # Start receiving from previously paired device\n")
        
        if load_mac():
            print(f"Start receiving from: {target_mac}")
            await asyncio.gather(scan(receive_button_data), replay())
        else:
            print("No button was paired. Run pairing first.")
    
    elif n_args == 2 and sys.argv[1].lower() == "pair":
        print("Start pairing")
        await scan(pair)
        print("Pairing completed")
        
asyncio.run(main())