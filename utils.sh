#!/bin/bash

should-print-help() {
    if [[ $# -eq 0 ||  "$1" == "-h" || "$1" == "--help" ]]
    then
        return 0
    fi
    
    return 1
}

should-print-help-allow-empty() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]
    then
        return 0
    fi
    
    return 1
}

