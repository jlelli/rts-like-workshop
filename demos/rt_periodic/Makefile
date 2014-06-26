CC=gcc
CFLAGS=-c -Wall
LDFLAGS=-lm -lrt -pthread
SOURCES=rt_periodic.c dl_syscalls.c rt_utils.c
OBJECTS=$(SOURCES:.c=.o)
EXECUTABLE=rt_periodic

all: $(SOURCES) $(EXECUTABLE)
	
$(EXECUTABLE): $(OBJECTS) 
	$(CC) $(OBJECTS) -o $@ $(LDFLAGS) 

.c.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -rf *.o $(EXECUTABLE)

distclean:
	rm -rf *.o *.dat $(EXECUTABLE)
