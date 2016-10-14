#!/bin/bash

SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi





INSTALL_CMD="yum install"
PACKAGES="subversion bison gcc gcc-c++ make cmake-3* flex git libedit-devel mesa-private-llvm mesa-private-llvm-devel python zlib-devel elfutils-libelf lua lua-devel"
if [ "$(which apt-get 2> /dev/null)" ] ; then
    INSTALL_CMD="apt-get install"
    PACKAGES="subversion bison build-essential cmake_3* flex git libedit-dev libllvm3.7 llvm-3.7-dev libclang-3.7-dev python zlib1g-dev libelf-dev luajit luajit-5.1-dev"
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
    ./bootstrap && make && make install
    cd ..

    svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm
    cd llvm
    svn update

    cd tools
    svn co http://llvm.org/svn/llvm-project/cfe/trunk clang
    cd clang
    svn update

    cd ../
    svn co http://llvm.org/svn/llvm-project/clang-tools-extra/trunk extra
    cd extra
    svn update

    #cd ../../projects
    #svn co http://llvm.org/svn/llvm-project/compiler-rt/trunk compiler-rt
    #cd compiler-rt
    #svn update
    

    mkdir ../../../build_clang
    cd ../../../build_clang
  
    #../llvm/configure 
    cmake  ../llvm
    cmake --build .
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
git clone https://github.com/iovisor/bcc.git
mkdir bcc/build; cd bcc/build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make
${SUDO_PREFIX} make install
popd > /dev/null



