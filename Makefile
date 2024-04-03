.POSIX:
.SUFFIXES:

FC      = gfortran
AR      = ar
MAKE    = make
PREFIX  = /usr

DEBUG   = -std=f2018 -g -O0 -Wall -fmax-errors=1
RELEASE = -std=f2018 -O2 -march=native

FFLAGS  = $(RELEASE)
LDLAGS  = -I$(PREFIX)/include -L$(PREFIX)/lib
LDLIBS  = -lzstd
ARFLAGS = rcs
INCDIR  = $(PREFIX)/include/libfortran-zstd
LIBDIR  = $(PREFIX)/lib
MODULE  = zstd.mod
TARGET  = ./libfortran-zstd.a
SHARED  = ./libfortran-zstd.so

.PHONY: all clean debug install shared test test_shared

all: $(TARGET)

shared: $(SHARED)

debug:
	$(MAKE) FFLAGS="$(DEBUG)"
	$(MAKE) test FFLAGS="$(DEBUG)"

$(TARGET): src/zstd.f90
	$(FC) $(FFLAGS) -c src/zstd.f90
	$(AR) $(ARFLAGS) $(TARGET) zstd.o

$(SHARED): src/zstd.f90
	$(FC) $(FFLAGS) -fPIC -shared -o $(SHARED) src/zstd.f90 $(LDLIBS)

test: $(TARGET) test/test_zstd.f90
	$(FC) $(FFLAGS) $(LDFLAGS) -o test_zstd test/test_zstd.f90 $(TARGET) $(LDLIBS)

test_shared: $(SHARED) test/test_zstd.f90
	$(FC) $(FFLAGS) $(LDFLAGS) -o test_zstd_shared test/test_zstd.f90 $(SHARED) $(LDLIBS)

install: $(TARGET)
	@echo "--- Installing library to $(LIBDIR)/ ..."
	install -d $(LIBDIR)
	install -m 644 $(TARGET) $(LIBDIR)/
	if [ -e $(SHARED) ]; then install -m 644 $(SHARED) $(LIBDIR)/; fi
	@echo "--- Installing module to $(INCDIR)/ ..."
	install -d $(INCDIR)
	install -m 644 $(MODULE) $(INCDIR)/

clean:
	if [ `ls -1 *.mod 2>/dev/null | wc -l` -gt 0 ]; then rm *.mod; fi
	if [ `ls -1 *.o 2>/dev/null | wc -l` -gt 0 ]; then rm *.o; fi
	if [ -e $(TARGET) ]; then rm $(TARGET); fi
	if [ -e $(SHARED) ]; then rm $(SHARED); fi
	if [ -e test_zstd ]; then rm test_zstd; fi
	if [ -e test_zstd_shared ]; then rm test_zstd_shared; fi
