#!/bin/bash

XEMMSB_dir=$1

if [ -z "$XEMMSB_dir" ]; then
  echo "Run with: ./install.sh /home/user/installation_dir"
  exit
fi

if [[ ! -d "$XEMMSB_dir" ]]; then
    echo "$XEMMSB_dir does not exist. Create it first. "
    exit
fi

cd $SEMMSB_dir

exit

## 1. Instalação das dependências: `open-mpi`, `gfortran`, `gcc`, `cmake`

sudo apt-get update -y
sudo apt-get install -y gfortran gcc openmpi-bin cmake

## 2. Instalação do Plumed

wget https://github.com/plumed/plumed2/archive/refs/tags/v2.5.5.tar.gz
tar -xvzf v2.5.5.tar.gz
cd plumed2-2.5.5
./configure --prefix=$XEMMSB_dir/plumed2
make -j 4
make install

export PATH=$PATH:/$XEMMSB_dir/plumed2/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$XEMMSB_dir/plumed2/lib
export PLUMED_KERNEL=$PLUMED_KERNEL:$XEMMSB_dir/plumed2

## 3. Instalação do Gromacs

wget ftp://ftp.gromacs.org/pub/gromacs/gromacs-2019.4.tar.gz
tar xfz gromacs-2019.4.tar.gz
cd gromacs-2019.4
plumed-patch -p -e gromacs-2019.4
mkdir build
cd build
cmake .. -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=OFF -DGMX_MPI=ON -DGMX_GPU=OFF -DCMAKE_C_COMPILER=gcc -DGMX_FFT_LIBRARY=fftpack -DCMAKE_INSTALL_PREFIX=$XEMMSB_dir/gromacs-2019.4
make -j 4
make install
source $XEMMSB_dir/gromacs-2019.4/bin/GMXRC

# Adicionando as variáveis de ambiente ao .bashrc

wget  https://raw.githubusercontent.com/m3g/XEMMSB2021/main/setenv.sh
chmod +x setenv.sh
./setenv.sh $XEMMSB_dir
echo "source $XEMMSB_dir/setenv.sh" >> ~/.bashrc

