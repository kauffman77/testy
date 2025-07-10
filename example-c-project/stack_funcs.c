// Service functions for the stack data type. By default will compile
// with bugs; compile via
//   make FLAGS=-DCORRECT
// to get the correct version
#include "stack.h"

#ifdef CORRECT
// CORRECT version: allocate and initialize a stack with the given
// capacity
stack_t *stack_new(int capacity){
  stack_t *stack = malloc(sizeof(stack_t));
  stack->data = malloc(sizeof(int)*capacity);
  stack->count = 0;
  stack->capacity = capacity;
  return stack;
}
#else
// BUGGY version: allocate and initialize a stack with the given
// capacity
stack_t *stack_new(int capacity){
  stack_t *stack = malloc(sizeof(stack_t));
  stack->data = malloc(capacity); // BUG: should scale by size of an int
  stack->count = 0;
  stack->capacity = capacity;
  return stack;
}
#endif

// CORRECT version: deallocate data associatd with the stack
void stack_free(stack_t *stack){
  free(stack->data);
  free(stack);
}

// return the count of items in the stack
int stack_count(stack_t *stack){
  return stack->count;
}

#ifdef CORRECT
// add the given item to the stack. Returns 'A' when adding without
// expansion, 'E' when the add requires the backing array to expand,
// and 'F' if expansion of the array fails
char stack_add(stack_t *stack, int item){
  if(stack->count < stack->capacity){
    stack->data[stack->count] = item;
    stack->count++;
    return 'A';                 // added without expansion
  }
  else{
    int *data_expanded = realloc(stack->data, 2*stack->capacity*sizeof(int));
    if(data_expanded == NULL){
      return 'F';               // failed to add due to memory exhaustion
    }
    stack->data = data_expanded;
    stack->capacity *= 2;
    stack->data[stack->count] = item;
    stack->count++;
    return 'E';                 // added after expansion
  }
}
#else
// BUGGY VERSION: add the given item to the stack. Returns 'A' when
// adding without expansion, 'E' when the add requires the backing
// array to expand, and 'F' if expansion of the array fails
char stack_add(stack_t *stack, int item){
  if(stack->count < stack->capacity){
    stack->data[stack->count] = item;
    stack->count++;
    return 'A';                 // added without expansion
  }
  else{
    int *data_expanded = realloc(stack->data, 2*stack->capacity); // missing sizeof(int)
    if(data_expanded == NULL){
      return 'F';               // failed to add due to memory exhaustion
    }
    stack->data = data_expanded;
    stack->capacity *= 2;
    stack->data[stack->count] = item;
    stack->count++;
    return 'E';                 // added after expansion
  }
}
#endif

// set the given `item` to the top element of the stack return 'S' on
// success; if the stack is empty, makes no changes and returns 'N'
char stack_top(stack_t *stack, int *item){
  if(stack->count == 0){
    return 'N';                        // no items present, no changes made
  }
  *item = stack->data[stack->count-1];
  return 'S';                          // item present, set to top
}

#ifdef CORRECT
// CORRECT version: like stack_top() but also removes the top element
// when it is present
char stack_remove(stack_t *stack, int *item){
  if(stack->count == 0){
    return 'N';                        // no items present, no changes made
  }
  *item = stack->data[stack->count-1];
  stack->count--;
  return 'S';                          // item present, set to top
}
#else
// BUGGY version: like stack_top() but also removes the top element
// when it is present
char stack_remove(stack_t *stack, int *item){
  if(stack->count == 0){
    return 'N';                        // no items present, no changes made
  }
  // *item = stack->data[stack->count-1];  // BUG: neglects to set item
  stack->count--;
  return 'S';                          // item present, set to top
}
#endif

#ifdef CORRECT
// CORRECT version: print all elements to stdout
void stack_print(stack_t *stack){
  for(int i=stack->count-1; i>=0; i--){
    printf("[%d]: %d\n",i,stack->data[i]);
  }
}
#else
// BUGGY version: print all elements to stdout
void stack_print(stack_t *stack){
  for(int i=stack->count-1; i>0; i--){ // BUG: off by one error
    printf("[%d]: %d\n",i,stack->data[i]);
  }
}
#endif

// // Alternative version of add which attempts to remove duplicate code
// char stack_add(stack_t *stack, int item, int options){
//   char ret = 'A';                      // default to returning without expansion
//   if(stack->count >= stack->capacity){ // require expansion
//     int *data_expanded = realloc(stack->data, 2*stack->capacity);
//     if(data_expanded == NULL){
//       return 'F';                      // failed to add due to memory exhaustion
//     }
//     else{
//       stack->data = data_expanded;
//       stack->capacity *= 2;
//       ret = 'E';
//     }
//   }
//   stack->data[stack->count] = item;    // add on item and return
//   stack->count++;
//   return ret;
// }
