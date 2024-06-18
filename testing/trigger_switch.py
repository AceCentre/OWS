import time
import board
import digitalio

# Set up the pin
pin = digitalio.DigitalInOut(board.D13)  # Replace D13 with your specific pin
pin.direction = digitalio.Direction.OUTPUT

# Set the interval time in seconds
interval = 1.0

while True:
    pin.value = True  # Turn the pin on
    time.sleep(interval)
    pin.value = False  # Turn the pin off
    time.sleep(interval)
