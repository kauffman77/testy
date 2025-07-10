// Command line interface to work with stacks. By default with compile
// with bugs; compile via
//   make FLAGS=-DCORRECT
// to get the correct version
#include "stack.h"

int main(int argc, char *argv[]){
  int echo = 0;                                // controls echoing, 0: echo off, 1: echo on
  if(argc > 1 && strcmp("-echo",argv[1])==0) { // turn echoing on via -echo command line option
    echo=1;
  }

  printf("Stack Manager\n");
  printf("Commands:\n");
  printf("  count:          shows the count of elements in the stack\n");
  printf("  add <N>:        add the given integer to the top of the stack\n");
  printf("  top:            shows the current top element of the stack\n");
  printf("  remove:         eliminate the top element in the stack\n");
  printf("  print:          print all elements in the stack top to bottom\n");
  printf("  reset <CAP>:    discard the old stack and create a new one with the given capacity\n");
  printf("  exit:           exit the program\n");

  char cmd[128];
  stack_t *stack = stack_new(DEFAULT_STACK_CAPACITY);
  int success;

  while(1){
    printf("STACK>> ");               // print prompt
    success = scanf("%s",cmd);        // read a command
    if(success==EOF){                 // check for end of input
      printf("\n");                   // found end of input
      break;                          // break from loop
    }

    if( strcmp("exit", cmd)==0 ){     // check for exit command
      if(echo){
        printf("exit\n");
      }
      break;                          // break from loop
    }

    else if( strcmp("add", cmd)==0 ){    // adding an element
      int item;
      scanf("%d",&item);                  // read item to add
      if(echo){
        printf("add %d\n",item);
      }

      char ret = stack_add(stack, item);
      printf("return: %c\n",ret);
    }

    else if( strcmp("top", cmd)==0 ){     // top command
      if(echo){
        printf("top\n");
      }
      int item;
      char ret = stack_top(stack, &item);
      if(ret == 'N'){
        printf("Empyt stack!\n");
      }
      else{
        printf("%d\n",item);
      }
    }

    else if( strcmp("remove", cmd)==0 ){     // get command
      if(echo){
        printf("remove\n");
      }
      int item;
      char ret = stack_remove(stack, &item);
      if(ret == 'N'){
        printf("Empyt stack!\n");
      }
      else{
        printf("removed %d\n",item);
      }
    }

    else if( strcmp("print", cmd)==0 ){   // print command
      if(echo){
        printf("print\n");
      }
      stack_print(stack);
    }

    // CORRECT code: has the `count` command, buggy version is mission
    // this command
#ifdef CORRECT
    else if( strcmp("count", cmd)==0 ){   // count command
      if(echo){
        printf("count\n");
      }
      printf("count is %d\n",stack_count(stack));
    }
#endif

    else if( strcmp("reset", cmd)==0 ){   // reset command
      int capacity;
      scanf("%d",&capacity);              // read new capacity
      if(echo){
        printf("reset %d\n",capacity);
      }
      // CORRECT code: will free before re-allocating; buggy code will have a memory leak
#ifdef CORRECT
      stack_free(stack);
#endif
      stack = stack_new(capacity);
      printf("reset to new size %d\n",capacity);
    }

    else{
      if(echo){
        printf("%s\n",cmd);
      }
      printf("unknown command '%s'\n",cmd);
    }
  }
  // end main while loop

  stack_free(stack);
  return 0;
}
