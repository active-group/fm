{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE TypeFamilies #-}
module Vending where

import Data.IORef (IORef)
import qualified Data.IORef as IORef
import System.IO.Unsafe (unsafePerformIO)
import Test.QuickCheck
import Test.QuickCheck.Monadic
import StateModel
import System.Process
import GHC.IO.Handle

data Product
  = Tea
  | Coffee
  deriving (Show, Eq)

data Output
  = DispenseTea
  | DispenseCoffee
  | ReturnCoin
  deriving (Show, Eq)

data CVending = CVending {
  actionHandle :: Handle,
  outputHandle :: Handle,
  processHandle :: ProcessHandle
}

{-# NOINLINE cVendingRef #-}
cVendingRef :: IORef CVending
cVendingRef = unsafePerformIO (IORef.newIORef undefined)

startCVending =
  do (Just actionHandle, Just outputHandle, Nothing, processHandle) <-
       createProcess (proc "./vending" []) { std_in = CreatePipe, std_out = CreatePipe }
     hSetBuffering actionHandle LineBuffering
     hSetBuffering outputHandle LineBuffering
     IORef.writeIORef cVendingRef (CVending actionHandle outputHandle processHandle)

finishCVending =
  do cVending <- IORef.readIORef cVendingRef
     cleanupProcess (Just (actionHandle cVending), Just (outputHandle cVending), Nothing, processHandle cVending)

cOutput :: IO (Maybe Output)
cOutput =
  do cVending <- IORef.readIORef cVendingRef
     line <- hGetLine (outputHandle cVending)
     -- putStrLn ("line: " ++ line)
     return (case line of
               "tea" -> Just DispenseTea
               "coffee" -> Just DispenseCoffee
               "coin" -> Just ReturnCoin
               _ -> Nothing)

cCoin :: IO (Maybe Output)
cCoin =
  do cVending <- IORef.readIORef cVendingRef
     hPutStr (actionHandle cVending) "coin\n"
     cOutput

cSelect :: Product -> IO (Maybe Output)
cSelect product =
  do cVending <- IORef.readIORef cVendingRef
     let action = case product of
                    Tea -> "tea"
                    Coffee -> "coffee"
     hPutStr (actionHandle cVending) (action ++ "\n")
     cOutput

-- Zustandsmaschine

data State = MkState (Maybe Product) 
  deriving Show

instance StateModel State where
  data Action State =
      Select Product
    | InsertCoin
    deriving Show

  type ActionMonad State = IO

  arbitraryAction :: State -> Gen (Action State)
  arbitraryAction _ = oneof [pure InsertCoin,
                             Select <$> elements [Tea, Coffee]]

  data Ret State = 
      Dispense Product
    | GiveBackCoin                  
    | Noop
    deriving Show

  initialState :: State
  initialState = MkState Nothing

  nextState :: State -> Action State -> Step -> State
  nextState (MkState previousSelection) (Select product) step = 
    MkState (Just product)
  nextState state InsertCoin step = state

  postcondition :: State -> Action State -> (Step -> Ret State) -> Ret State -> Bool
  postcondition state (Select product) getStep (Dispense product') =
    product == product'
  postcondition state (Select product) getStep GiveBackCoin =
    True
  postcondition state (Select product) getStep Noop =
    True
  postcondition (MkState (Just product)) InsertCoin getStep (Dispense product') =
    product == product'
  postcondition (MkState Nothing) InsertCoin getStep (Dispense product') =
    False
  postcondition state InsertCoin getStep GiveBackCoin = True
  postcondition state InsertCoin getStep Noop = True

  perform :: Action State -> [Ret State] -> ActionMonad State (Ret State)
  perform (Select product) _ = 
    do maybeOutput <- cSelect product
       case maybeOutput of
         Nothing -> return Noop
         Just DispenseTea -> return (Dispense Tea)
         Just DispenseCoffee -> return (Dispense Coffee)
         Just ReturnCoin -> return GiveBackCoin

  perform InsertCoin _ = 
    do maybeOutput <- cCoin
       case maybeOutput of
        Nothing -> return Noop
        Just DispenseTea -> return (Dispense Tea)
        Just DispenseCoffee -> return (Dispense Coffee)
        Just ReturnCoin -> return GiveBackCoin

prop_CorrectProduct :: Script State -> Property
prop_CorrectProduct s =
  monadicIO $ do
    run startCVending
    runScript s
    run finishCVending
    assert True
        
main :: IO ()
main = quickCheck prop_CorrectProduct