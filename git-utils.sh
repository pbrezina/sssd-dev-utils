#!/bin/bash

mygit-current-branch() {
    if should-print-help-allow-empty $@
    then 
        echo "Print current git branch" 
    	echo "Usage:"
    	echo "$0" 
    	echo ""
        return 0
    fi

    local BRANCH=`git rev-parse --abbrev-ref HEAD`
    echo $BRANCH
}

mygit-push() {
    if should-print-help-allow-empty $@
    then 
        echo "Push current branch into $GIT_REPOSITORIES repositories" 
    	echo "Usage:"
    	echo "$0" 
    	echo ""
        return 0
    fi

    local BRANCH=$(mygit-current-branch)
    for repo in $GIT_PUSH_REPOSITORIES
    do
        echo "Pushing $BRANCH into $repo"
        git push $repo $BRANCH --force
    done
}

mygit-mv-patch() {
    if should-print-help $@
    then 
        echo "Move and reindex git patch" 
    	echo "Usage:"
    	echo "$0 PATCH NEWINDEX [DIR=$SSSD_RHEL_PACKAGE]" 
    	echo ""
        return 0
    fi

    local PATCHPATH=$1
    local INDEX=$2
    local DIR=${3-$HOME/packages/rhel/sssd}

    local PATCH=$(basename $PATCHPATH)
    local NEWPATCH=$INDEX-${PATCH:5}
    local NEWPATH="$DIR/$NEWPATCH"

    echo "Patch$INDEX:  $NEWPATCH"
    mv $PATCHPATH $NEWPATH
}

mygit-mv-patches() {
    if should-print-help $@
    then 
        echo "Move all git patches in current directory" 
    	echo "Usage:"
    	echo "$0 START-INDEX [DIR=$SSSD_RHEL_PACKAGE]" 
    	echo ""
        return 0
    fi
    
    local INDEX=$((10#$1))
    local DIR=${2-$SSSD_RHEL_PACKAGE}

    for PATCH in *.patch
    do
        printf -v PREFIX '%04d' $INDEX
        mv-patch $PATCH $PREFIX $DIR
        ((INDEX++))
    done
}

mygit-fp() {
    if should-print-help $@
    then 
        echo "Format git patch" 
    	echo "Usage:"
    	echo "$0 'git format-patch attributes'" 
    	echo ""
        return 0
    fi
    
    git format-patch -M -C --patience --full-index $@
}

mygit-am() {
    if should-print-help-allow-empty $@
    then 
        echo "Apply git patches from $GIT_PATCH_LOCATION or from specified files" 
    	echo "Usage:"
    	echo "$0 'git am attributes'" 
    	echo ""
        return 0
    fi
    
    if [ $# -eq 0 ]
    then
        git am --whitespace=fix $GIT_PATCH_LOCATION/*.patch
    else
        git am --whitespace=fix $@
    fi
}

mygit-rm() {
    if should-print-help-allow-empty $@
    then 
        echo "Remove git patches from $GIT_PATCH_LOCATION"  
    	echo "Usage:"
    	echo "$0" 
    	echo ""
        return 0
    fi
    
    rm -f $GIT_PATCH_LOCATION/*.patch
}

mygit-review() {
    if should-print-help-allow-empty $@
    then 
        echo "Review patches from $GIT_PATCH_LOCATION or from pull request"
    	echo "Usage:"
    	echo "$0" 
    	echo ""
        return 0
    fi
    
    git checkout master
    git pull --rebase
    git branch -D review

    if [ $# -eq 0 ]
    then
        git checkout -b review
        mygit-am
    else
        hub checkout $1 review
    fi
}

