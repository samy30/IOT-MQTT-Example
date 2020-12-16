#!python3
import paho.mqtt.client as mqtt  #import the client1
import time

def on_connect(client, userdata, flags, rc):
    if rc==0:
        client.connected_flag=True #set flag
        print("connected OK")
    else:
        print("Bad connection Returned code=",rc)

def on_message(client, userdata, message):
    time.sleep(1)
    print("received message =",str(message.payload.decode("utf-8")))



mqtt.Client.connected_flag=False#create flag in class
broker="52.23.187.235"
client = mqtt.Client("python1")             #create new instance 
client.on_connect=on_connect  #bind call back function
client.on_message=on_message
client.loop_start()
print("Connecting to broker ",broker)
client.connect(broker)      #connect to broker
while not client.connected_flag: #wait in loop
    print("In wait loop")
    time.sleep(1)
print("in Main Loop")
client.loop_stop()    #Stop loop 
client.loop_start()
print("waiting for messages")
client.subscribe("GL5/SLE/SAMI") #subscribe
time.sleep(60*60*24)
client.loop_stop()
client.disconnect() # disconnect
