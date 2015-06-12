SRCDIR := ./src

DC := dmd
DFLAGS := -debug -g -unittest -inline -wi -I$(SRCDIR)
LDFLAGS := -main
LD := dmd

SOURCES := $(wildcard $(SRCDIR)/*.d)
OBJECTS := $(patsubst %.d, %.o, $(SOURCES))

EXECUTABLE := conv-test

%.o : %.d
	$(DC) $(DFLAGS) -c $< -of$@

.PHONY: all
all: build

.PHONY: build
build: $(OBJECTS)
	$(LD) $(LDFLAGS) $^ -of$(EXECUTABLE)

.PHONY: run
run: build
	./$(EXECUTABLE)

.PHONY: clean
clean:
	$(RM) $(OBJECTS) $(EXECUTABLE)
