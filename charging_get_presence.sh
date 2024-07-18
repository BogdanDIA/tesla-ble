#!/bin/bash
# BogdanDIA

# load config  
. $(dirname "$0")/tesla-ble.conf
# cd to BIN_PATH
cd "$BIN_PATH"
echo "" | tee -a charging-log.txt
echo "`date` get-presence" | tee -a charging-log.txt
echo "BIN_PATH: $BIN_PATH" | tee -a charging-log.txt
echo "VIN: $VIN" | tee -a charging-log.txt
echo "PWD: `pwd`" | tee -a charging-log.txt
echo "SCRIPTS_PATH: $SCRIPTS_PATH" | tee -a charging-log.txt
echo "Burst start" | tee -a charging-log.txt

if [[ -n $VIN ]]; then
	echo VIN provided | tee -a charging-log.txt
else
	echo no VIN provided in tesla-config.conf. Exiting... | tee -a charging-log.txt
fi

# calculate BLE Local Name for which we want the MAC
BLE_LOCAL_NAME=$(python $SCRIPTS_PATH/ble-name.py $VIN)
echo BLE_LOCAL_NAME: $BLE_LOCAL_NAME | tee -a charging-log.txt

# timeouts et all
DEVICES_TIMEOUT=5
LOOP_COUNT=6
SCAN_TIMEOUT=$((DEVICES_TIMEOUT*$LOOP_COUNT+2))

echo DEVICES_TIMEOUT: $DEVICES_TIMEOUT | tee -a charging-log.txt 
echo LOOP_COUNT: $LOOP_COUNT | tee -a charging-log.txt
echo SCAN_TIMEOUT: "$SCAN_TIMEOUT" | tee -a charging-log.txt

# start scan
bluetoothctl --timeout "$SCAN_TIMEOUT" scan on > /dev/zero 2>&1 &

INFOMAC=""
INFORSSI=""
for (( i=0; i<$LOOP_COUNT; i++ ))
do
        DEVICES=$(bluetoothctl --timeout "$DEVICES_TIMEOUT" devices | grep "$BLE_LOCAL_NAME")
        echo try: $i, DEVICES: "$DEVICES" | tee -a charging-log.txt

        if [[ -n "$DEVICES" ]]; then
                echo try: $i, Matched car\'s BLE name | tee -a charging-log.txt

                INFOMAC=$(echo "$DEVICES" | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
                echo try: $i, INFOMAC: "$INFOMAC" | tee -a charging-log.txt

		INFORSSI=$(bluetoothctl --timeout 1 info "$INFOMAC" | grep RSSI)
        	if [[ -n "$INFORSSI" ]]; then
			break;
		fi
        fi
done

echo MAC: "$INFOMAC" | tee -a charging-log.txt
echo RSSI: "$INFORSSI" | tee -a charging-log.txt

bluetoothctl --timeout 1 scan off > /dev/zero 2>&1

echo "Burst end" | tee -a charging-log.txt

if [[ -n "$INFORSSI" ]]; then
	echo Car Present | tee -a charging-log.txt
	echo "$INFORSSI" >&2
	exit 0
else
	echo Car Not Present | tee -a charging-log.txt
	echo "Car Not Present" >&2
	exit 1
fi
