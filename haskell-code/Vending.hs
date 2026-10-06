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
