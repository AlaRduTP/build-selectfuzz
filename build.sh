#!/bin/bash

set -eux

SF_DEP_PACKAGES="build-essential make cmake git texinfo bison flex libtool wget"

sudo apt-get update
sudo apt-get install -y $SF_DEP_PACKAGES

git clone https://github.com/cuhk-seclab/SelectFuzz.git
cd SelectFuzz
git apply ../select-fuzz.patch

export AFLGO=$PWD

BUILD_TOOLS=$AFLGO/build-tools
mkdir $BUILD_TOOLS

cd $BUILD_TOOLS
git clone git://sourceware.org/git/binutils-gdb.git binutils
cd binutils
git checkout binutils-2_26_1
git apply ../../../binutils.patch

mkdir build
cd build
../configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim --enable-gold --enable-plugins --disable-werror --prefix=$BUILD_TOOLS
make
make install

cd $BUILD_TOOLS
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout llvmorg-4.0.0
git apply ../../../llvm-project.patch

mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=$BUILD_TOOLS -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON -DLLVM_ENABLE_PROJECTS='clang' -DCMAKE_BUILD_TYPE='Release' -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_BINUTILS_INCDIR="$BUILD_TOOLS/include" ../llvm
make -j4
make install

mkdir -p $BUILD_TOOLS/lib/bfd-plugins
cp $BUILD_TOOLS/lib/LLVMgold.so $BUILD_TOOLS/lib/bfd-plugins
cp $BUILD_TOOLS/lib/libLTO.so $BUILD_TOOLS/lib/bfd-plugins

cd $AFLGO
rm -rf temporal-specialization
git clone https://github.com/shamedgh/temporal-specialization
cd temporal-specialization
git checkout 7c905d3

tar -Jxvf llvm-7.0.0.src.wclang.tar.xz
cd llvm-7.0.0.src

mkdir build
cd build
cmake -G "Unix Makefiles" -DLLVM_BINUTILS_INCDIR="$BUILD_TOOLS/include" -DLLVM_TARGETS_TO_BUILD="X86" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../install ../
make -j4
make install

export LLVM_DIR="$PWD/../install"

cd $AFLGO/temporal-specialization
git apply ../../temporal-specialization.patch
cd SVF
./build.sh

# export PATH=$BUILD_TOOLS/bin:$PATH
# cd $AFLGO/scripts/fuzz
# ./libming-CVE-2016-9827.sh
