#!/bin/bash
# BogdanDIA

. $(dirname "$0")/tesla-ble.conf
cd "$BIN_PATH"

charging_wake()
{
  # load config
  . $(dirname "$0")/tesla-ble.conf
  # cd to BIN_PATH
  cd "$BIN_PATH"
  echo "" | tee -a charging-log.txt
  echo "`date` wake" | tee -a charging-log.txt
  echo "BIN_PATH: $BIN_PATH" | tee -a charging-log.txt
  echo "VIN: $VIN" | tee -a charging-log.txt
  echo "PWD: `pwd`" | tee -a charging-log.txt
  echo "SCRIPTS_PATH: $SCRIPTS_PATH" | tee -a charging-log.txt
  echo "COMMAND_TIMEOUT: $COMMAND_TIMEOUT" | tee -a charging-log.txt
  echo "Burst start" | tee -a charging-log.txt

  if [[ -n $VIN ]];then
    echo VIN provided | tee -a charging-log.txt
  else
    echo no VIN provided in tesla-config.conf. Exiting... | tee -a charging-log.txt
  fi

  if [[ -n $PRIVATE_KEY ]];then
    echo PRIVATE_KEY provided | tee -a charging-log.txt
  else
    echo no PRIVATE_KEY provided in tesla-config.conf. Exiting... | tee -a charging-log.txt
  fi

  CMD_OUT=""
  CMD_STAT=""

  for (( i=0; i<5; i++ ))
  do
    CMD_OUT=$(./tesla-control -vin "$VIN" -key-file "$PRIVATE_KEY" -ble -domain vcsec wake)
    CMD_STAT="$?"
    if [[ "$CMD_STAT" -eq 0 ]]; then
      echo Ok: try: $i, CMD_OUT: "$CMD_OUT" | tee -a charging-log.txt
      break
    else
      echo Fail: try: $i, CMD_OUT: "$CMD_OUT" | tee -a charging-log.txt
    fi
  done

  echo CMD_OUT: "$CMD_OUT"
  echo CMD_STAT: "$CMD_STAT"

  echo "Burst end" | tee -a charging-log.txt

  if [[ $CMD_STAT -eq 0 ]]; then
    echo Car wake success | tee -a charging-log.txt
    return 0
  else
    echo Car wake failed | tee -a charging-log.txt
    return 1
  fi
}

export -f charging_wake
  
# set the default value if the initial definition is not correct
if [[ ! $COMMAND_TIMEOUT =~ ^[0-9]+$ ]]; then
  COMMAND_TIMEOUT=0
fi
  
# return after the timeout period
OUT=$(timeout --preserve-status -k 1 -s SIGKILL "$COMMAND_TIMEOUT" bash -c "charging_wake")
STATUS=$?
echo "$OUT"
  
if [[ ! STATUS -eq 0 ]]; then
  echo "Fail - Command Timeout" | tee -a charging-log.txt
  echo "Command Timeout" >&2
fi
exit "$STATUS" 

