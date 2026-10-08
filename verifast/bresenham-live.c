#include <stdlib.h>
#include <stdio.h>

typedef enum { Pulse, NoPulse } Signal;

typedef struct {
    int dx;
    int dy;
    int x;
    int y;
    int d;
    int incE;
    int incNE;
    Signal signal;
} Bres;

/*@

predicate bres_access(Bres *b) =
  Bres_dx_(b, _)  &*&
  Bres_dy_(b, _)  &*&
  Bres_x_(b, _) &*&
  Bres_y_(b, _) &*&
  Bres_d_(b, _) &*&
  Bres_incE_(b,_) &*&
  Bres_incNE_(b,_) &*&
  Bres_signal_(b,_)
  ;

predicate bres_state(Bres *b) =
  Bres_dx(b, _)  &*&
  Bres_dy(b, _)  &*&
  Bres_x(b, _) &*&
  Bres_y(b, _) &*&
  Bres_d(b, _) &*&
  Bres_incE(b,_) &*&
  Bres_incNE(b,_) &*&
  Bres_signal(b,_)
  ;


@*/

void init(int dx, int dy, Bres *b)
  //@ requires bres_access(b);
  //@ ensures bres_state(b);
{
    b->dx = 0;
    b->dy = 0;
    b->x = 0;
    b->y = 0;
    b->d = 0;
    b->incE = 0;
    b->incNE = 0;
    b->signal = NoPulse;
    //@ close bres_state(b);
}

void step(Bres *b)
  //@ requires true;
  //@ ensures true;
{
    // if (b->d < 0) {
    //     ...
    // } else {
    //     ...
    // }
}

void bresenham(int lowerRateLimitBpm, int intrinsicRateBpm)
  //@ requires true;
  //@ ensures true;
{
    Bres state;
    //@ close bres_access(&state);
    init(lowerRateLimitBpm, intrinsicRateBpm, &state);
    // printf("Step: (%d,%d)", state.x, state.y);

    // printf("pulses: ");
    // while (1) {
    //     step(&state);
    //     printf("%c", (state.signal == NoPulse ? '.' : '+'));
    // }
    // printf("\n");
}

int main()
  //@ requires true;
  //@ ensures true;
{
    bresenham(80, 60);
    return 0;
}
