#!/bin/bash

export PO4A="po4a"

# Architecture

ARCH=$(uname -p)
LIB=$(rpm --eval %{_lib})
LIBDIR=$(rpm --eval %{_libdir})
NCPU=$(/usr/bin/getconf _NPROCESSORS_ONLN)

# Build options

CFLAGS_COMMON="-m64 -mtune=generic -fstack-protector-all -Wall -Wextra -Wno-sign-compare -Wshadow -Wunused-variable -Wno-unused-parameter -Wno-error=cpp $CFLAGS_CUSTOM"

alias cflags_warning='    CFLAGS="$CFLAGS_COMMON -O0 -ggdb3 -Wp,-U_FORTIFY_SOURCE"'
alias cflags_devel='      CFLAGS="$CFLAGS_COMMON -O0 -ggdb3 -Werror -Wp,-U_FORTIFY_SOURCE"'
alias cflags_early_devel='CFLAGS="$CFLAGS_COMMON -O0 -ggdb3 -Werror -Wno-unused-but-set-variable -Wp,-U_FORTIFY_SOURCE"'
alias cflags_optimize='   CFLAGS="$CFLAGS_COMMON -O3"'

cflags_devel
export CFLAGS

# Build

alias make='make -j $NCPU'
alias make-only-errors='make 1> /dev/null'

# Configure SSSD

alias configure-mans='$SSSD_SOURCE/configure \
                         --build=$ARCH-unknown-linux-gnu \
                         --host=$ARCH-unknown-linux-gnu \
                         --target=$ARCH-redhat-linux-gnu \
                         --program-prefix= \
                         --prefix=/usr \
                         --exec-prefix=/usr \
                         --bindir=/usr/bin \
                         --sbindir=/usr/sbin \
                         --sysconfdir=/etc \
                         --datadir=/usr/share \
                         --includedir=/usr/include \
                         --libdir=$LIBDIR \
                         --libexecdir=/usr/libexec \
                         --localstatedir=/var \
                         --sharedstatedir=/var/lib \
                         --mandir=/usr/share/man \
                         --infodir=/usr/share/info \
                         --enable-nsslibdir=/$LIB \
                         --enable-pammoddir=/$LIB/security \
                         --with-test-dir=/dev/shm/sssd-tests \
                         --enable-silent-rules \
                         --enable-all-experimental-features'

alias configure='configure-mans --without-manpages'

# Build SSSD

alias cd-sssd-build='mkdir $SSSD_BUILD &> /dev/null && cd $SSSD_BUILD'
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

