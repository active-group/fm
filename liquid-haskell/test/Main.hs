{-# LANGUAGE StandaloneDeriving #-}
module Main where

import Test.QuickCheck
import Bresenham

deriving instance Show State

data XY = XY Int Int deriving Show
data Nat = Nat Int deriving Show

-- This arbitrary instance mirrors the Liquid Haskell constraints on the `init_state` function
instance Arbitrary XY where
  arbitrary = do
    y <- arbitrary `suchThat` (>= 0)
    x <- arbitrary `suchThat` (> y)
    return (XY x y)
  shrink (XY x y) = [ ]

instance Arbitrary Nat where
  arbitrary = do
    x <- arbitrary `suchThat` (>= 0)
    return (Nat x)

state_at_x :: Int -> Int -> Int -> ValidState
state_at_x dx dy x = State dx dy x y d
  where
    m :: Double
    m = (fromIntegral dy) / (fromIntegral dx)
    y = round (m * (fromIntegral x))
    d = 2 * dy * (x + 1) - (2 * y * dx) - dx

make_state :: Int -> Int -> Int -> ValidState
make_state dx dy x = state_at_x dx dy x

instance Arbitrary State where
  arbitrary = do
    (XY dx dy) <- arbitrary
    x <- arbitrary
    return (make_state dx dy x)
  shrink (State {}) = [ ]

prop_into_produces_correct_states :: XY -> Nat -> Bool
prop_into_produces_correct_states (XY dx dy) (Nat x) =
  let st = make_state dx dy x
   in state_y_correct st && state_d_correct st

prop_step_preserves_validity :: State -> Bool
prop_step_preserves_validity st =
  let st' = step st
   in state_y_correct st' && state_d_correct st'

main :: IO ()
main = do
  putStrLn "prop_into_produces_correct_states"
  quickCheck prop_into_produces_correct_states

  putStrLn "prop_step_preserves_validity"
  quickCheck prop_step_preserves_validity
