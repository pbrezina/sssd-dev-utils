#!/bin/bash

_SSSSCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sss-rename-codefile() {
    if should-print-help $@
    then 
        echo "Rename codefile and replaces its name in all files" 
    	echo "Usage:"
    	echo "$0 OLDNAME NEWNAME" 
    	echo ""
        return 0
    fi

    local OLDNAME=$1
    local NEWNAME=$2
    
    local NOSRC_OLDNAME=${OLDNAME/#src\//}
    local NOSRC_NEWNAME=${NEWNAME/#src\//}

    local MAKE_SED="s/${OLDNAME//\//\\\/}/${NEWNAME//\//\\\/}/g"
    local CODE_SED="s/${NOSRC_OLDNAME//\//\\\/}/${NOSRC_NEWNAME//\//\\\/}/g"

    echo "Renaming $OLDNAME to $NEWNAME"
    git mv $OLDNAME $NEWNAME

    echo "Replacing $OLDNAME for $NEWNAME in *.am"
    find . -type f -name "*.am" -exec sed -i $MAKE_SED {} +

    echo "Replacing $NOSRC_OLDNAME for $NOSRC_NEWNAME in *.c and *.h"
    find . -type f -name "*.c" -exec sed -i $CODE_SED {} +
    find . -type f -name "*.h" -exec sed -i $CODE_SED {} +

    git commit -a -m "Rename $(basename $OLDNAME) to $(basename $NEWNAME)"
}

sss-brew-repo() {
    if should-print-help $@
    then 
        echo "Prepare brew repository with newest packages" 
    	echo "Usage:"
    	echo "$0 RHEL-VERSION" 
    	echo ""
        return 0
    fi

    local RHEL=$1
    local pkgnames="libtalloc libtevent libtdb libldb ding-libs"
    local tag=$RHEL-temp-override
    local repo=$RHEL-build
 
    for pkg in $pkgnames; do
        local latest=$(brew -q latest-pkg rhel-7.3-candidate $pkg 2>/dev/null | awk '{print $1}')
        brew tag-pkg $tag $latest
    done

    brew wait-repo $repo --build $latest
}

sss-brew-rpms-fetch() {
    if should-print-help $@
    then 
        echo "Download SSSD RPMs from brew build, located at \$BREW_URL ($BREW_URL)" 
    	echo "Usage:"
    	echo "$0 URL-TO-ANY-PACKAGE" 
    	echo ""
        return 0
    fi

	local URL=$1
	local PATTERN="^\($BREW_URL/brewroot/work/tasks/[0-9]*/[0-9]*/\)[^0-9]*\(.*\)\.\(.*\)\.rpm$"
    
    for rpm in $(< "$_SSSSCRIPTDIR/rpms_arch"); do
        wget $(echo $URL | sed 's|'$PATTERN'|\1'$rpm'-\2.\3.rpm|')
    done

    for rpm in $(< "$_SSSSCRIPTDIR/rpms_noarch"); do
        wget $(echo $URL | sed 's|'$PATTERN'|\1'$rpm'-\2.noarch.rpm|')
    done
}

sss-brew-rpms-push() {
    if should-print-help $@
    then 
        echo "Push SSSD RPMs into fedorapeople scratch build" 
    	echo "Usage:"
    	echo "$0 BUILD-NAME" 
    	echo ""
        return 0
    fi

    local SCRATCH="public_html/scratch/${1}"
    ssh fedorapeople.org "rm -frv $SCRATCH ; mkdir -p $SCRATCH"
    scp *.rpm fedorapeople.org:$SCRATCH
}

sss-brew-scratch-build() {
    if should-print-help-allow-empty $@
    then 
        echo "Issue an SSSD scratch build" 
    	echo "Usage:"
    	echo "$0 [RHEL-VERSION=current-branch]" 
    	echo ""
        return 0
    fi
    
    local BRANCH="$(mygit-current-branch)"
    local SRPM=$(rhpkg srpm 2> /dev/null | tail -n 2 | sed 's/^Wrote: //')
    local RHEL=${1-$BRANCH}

    rhpkg --release $RHEL scratch-build --srpm $SRPM
}

sss-run() {
    rm -f /var/lib/sss/db/* /var/log/sssd/*
    sssd -i -d 0x3ff0 ${1-}
}

sss-talloc-report() {
    if should-print-help $@
    then 
        echo "Generate a talloc report from SSSD binary." 
        echo "Usage:"
        echo "$0 SSSD-PROCESS [FILENAME/tmp/sssd.talloc/@process.@timestamp]" 
        echo ""
        return 0
    fi
    
    local TIME=`date +"%s"`
    local PROGRAM=$1
    local FILE=$2
    local DIR="/tmp/sssd.talloc"
    local PROCESS=""
    
    if [ -z "$FILE" ]
    then
        mkdir -p $DIR
        FILE="$DIR/$PROGRAM.$TIME"
    fi
    
    pgrep $PROGRAM &> /dev/null
    if [ $? -eq 0 ];
    then
        PROCESS=`pgrep $PROGRAM | head -n 1`
    else
        echo "No such process."
        return 1
    fi
    
    echo "Attaching GDB to $PROGRAM with PID $PROCESS"
        
    sudo gdb -quiet -batch -p $PROCESS \
        -ex "set \$file = (FILE*)fopen(\"$FILE\", \"w+\")" \
        -ex 'call talloc_enable_null_tracking()' \
        -ex 'call talloc_report_full(0, $file)' \
        -ex 'detach' \
        -ex 'quit' &> /dev/null
        
    if [ $? -eq 0 ];
    then
        echo "Talloc report generated to: $FILE"
    else
        echo "Unable to generate talloc report."
    fi
}
