#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 path/to/file.dtsi target_cpu shmem_base shmem_size"
    exit 1
fi

# Input arguments
DTS_FILE=$1
TARGET_CPU=$2
SHMEM_BASE=$3
SHMEM_SIZE=$4

# Check if the DTSI file exists
if [ ! -f "$DTS_FILE" ]; then
    echo "Error: File '$DTS_FILE' not found!"
    exit 1
fi

# Extract the node name referenced in memory-region
if [ "$TARGET_CPU" = "A" ]; then
    if grep -q "amp:" "$DTS_FILE"; then
        echo "Attempting to parse amp node..."
    else
        echo "Error: AMP node not found!"
        exit 1
    fi
    MEMORY_REGION=$(awk '/amp: amp/,/}/' "$DTS_FILE" | grep -oP '(?<=memory-region = <&)[^>]+')
else
    if grep -q "ampm:" "$DTS_FILE"; then
        echo "Attempting to parse ampm node..."
    else
        echo "Error: AMPM node not found!"
        exit 1
    fi
    MEMORY_REGION=$(awk '/ampm: ampm/,/}/' "$DTS_FILE" | grep -oP '(?<=memory-region = <&)[^>]+')
fi

if [ -z "$MEMORY_REGION" ]; then
    echo "Error: Unable to find memory-region in amp node."
    exit 1
fi

echo "Found memory-region reference: $MEMORY_REGION"

# Update the base address and size in the reserved-memory node
sed -i -E "/$MEMORY_REGION:/,/no-map;/s/(<0x0 )0x[0-9a-fA-F]+( 0x0 )0x[0-9a-fA-F]+/\1$SHMEM_BASE\2$SHMEM_SIZE/" "$DTS_FILE"

echo "Updated $MEMORY_REGION node with base address: $SHMEM_BASE and size: $SHMEM_SIZE in $DTS_FILE."

if [ "$TARGET_CPU" = "A" ]; then

    # 1. Change status of amp to 'okay'
    sed -i '/amp: amp {/,/status =/s/status = .*;/status = "okay";/' $DTS_FILE
    if grep -q "rpmsg {" "$DTS_FILE"; then
        sed -i '/rpmsg {/,/status =/s/status = .*;/status = "disabled";/' $DTS_FILE
    fi

    # 2. Extract rxipi and txipi node references
    AMP_NODE=$(awk '/amp: amp {/,/};/' "$DTS_FILE")
    RXIPI=$(echo "$AMP_NODE" | grep -oP '(?<=rxipi = <&)[^>]+')
    TXIPI=$(echo "$AMP_NODE" | grep -oP '(?<=txipi = <&)[^>]+')

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

else

    # 1. Change status of ampm to 'okay', change status of rpmsg to 'disabled'
    sed -i '/ampm: ampm {/,/status =/s/status = .*;/status = "okay";/' $DTS_FILE
    if grep -q "rpmsg {" "$DTS_FILE"; then
        sed -i '/rpmsg {/,/status =/s/status = .*;/status = "disabled";/' $DTS_FILE
    fi

    echo "Updated $DTS_FILE with 'okay' status for ampm."

fi

