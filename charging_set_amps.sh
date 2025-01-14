#!/command/with-contenv bashio
. /app/libproduct.sh
# BogdanDIA

if [[ "$#" -eq 0 ]]; then
  echo No parameter passed, exiting...
  exit 1
fi  

CPATH=$(dirname "$0")/tesla-ble.conf
. $CPATH 
. ${SCRIPTS_PATH}/log-def.sh

charging_set_amps()
{
  app() {
    # set timeouts variable
    CMD_TMO="-command-timeout $BLE_CMD_TIMEOUT -connect-timeout $BLE_CONN_TIMEOUT"

    # set BT Controller Number
    export HCINUM=$HCI_NUM

    #run command
    OUT=$(./tesla-control $CMD_TMO -vin "$VIN" -key-file "$PRIVATE_KEY" -ble charging-set-amps $1)
    STATUS=$?

    # for case when return not zero but output is on stdout
    if [[ $STATUS -eq 0 ]]; then
      echo "$OUT" >&1
    else
      echo "$OUT" >&2
    fi

    return $STATUS
  }

  # load log definition  
  . ${SCRIPTS_PATH}/log-def.sh

  # cd to BIN_PATH
  cd "$BIN_PATH"
  log ""
  log "`date` set-amps $1 Amps"
  log "BIN_PATH: $BIN_PATH"
  log "VIN: $VIN"
  log "HCI_NUM: $HCI_NUM"
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

  CMD_STAT=-1

  # execute the command twice only if target Amps is under 5 Amps

  for (( count=0; count<2; count++ ))
  do
    for (( i=0; i<5; i++ ))
    do
      app $1 2> >(tee -a charging-log.txt >&2) 1> >(tee -a charging-log.txt >&1)
      TMP_STAT=$?

      if [[ "$TMP_STAT" -eq 0 ]]; then
        log "Ok count: $count, try: $i"
        break
      else
        log "Fail count: $count, try: $i"
      fi
    done

    # AND the status for both loops 
    CMD_STAT=$(($CMD_STAT & $TMP_STAT))
    log "count: $count, CMD_STAT: $CMD_STAT"

    # if first loop fails then we quit 
    if [[ $count -eq 0 ]] && [[ "$CMD_STAT" -ne 0 ]]; then
      break
    fi

    # if target Amps is above 4 we don't execute second loop
    if [[ $1 -gt 4 ]]; then
      break;
    fi
  done

  log "Burst end"
  return $CMD_STAT
}

export -f charging_set_amps

# set the default value if the initial definition is not correct
if [[ ! $COMMAND_TIMEOUT =~ ^[0-9]+$ ]]; then
  COMMAND_TIMEOUT=0
fi

# return after timeout period. Load config upon executing function 
set +e
timeout -k 1 -s SIGKILL "$COMMAND_TIMEOUT" bash -c ". ${SCRIPTS_PATH}/tesla-ble.conf; charging_set_amps $1"
STATUS=$?
set -e
wait

log "STATUS: $STATUS"

if [[ $STATUS -eq 0 ]]; then
  log "Command set-amps $1 Amps success"
elif [[ $STATUS -eq 137 ]]; then
  log "Fail - Command Timeout"
else
  log "Command set-amps $1 Amps fail"
fi
exit "$STATUS"
