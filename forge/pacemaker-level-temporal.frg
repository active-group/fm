#lang forge/temporal

option max_tracelength 20

abstract sig Stimulus {}
one sig L, M, H extends Stimulus {}

abstract sig Response {}
one sig Blip, Bz extends Response {}

one sig Trace {
    var currentState : one State,
    var response : one Response
}

sig State {
    stimulus : one Stimulus,
    blipCount : one Int,  // FIXME: unify blipCount & hCount
    hCount : one Int -- how long we've been in H
}

-- if it reacts to L, stay with L
-- if it doesn't react to L, try M
-- if it doesn't react to M, try H
-- if it reacts to M 2 times, try L again
-- if it reacts to H 3 times, try M

pred hardware_constraints {
    always {
        // can't skip level
        Trace.currentState.stimulus = L => Trace.currentState'.stimulus = L or Trace.currentState'.stimulus = M
        // can go anywhere from M
        Trace.currentState.stimulus = H => Trace.currentState'.stimulus = H or Trace.currentState'.stimulus = M
    }
}

pred heart_constraints {
    -- no more than 3 Hs in a row
    always {
        not {
            Trace.currentState.stimulus = H
            Trace.currentState'.stimulus = H
            Trace.currentState''.stimulus = H
            Trace.currentState'''.stimulus = H
        }
    }
    -- if the heart's not reacting, get to H within 4 beats
    always {
        { Trace.response = Bz
          Trace.response' = Bz
          Trace.response'' = Bz
          Trace.response''' = Bz
        } => 
        Trace.currentState.stimulus = H or
        Trace.currentState'.stimulus = H or
        Trace.currentState'''.stimulus = H or
        Trace.currentState''''.stimulus = H
    }
}

pred algorithm_transition {
    Trace.response = Bz => Trace.currentState'.blipCount = 0

    Trace.currentState.stimulus = L and Trace.response = Blip => {
        Trace.currentState'.stimulus = L
        Trace.currentState'.blipCount = 0 // not really necessary, but force determinism
    }
    Trace.currentState.stimulus = L and Trace.response = Bz => {
        Trace.currentState'.stimulus = M
    }

    Trace.currentState.stimulus = M and Trace.response = Blip and Trace.currentState.blipCount < 2 => {
        Trace.currentState'.stimulus = M
        Trace.currentState'.blipCount = add[Trace.currentState.blipCount, 1]
    }
    Trace.currentState.stimulus = M and Trace.response = Bz => {
        Trace.currentState'.stimulus = H
    }
    Trace.currentState.stimulus = M and Trace.response = Blip and Trace.currentState.blipCount = 2 => {
        Trace.currentState'.stimulus = L
    }

    Trace.currentState.stimulus != H => Trace.currentState'.hCount = 0

    Trace.currentState.stimulus = H and Trace.currentState.hCount = 2 => { // this H is the 3rd one
        Trace.currentState'.stimulus = M
        Trace.currentState'.hCount = 0
        Trace.currentState'.blipCount = 0 // cause M level to go for a bit before going down to L
    }
    Trace.currentState.stimulus = H and Trace.response = Blip and Trace.currentState.hCount < 2 => {
        Trace.currentState'.stimulus = M
        Trace.currentState'.blipCount = 1
    }
    Trace.currentState.stimulus = H and Trace.response = Bz and Trace.currentState.hCount < 2 => { -- zap it again
        Trace.currentState'.stimulus = H
        Trace.currentState'.hCount = add[Trace.currentState.hCount, 1]
    }

}

pred algorithm {
    all s: State | { eventually s = Trace.currentState }
    Trace.currentState.blipCount = 0
    Trace.currentState.hCount = 0
    Trace.currentState.stimulus = L
    always algorithm_transition
}

random_trajectory: run {
    algorithm
} for exactly 6 State

dead: run {
    always { Trace.response = Bz }
    algorithm
} for exactly 6 State

correct: check {
    algorithm => { hardware_constraints and heart_constraints }
} for 6 State

