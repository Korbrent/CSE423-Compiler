# Filename: Makefile
# Author: Korbin Shelley
# Description: Makefile for the fec compiler project.
# Date: March 3, 2024

# Output executable name (Can be whatever you want.)
OUTPUT = fec

# File Names
MAIN_FILE = main.c
FLEX_FILE = rustlex.l
BISON_FILE = rustparse.y
C_FILES = token.c tree.c graphicTree.c hashtable.c symtab.c
HEADER_FILES = token.h tree.h parserRules.h graphicTree.h hashtable.h symtab.h

# Compilers
CC = gcc

# Flags
LINK_FLAGS = -lfl -lm
W_FLAGS = -Wall -Wextra
C_FLAGS = $(W_FLAGS) $(LINK_FLAGS) -Werror
O_FLAGS = $(W_FLAGS) -c

# generated file names (for cleanup)
BUILDER_FILES = $(FLEX_FILE:.l=.c) $(BISON_FILE:.y=.c) $(BISON_FILE:.y=.h)
OBJECTS = $(FLEX_FILE:.l=.o) $(BISON_FILE:.y=.o) $(C_FILES:.c=.o)

# Builder functions
all: $(OUTPUT)

$(OUTPUT): $(MAIN_FILE) $(OBJECTS) 
	$(CC) $(C_FLAGS) $^ -o $@

$(FLEX_FILE:.l=.c): $(FLEX_FILE) $(BISON_FILE:.y=.h) $(HEADER_FILES)
	flex --outfile=$@ $<

$(BISON_FILE:.y=.c): $(BISON_FILE) $(HEADER_FILES)
	bison -d --output=$@ --header=$(BISON_FILE:.y=.h) $< -Wcounterexamples

$(BISON_FILE:.y=.h): $(BISON_FILE:.y=.c)

$(FLEX_FILE:.l=.o): $(FLEX_FILE:.l=.c) token.o
	$(CC) $(O_FLAGS) $< -o $@

$(BISON_FILE:.y=.o): $(BISON_FILE:.y=.c) tree.o
	$(CC) $(O_FLAGS) $< -o $@

%.o: %.c $(HEADER_FILES) $(BISON_FILE:.y=.h)
	$(CC) $(O_FLAGS) $< -o $@

clean:
	rm $(OBJECTS) $(BUILDER_FILES) $(OUTPUT)
