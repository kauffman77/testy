#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  int *data;
  int count;
  int capacity;
} stack_t;

// default size for stacks in the main application
#define DEFAULT_STACK_CAPACITY 4

stack_t *stack_new(int capacity);
void stack_free(stack_t *stack);
int stack_count(stack_t *stack);
char stack_add(stack_t *stack, int item);
char stack_top(stack_t *stack, int *item);
char stack_remove(stack_t *stack, int *item);
void stack_print(stack_t *stack);
