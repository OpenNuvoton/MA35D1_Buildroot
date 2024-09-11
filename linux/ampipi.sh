#!/bin/bash

# Check if the DTS file is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path/to/file.dtsi"
    exit 1
fi

# Path to the DTS file
DTS_FILE=$1

# Check if the amp node exists
if grep -q "amp:" "$DTS_FILE"; then
    echo "Attempting to parse amp node..."
else
    echo "Error: AMP node not found!"
    exit 1
fi

# 1. Change status of amp to 'okay'
sed -i '/amp: amp {/,/status =/s/status = "disabled";/status = "okay";/' $DTS_FILE

# 2. Extract rxipi and txipi node references
RXIPI=$(grep -oP '(?<=rxipi = <&)[^>]*' $DTS_FILE)
TXIPI=$(grep -oP '(?<=txipi = <&)[^>]*' $DTS_FILE)

# 3. Change status of rxipi to 'okay'
if [ -n "$RXIPI" ]; then
    sed -i "/$RXIPI:/,/status =/s/status = .*/status = \"okay\";/" $DTS_FILE
else
    echo "Error: rxipi not found!"
fi

# 4. Change status of txipi to 'okay'
if [ -n "$TXIPI" ]; then
    sed -i "/$TXIPI:/,/status =/s/status = .*/status = \"okay\";/" $DTS_FILE
else
    echo "Error: txipi not found!"
fi

echo "Updated $DTS_FILE with 'okay' status for amp, $RXIPI, and $TXIPI."