#!/bin/bash
# Author: Andrew Rivett <VA3NED@qruqsp.org> based on original setup.sh by Calvin GLuck <W7KYG@qruqsp.org>
#
#
# This script is designed to build the binaries required for the raspberry pi and copy them 
# into the bin directory
#
# This script must be run from inside the pibin module

# Verify that gcc is configured to generate hardware floating point code. 
# Enter the “gcc –v” command and observe the result. 
# Make sure that “--with-fpu=vfp --with-float=hard” appears in the configuration.
if [ `gcc -v 2>&1 | egrep -c 'with-fpu=vfp'` -ne 1 ]
then
    echo "FAIL: gcc is NOT configured with --with-fpu=vfp to generate hardware floating point code."
    exit 1
else
    echo "OK: gcc is configured with --with-fpu=vfp as required to generate hardware floating point code."
fi
if [ `gcc -v 2>&1 | egrep -c 'with-float=hard'` -ne 1 ]
then
    echo "FAIL: gcc is NOT configured with --with-float=hard to generate hardware floating point code."
    exit 1
else
    echo "OK: gcc is configured with --with-float=hard to generate hardware floating point code."
fi

if [ ! -d bin ]; then
    echo "FAIL: must be located within pibin module"
    exit 1;
fi

if [ ! -d src ]; then
    mkdir src
fi

#
# FIXME: Need to get hamlib setup
#
echo "Attempting to wget hamlib and make it to provide support for more types of PTT control..."
wget -O src/hamlib-latest.tar.gz "https://downloads.sourceforge.net/project/hamlib/hamlib/3.0.1/hamlib-3.0.1.tar.gz?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fhamlib%2F%3Fsource%3Dtyp_redirect&ts=1514591482&use_mirror=svwh" 
    (cd src && tar xzf hamlib-latest.tar.gz)
    (cd src/hamlib-3.0.1 && ./configure --prefix=/ciniki/sites/qruqsp.local/site/qruqsp-mods/pibin)
    make -C src/hamlib-3.0.1
    make -C src/hamlib-3.0.1 check
#    make -C src/hamlib-3.0.1 install

#echoAndLog "Check for files that should have been created by the make of hamlib..."
## You should now have many new files including:
#checkFiles /usr/local/include/hamlib/rig.h /usr/local/lib/libhamlib.so


if [ -f src/direwolf/Makefile ]
then
    echo "It looks like we have already pulled direwolf from github"
    (cd src/direwolf & git pull)
else
    echo "* git clone direwolf"
    git clone https://www.github.com/wb2osz/direwolf src/direwolf 
fi

#
# Build direwolf
#
# When building direwolf, the compiler and linker know enough to search /usr/local/include/... and /usr/local/lib/... but when it comes time to run direwolf, you might see a message like this:
# direwolf: error while loading shared libraries: libhamlib.so.2: cannot open shared object file: No such file or directory
# Edit your ~/.bashrc file and add this after the initial comment lines, and before the part that tests for running interactively.
#set LD_LIBRARY_PATH=/ciniki/sites/qruqsp.local/site/qruqsp-mods/pibin/lib
#export LD_LIBRARY_PATH
# Type this so it will take effect now, instead of waiting for next login:
#    source ~/.bashrc
# Edit direwolf/Makefile.linux and look for this section:
# Uncomment following lines to enable hamlib support. 
#CFLAGS += -DUSE_HAMLIB
#LDFLAGS += -lhamlib
#perl -pi -e 
# Staticly link libham so not dependency issues
sed -i 's/wildcard \/usr\/include\/hamlib/wildcard ..\/..\/src\/hamlib-3.0.1\/include\/rig.h \/usr\/include\/hamlib/; s/-lhamlib$/-ldl ..\/..\/lib\/libhamlib.a/; s/#CFLAGS/CFLAGS/g; s/#LDFLAGS/LDFLAGS/g' src/direwolf/Makefile.linux
#egrep -i 'hamlib' src/direwolf/Makefile.linux 

# Compile an install the Direwolf application.
# cd ~/direwolf
make -C src/direwolf clean
make -C src/direwolf 
#DESTDIR=/ciniki/sites/qruqsp.local/site/qruqsp-mods/pibin 

cp src/direwolf/direwolf bin/
cp src/direwolf/kissutil bin/

#    # NOTE The above 'sudo make install' outputs the following but don't do it yet.
#    # If this is your first install, not an upgrade, type this to put a copy
#    # of the sample configuration file (direwolf.conf) in your home directory:
#    # make install-conf
#    # This gets done a little later after verification of a few required files
#
#    make -C /ciniki/src/direwolf install-rpi
#
#    # OUTPUT from make install-rpi
#    # cp dw-start.sh ~
#    # ln -f -s /usr/share/applications/direwolf.desktop ~/Desktop/direwolf.desktop

#
# Install rtl-sdr software
#
if [ -d src/rtl-sdr/cmake ]
then
    echo "OK: It appears that we already did git clone rtl-sdr"
    (cd src/rtl-sdr & git pull)
else
    echo "* Attempting to git clone rtl-sdr"
    git clone git://git.osmocom.org/rtl-sdr.git src/rtl-sdr
fi

if [ -d src/rtl-sdr/build ]
then
    echo "OK: It appears that we already did a build of rtl-sdr"
else
    mkdir src/rtl-sdr/build
fi
(cd src/rtl-sdr/build && cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON) 
make -C src/rtl-sdr/build
cp src/rtl-sdr/build/src/rtl_* bin/


# git clone rtl_433
if [ -d src/rtl_433/build ]
then
    echo "OK: It appears that we already did a build of rtl_433"
    (cd src/rtl_433 & git pull)
else
    git clone https://github.com/merbanan/rtl_433 src/rtl_433
    mkdir -p src/rtl_433/build
fi
(cd src/rtl_433/build && cmake ../ ) 
make -C src/rtl_433/build
cp src/rtl_433/build/src/rtl_* bin/
