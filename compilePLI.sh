gcc -c -fPIC edgeVPI.c
gcc -shared -Bsymbolic -o edgeVPI.so edgeVPI.o
