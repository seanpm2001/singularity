#!/bin/sh

if [ ! -f "autogen.sh" ]; then
    echo "ERROR: Run this from the singularity source root"
    exit 1
fi

if [ ! -f "libexec/functions" ]; then
    echo "ERROR: Could not find functions file"
    exit 1
fi

MESSAGELEVEL=2
TEMPDIR=`mktemp -d /tmp/singularity-test.XXXXXX`
SINGULARITY_CACHEDIR="$TEMPDIR"
export SINGULARITY_CACHEDIR MESSAGELEVEL

. ./libexec/functions



echo "${BLUE}Gaining/checking sudo access...${NORMAL}"
sudo true

echo "${BLUE}Building/Installing Singularity to temporary directory${NORMAL}"
stest 0 sh ./autogen.sh --prefix="$TEMPDIR"
stest 0 make
stest 0 make install
stest 0 sudo make install-perms

PATH="$TEMPDIR/bin:$PATH"

echo "${BLUE}Creating temp working space at: $TEMPDIR${NORMAL}"
stest 0 mkdir -p "$TEMPDIR"
stest 0 pushd "$TEMPDIR"

echo "${BLUE}Running tests...${NORMAL}"

# Testing singularity internal commands
stest 0 singularity
stest 0 singularity help
stest 0 singularity help build
stest 0 singularity help check
stest 0 singularity help delete
stest 0 singularity help help
stest 0 singularity help install
stest 0 singularity help list
stest 0 singularity help run
stest 0 singularity help shell
stest 0 singularity help specgen
stest 0 singularity help strace
stest 1 singularity help blahblah
stest 0 singularity -h
stest 0 singularity --help
stest 0 singularity --version

# Creating a minimal container
stest 0 sh -c "echo 'Name: cat' > example.sspec"
stest 0 sh -c "echo 'Exec: /bin/cat' >> example.sspec"
stest 0 singularity --quiet build example.sspec

# Running basic tests on sapp directly
stest 1 ls $TEMPDIR/tmp/*
stest 0 ./cat.sapp example.sspec
stest 0 ./cat.sapp /etc/hosts
stest 0 ./cat.sapp /etc/resolv.conf
stest 1 ./cat.sapp /etc/passwd
stest 1 ./cat.sapp /etc/shadow
stest 0 sh -c "cat example.sspec | ./cat.sapp | grep -q '^Name'"
stest 1 ls $TEMPDIR/tmp/*

# Making sure cache is empty and installing cat.sapp
stest 1 singularity list
stest 0 singularity install cat.sapp
stest 0 singularity list
stest 0 singularity check cat

# Running 'cat' from singularity cache
stest 0 singularity run cat example.sspec
stest 0 singularity run cat /etc/hosts
stest 0 singularity run cat /etc/resolv.conf
stest 1 singularity run cat /etc/passwd
stest 1 singularity run cat /etc/shadow
stest 0 sh -c "cat example.sspec | singularity run cat | grep -q '^Name'"

# Checking additional tests and functions of installed containers
stest 0 sh -c "echo 'exit' | singularity shell cat"
stest 1 sh -c "echo 'exit 1' | singularity shell cat"
stest 0 sh -c "echo 'echo hello' | singularity shell cat | grep -q 'hello'"
stest 0 singularity strace cat example.sspec
stest 0 singularity test cat

# Cleaning up
stest 0 singularity delete cat
stest 1 singularity list



echo "${BLUE}Cleaning up${NORMAL}"
stest 0 popd
stest 0 rm -rf "$TEMPDIR"
stest 0 make maintainer-clean

echo
echo "${GREEN}Done. All tests completed successfully${NORMAL}"
echo
