module Mersenne where

import Test.QuickCheck

divides :: Integer -> Integer -> Bool
m `divides` n = n `mod` m == 0

isPrime :: Integer -> Bool
isPrime n | n <= 1 = False
isPrime 2 = True
isPrime n = not (any (`divides` n) [2..n-1])

prop :: Integer -> Property
prop = \n -> isPrime n && n /= 11 ==> isPrime (2 ^ n - 1)

main = quickCheck prop
