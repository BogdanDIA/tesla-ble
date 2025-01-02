function ble-name() {
  VIN=$1
  BLE_NAME=""
  BLE_NAME="S$(echo -n ${VIN} | sha1sum | cut -c 1-16)C"

  echo $BLE_NAME
}
