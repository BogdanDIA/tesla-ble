#!/bin/bash
# BogdanDIA

if [[ "$#" -eq 0 ]]; then
  echo No parameter passed, exiting...
  exit 1
fi 

. $(dirname "$0")/tesla-ble.conf
cd "$BIN_PATH"

charging_set_amps()
{
  # load config
  . $(dirname "$0")/tesla-ble.conf
  # cd to BIN_PATH
  cd "$BIN_PATH"
  echo "" | tee -a charging-log.txt
  echo "`date` set-amps $1 Amps" | tee -a charging-log.txt
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

  if [[ -n $PRIVATE_KEY ]];then
    echo PRIVATE_KEY provided | tee -a charging-log.txt
  else
    echo no PRIVATE_KEY provided in tesla-config.conf. Exiting... | tee -a charging-log.txt
  fi

  CMD_STAT=-1

  # execute the command twice only if target Amps is under 5 Amps

  for (( count=0; count<2; count++ ))
  do
    for (( i=0; i<5; i++ ))
    do
      TMP_OUT=$(./tesla-control -vin "$VIN" -key-file "$PRIVATE_KEY" -ble charging-set-amps "$1" 2>&1)
      TMP_STAT="$?"

      if [[ "$TMP_STAT" -eq 0 ]]; then
        echo Ok count: $count, try: $i, TMP_OUT: "$TMP_OUT" | tee -a charging-log.txt
        break
      else
        echo Fail count: $count, try: $i, TMP_OUT: "$TMP_OUT" | tee -a charging-log.txt
      fi
    done

    # AND the status for both loops 
    CMD_STAT=$(($CMD_STAT & $TMP_STAT))
    echo count: $count, CMD_STAT: $CMD_STAT | tee -a charging-log.txt

    # if first loop fails then we quit 
    if [[ $count -eq 0 ]] && [[ "$CMD_STAT" -ne 0 ]]; then
      break
    fi

    # if target Amps is above 4 we don't execute second loop
    if [[ $1 -gt 4 ]]; then
      break;
    fi
  done

  echo "Burst end" | tee -a charging-log.txt

  if [[ "$CMD_STAT" -eq 0 ]]; then
    echo Car Charging set to $1 Amps success | tee -a charging-log.txt
    return 0
  else
    echo Car Charging Set to $1 Amps failed | tee -a charging-log.txt
    return 1
  fi 
}

export -f charging_set_amps
  
# set the default value if the initial definition is not correct
if [[ ! $COMMAND_TIMEOUT =~ ^[0-9]+$ ]]; then
  COMMAND_TIMEOUT=0
fi
  
# return after the timeout period
OUT=$(timeout --preserve-status -k 1 -s SIGKILL "$COMMAND_TIMEOUT" bash -c "charging_set_amps $1")
STATUS=$?
echo "$OUT"

if [[ ! STATUS -eq 0 ]]; then
  echo "Fail - Command Timeout" | tee -a charging-log.txt
  echo "Command Timeout" >&2
fi
exit "$STATUS"
