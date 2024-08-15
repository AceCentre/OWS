import asyncio
import ows_advertisement  # Import the button sender module

# Start the BLE simulator
ows_advertisement.start_ows_advertisement()

# Example function to trigger pairing programmatically
async def example_trigger_pairing():
    await ows_advertisement.trigger_pairing()

# Example function to trigger a button press programmatically
async def example_trigger_button():
    await ows_advertisement.trigger_button(0)  # Trigger button 1

# Running example triggers
asyncio.run(example_trigger_pairing())
asyncio.run(example_trigger_button())
