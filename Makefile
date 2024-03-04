# Filename: Makefile
# Author: Korbin Shelley
# Description: Makefile for the fec lexical analyzer
# Version: lab1-part2

# Output executable name (Can be whatever you want.)
OUTPUT = fec

# File Names
# Only the main C file and the flex file are needed.
# C_FILES is for future use for object files.
MAIN_FILE = main.c
FLEX_FILE = rustlex.l

# Compilers
CC = gcc
LEX = flex

# Flags
LINK_FLAGS = -lfl -lm
W_FLAGS = -Wall -Wextra -pedantic -std=c99
C_FLAGS = $(W_FLAGS) $(LINK_FLAGS) -Werror
O_FLAGS = $(W_FLAGS) -c

# generated file names (for cleanup)
FLEX_OUTPUT = $(FLEX_FILE:.l=.c)
OBJECTS = $(FLEX_OUTPUT:.c=.o)

# Builder functions
all: $(OUTPUT)
#	rm -f $(FLEX_FILES)

$(OUTPUT): $(MAIN_FILE) $(OBJECTS) 
	$(CC) $(C_FLAGS) $^ -o $@

%.c: %.l
	$(LEX) --outfile=$@ $^

%.o: %.c
	$(CC) $(O_FLAGS) $^ -o $@

clean:
	rm -f $(FLEX_OUTPUT) $(OUTPUT) *.o
