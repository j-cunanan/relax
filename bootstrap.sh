#!/bin/bash
# Symlink both python2 and gfortran-10 to python and gfortran
ln -s /usr/bin/python2 /usr/bin/python
ln -sfn /usr/bin/gfortran-10 /usr/bin/gfortran
# Configure and build
./waf configure --netcdf-dir=/usr --mkl-libdir=/opt/intel/oneapi/mkl/latest/lib --mkl-incdir=/opt/intel/oneapi/mkl/latest/include/ --mkl-libs='mkl_gf_lp64 mkl_gnu_thread mkl_core pthread gfortran'
./waf -v build