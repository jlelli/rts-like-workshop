CC=gcc
CFLAGS=-c -Wall
LDFLAGS=-lm -lrt -pthread
SOURCES=simplest.c dl_syscalls.c
OBJECTS=$(SOURCES:.c=.o)
EXECUTABLE=simplest

all: $(SOURCES) $(EXECUTABLE)
	
$(EXECUTABLE): $(OBJECTS) 
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

.c.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -rf *.o $(EXECUTABLE)

distclean:
	rm -rf *.o *.dat $(EXECUTABLE)
