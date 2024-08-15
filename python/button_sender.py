import asyncio
import logging
import sys
import threading
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


# Function to simulate button press states (would be replaced with actual button handling code)
def simulate_button_states():
    global button_states, button_states_prev, sampling, last_action
    # This is where you would read the actual button states
    # For now, we simulate it by toggling the first button state every loop
    button_states[0] = not button_states[0]
    if button_states != button_states_prev:
        sampling = True
        last_action = asyncio.get_event_loop().time()
    button_states_prev[:] = button_states


# Function to manage advertising based on current button states or pairing state
async def manage_advertising(server: BlessServer):
    if not await server.is_advertising():
        logger.debug("Advertising is not running; starting now...")
        # Since we can't directly update, we handle advertisements once during start
        await server.start()
        logger.debug("Advertising started.")
    else:
        logger.debug("Advertising is already running.")


async def run(loop):
    global pairing, sampling, sample_n, package_i, last_action
    trigger.clear()

    # Initialize the BLE server
    server = BlessServer(name="BLE Test Server", loop=loop)
    
    # Start advertising initially
    await manage_advertising(server)
    
    # Simulate button press and handle pairing
    while True:
        simulate_button_states()

        if sampling:
            if sample_n < package_size:
                for i in range(n_buttons):
                    if button_states[i]:
                        button_packs[i] |= set_bit
                    button_packs[i] >>= 1
                sample_n += 1
            else:
                # Update advertisement data logic can be handled here
                # However, since we can't restart advertising, we might log or handle state differently.
                logger.debug("Sampling completed; advertisement data updated.")
                sample_n = 0
                package_i += 1
                sampling = False
        
        if pairing:
            logger.debug("Pairing data would be advertised here.")
            pairing = False

        await asyncio.sleep(0.03)  # Control loop timing (e.g., 30ms interval)


loop = asyncio.get_event_loop()
last_action = loop.time()
loop.run_until_complete(run(loop))
