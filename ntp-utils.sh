#!/bin/bash

ntp-update() {
    if should-print-help-allow-empty $@
    then 
        echo "Update time through ntp" 
    	echo "Usage:"
    	echo "$0 [NTP-SERVER=$NTP_SERVER]" 
    	echo ""
        return 0
    fi

    SERVER=${1:-$NTP_SERVER}

    sudo service ntpd stop
    sudo ntpdate $SERVER
    sudo ntpdate $SERVER
    sudo ntpdate $SERVER
    sudo service ntpd start
}

