# tesla-ble
Example scripts used to communicate with Tesla cars over BLE.

As the BLE commands may not succeed all the time, the scripts are trying to do the best to have a successful result.

Tesla released a FleetAPI together with a vehicle-command go package created for executing actions on the car over BLE:
https://github.com/teslamotors/vehicle-command/tree/main/cmd/tesla-control

For communicating with the car there is need for VIN of the car and a a set of private/public keys. The public key should be enrolled to the car, see here:
https://github.com/teslamotors/vehicle-command/blob/main/README.md

## **Install and Run**

0. When built and installed, the **vehicle-command** package will provide a set of executable commands placed by default in a $home/go/bin directory.

All scrips are using **tesla-control** executable found in go/bin/ that is the main entry point to the go package.
At this point we assume the the **vehicle-command** has been built with the instructions above and **tesla-control** executable exists in /home/id/go/bin/ assuming the user name is "id". 

1. clone https://github.com/BogdanDIA/tesla-ble/ somewhere on the filesystem:
2. update tesla-ble/tesla-ble.conf with your information:

```
tesla-ble.conf:

VIN=YOUR-VIN
PRIVATE_KEY=private_key.pem
BIN_PATH=/home/`whoami`/go/bin/ #<-this is where the tesla-control is placed
SCRIPTS_PATH=/home/`whoami`/go/bin/tesla-ble/ #<-this is where the tesla-ble is cloned
```

3. run tesla-ble/check-configuration.sh script to see if everything is correctly setup.

4. run ./charging_get_presence.sh

When the car is present, it should give an output like the following:

```
Sun  7 May 20:24:00 +03 2024 get-presence
BIN_PATH: /home/id/go/bin/
VIN: X1122334455667788 
PWD: /home/id/go/bin
SCRIPTS_PATH: /home/id/go/bin/tesla-ble/
Burst start
VIN provided
BLE_LOCAL_NAME: SxxxxxxxxxxxxxxxC
DEVICES_TIMEOUT: 5
LOOP_COUNT: 6
SCAN_TIMEOUT: 32
try: 0, DEVICES: [NEW] Device 74:46:B3:11:22:22 SxxxxxxxxxxxxxxxC
try: 0, Matched car's BLE name
try: 0, INFOMAC: 74:46:B3:11:22:33
MAC: 74:46:B3:11:22:33
RSSI:   RSSI: -78
Burst end
Car Present
```

If all above worked, now the rest of commands should work as well, e.g setting 3 Amps charging current:

```
./charging_set_amps 3
```

**Note 1:**
tesla-ble/yaml/ directory contains HA example scripts that use tesla-ble scripts. For example, with a few HA helpers it can give the following information in lovelace:

![alt text](https://github.com/BogdanDIA/tesla-ble/blob/main/yaml/img/HA_lovelace.png)

**Note 2:**
running on rpi with WiFi at 2.4Ghz band may give poor results as the BLE receiver can get drowned by the WiFi. It is better to use an ethernet cable or an rpi with 5Ghz band like rpi5.


