import asyncio
from gpiozero import AngularServo
from nats.aio.client import Client as NATS
from time import sleep

# Define the NATS server URL
NATS_SERVER_URL = "nats://192.168.31.225:4222"
# Define the subject to subscribe to
SUBJECT = "chicken.coordinates"

# Initialize the servo motors
servo_x = AngularServo(18, min_pulse_width=0.0006, max_pulse_width=0.0023)
servo_y = AngularServo(17, min_pulse_width=0.0006, max_pulse_width=0.0023)

def move_servo_smoothly(servo, start_angle, end_angle, steps, delay):
    """Smoothly move the servo from start_angle to end_angle with interpolation."""
    step_size = (end_angle - start_angle) / steps
    for step in range(steps):
        angle = start_angle + step * step_size
        servo.angle = angle
        sleep(delay)

def move_to_center(servo, steps, delay):
    """Move the servo to the center position (0 degrees)."""
    move_servo_smoothly(servo, servo.angle, 0, steps, delay)

async def run():
    nc = NATS()

    # Connect to the NATS server
    await nc.connect(servers=[NATS_SERVER_URL])

    async def message_handler(msg):
        data = msg.data.decode()
        print(f"Received message on '{msg.subject}': {data}")

        # Parse the coordinates from the message
        try:
            # Assuming message data is in format "x,y"
            x_str, y_str = data.split(',')
            x = float(x_str)
            y = float(y_str)

            # Map the coordinates to servo angles
            # Ensure that the coordinates are within expected range
            x_angle = max(min(x, 90), -90)  # Clamp value to range -90 to 90 degrees
            y_angle = max(min(y, 90), -90)  # Clamp value to range -90 to 90 degrees

            # Smoothly move the servos to the desired angles
            move_servo_smoothly(servo_x, servo_x.angle, x_angle, 200, 0.01)
            move_servo_smoothly(servo_y, servo_y.angle, y_angle, 200, 0.01)

        except ValueError:
            print(f"Invalid coordinate data: {data}")

    # Subscribe to the subject
    await nc.subscribe(SUBJECT, cb=message_handler)

    # Keep the connection alive
    try:
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        pass
    finally:
        await nc.close()

if __name__ == "__main__":
    asyncio.run(run())
