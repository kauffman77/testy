# sample makefile for stack project

CFLAGS = -Wall -Werror -g
CC     = gcc $(CFLAGS) $(FLAGS)
# compile with `make FLAGS=-DCORRECT` to get correct version
SHELL  = /bin/bash
CWD    = $(shell pwd | sed 's/.*\///g')

PROGRAMS = \
	stack_main \
	test_stack_funcs \

export PARALLEL?=True		#enable parallel testing if not overridden

all : $(PROGRAMS)

# cleaning target to remove compiled programs/objects
clean :
	rm -f $(PROGRAMS) *.o

help :
	@echo 'Typical usage is:'
	@echo '  > make                          # build all programs, buggy version by default'
	@echo '  > make FLAGS=-DCORRECT          # build all programs, correct version'
	@echo '  > make clean                    # remove all compiled items'
	@echo '  > make test                     # run all tests'
	@echo '  > make test-funcs               # run tests for stack_funcs.c'
	@echo '  > make test-funcs testnum=5     # run test #5 of stack_funcs.c only'
	@echo '  > make test-main                # run tests for stack_main.c'

################################################################################
# scale problem
%.o : %.c stack.h
	$(CC) -c $<

stack_main : stack_main.o stack_funcs.o
	$(CC) -o $@ $^

test_stack_funcs : test_stack_funcs.o stack_funcs.o
	$(CC) -o $@ $^

test-funcs : test_stack_funcs
	./testy test_stack_funcs.org $(testnum)

test-main : stack_main
	./testy test_stack_main.org $(testnum)

test : test-funcs test-main
