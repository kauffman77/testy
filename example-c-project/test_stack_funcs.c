#include "stack.h"

// macro to set up a test with given name, print the source of the
// test; very hacky, fragile, but useful
#define IF_TEST(TNAME) \
  if( RUNALL || strcmp( TNAME, test_name)==0 ) { \
    sprintf(sysbuf,"awk 'NR==(%d){P=1;gsub(\"^ *\",\"\");} P==1 && /ENDTEST/{P=0; print \"}\\n---OUTPUT---\"} P==1{print}' %s", __LINE__, __FILE__); \
    system(sysbuf); nrun++;  \
  } \
  if( RUNALL || strcmp( TNAME, test_name)==0 )

char sysbuf[1024];
int RUNALL = 0;
int nrun = 0;

int main(int argc, char *argv[]){
  if(argc < 2){
    printf("usage: %s <test_name>\n", argv[0]);
    return 1;
  }
  char *test_name = argv[1];
  char sysbuf[1024];
  if(strcmp(test_name,"ALL")==0){
    RUNALL = 1;
  }

  ////////////////////////////////////////////////////////////////////////////////
  // stack_funcs.c TESTS 10
  ////////////////////////////////////////////////////////////////////////////////
  IF_TEST("stack_new / stack_free") {
    // checks that the new/free functions are present, the new
    // function at least returns non-NULL, and that freening it will
    // lead to no memory leaks.
    stack_t *stack = stack_new(5);
    if(stack == NULL){
      printf("the stack was NULL unexpectedly\n");
    }
    stack_free(stack);
  }
  // ENDTEST

  IF_TEST("stack_count on empty") {
    // checks that stack_count on an empty stack returns 0
    stack_t *stack = stack_new(5);
    int count = stack_count(stack);
    printf("count: %d\n",count);
    stack_free(stack);
  }
  // ENDTEST

  IF_TEST("stack_add_top_1") {
    // checks that stack_add() and stack_top() seems to work correctly
    // for a single element
    stack_t *stack = stack_new(5);
    char ret = stack_add(stack, 20);
    int count = stack_count(stack);
    printf("ret: %c\ncount: %d\n",ret,count);
    int top_item;
    ret = stack_top(stack, &top_item);
    printf("ret: %c\ntop_item: %d\n",ret,top_item);
    stack_free(stack);
  }
  // ENDTEST

  IF_TEST("stack_add_top_2") {
    // checks that stack_add() and stack_top() seems to work correctly
    // for several elements
    stack_t *stack = stack_new(5);
    char ret; int count, top_item;
    printf("FIRST ADD\n");
    ret = stack_add(stack, 20);
    count = stack_count(stack);
    printf("ret: %c\ncount: %d\n",ret,count);
    ret = stack_top(stack, &top_item);
    printf("ret: %c\ntop_item: %d\n",ret,top_item);
    printf("SECOND ADD\n");
    ret = stack_add(stack, 40);
    count = stack_count(stack);
    printf("ret: %c\ncount: %d\n",ret,count);
    ret = stack_top(stack, &top_item);
    printf("ret: %c\ntop_item: %d\n",ret,top_item);
    printf("THIRD ADD\n");
    ret = stack_add(stack, 60);
    count = stack_count(stack);
    printf("ret: %c\ncount: %d\n",ret,count);
    ret = stack_top(stack, &top_item);
    printf("ret: %c\ntop_item: %d\n",ret,top_item);
    stack_free(stack);
  }
  // ENDTEST

  IF_TEST("stack_add_print_1") {
    // checks that stack_add() followed by stack_print() behaves correctly
    stack_t *stack = stack_new(16);
    stack_add(stack, 20);
    stack_add(stack, 40);
    stack_add(stack, 60);
    stack_print(stack);
    stack_free(stack);
  }
  // ENDTEST

  IF_TEST("stack_add_print_2") {
    // checks that stack_add() followed by stack_print() behaves correctly
    stack_t *stack = stack_new(16);
    stack_add(stack, 100);
    stack_add(stack, 200);
    stack_add(stack, 300);
    stack_add(stack, 400);
    stack_add(stack, 500);
    stack_print(stack);
    stack_free(stack);
  }
  // ENDTEST

  IF_TEST("stack_remove_1") {
    // checks that stack_add() followed by stack_remove() behaves correctly
    stack_t *stack = stack_new(5);
    char ret; int count, removed_item;
    ret = stack_add(stack, 100);
    ret = stack_remove(stack, &removed_item);
    count = stack_count(stack);
    printf("ret: %c\nremoved_item: %d\n",
           ret, removed_item);
    printf("count: %d\n",count);
    stack_free(stack);
  }
  // ENDTEST

  IF_TEST("stack_remove_2") {
    // checks that stack_add() followed by stack_remove() behaves correctly
    stack_t *stack = stack_new(5);
    char ret; int count, removed_item;
    ret = stack_add(stack, 100);
    ret = stack_add(stack, 200);
    ret = stack_add(stack, 300);
    ret = stack_remove(stack, &removed_item);
    count = stack_count(stack);
    printf("ret: %c\nremoved_item: %d\n",
           ret, removed_item);
    printf("count: %d\n",count);
    ret = stack_remove(stack, &removed_item);
    count = stack_count(stack);
    printf("ret: %c\nremoved_item: %d\n",
           ret, removed_item);
    printf("count: %d\n",count);
    stack_free(stack);
  }
  // ENDTEST

  IF_TEST("stack_expansion_1") {
    // checks that stack_add() will expand the stack when needed
    stack_t *stack = stack_new(2);
    char ret;
    ret = stack_add(stack, 100);
    printf("ret: %c\n",ret);
    ret = stack_add(stack, 200);
    printf("ret: %c\n",ret);
    ret = stack_add(stack, 300); // should trigger expansion
    printf("ret: %c\n",ret);
    ret = stack_add(stack, 400);
    printf("ret: %c\n",ret);
    stack_free(stack);
  }
  // ENDTEST

  IF_TEST("stack_expansion_2") {
    // checks that stack_add() will expand the stack when needed
    stack_t *stack = stack_new(1);
    char ret;
    ret = stack_add(stack, 100);
    printf("ret: %c\n",ret);
    ret = stack_add(stack, 200); // should trigger expansion
    printf("ret: %c\n",ret);
    ret = stack_add(stack, 300); // should trigger expansion
    printf("ret: %c\n",ret);
    ret = stack_add(stack, 400);
    printf("ret: %c\n",ret);
    ret = stack_add(stack, 500); // should trigger expansion
    printf("ret: %c\n",ret);
    stack_free(stack);
  }
  // ENDTEST

  ////////////////////////////////////////////////////////////////////////////////
  // END MATTER
  ////////////////////////////////////////////////////////////////////////////////
  if(nrun == 0){
    printf("No test named '%s' found\n",test_name);
    return 1;
  }
  else if(nrun > 1){
    printf("%d tests run\n",nrun);
  }

  return 0;
}
