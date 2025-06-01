package ble

import (
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/go-ble/ble"
	"github.com/go-ble/ble/linux"
	"github.com/go-ble/ble/linux/hci/cmd"
)

func IsAdapterError(err error) bool {
	return strings.Contains(err.Error(), "operation not permitted")
}

func AdapterErrorHelpMessage(err error) string {
	// The underlying BLE package calls HCIDEVDOWN on the BLE device, presumably as a
	// heavy-handed way of dealing with devices that are in a bad state.
	return "Failed to initialize BLE adapter: \n\t" + err.Error() + "\n" +
		"Try again after granting this application CAP_NET_ADMIN or running with root:\n\n" +
		"\tsudo setcap 'cap_net_admin=eip' \"$(which " + os.Args[0] + ")\""
}

const bleTimeout = 20 * time.Second

// TODO: Depending on the model and state, BLE advertisements come every 20ms or every 150ms.

var scanParams = cmd.LESetScanParameters{
	LEScanType:           1,    // Active scanning
	LEScanInterval:       0x10, // 10ms
	LEScanWindow:         0x10, // 10ms
	OwnAddressType:       0,    // Static
	ScanningFilterPolicy: 0,    // Change from 0x02 to 0, Basic filtered - support for BT4.x
}

var createConnection = cmd.LECreateConnection{
  LEScanInterval:        0x0010,    // 0x0004 - 0x4000; N * 0.625 msec
  LEScanWindow:          0x0010,    // 0x0004 - 0x4000; N * 0.625 msec
  InitiatorFilterPolicy: 0x00,      // White list is not used
  PeerAddressType:       0x00,      // Public Device Address
  PeerAddress:           [6]byte{}, //
  OwnAddressType:        0x00,      // Public Device Address
  ConnIntervalMin:       0x0006,    // 0x0006 - 0x0C80; N * 1.25 msec
  ConnIntervalMax:       0x0006,    // 0x0006 - 0x0C80; N * 1.25 msec
  ConnLatency:           0x0000,    // 0x0000 - 0x01F3; N * 1.25 msec
  SupervisionTimeout:    0x0048,    // 0x000A - 0x0C80; N * 10 msec
  MinimumCELength:       0x0000,    // 0x0000 - 0xFFFF; N * 0.625 msec
  MaximumCELength:       0x0000,    // 0x0000 - 0xFFFF; N * 0.625 msec
}

func newAdapter(id *string) (ble.Device, error) {
	opts := []ble.Option{
		ble.OptDialerTimeout(bleTimeout),
		ble.OptListenerTimeout(bleTimeout),
		ble.OptScanParams(scanParams),
		ble.OptConnParams(createConnection),
	}
	if id != nil && *id != "" {
		if !strings.HasPrefix(*id, "hci") {
			return nil, ErrAdapterInvalidID
		}
		hciStr := strings.TrimPrefix(*id, "hci")
		hciID, err := strconv.Atoi(hciStr)
		if err != nil || hciID < 0 || hciID > 15 {
			return nil, ErrAdapterInvalidID
		}
		opts = append(opts, ble.OptDeviceID(hciID))
	}

	device, err := linux.NewDeviceWithName("vehicle-command", opts...)
	if err != nil {
		return nil, err
	}
	return device, nil
}
