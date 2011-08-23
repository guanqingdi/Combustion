# -*- Makefile -*-
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#                               Michael A.G. Aivazis
#                        California Institute of Technology
#                        (C) 1998-2001  All Rights Reserved
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#

include local.def

PROJECT = cv-combustor
PROJ_LIB = $(BLD_LIBDIR)/$(PROJECT).$(EXT_LIB)
PROJ_CLEAN += *~ core cv

MECHANISM = $(PYTHIA_DIR)/share/mechanisms/GRIMech-3.0.ck2

# Project source files
PROJ_SRCS = \
    ddebdf.$(EXT_F77) \
    dzeroin.$(EXT_F77) \
    readcv2.$(EXT_F77) \
    fuego.$(EXT_C)


LIBS = $(PROJ_LIB) $(EXTERNAL_LIBS) -lm


all: $(PROJ_LIB) cv


cv: patcv.$(EXT_F77)
	$(F77) -o cv patcv.$(EXT_F77) $(F77FLAGS) $(LF77FLAGS) $(LIBS)
	-$(RM) patcv.$(EXT_OBJ)


fuego.$(EXT_C): fuego.py $(MECHANISM)
	python fuego.py --file=fuego.$(EXT_C) --mechanism=$(MECHANISM) --output=c


# version
# $Id$

#
# End of file
