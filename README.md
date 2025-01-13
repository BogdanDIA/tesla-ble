# tesla-ble
Example scripts used to communicate with Tesla cars over BLE.

As the BLE commands may not succeed all the time, the scripts are trying to do the best to have a successful result.

Tesla released a FleetAPI together with a vehicle-command go package created for executing actions on the car over BLE:
https://github.com/teslamotors/vehicle-command/tree/main/cmd/tesla-control

For communicating with the car there is need for VIN of the car and a a set of private/public keys. The public key should be enrolled to the car, see here:
https://github.com/teslamotors/vehicle-command/blob/main/README.md

## **Install and Run**

#### Build vehicle-command and tesla-ble
When built and installed, the **vehicle-command** package will provide a set of executable commands placed by default in a /home/$user/go/bin directory.
To have the option to use different controllers, a patch needs to be applied to vehicle-command before building:
```
# assume the current user is "id"
cd /home/id
git clone https://github.com/teslamotors/vehicle-command.git
git clone https://github.com/BogdanDIA/tesla-ble.git
cp tesla-ble/patches/vehicle-command/device_linux.go vehicle-command/pkg/connector/ble/
cd vehicle-command
go get ./...
go build ./...
go install ./...
```

All scripts are using **tesla-control** executable found in /home/$user/go/bin/ that is the main entry point to the go package.
At this point we assume **vehicle-command** executable has been built with the instructions above. 

#### Update tesla-ble.conf:
```
cd tesla-ble/
vi tesla-ble.conf:

VIN=X1122334455667788                           # car's VIN
PRIVATE_KEY=private_key.pem                     # car's private key
HCI_NUM=1                                       # BT controller number
BLE_CMD_TIMEOUT=10s                             # tesla-control command timeout
BLE_CONN_TIMEOUT=20s                            # tesla-control connect timeout
BIN_PATH=/home/`whoami`/go/bin/                 # directory where tesla-control is placed
SCRIPTS_PATH=/home/`whoami`/go/bin/tesla-ble/   # directory this is where tesla-ble is cloned
COMMAND_TIMEOUT=55                              # overall timeout 
```
Overall timeout support has been added so that commands will be closed after a specific period. This is necessary in case long lasting commands are still running while new commands are executed.

#### Run checks
```
./check-configuration.sh
```

#### Run presence command
```
./charging_get_presence.sh
```

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

#### Run other commands:

```
./charging_set_amps.sh 3
./charging_get_bcontroller.sh
./charging_set_state.sh
...
```

**Note 1:**
tesla-ble/yaml/ directory contains HA example scripts that use tesla-ble scripts. For example, with a few HA helpers it can give the following information in lovelace:

![alt text](https://github.com/BogdanDIA/tesla-ble/blob/main/yaml/img/HA_lovelace.png)

**Note 2:**
running on rpi with WiFi at 2.4Ghz band may give poor results as the BLE receiver can get drowned by the WiFi. It is better to use an ethernet cable or an rpi with 5Ghz band like rpi5.


