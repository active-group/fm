#lang forge/temporal
abstract sig Input {}
one sig Coin, SelectTea, SelectCoffee extends Input {}

abstract sig Output {}
one sig ReturnCoin, DispenseTea, DispenseCoffee extends Output {}

abstract sig Selection {}
one sig Tea, Coffee extends Selection {}

sig State {
    money : one Int,
    selection : lone Selection, // Multiplizität 0 oder 1
    output : lone Output // Output von vorher
    // , next : lone State
}

one sig Trace {
    // initialState : one State,
    var currentState : one State,
    // inputAfter : pfunc State -> Input
    var input : one Input
}

pred machine_transition {
    Trace.currentState.money = 3 => {
        Trace.input = Coin => { 
            Trace.currentState'.money = 3 // nächster Zustand
            Trace.currentState'.selection = Trace.currentState.selection
            Trace.currentState'.output = ReturnCoin
        }
        Trace.input = SelectTea => {
            Trace.currentState'.money = 0
            no Trace.currentState'.selection
            Trace.currentState'.output = DispenseTea 
        }
        Trace.input = SelectCoffee => {
            Trace.currentState'.money = 0
            no Trace.currentState'.selection
            Trace.currentState'.output = DispenseCoffee
        }
    }
    Trace.currentState.money < 2 and Trace.input = Coin => {
        Trace.currentState'.money = add[Trace.currentState.money, 1]
        Trace.currentState'.selection = Trace.currentState.selection
        no Trace.currentState'.output
    }
    Trace.currentState.money < 3 and Trace.input != Coin => {
        Trace.currentState'.money = Trace.currentState.money
        Trace.input = SelectTea => Trace.currentState'.selection = Tea
        Trace.input = SelectCoffee => Trace.currentState'.selection = Coffee
        no Trace.currentState'.output
    }
    Trace.currentState.money = 2 and Trace.input = Coin and no Trace.currentState.selection => {
        Trace.currentState'.money = 3
        no Trace.currentState'.selection
        no Trace.currentState'.output
    }
    Trace.currentState.money = 2 and Trace.input = Coin and one Trace.currentState.selection => {
        Trace.currentState'.money = 0
        no Trace.currentState'.selection
        Trace.currentState.selection = Tea => Trace.currentState'.output = DispenseTea
        Trace.currentState.selection = Coffee => Trace.currentState'.output = DispenseCoffee
    }
}

pred algorithm {
    // initialer Zustand
    Trace.currentState.money = 0
    no Trace.currentState.selection
    no Trace.currentState.output

    always machine_transition    

    all s: State | { eventually Trace.currentState = s }
}

random_run: run { // Beispiel
    algorithm
} for 6 State

tea_in_4_steps: run {
    algorithm  // and
    some i1, i2, i3, i4 : Input | {
        Trace.input = i1
        next_state Trace.input = i2  // X
        next_state next_state Trace.input = i3
        Trace.input''' = i4
        next_state next_state next_state next_state Trace.currentState.output = DispenseTea
    }
} for 5 State

always_tea_in_4_steps: check {
    algorithm =>
    always { 
        some i1, i2, i3, i4 : Input | {
            { Trace.input = i1
            next_state Trace.input = i2  // X
            next_state next_state Trace.input = i3
            Trace.input''' = i4 } =>
            next_state next_state next_state next_state Trace.currentState.output = DispenseTea
        }
    }
} for 10 State

/*
criterion: check { // Gegenbeispiel
    algorithm =>
    true // Angelas Kriterium
}

*/