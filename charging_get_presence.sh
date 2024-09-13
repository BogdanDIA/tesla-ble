#!/bin/bash
# BogdanDIA

. $(dirname "$0")/tesla-ble.conf
cd "$BIN_PATH"

charging_get_presence()
{
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
  echo "COMMAND_TIMEOUT: $COMMAND_TIMEOUT" | tee -a charging-log.txt

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

  echo Going to reset HCI | tee -a charging-log.txt

  # obtain the default controller index, for hciconfig
  HCINUM=$(bluetoothctl list | wc -l)
  HCINUM=hci$(($HCINUM-1))
  echo HCI index: "$HCINUM" | tee -a charging-log.txt
   
  # reset Host Controller 
  INFORESET=""
  RESETRET=""
  for (( i=0; i<$LOOP_COUNT; i++ ))
  {
    INFORESET=$(hciconfig $HCINUM reset 2>&1)
    if [ $? -eq 0 ];then
      echo try: $i, Ok | tee -a charging-log.txt
      RESETRET=0
      break
    else
      echo try: $i, Fail, $INFORESET | tee -a charging-log.txt
      RESETRET=1
    fi
  }

  if [ ! $RESETRET -eq 0 ];then
    echo $INFORESET | tee -a charging-log.txt
    echo "Cannot reset HCI", Exiting...  | tee -a charging-log.txt
    echo "Cannot reset HCI" >&2
    exit 1
  else
    echo Successfully reset HCI | tee -a charging-log.txt
  fi

  # start scan
  bluetoothctl --timeout "$SCAN_TIMEOUT" scan on > /dev/zero 2>&1 &

  INFOMAC=""
  INFORSSI=""
  echo Starting get_presence | tee -a charging-log.txt
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
        break
      fi
    fi
  done

  echo MAC: "$INFOMAC" | tee -a charging-log.txt
  echo RSSI: "$INFORSSI" | tee -a charging-log.txt

  bluetoothctl --timeout 1 scan off > /dev/zero 2>&1

  echo "Burst end" | tee -a charging-log.txt

  if [[ -n "$INFORSSI" ]]; then
    echo Car Present | tee -a charging-log.txt
    echo "$INFORSSI dBm" >&2
    return 0
  else
    echo Car Not Present | tee -a charging-log.txt
    echo "Car Not Present" >&2
    return 1
  fi
}

export -f charging_get_presence

# set the default value if the initial definition is not correct
if [[ ! $COMMAND_TIMEOUT =~ ^[0-9]+$ ]]; then
  COMMAND_TIMEOUT=0
fi

# return after the timeout period
OUT=$(timeout --preserve-status -k 1 -s SIGKILL "$COMMAND_TIMEOUT" bash -c "charging_get_presence")
STATUS=$?
echo "$OUT"

if [[ ! STATUS -eq 0 ]]; then
  echo "Fail - Command Timeout" | tee -a charging-log.txt
  echo "Command Timeout" >&2
fi
exit "$STATUS"
