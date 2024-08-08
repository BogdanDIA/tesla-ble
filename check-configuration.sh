#!/bin/bash
# BogdanDIA

echo "" | tee -a helpers-log.txt
echo "`date` get-presence" | tee -a helpers-log.txt

if test -f "./tesla-ble.conf"; then
  echo chech-config: OK: tesla-ble.conf found | tee -a helpers-log.txt
else
  echo check-config: NOK: tesla-ble.conf not found | tee -a helpers-log.txt
fi

source $(dirname "$0")/tesla-ble.conf

if [[ -n "$VIN" ]]; then
  echo check-config: OK: VIN: "$VIN" found | tee -a helpers-log.txt
  LOCAL_PATH=$(dirname "$0")
  BLE_LOCAL_NAME=$(python $(dirname "$0")/ble-name.py $VIN)
  if [[ -n "$BLE_LOCAL_NAME" ]]; then
    echo check-config: OK: BLE_LOCAL_NAME: "$BLE_LOCAL_NAME" calculated
  else
    echo check-config: NOK: BLE_LOCAL_NAME: "$BLE_LOCAL_NAME"
  fi
else
  echo check-config: NOK: VIN: "$VIN" not found | tee -a helpers-log.txt
fi

if ! test -d "$BIN_PATH"; then
  echo check-config: NOK: BIN_PATH: $BIN_PATH not accessible | tee -a helpers-log.txt
else
  echo check-config: OK: BIN_PATH: $BIN_PATH accessible | tee -a helpers-log.txt
fi

if ! test -f "$BIN_PATH/tesla-control"; then
  echo check-config: NOK: tesla-control not found | tee -a helpers-log.txt
else
  echo check-config: OK: tesla-control found | tee -a helpers-log.txt
fi

if [[ -n "$BIN_PATH/$PRIVATE_KEY" ]]; then
  echo check-config: OK: PRIVATE_KEY: $PRIVATE_KEY found | tee -a helpers-log.txt
else
  echo check-config: NOK: PRIVATE_KEY: $PRIVATE_KEY not found | tee -a helpers-log.txt
fi

if ! test -d "$SCRIPTS_PATH"; then
  echo check-config: NOK: SCRIPTS_PATH not accessible| tee -a helpers-log.txt
else
  echo check-config: OK: SCRIPTS_PATH: $SCRIPTS_PATH found | tee -a helpers-log.txt
fi
