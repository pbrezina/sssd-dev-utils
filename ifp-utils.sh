#!/bin/bash

export IFP="org.freedesktop.sssd.infopipe"
export IFP_IFACE=$IFP
export IFP_PATH="/org/freedesktop/sssd/infopipe"

ifp-send() {
    if should-print-help $@
    then 
        echo "Send an InfoPipe request" 
    	echo "Usage:"
    	echo "$0 OBJECT-PATH METHOD ARGUMENTS" 
    	echo ""
    	echo "InfoPipe prefix for object path and method may be skipped."
    	echo "Example: ifp-send Users Users.FindByName string:John"
        return 0
    fi
    
    local OBJECT=$1
    local METHOD=$2
    local ARGS=${@:3}

    if [[ $OBJECT != /* ]]
    then
        OBJECT=`echo "$IFP_PATH/$OBJECT" | sed 's/\/$//'`
    fi

    if [[ $METHOD != org.* ]]
    then
        METHOD="$IFP_IFACE.$METHOD"
    fi

    echo "Calling $METHOD on $OBJECT"

    dbus-send --print-reply --system --dest=$IFP $OBJECT $METHOD $ARGS
}

ifp-get() {
    if should-print-help $@
    then 
        echo "Send an InfoPipe DBus.Property.Get request" 
    	echo "Usage:"
    	echo "$0 OBJECT-PATH INTERFACE PROPERTY" 
    	echo ""
        return 0
    fi

    local OBJECT=$1
    local IFACE=$2
    local PROPERTY=$3

    ifp-send $OBJECT org.freedesktop.DBus.Properties.Get string:$IFACE string:$PROPERTY
}

ifp-get-all() {
    if should-print-help $@
    then 
        echo "Send an InfoPipe DBus.Property.GetAll request" 
    	echo "Usage:"
    	echo "$0 OBJECT-PATH INTERFACE" 
    	echo ""
        return 0
    fi
    
    local OBJECT=$1
    local IFACE=$2

    ifp-send $OBJECT org.freedesktop.DBus.Properties.GetAll string:$IFACE
}

ifp-introspect() {
    if should-print-help $@
    then 
        echo "Send an InfoPipe DBus.Introspectable.Introspect request" 
        echo "Usage:"
        echo "$0 OBJECT-PATH" 
        echo ""
        echo "Example: ifp-introspect /org/freedesktop/sssd/infopipe"
        return 0
    fi
    
    local OBJECT=$1

    ifp-send $OBJECT org.freedesktop.DBus.Introspectable.Introspect
}
