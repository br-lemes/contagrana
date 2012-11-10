
all:
	gcc -O2 -fPIC -shared -o core.so md5.c md5lib.c
	i686-w64-mingw32-gcc -O2 -shared -o core.dll md5.c md5lib.c -llua52 -L ..
	strip --strip-unneeded core.so core.dll

clean:
	rm core.so
	rm core.dll
