#==============================================================================
#
# Isaac Moradi, Isaac.Moradi@noaa.gov March 10, 2015
#
# $Id:$
#
#==============================================================================

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR := $(dir $(MKFILE_PATH))

ESMADIR = /home/dao_ops/GEOSadas-5_29_5/GEOSadas

ARCH = $(shell uname -s)
BASELIBDIR = $(BASEDIR)/$(ARCH)

NETCDF_LIBDIR = ${BASELIBDIR}/lib
NETCDF_INCDIR = ${BASELIBDIR}/include/netcdf

LIB_NETCDF = $(shell $(BASELIBDIR)/bin/nf-config --flibs)
INC_NETCDF = -I$(NETCDF_INCDIR)

INC_HDF4 = -I$(BASELIBDIR)/include/hdf
INC_HDF5 = -I$(BASELIBDIR)/include/hdf5

INC_DATETIME = -I./datetime-fortran/build/include
LIB_DATETIME = ./datetime-fortran/build/lib

GEOSLIBDIR = $(ESMADIR)/install/lib
INCLUDE_DIR = ./

export BUFRTAB="./bufrtab"

#FL=ifort
FL=mpiifort

help:
	@echo MKFILE_PATH = $(MKFILE_PATH)
	@echo MKFILE_DIR  = $(MKFILE_DIR)

datetime-fortran: datetime-fortran/build/lib/libdatetime.a

datetime-fortran/build/lib/libdatetime.a:
	cd $(MKFILE_DIR)/datetime-fortran; mkdir build; \
		cd build; cmake ..; make;\
		cd $(MKFILE_DIR)


REMOVE=/bin/rm

# The executable and object files
EXE_FILE = fcdr2bufr.exe

# put the majules first to avoid independency problems
SRC_FILE = jd_to_date.f90 date_to_jd.f90 Write_Bufr_Module.f90 Read_Data.f90 fcdr2bufr.f90
SRC_FILE = Write_Bufr_Module.f90 Read_Data.f90 fcdr2bufr.f90

OBJ_FILE = ${SRC_FILE:.f90=.o}

EXTRA_FC_FLAGS = -stand f08 -g -traceback \
		 $(INC_NETCDF) \
		 $(INC_HDF4) \
		 $(INC_DATETIME)

LIBRARIES =  -limf -lm \
            $(LIB_NETCDF) \
            -L$(GEOSLIBDIR) -lNCEP_bufr_r4i4 -lNCEP_w3_r4i4 -lNCEP_bacio_r4i4 \
            -L$(LIB_DATETIME)  -ldatetime

#all: $(OBJ_FILE), external
all: $(EXE_FILES) datetime-fortran
	$(FL) $(EXTRA_FC_FLAGS) $(FL_FLAGS) $(LIBRARIES)  -c  $(SRC_FILE) 
	$(FL) $(OBJ_FILE) $(EXTRA_FC_FLAGS) $(FL_FLAGS) $(LIBRARIES) -o $(EXE_FILE)

clean:
	$(REMOVE) -f $(EXE_FILE) *.o *.mod gmon.out *.output results/*.signal *.mod
	$(REMOVE) -rf datetime-fortran/build

# Local dependencies
$(OBJ_FILE): $(SRC_FILE)
