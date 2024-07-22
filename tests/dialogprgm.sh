#!/bin/bash

dialog --programbox "Monitoring a command" 20 50 < <(
    for i in {1..10}; do
        echo "Step $i"
        sleep 1
    done
)

