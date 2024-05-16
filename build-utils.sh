#!/bin/bash

_SSSSCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export PO4A="po4a"

# Architecture

LIB=`rpm --eval %{_lib}`
LIBDIR=`rpm --eval %{_libdir}`
NCPU=`/usr/bin/getconf _NPROCESSORS_ONLN`

# Build options

CFLAGS_COMMON="-m64 -mtune=generic -fstack-protector-all -Wall -Wextra -Wno-sign-compare -Wshadow -Wunused-variable -Wno-unused-parameter -Wno-error=cpp -Wno-error=deprecated-declarations $CFLAGS_CUSTOM"

alias cflags_warning='    CFLAGS="$CFLAGS_COMMON -O0 -ggdb3 -Wp,-U_FORTIFY_SOURCE"'
alias cflags_devel='      CFLAGS="$CFLAGS_COMMON -O0 -ggdb3 -Werror -Wp,-U_FORTIFY_SOURCE"'
alias cflags_early_devel='CFLAGS="$CFLAGS_COMMON -O0 -ggdb3 -Werror -Wno-unused-but-set-variable -Wp,-U_FORTIFY_SOURCE"'
alias cflags_optimize='   CFLAGS="$CFLAGS_COMMON -O3"'

shopt -s expand_aliases
cflags_devel
export CFLAGS

# Build

alias make='make -j $NCPU'
alias make-only-errors='make 1> /dev/null'

# Configure SSSD

if [ ! -d $SSSD_TEST_DIR ]; then
    mkdir $SSSD_TEST_DIR
fi

RPM_FLAGS=""
for flag in $(< "$_SSSSCRIPTDIR/rpms_flags"); do
    RPM_FLAGS+=" --$flag=`rpm --eval %{_$flag}`"
done

# Additional flags for RHEL
if [ `rpm --eval 0%{?rhel}` -ne 0 ] ; then
    RPM_FLAGS+=" --without-python3-bindings"
    RPM_FLAGS+=" --with-ad-gpo-default=permissive"
    RPM_FLAGS+=" --without-secrets"
fi

alias configure-mans="$SSSD_SOURCE/configure $RPM_FLAGS \
                         --program-prefix= \
                         --exec-prefix=`rpm --eval %{_prefix}` \
                         --with-test-dir=$SSSD_TEST_DIR \
                         --with-sssd-user=$SSSD_USER \
                         --with-initscript=systemd \
                         --enable-nsslibdir=$LIBDIR \
                         --enable-pammoddir=$LIBDIR/security \
                         --enable-nfsidmaplibdir=$LIBDIR/libnfsidmap \
                         --enable-silent-rules \
                         --enable-all-experimental-features"

alias configure='configure-mans --without-manpages'

# Build SSSD

alias cd-sssd-build='mkdir $SSSD_BUILD &> /dev/null ; cd $SSSD_BUILD'
alias cd-sssd-source='cd $SSSD_SOURCE'

alias sssd-install='sudo make install && sudo rm -f $LIBDIR/ldb/modules/ldb/memberof.la'
alias sssd-reconfig='cd-sssd-source && rm -fr $SSSD_BUILD && autoreconf -if && cd-sssd-build && configure'
alias sssd-reconfig-mans='cd-sssd-source && rm -fr $SSSD_BUILD && autoreconf -if && cd-sssd-build && configure-mans'

alias rebuild='sssd-reconfig && make'
alias rebuild-mans='sssd-reconfig-mans && make'

test-build() {
    cd-sssd-source

    CURRENT=`mygit-current-branch`
    BRANCH=${1-$CURRENT}
    REBUILD=${2-false}

    if [ "$CURRENT" != "$BRANCH" ] ; then
        REBUILD="true"
    fi

    if [ ! -f "$SSSD_BUILD/Makefile" ] ; then
        REBUILD="true"
    fi

    git stash
    git fetch $GIT_DEVEL_REPOSITORY
    git checkout $1
    git pull --rebase

    if [ "$REBUILD" = "true" ] ; then
        rebuild
    else
        cd-sssd-build
        make
    fi
}

run-integration-test() {
    if should-print-help $@
    then
        echo "Run specific integration test"
        echo "Make sure 'make intgcheck' has been run before this call!"
        echo "Usage:"
        echo "$0 TEST-NAME"
        echo ""
        return 0
    fi

    cd-sssd-build
    INTGCHECK_PYTEST_ARGS="-s -k$1" make -C intg/bld/src/tests/intg/ intgcheck-installed
}
