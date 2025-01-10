#!/command/with-contenv bashio
. /app/libproduct.sh
# BogdanDIA

CPATH=$(dirname "$0")/tesla-ble.conf
. $CPATH 
. ${SCRIPTS_PATH}/log-def.sh

charging_get_state()
{
  app() {
    # set timeouts variable
    CMD_TMO="-command-timeout $BLE_CMD_TIMEOUT -connect-timeout $BLE_CONN_TIMEOUT"

    # set BT Controller Number
    export HCINUM=$HCI_NUM

    # run command
    ./tesla-control $CMD_TMO -vin "$VIN" -key-file "$PRIVATE_KEY" -ble state charge
    STATUS=$?
    return $STATUS
  }

  # load log definition  
  . ${SCRIPTS_PATH}/log-def.sh

  # cd to BIN_PATH
  cd "$BIN_PATH"
  log ""
  log "`date` get-state"
  log "BIN_PATH: $BIN_PATH"
  log "VIN: $VIN"
  log "HCINUM: $HCINUM"
  log "PWD: `pwd`"
  log "SCRIPTS_PATH: $SCRIPTS_PATH"
  log "COMMAND_TIMEOUT: $COMMAND_TIMEOUT"

  log "Burst start"

  if [[ -n $VIN ]]; then
    log "VIN provided"
  else
    log "no VIN provided in tesla-ble.conf. Exiting..."
  fi

  if [[ -n $PRIVATE_KEY ]];then
    log "PRIVATE_KEY provided"
  else
    log "no PRIVATE_KEY provided in tesla-ble.conf. Exiting..."
  fi

  CMD_STAT=""

  for (( i=0; i<5; i++ ))
  do
    app 1> >(tee -a charging-log.txt >&1) 2> >(tee -a charging-log.txt >&2)
    CMD_STAT=$?

    if [[ $CMD_STAT -eq 0 ]]; then
      log "Ok: try: $i"
      break
    else
      log "Fail: try: $i"
    fi
  done

  log "Burst end"
  return $CMD_STAT
}

export -f charging_get_state

# set the default value if the initial definition is not correct
if [[ ! $COMMAND_TIMEOUT =~ ^[0-9]+$ ]]; then
  COMMAND_TIMEOUT=0
fi

# return after timeout period. Load config upon executing function 
set +e
timeout -k 1 -s SIGKILL "$COMMAND_TIMEOUT" bash -c ". ${SCRIPTS_PATH}/tesla-ble.conf; charging_get_state"
STATUS=$?
set -e
wait

log "STATUS: $STATUS"

if [[ $STATUS -eq 0 ]]; then
  log "Command get-state success"
elif [[ $STATUS -eq 137 ]]; then
  log "Fail - Command Timeout"
else
  log "Command get-state fail"
fi
exit "$STATUS"
