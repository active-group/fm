mapL : (a -> b) -> List a -> List b
mapL f [] = []
mapL f (x :: xs) = f x :: mapL f xs

data Vect : Nat -> Type -> Type where
  Nil : Vect 0 a
  (::) : a -> Vect n a -> Vect (n+1) a
  
mapV : (a -> b) -> Vect n a -> Vect n b
mapV f [] = []
mapV f (x :: y) = f x :: mapV f y
