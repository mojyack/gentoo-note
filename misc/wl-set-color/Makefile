#CFLAGS=-O0 -g
CFLAGS=-O3 -march=native
CXXFLAGS=${CFLAGS} -std=c++20

wl-set-color: main.cpp wlr-gamma-control-unstable-v1.h wlr-gamma-control-unstable-v1.o
	clang++ ${CXXFLAGS} -lwayland-client -lm -o $@ main.cpp *.o

zwlr_gamma_control_manager_v1_interface.o: wlr-gamma-control-unstable-v1.c
	clang ${CFLAGS} -c -o $@  $<

wlr-gamma-control-unstable-v1.h: wlr-gamma-control-unstable-v1.xml
	wayland-scanner client-header wlr-gamma-control-unstable-v1.xml wlr-gamma-control-unstable-v1.h

wlr-gamma-control-unstable-v1.c: wlr-gamma-control-unstable-v1.xml
	wayland-scanner private-code wlr-gamma-control-unstable-v1.xml wlr-gamma-control-unstable-v1.c
