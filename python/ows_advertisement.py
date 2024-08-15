import asyncio
import logging
import sys
import threading
from pynput import keyboard  # Import pynput for keyboard handling
from typing import Union, Any
from bless import (  # type: ignore
    BlessServer,
    BlessGATTCharacteristic,
    GATTCharacteristicProperties,
    GATTAttributePermissions,
)

# Setup logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(name=__name__)

# Synchronization method depending on the platform
trigger: Union[asyncio.Event, threading.Event]
if sys.platform in ["darwin", "win32"]:
    trigger = threading.Event()
else:
    trigger = asyncio.Event()

# Button states and simulation variables
n_buttons = 4
button_states = [0] * n_buttons
button_states_prev = [0] * n_buttons
button_packs = [0] * n_buttons
package_size = 8
package_i = 0
sample_n = 0
set_bit = 1 << package_size

pairing = False
sampling = False

# Advertisement and manufacturer data
manufacturer_id = 0xFFFF
pair_package = bytearray([0xFF, 0xFF, 0x9C, 0x7C] + [0] * 16)
buttons_data = bytearray([manufacturer_id & 0xFF, (manufacturer_id >> 8) & 0xFF] + [0] * 16)

# An asyncio queue to communicate between threads
event_queue = asyncio.Queue()

# Function to trigger a specific button
async def trigger_button(n_button: int):
    global button_states, sampling, last_action
    if 0 <= n_button < n_buttons:
        button_states[n_button] = 1  # Set the button state to "pressed"
        sampling = True
        last_action = asyncio.get_event_loop().time()
        logger.debug(f"Button {n_button + 1} triggered")


# Function to reset all button states after handling
def reset_button_states():
    global button_states
    button_states = [0] * n_buttons


# Function to simulate pairing
async def trigger_pairing():
    global pairing
    pairing = True
    logger.debug("Pairing triggered")
    await event_queue.put("pairing")


# Function to manage advertising based on current button states or pairing state
async def manage_advertising(server: BlessServer):
    if not await server.is_advertising():
        logger.debug("Advertising is not running; starting now...")
        await server.start()
        logger.debug("Advertising started.")
    else:
        logger.debug("Advertising is already running.")


# Function to handle key presses using pynput
def on_press(key):
    try:
        if key.char in ['1', '2', '3', '4']:
            n_button = int(key.char) - 1
            asyncio.run_coroutine_threadsafe(event_queue.put(n_button), loop)
        elif key.char == 'p':
            asyncio.run_coroutine_threadsafe(trigger_pairing(), loop)
    except AttributeError:
        pass  # Handle special keys that don't have a char attribute


async def process_events():
    while True:
        event = await event_queue.get()
        if isinstance(event, int):
            await trigger_button(event)
        elif event == "pairing":
            logger.debug("Pairing event processed")


async def run(loop):
    global pairing, sampling, sample_n, package_i, last_action
    trigger.clear()

    # Initialize the BLE server
    server = BlessServer(name="OWS Advertisement Server", loop=loop)
    
    # Start advertising initially
    await manage_advertising(server)
    
    # Start listening to key presses in a separate thread
    listener = keyboard.Listener(on_press=on_press)
    listener.start()

    # Process events like button presses and pairing
    asyncio.create_task(process_events())
    
    while True:
        # Check if any button has been triggered
        if sampling:
            if sample_n < package_size:
                for i in range(n_buttons):
                    if button_states[i]:
                        button_packs[i] |= set_bit
                    button_packs[i] >>= 1
                sample_n += 1
            else:
                # Process the button states and update advertising data
                for i in range(n_buttons):
                    for j in range(3, 0, -1):
                        buttons_data[2 + j * 4 + i] = buttons_data[2 + (j - 1) * 4 + i]
                    buttons_data[2 + i] = button_packs[i]

                logger.debug("Button states processed and advertisement data updated.")
                sample_n = 0
                package_i += 1
                sampling = False

                # Reset button states for the next iteration
                reset_button_states()
        
        if pairing:
            # Handle pairing event
            logger.debug("Handling pairing - updating advertisement data")
            pairing = False

        await asyncio.sleep(0.03)  # Control loop timing (e.g., 30ms interval)


def start_ows_advertisement():
    global loop, last_action
    loop = asyncio.get_event_loop()
    last_action = loop.time()
    loop.run_until_complete(run(loop))
