#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define  MAX_LINE_LENGTH  100

typedef unsigned long money_t;
typedef enum output_e {
 NO_OUTPUT, DISPENSE_TEA, DISPENSE_COFFEE, RETURN_COIN
} output_t;
typedef enum selection_e {
  NOTHING, TEA, COFFEE
} selection_t;

money_t money = 0;
selection_t selection = NOTHING;

const money_t product_price = 3;

output_t
maybeDispense(void)
{
  switch (selection) {
  case NOTHING: return NO_OUTPUT;
  default:
    if (money >= product_price) {
      output_t output = NO_OUTPUT;
      switch (selection) {
      case TEA: output = DISPENSE_TEA; break;
      case COFFEE: output = DISPENSE_COFFEE; break;
      default: break; /* can't happen */
      }
      selection = NOTHING;
      money = 0;
      return output;
    } else
      return NO_OUTPUT;
  }
}

output_t
insert_coin(void)
{
  if (money >= product_price)
    return RETURN_COIN;
  else {
    ++money;
    return maybeDispense();
  }
}

output_t
select(selection_t new_selection)
{
  if (money != 1)
    selection = new_selection;
  return maybeDispense();
}

void
print(output_t output)
{
  switch (output) {
  case NO_OUTPUT: printf("\n"); break;
  case DISPENSE_TEA: printf("tea\n"); break;
  case DISPENSE_COFFEE: printf("coffee\n"); break;
  case RETURN_COIN: printf("coin\n"); break;
  }
  fflush(stdout);
}

int
main(void)
{
  char *result;
  char line[MAX_LINE_LENGTH];
  
  while ((result = fgets(line, MAX_LINE_LENGTH, stdin)) != NULL) {
    output_t output = NO_OUTPUT;
    if (strncmp("tea", line, 3) == 0)
      output = select(TEA);
    else if (strncmp("coffee", line, 6) == 0)
      output = select(COFFEE);
    else if (strncmp("coin", line, 4) == 0) {
      output = insert_coin();
    }
    print(output);
  }
}
