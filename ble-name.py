import sys
from cryptography.hazmat.primitives import hashes

def get_ble_name(vin):
  vin = bytes(vin, "UTF8")
  digest = hashes.Hash(hashes.SHA1())
  digest.update(vin)
  vinSHA = digest.finalize().hex()
  middleSection = vinSHA[0:16]
  bleName = "S" + middleSection + "C"
  return (bleName)

if __name__ == "__main__":
  vin = sys.argv[1]
  print(get_ble_name(vin))

