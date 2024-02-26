#
##  Copyright (c) 1995-2017 University Corporation for Atmospheric Research
## All rights reserved
#
#/**----------------------------------------------------------------------
# @file   Makefile
#
# Makefile for the FORTRAN portion of cdaac2ncep, a program which batches
# CDAAC Radio Occultation individual-profile BUFR files into a combined file
# including NCEP header, suitable for ingesting into GSI.
#
# @author     Doug Hunt
# @since      2/6/2017
# @version    1.0
#-----------------------------------------------------------------------*/

PROGRAM    = write_ro_hdr
INSTALLDIR = .
INSTALL    = /usr/bin/install -m 0555
RM         = rm -f

F90FLAGS   =
F90        = ifort

SOURCES    = write_ro_hdr.f90
LIBPATH   += -L/discover/nobackup/sdutta7/nwprod_2016q1/oper/lib
LIBS       = -lbufr_v10.2.5_4_64

${PROGRAM}:  
	${F90} ${F90FLAGS} -o ${PROGRAM} ${LIBPATH} ${SOURCES} ${LIBS}

clean:
	${RM} ${OBJECTS} core ${PROGRAM}

install:
	${INSTALL} ${PROGRAM} ${INSTALLDIR}

