{-# OPTIONS_GHC -fplugin=LiquidHaskell #-}
-- {-# OPTIONS_GHC -fplugin=LiquidHaskell -fplugin-opt=LiquidHaskell:--verbose #-}

module Bresenham where

{-@

data State = State {
  state_dx :: {dx':Int | 0 < dx'},
  state_dy :: {dy':Int | 0 <= dy' && dy' <= state_dx},
  state_x :: {x':Int | x' >= 0},
  state_y :: Int,
  state_d :: Int,
}

@-}
data State = State {
  state_dx :: Int,
  state_dy :: Int,
  state_x :: Int,
  state_y :: Int,
  state_d :: Int
  }

{-@ measure state_y_correct @-}
state_y_correct :: State -> Bool
--                                    y          > dy/dx * x - 1/2 && y          <= dy/dx * x + 1/2
--                                    2 * dx * y > 2 * dy * x - dx && 2 * y * dx <= 2 * dy * x + dx
state_y_correct (State dx dy x y _) = 2 * dx * y > 2 * dy * x - dx && 2 * y * dx <= 2 * dy * x + dx

{-@ measure state_d_correct @-}
state_d_correct :: State -> Bool
state_d_correct (State dx dy x y d) = d == 2 * dy * (x + 1) - (2 * y * dx) - dx

{-@ type ValidState = {st:State | state_y_correct st && state_d_correct st} @-}
type ValidState = State


{-@ step :: st:ValidState -> {st':ValidState | state_x st' == state_x st + 1} @-}
step :: ValidState -> ValidState
step (State dx dy x y d) =
  if d >= 0
  then
    (State dx dy (x + 1) (y + 1) (d + ((2 * dy) - (2 * dx))))
  else
    (State dx dy (x + 1) y (d + (2 * dy)))

{-@ into_state :: {dx:Int | dx > 0} -> {dy:Int | dy >= 0 && dy <= dx} -> ValidState @-}
into_state :: Int -> Int -> ValidState
into_state dx dy = State dx dy 0 0 d
  where
    d = 2 * dy * (0 + 1) - (2 * 0 * dx) - dx
