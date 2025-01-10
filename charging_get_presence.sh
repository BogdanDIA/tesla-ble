#!/command/with-contenv bashio
. /app/libproduct.sh
# BogdanDIA

CPATH=$(dirname "$0")/tesla-ble.conf
. $CPATH 
. ${SCRIPTS_PATH}/log-def.sh

charging_get_presence()
{
  # load config  
  . $SCRIPTS_PATH/ble-name.sh
  # load log definition
  . ${SCRIPTS_PATH}/log-def.sh

  # cd to BIN_PATH
  cd "$BIN_PATH"
  log ""
  log "`date` get-presence"
  log "BIN_PATH: $BIN_PATH"
  log "VIN: $VIN"
  log "PWD: `pwd`"
  log "SCRIPTS_PATH: $SCRIPTS_PATH"
  log "COMMAND_TIMEOUT: $COMMAND_TIMEOUT"

  log "Burst start"

  if [[ -n $VIN ]]; then
    log "VIN provided"
  else
    log "no VIN provided in tesla-config.conf. Exiting..."
  fi

  # calculate BLE Local Name for which we want the MAC
  #BLE_LOCAL_NAME=$(python $SCRIPTS_PATH/ble-name.py $VIN)
  BLE_LOCAL_NAME=$(ble-name $VIN)

  log "BLE_LOCAL_NAME: $BLE_LOCAL_NAME"

  # timeouts et all
  DEVICES_TIMEOUT=5
  LOOP_COUNT=6
  SCAN_TIMEOUT=$((DEVICES_TIMEOUT*$LOOP_COUNT+2))

  log "DEVICES_TIMEOUT: $DEVICES_TIMEOUT" 
  log "LOOP_COUNT: $LOOP_COUNT"
  log "SCAN_TIMEOUT: $SCAN_TIMEOUT"

  log "Going to reset HCI"

  # obtain the default controller index, for hciconfig
  HCINUM=$(bluetoothctl list | wc -l)
  HCINUM=hci$(($HCINUM-1))
  log "HCI index: $HCINUM"
   
  # reset Host Controller 
  INFORESET=""
  RESETRET=""
  for (( i=0; i<$LOOP_COUNT; i++ ))
  {
    INFORESET=$(hciconfig $HCINUM reset 1>&2)
    if [ $? -eq 0 ];then
      log "try: $i, Ok"
      RESETRET=0
      break
    else
      log "try: $i, Fail, $INFORESET"
      RESETRET=1
    fi
  }

  if [ ! $RESETRET -eq 0 ];then
    log "$INFORESET"
    log "Cannot reset HCI, Exiting..."
    log "Cannot reset HCI" >&1
    exit 1
  else
    log "Successfully reset HCI"
  fi

  # start scan
  log "Starting bluetoothctl scan on"
  bluetoothctl --timeout "$SCAN_TIMEOUT" scan on 1>&2 &

  INFOMAC=""
  INFORSSI=""
  log "Starting get_presence"
  for (( i=0; i<$LOOP_COUNT; i++ ))
  do
    DEVICES=$(bluetoothctl --timeout "$DEVICES_TIMEOUT" devices | grep "$BLE_LOCAL_NAME")
    log "try: $i, DEVICES: $DEVICES"

    if [[ -n "$DEVICES" ]]; then
      log "try: $i, Matched car\'s BLE name"

      INFOMAC=$(echo "$DEVICES" | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
      log "try: $i, INFOMAC: $INFOMAC"

      INFORSSI=$(bluetoothctl --timeout 1 info "$INFOMAC" | grep RSSI)
      if [[ -n "$INFORSSI" ]]; then
        break
      fi
    fi
  done

  log "MAC: $INFOMAC"
  log "RSSI: $INFORSSI"

  log "Starting bluetoothctl scan off"
  bluetoothctl --timeout 1 scan off 1>&2

  killall -SIGTERM bluetoothctl

  log "Burst end"

  if [[ -n "$INFORSSI" ]]; then
    log "Car Present"
    echo "$INFORSSI dBm" >&1
    return 0
  else
    log "Car Not Present"
    echo "Car Not Present" >&1
    return 1
  fi
}

export -f charging_get_presence 

# set the default value if the initial definition is not correct
if [[ ! $COMMAND_TIMEOUT =~ ^[0-9]+$ ]]; then
  COMMAND_TIMEOUT=0
fi

# return after timeout period. Load config upon executing function 
set +e
timeout -k 1 -s SIGKILL "$COMMAND_TIMEOUT" bash -c ". ${SCRIPTS_PATH}/tesla-ble.conf; charging_get_presence"
STATUS=$?
set -e
wait

log "STATUS: $STATUS"

if [[ $STATUS -eq 0 ]]; then
  log "Command get-presence success"
elif [[ $STATUS -eq 137 ]]; then
  log "Fail - Command Timeout"
else
  log "Command get-presence fail"
fi
exit "$STATUS"
