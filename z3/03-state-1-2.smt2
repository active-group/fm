(declare-datatypes ()
                   ((Line (mk-line (line-dx Int)
                                   (line-dy Int)))))

(define-fun line-valid ((l Line))
  Bool
    (and
       (>  (line-dx l) 0)
       (>= (line-dy l) 0)
       (>= (line-dx l)
           (line-dy l))))

(define-fun line-slope ((l Line))
  Real
  (/ (line-dy l)
     (line-dx l)))

(define-fun line-y ((l Line) (x Int))
  Real
  (* (line-slope l) x))

(define-fun round-to-nearest ((value Real))
  Int
  (to_int (+ value 0.5)))

(define-fun line-rounded-y ((l Line) (x Int))
  Int
  (round-to-nearest (line-y l x)))


(define-fun-rec draw-simple- ((l Line) (x Int) (steps-left Int))
  (List Int)
  (ite (<= steps-left 0)
     ;; done
     nil
     ;; recurse
     (insert (line-rounded-y l x)
             (draw-simple- l (+ x 1) (- steps-left 1)))))

(define-fun draw-simple ((l Line) (steps-left Int))
  (List Int)
  (draw-simple- l 0 steps-left))


(declare-datatypes ()
                   ((State-1 (mk-state-1 (state-1-line Line)
                                         (state-1-x Int)))))

(define-fun state-1-valid ((st State-1))
  Bool
  (and (line-valid (state-1-line st))
       (>= (state-1-x st) 0)))

(define-fun state-1-y ((st State-1))
  Real
  (line-y (state-1-line st) (state-1-x st)))

(define-fun state-1-rounded-y ((st State-1))
  Int
  (line-rounded-y (state-1-line st) (state-1-x st)))

(define-fun step-1 ((st State-1))
  State-1
  (mk-state-1 (state-1-line st)
              (+ 1 (state-1-x st))))

(define-fun-rec draw-1- ((st State-1) (steps-left Int))
  (List Int)
  (ite (<= steps-left 0)
    ;; done
    nil
    ;; recursive
    (insert (state-1-rounded-y st)
            (draw-1- (step-1 st) (- steps-left 1)))))


(define-fun draw-1 ((l Line) (steps-left Int))
  (List Int)
  (draw-1- (mk-state-1 l 0) steps-left))


;; weniger Multiplikation - mehr Addition

(declare-datatypes ()
                   ((State-2 (mk-state-2 (state-2-line Line)
                                         (state-2-x Int)
                                         (state-2-y Real)))))

(define-fun state-2-rounded-y ((st State-2))
  Int
  (round-to-nearest (state-2-y st)))

(define-fun state-2-valid ((st State-2))
  Bool
  (and (line-valid (state-2-line st))
       (>= (state-2-x st) 0)
       (= (state-2-y st)
          (line-y (state-2-line st)
                  (state-2-x st)))))

(define-fun step-2 ((st State-2))
  State-2
  (mk-state-2 (state-2-line st)
              (+ 1 (state-2-x st))
              (+ (state-2-y st) (line-slope (state-2-line st)))))

(define-fun into-state-2 ((st State-1))
  State-2
  (let ((l (state-1-line st))
        (x (state-1-x st)))
    (mk-state-2 l x (line-y l x))))

(define-fun init-state-2 ((l Line))
  State-2
  (into-state-2 (mk-state-1 l 0)))


(define-fun-rec draw-2- ((st State-2) (steps-left Int))
  (List Int)
  (ite (<= steps-left 0)
       ;; done
       nil
       ;; recursive
       (insert (state-2-rounded-y st)
               (draw-2- (step-2 st) (- steps-left 1)))))

(define-fun draw-2 ((l Line) (steps Int))
  (List Int)
  (draw-2- (init-state-2 l) steps))

(echo "--- tests for draw-1 and draw-2")

(push)
(assert (forall ((l Line)
                 (steps Int))
            (= (draw-1 l steps)
               (draw-2 l steps))))
(echo "sat expected")
;; (check-sat)
(pop)


;; (push)
;; (assert (forall ((l Line))
;;         (or (not (line-valid l))
;;             (state-2-valid (init-state-2 l)))))
;; (echo "expect sat")
;; (check-sat)
;; (pop)

(push)
(declare-const l Line)
(assert (line-valid l))
(assert (not (state-2-valid (init-state-2 l))))

(echo "unsat expected")
(check-sat)
(pop)

;; step-1 und step-2

(push)
(declare-const st State-1)
(assert (state-1-valid st))

(assert
  (not (= (step-2 (into-state-2 st))
          (into-state-2 (step-1 st)))))

(echo "unsat expected")
(check-sat)
(pop)














