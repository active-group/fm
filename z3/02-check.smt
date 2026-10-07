(declare-datatypes ()
                   ((Line (mk-line (line-dx Int)
                                   (line-dy Int)))))

(define-fun line-valid ((l Line))
  Bool
  (>= (line-dx l) (line-dy l)))

(echo "--- tests for valid slope.")
(push)
(echo "sat expected")
(assert (line-valid (mk-line 12 4)))
(check-sat)
(pop)

(push)
(echo "unsat expected")
(assert (line-valid (mk-line 4 12)))
(check-sat)
(pop)

(push)
(echo "sat expected")
(assert (line-valid (mk-line 2 1)))
(check-sat)
(pop)

;; this is a comment

(define-fun line-valid-var-1 ((l Line))
  Bool
  (<= (line-dy l) (line-dx l)))

(define-fun line-valid-var-2 ((l Line))
  Bool
  (< (line-dy l) (line-dx l)))

(push)
(declare-const l Line)
(assert (= (line-valid l) (line-valid-var-1 l)))
(echo "sat expected")
(check-sat)
(pop)

(push)
(declare-const l Line)
(assert (= (line-valid l) (line-valid-var-2 l)))
(echo "sat expected")
(check-sat)
(get-value (l))
(get-model)
(pop)

(push)
(assert (forall ((l Line))
           (= (line-valid l) (line-valid-var-1 l))))
(echo "sat expected")
(check-sat)
(pop)

(push)
(assert (forall ((l Line))
           (= (line-valid l) (line-valid-var-2 l))))
(echo "unsat expected")
(check-sat)
(pop)
