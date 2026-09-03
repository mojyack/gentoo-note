#!/bin/sh

url="https://gist.githubusercontent.com/kiding/34916dd163d700098980ec0b8901a033/raw/37c0ea4071cfa89e663644c743ecd899aed5fb0c"
out="/tmp"

curl -L "$url/BCM.hcd.b64" | base64 -d > "$out/BCM.hcd"
curl -L "$url/brcmfmac4356a3-pcie.bin.b64" | base64 -d > "$out/brcmfmac4356a3-pcie.bin"
curl -L "$url/brcmfmac4356a3-pcie.txt" > "$out/brcmfmac4356a3-pcie.txt"
