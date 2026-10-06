(declare-const x Int)
(declare-const y Int)
(declare-const dx Int)
(declare-const dy Int)

(assert (not

         (=>
          (and
           (>= x 0)
           (>= y 0)
           (> dx 0)
           (>= dy 0)
           (>= dx dy))

          (=>

           ;; our declared invariant in Liquid Haskell ...
           ;; y_minus_half_times_2dx b <= ideal_y_times_2dx b
           (<=
            (-
             (* 2 y dx)
             dx)
            (* 2 dy x))

           ;; ... implies the actual error bound invariant we want to prove:
           (<=
            (- y 0.5)
            (* x (/ dy dx)))))))

(check-sat)
