#!/bin/bash

# Get prerequisite packages:
PREREQUISITE_PACKAGES="build-essential g++ libudev-dev libdbus-1-dev libusb-1.0-0-dev zlib1g-dev libpng-dev libjpeg-dev libtiff-dev libasound2-dev libspeex-dev libopenal-dev libv4l-dev libdc1394-22-dev libtheora-dev libbluetooth-dev libxi-dev libxrandr-dev mesa-common-dev libgl1-mesa-dev libglu1-mesa-dev"
echo "Please enter your password to install Vrui's prerequisite packages"
sudo apt-get install $PREREQUISITE_PACKAGES
INSTALL_RESULT=$?

if [ $INSTALL_RESULT -ne 0 ]; then
	echo "Problem while downloading prerequisite packages; please fix the issue and try again"
	exit $INSTALL_RESULT
fi

# Create src directory:
echo "Creating source code directory $HOME/src"
cd $HOME
mkdir src
cd src
CD_RESULT=$?

if [ $CD_RESULT -ne 0 ]; then
	echo "Could not create source code directory $HOME/src. Please fix the issue and try again"
	exit $CD_RESULT
fi

# Determine current Vrui version:
VRUI_CURRENT_RELEASE=$(wget -q -O - http://idav.ucdavis.edu/~okreylos/ResDev/Vrui/CurrentVruiRelease.txt)
GETVERSION_RESULT=$?
if [ $GETVERSION_RESULT -ne 0 ]; then
	echo "Could not determine current Vrui release number; please check your network connection and try again"
	exit $GETVERSION_RESULT
fi
read VRUI_VERSION VRUI_RELEASE <<< "$VRUI_CURRENT_RELEASE"

# Download and unpack Vrui tarball:
echo "Downloading Vrui-$VRUI_VERSION-$VRUI_RELEASE into $HOME/src"
wget -O - http://idav.ucdavis.edu/~okreylos/ResDev/Vrui/Vrui-$VRUI_VERSION-$VRUI_RELEASE.tar.gz | tar xfz -
cd Vrui-$VRUI_VERSION-$VRUI_RELEASE
DOWNLOAD_RESULT=$?

if [ $DOWNLOAD_RESULT -ne 0 ]; then
	echo "Problem while downloading or unpacking Vrui; please check your network connection and try again"
	exit $DOWNLOAD_RESULT
fi

# Set up Vrui's installation directory:
VRUI_INSTALLDIR=/usr/local
if [ $# -ge 1 ]; then
	VRUI_INSTALLDIR=$1
fi

# Check if make install requires sudo, i.e., install directory is not under user's home:
INSTALL_NEEDS_SUDO=1
[[ $VRUI_INSTALLDIR = $HOME* ]] && INSTALL_NEEDS_SUDO=0

# Check if make directory path needs Vrui-<version> shim:
VRUI_MAKEDIR=$VRUI_INSTALLDIR/share/Vrui-$VRUI_VERSION/make
[[ $VRUI_INSTALLDIR = *Vrui-$VRUI_VERSION* ]] && VRUI_MAKEDIR=$VRUI_INSTALLDIR/share/make 

# Determine the number of CPUs on the host computer:
NUM_CPUS=`cat /proc/cpuinfo | grep processor | wc -l`

# Build Vrui:
echo "Building Vrui on $NUM_CPUS CPUs"
make -j$NUM_CPUS INSTALLDIR=$VRUI_INSTALLDIR
BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
	echo "Build unsuccessful; please fix any reported errors and try again"
	exit $BUILD_RESULT
fi

# Install Vrui
echo "Build successful; installing Vrui in $VRUI_INSTALLDIR"
if [ $INSTALL_NEEDS_SUDO -ne 0 ]; then
	echo "Please enter your password to install Vrui in $VRUI_INSTALLDIR"
	sudo make INSTALLDIR=$VRUI_INSTALLDIR install
else
	make INSTALLDIR=$VRUI_INSTALLDIR install
fi
INSTALL_RESULT=$?

if [ $INSTALL_RESULT -ne 0 ]; then
	echo "Could not install Vrui in $VRUI_INSTALLDIR. Please fix the issue and try again"
	exit $INSTALL_RESULT
fi

# Install device permission rules
echo "Installation in $VRUI_INSTALLDIR successful; installing device permission rules in /etc/udev/rules.d"
echo "If prompted, please enter your password again to install device permission rules"
sudo make INSTALLDIR=$VRUI_INSTALLDIR installudevrules
UDEVRULES_RESULT=$?
if [ $UDEVRULES_RESULT -ne 0 ]; then
	echo "Could not install device permission rules in /etc/udev/rules.d. Please fix the issue and try again"
	exit $UDEVRULES_RESULT
fi

# Build Vrui example applications
cd ExamplePrograms
echo "Building Vrui example programs on $NUM_CPUS CPUs"
make -j$NUM_CPUS VRUI_MAKEDIR=$VRUI_MAKEDIR INSTALLDIR=$VRUI_INSTALLDIR
BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
	echo "Build unsuccessful; please fix any reported errors and try again"
	exit $BUILD_RESULT
fi

# Install Vrui example applications
echo "Build successful; installing Vrui example programs in $VRUI_INSTALLDIR"
if [ $INSTALL_NEEDS_SUDO -ne 0 ]; then
	echo "If prompted, please enter your password again to install Vrui's example applications in $VRUI_INSTALLDIR"
	sudo make VRUI_MAKEDIR=$VRUI_MAKEDIR INSTALLDIR=$VRUI_INSTALLDIR install
else
	make VRUI_MAKEDIR=$VRUI_MAKEDIR INSTALLDIR=$VRUI_INSTALLDIR install
fi
INSTALL_RESULT=$?

if [ $INSTALL_RESULT -ne 0 ]; then
	echo "Could not install Vrui example programs in $VRUI_INSTALLDIR. Please fix the issue and try again"
	exit $INSTALL_RESULT
fi

# Run ShowEarthModel
echo "Running ShowEarthModel application. Press Esc or close the window to exit."
cd $HOME
$VRUI_INSTALLDIR/bin/ShowEarthModel

