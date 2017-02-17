#!/bin/bash

if [ "x$(uname -m)" != "xaarch64" ] ; then
    echo "This setup is only valid for aarch64 platform"
    exit 0
fi


SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

INSTALL_CMD="yum install"
PACKAGES="wget subversion bison gcc gcc-c++ make cmake-3* flex git clang libedit-devel mesa-private-llvm mesa-private-llvm-devel python zlib-devel elfutils-libelf elfutils-libelf-devel lua lua-devel"
if [ "$(which apt-get 2> /dev/null)" ] ; then
    INSTALL_CMD="apt-get install"
    PACKAGES="wget subversion bison build-essential cmake-3.7* flex git clang libedit-dev libllvm3.7 llvm-3.7-dev libclang-3.7-dev python zlib1g-dev libelf-dev luajit luajit-5.1-dev"
else
    ${SUDO_PREFIX} yum install -y "Development Tools"
fi


build_and_install_clang() {
    #Download and install clang 
    mkdir builddir
    pushd builddir > /dev/null
    
    if [ ! -f "cmake-3.7.0-rc1.tar.gz" ]; then   
        wget https://cmake.org/files/v3.7/cmake-3.7.0-rc1.tar.gz
        tar -zxf cmake-*.tar.gz
    fi

    cd cmake-3.7.0-rc1  
    ./bootstrap --parallel=32 --bindir=/bin/
    make
    #Remove old cmake
    ${SUDO_PREFIX} yum remove -y cmake
    ${SUDO_PREFIX} make install
    cd ..

    svn co http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_390/final/ llvm
    #svn co http://llvm.org/svn/llvm-project/llvm/trunk/ llvm

    cd ./llvm/tools
    svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_390/final/ clang
    #svn co http://llvm.org/svn/llvm-project/cfe/trunk/ clang
    cd ../

    #cd ../
    #svn co http://llvm.org/svn/llvm-project/clang-tools-extra/trunk extra
    #cd extra
    #svn update

    #cd ./projects
    #svn co http://llvm.org/svn/llvm-project/compiler-rt/trunk compiler-rt
    #cd ../

    mkdir ../build_clang
    cd ../build_clang
  
    #cmake  ../llvm 
    cmake -DCMAKE_BUILD_TYPE=Release ../llvm  
    make -j32
    cmake --build . --parallel=32
    cmake --build . --target install

    #make -j32
    #make install
  
    if [ -z "$(which clang)" ] ; then
        echo "Fail to install clang"
        exit 0
    fi

    popd > /dev/null
}

${SUDO_PREFIX} ${INSTALL_CMD} -y  ${PACKAGES}

if [ -z "$(which clang)" ] ; then
    echo "Begin to download and install clang......."
    build_and_install_clang 
fi

#Build and install
mkdir builddir
pushd builddir > /dev/null
git clone https://github.com/sjtuhjh/bcc.git

mkdir build_bcc; cd build_bcc
cmake ../bcc -DCMAKE_INSTALL_PREFIX=/usr
make -j 64
${SUDO_PREFIX} make install
popd > /dev/null

if [ ! -d /usr/src/kernels/$(uname -r) ] ; then
   echo "Please install linux kernel sources under /usr/src/kernels/$(uname -r) in order to use bcc tools properly"
fi

