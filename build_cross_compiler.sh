#!/bin/sh

#-------------------------------------------------------------------------------------------
# Author: Charalambos Konstantinou 
# W: http://ckonstantinou.info/ 
# 
# This script will download packages for, configure, build and install a GCC cross-compiler.
# 
# More on: hhttps://harryskon.wordpress.com/2015/02/10/shell-script-for-building-a-complete-gcc-cross-compiler/
# and: http://w3-tutorials.com/item/29-shell-script-for-building-a-complete-gcc-cross-compiler
#-------------------------------------------------------------------------------------------


# See http://gcc.gnu.org/install/specific.html for more examples on host and target specifics

# For our case: HOST="x86_64-pc-linux-gnu"

# Choose your target: https://gcc.gnu.org/install/specific.html
TARGET="powerpc-eabisim"

# Tried parallel build with e.g. MAKEOPTS="-j 2" but didn't work, thus leave it empty
MAKEOPTS=""

abort() {
	echo "**************************************************************"
	echo error: $@
	echo "**************************************************************"
	exit 1
}
success() {
	echo "***************************************************************"
	echo success: $@
	echo "***************************************************************"
	echo "\a"
	sleep 3s
}

# GCC should not be build in the source directory: why? http://gcc.gnu.org/ml/gcc-bugs/2007-06/msg00234.html
prepare_clean_build() {
	rm -rf $BUILDDIR
	mkdir $BUILDDIR
	cd $BUILDDIR
}

CROSSDIR=$HOME/ppc
BUILDDIR=$CROSSDIR/build
SOURCEDIR=$CROSSDIR/sources
DOWNLOADS=$CROSSDIR/downloads
INSTDIR=$CROSSDIR/cross-gcc

export PATH="$INSTDIR/bin:$PATH"

test -d $CROSSDIR || mkdir $CROSSDIR
test -d $DOWNLOADS || mkdir $DOWNLOADS
test -d $SOURCEDIR || mkdir $SOURCEDIR
test -d $INSTDIR && rm -rf $INSTDIR; mkdir $INSTDIR

# 1. Install binutils (containing the assembler and the linker)
	BINUTILS=binutils-2.25
	cd $DOWNLOADS
	test -f $BINUTILS.tar.gz || wget http://ftp.gnu.org/gnu/binutils/$BINUTILS.tar.gz
	cd $SOURCEDIR
	test -d $BINUTILS || tar -xzf $DOWNLOADS/$BINUTILS.tar.gz
	prepare_clean_build
	$SOURCEDIR/$BINUTILS/configure --prefix=$INSTDIR --target=$TARGET --disable-nls --disable-werror
	make $MAKEOPTS all install || abort "building of $BINUTILS failed"
	success "$BINUTILS successfully installed to $INSTDIR"

# 2. Install GMP (GNU multiple precision arithmetic library)
	GMP=gmp-4.3.2
	cd $DOWNLOADS
	test -f $GMP.tar.bz2 || wget ftp://gcc.gnu.org/pub/gcc/infrastructure/$GMP.tar.bz2
	cd $SOURCEDIR
	test -d $GMP || tar -xjf $DOWNLOADS/$GMP.tar.bz2
	prepare_clean_build
	$SOURCEDIR/$GMP/configure --disable-shared --enable-static --prefix=$INSTDIR
	make $MAKEOPTS all install || abort "building of $GMP failed"
	success "$GMP successfully installed to $INSTDIR"

# 3. Install MPFR (library for multiple-precision floating-point computations)
	MPFR=mpfr-2.4.2
	cd $DOWNLOADS
	test -f $MPFR.tar.bz2 || wget ftp://gcc.gnu.org/pub/gcc/infrastructure/$MPFR.tar.bz2
	cd $SOURCEDIR
	test -d $MPFR || tar -xjf $DOWNLOADS/$MPFR.tar.bz2
	prepare_clean_build
	$SOURCEDIR/$MPFR/configure --disable-shared --enable-static --prefix=$INSTDIR --with-gmp=$INSTDIR
	make $MAKEOPTS all install || abort "building of $MPFR failed"
	success "$MPFR successfully installed to $INSTDIR"

# 4. Install MPC (library for the arithmetic of complex numbers with arbitrarily high precision)
	MPC=mpc-0.8.1
	cd $DOWNLOADS
	test -f $MPC.tar.gz || wget ftp://gcc.gnu.org/pub/gcc/infrastructure/$MPC.tar.gz
	cd $SOURCEDIR
	test -d $MPC || tar -xzf $DOWNLOADS/$MPC.tar.gz
	prepare_clean_build
	$SOURCEDIR/$MPC/configure --disable-shared --enable-static --prefix=$INSTDIR --with-gmp=$INSTDIR --with-mpfr=$INSTDIR
	make $MAKEOPTS all install || abort "building of $MPC failed"
	success "$MPC successfully installed to $INSTDIR"

# 5. Install GCC (version 4 and above need GMP, MPFR and MPC development libraries to be installed)
	GCC=gcc-4.8.4
	cd $DOWNLOADS
	test -f $GCC.tar.bz2 || wget http://mirrors.kernel.org/gnu/gcc/$GCC/$GCC.tar.bz2
	cd $SOURCEDIR
	test -d $GCC || tar -xjf $DOWNLOADS/$GCC.tar.bz2
	prepare_clean_build
	$SOURCEDIR/$GCC/configure --prefix=$INSTDIR --target=$TARGET --disable-nls --disable-libssp --enable-languages="c" --without-headers --with-newlib  --with-gmp=$INSTDIR --with-mpfr=$INSTDIR --with-mpc=$INSTDIR
	make $MAKEOPTS all install || abort "building of $GCC failed"
	success "$GCC successfully installed to $INSTDIR"

# 6. Install newlib (library implementation intended for use on embedded systems)
	NEWLIB=newlib-2.2.0
	cd $DOWNLOADS
	test -f $NEWLIB.tar.gz || wget ftp://sources.redhat.com/pub/newlib/$NEWLIB.tar.gz
	cd $SOURCEDIR
	test -d $NEWLIB || tar -xzf $DOWNLOADS/$NEWLIB.tar.gz
	prepare_clean_build
	$SOURCEDIR/$NEWLIB/configure --prefix=$INSTDIR --target=$TARGET --disable-nls
	make $MAKEOPTS all install || abort "building of $NEWLIB failed"
	success "$NEWLIB successfully installed to $INSTDIR"


echo "Use cross-compiler by typing:"
echo "$INSTDIR/bin/$TARGET-gcc sourcefile.c"
echo "For more options type: $INSTDIR/bin/$TARGET-gcc --help"
echo "For example: include the -msim option to choose the specific (ppc) machine type"
