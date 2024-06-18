from pynput import keyboard
import logging
from datetime import datetime

# Set up logging
logging.basicConfig(filename='key_press_log.txt', level=logging.INFO, format='%(asctime)s - %(message)s')

def on_press(key):
    try:
        if key.char == '1':
            logging.info('Key "1" pressed')
    except AttributeError:
        pass  # Handle special keys (like arrow keys, etc.)

def on_release(key):
    # Stop listener
    if key == keyboard.Key.esc:
        return False

# Set up the listener
with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    listener.join()
