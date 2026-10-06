#lang forge/froglet
abstract sig Input {}
one sig Coin, SelectTea, SelectCoffee extends Input {}

abstract sig Output {}
one sig ReturnCoin, DispenseTea, DispenseCoffee extends Output {}

abstract sig Selection {}
one sig Tea, Coffee extends Selection {}

sig State {
    money : one Int,
    selection : lone Selection, // Multiplizität 0 oder 1
    output : lone Output, // Output von vorher
    next : lone State
}

one sig Trace {
    initialState : one State,
    inputAfter : pfunc State -> Input
}

pred machine_transition[prevState : State, input : Input, nextState : State] {
    prevState.money = 3 => {
        input = Coin => { 
            nextState.money = 3
            nextState.selection = prevState.selection
            nextState.output = ReturnCoin
        }
        input = SelectTea => {
            nextState.money = 0
            no nextState.selection
            nextState.output = DispenseTea 
        }
        input = SelectCoffee => {
            nextState.money = 0
            no nextState.selection
            nextState.output = DispenseCoffee
        }
    }
    prevState.money < 2 and input = Coin => {
        nextState.money = add[prevState.money, 1]
        nextState.selection = prevState.selection
        no nextState.output
    }
    prevState.money < 3 and input != Coin => {
        nextState.money = prevState.money
        input = SelectTea => nextState.selection = Tea
        input = SelectCoffee => nextState.selection = Coffee
        no nextState.output
    }
    prevState.money = 2 and input = Coin and no prevState.selection => {
        nextState.money = 3
        no nextState.selection
        no nextState.output
    }
    prevState.money = 2 and input = Coin and one prevState.selection => {
        nextState.money = 0
        no nextState.selection
        prevState.selection = Tea => nextState.output = DispenseTea
        prevState.selection = Coffee => nextState.output = DispenseCoffee
    }
}

pred algorithm {
    // initialer Zustand
    Trace.initialState.money = 0
    no Trace.initialState.selection
    no Trace.initialState.output
    
    all s1, s2 : State | {
        s1.next = s2 => {
            some input : Input | {
                Trace.inputAfter[s1] = input and
                machine_transition[s1, input, s2]
            }
        }
    }

    all s: State | { s = Trace.initialState or 
                      reachable[s, Trace.initialState, next]}
}

random_run: run {
    algorithm
} for exactly 6 State for { next is linear } 