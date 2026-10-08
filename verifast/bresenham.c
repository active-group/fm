// verifast_options{disable_overflow_check}
#include <stdlib.h>
#include <stdio.h>

/*@
  lemma void mul_le_mono(int x, int y, int z)
      requires x * z <= y * z &*& 0 < z;
      ensures x <= y;
  {
      if (x > y) {
          mul_mono_l(y + 1, x, z); // (y + 1) * z <= x * z
          assert false;
      }
  }


  lemma void le_ge_eq(int a, int b)
      requires a <= b &*& b <= a;
      ensures a == b;
  {}

  lemma void end_of_cycle_y_equals_dy(int dx, int dy, int y)
    requires -dx <= err(dx, dy, dx, y) &*& err(dx, dy, dx, y) < dx;
    ensures y == dy;
  {
      mul_le_mono(2*y, 2*dy + 1, dx); // 2*y <= 2*dy + 1 < 2*dy + 2
      mul_le_mono(2*dy, 2*y + 1, dx); // 2*dy <= 2*y + 1 < 2*y + 2
      le_ge_eq(y, dy);
  }


@*/

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
    Bres_dx_(b, _)      &*&
    Bres_dy_(b, _)      &*&
    Bres_x_(b, _)       &*&
    Bres_y_(b, _)       &*&
    Bres_d_(b, _)       &*&
    Bres_incE_(b, _)    &*&
    Bres_incNE_(b, _)   &*&
    Bres_signal_(b, _)
;

fixpoint int err(int dx, int dy, int x, int y) {
  return 2*dy*x - 2*dx*y;
}

predicate bres_state(Bres *b, int dx, int dy, int x, int y, int d, Signal s) =
    b->dx     |-> dx         &*&
    b->dy     |-> dy         &*&
    b->x      |-> x          &*&
    b->y      |-> y          &*&
    b->d      |-> d          &*&
    b->incE   |-> 2*dy       &*&
    b->incNE  |-> 2*(dy -dx) &*&
    b->signal |-> s          &*&

    // basic bounds/shape
    0 <= dy &*& dy <= dx &*&    // Note: both dy == 0 and dy == dx edge cases are indeed fine
    0 <= x &*&                  // follows from initial state and x_i == x_(i-1) + 1
    0 <= y &*&                  // follows from initial state and y_i == y_(i-1) || y_i == y_(i-1) + 1

    // "Bresenham" invariant about d
    d == 2*dy*x - 2*dx*y + 2*dy - dx &*&

    // Pixel correctness invariant: 2*dx*y - dx <= 2*dy*x <= 2*dx*y + dx
    -dx <= err(dx, dy, x, y) &*& err(dx, dy, x, y) < dx

;

@*/

void init(int dx, int dy, Bres *b)
  //@ requires bres_access(b) &*& 0 <= dy &*& dy <= dx &*& 0 < dx;
  //@ ensures bres_state(b, dx, dy, 0, 0, 2*dy - dx, NoPulse);
{
  //@open bres_access(b);
  b->dx = dx;
  b->dy = dy;
  b->x = 0;
  b->y = 0;
  b->d = 2*dy - dx;
  b->incE = 2*dy;
  b->incNE = 2*(dy - dx);
  b->signal = NoPulse;
  //@ close bres_state(b, _, _, _, _, _, _);
}



void step(Bres *b)
  //@ requires bres_state(b, ?dx, ?dy, ?x, ?y, _, _);
  //@ ensures bres_state(b, dx, dy, x+1, _, _, _);
{
  //@ open bres_state(b, _, _, _, _, _, _);
  if (b->d < 0) {
      b->x += 1;
      b->d += b->incE;
      b->signal = Pulse;
      //@ close bres_state(b, _, _, x+1, y, _, Pulse);

  } else {
      b->x += 1;
      b->y += 1;
      b->d += b->incNE;
      b->signal = NoPulse;
      //@ close bres_state(b, _, _, x+1, y+1, _, NoPulse);
  }
}

void bresenham(int lowerRateLimitBpm, int intrinsicRateBpm)
  //@ requires 0 <= intrinsicRateBpm &*& intrinsicRateBpm <= lowerRateLimitBpm &*& 0 < lowerRateLimitBpm;
  //@ ensures true;
{
  Bres state;
  //@ close bres_access(&state);
  init(lowerRateLimitBpm, intrinsicRateBpm, &state);
  printf("pulses: ");
  while (1)
    //@ invariant bres_state(&state, lowerRateLimitBpm, intrinsicRateBpm, ?x, _, _, _) &*& x <= lowerRateLimitBpm;
    //@ decreases lowerRateLimitBpm - x;
  {
    //@ open bres_state(&state, _, _, _, _, _, _);
    int cx = state.x;
    //@ close bres_state(&state, _, _, _, _, _, _);
    if (cx == lowerRateLimitBpm) break;
    step(&state);
    //@ open bres_state(&state, _, _, _, _, _, _);
    printf("%c", (state.signal == NoPulse ? '.' : '+'));
    //@ close bres_state(&state, _, _, _, _, _, _);

  }
  printf("\n");

  //@ open bres_state(&state, lowerRateLimitBpm, intrinsicRateBpm, ?lx, ?ly, _, _);
  //@ assert lx == lowerRateLimitBpm;
  //@ end_of_cycle_y_equals_dy(lowerRateLimitBpm, intrinsicRateBpm, ly);
  //@ assert ly == intrinsicRateBpm;

}

int main()
  //@ requires true;
  //@ ensures true;
{
  bresenham(80, 60);
  return 0;
}
