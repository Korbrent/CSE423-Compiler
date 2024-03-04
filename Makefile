# Filename: Makefile
# Author: Korbin Shelley
# Description: Makefile for the fec compiler project.
# Date: February 08, 2024

# Output executable name (Can be whatever you want.)
OUTPUT = fec

# File Names
MAIN_FILE = main.c
FLEX_FILE = rustlex.l
BISON_FILE = rustparse.y

# Compilers
CC = gcc
LEX = flex

# Flags
LINK_FLAGS = -lfl -lm
W_FLAGS = -Wall -Wextra -pedantic -std=c99
C_FLAGS = $(W_FLAGS) $(LINK_FLAGS) -Werror
O_FLAGS = $(W_FLAGS) -c

# generated file names (for cleanup)
BUILDER_FILES = $(FLEX_FILE:.l=.c) $(BISON_FILE:.y=.c) $(BISON_FILE:.y=.h)
OBJECTS = $(FLEX_FILE:.l=.o) $(BISON_FILE:.y=.o)

# Builder functions
all: $(OUTPUT)

$(OUTPUT): $(MAIN_FILE) $(OBJECTS) 
	$(CC) $(C_FLAGS) $^ -o $@

$(FLEX_FILE:.l=.c): $(FLEX_FILE) $(BISON_FILE:.y=.h)
	$(LEX) --outfile=$@ $^

$(BISON_FILE:.y=.c): $(BISON_FILE)
	bison -d --output=$@ --header=$(BISON_FILE:.y=.h) $^ -Wcounterexamples

$(BISON_FILE:.y=.h): $(BISON_FILE:.y=.c)

%.o: %.c
	$(CC) $(O_FLAGS) $^ -o $@

clean:
	rm $(OBJECTS) $(BUILDER_FILES) $(OUTPUT) *.o
