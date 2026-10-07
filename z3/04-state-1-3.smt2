(declare-datatypes ()
                   ((Line (mk-line (line-dx Int)
                                   (line-dy Int)))))

(define-fun line-valid ((l Line))
  Bool
  (and
   (>  (line-dx l) 0) ;; Steigung darf nicht 0 sein & rechts oben
   (>= (line-dy l) 0) ;; nach rechts oben
   (>= (line-dx l)
       (line-dy l)))) ;; Steigung nicht mehr als 45° ; dy / dx <= 1; between 0 and 1

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

;; RAHMEN

(declare-datatypes ()
                   ((State-1 (mk-state-1 (state-1-line Line)
                                         (state-1-x Int)))))

(define-fun state-1-valid ((st State-1))
  Bool
  (and
   (line-valid (state-1-line st))
   (>= (state-1-x st) 0)))

(define-fun state-1-y ((st State-1))
  Real
  (line-y (state-1-line st) (state-1-x st)))

(define-fun state-1-rounded-y ((st State-1))
  Int
  (round-to-nearest (state-1-y st)))

(define-fun step-1 ((st State-1))
  State-1
  (mk-state-1 (state-1-line st)
              (+ 1 (state-1-x st))))

(define-fun-rec draw-1- ((st State-1) (steps-left Int))
  (List Int)
  (ite (<= steps-left 0)
       ;; done
       nil
       ;; recurse
       (insert (state-1-rounded-y st)
               (draw-1- (step-1 st) (- steps-left 1)))))

(define-fun draw-1 ((l Line) (steps Int))
  (List Int)
  (draw-1- (mk-state-1 l 0) steps))

;; weg mit der reelen Zahl

(define-fun candidate-y-stay ((st State-1))
  Int
  (state-1-rounded-y st))

(define-fun candidate-y-move-up ((st State-1))
  Int
  (+ 1 (state-1-rounded-y st)))

(echo "--- tests next y is either stay or up")
(push)

(declare-const st State-1)

(assert (state-1-valid st))
(assert (not (let ((next-st (step-1 st)))
                (or (= (candidate-y-stay    st) (state-1-rounded-y next-st))
                    (= (candidate-y-move-up st) (state-1-rounded-y next-st))))))
(echo "unsat expected")
(check-sat)
(pop)

;; Abstand vom Ideal

(define-fun state-1-next-y-distance-top ((st State-1))
  Real
  (- (candidate-y-move-up st)
     (state-1-y (step-1 st))))

(define-fun state-1-next-y-distance-bottom ((st State-1))
  Real
  (- (state-1-y (step-1 st))
     (candidate-y-stay st)))

(echo "--- tests the msaller distance is chosen")

;; (push)
;; (declare-const st State-1)
;; (assert (state-1-valid st))
;;
;; (assert (not (let ((next-y (state-1-rounded-y (step-1 st))))
;;                 (ite (< (state-1-next-y-distance-top    st)
;;                         (state-1-next-y-distance-bottom st))
;;                      (= next-y (candidate-y-move-up st))
;;                      (= next-y (candidate-y-stay    st))))))
;;
;; (echo "unsat expected")
;; (check-sat)
;; (get-value ((state-1-rounded-y (step-1 st))
;;             (state-1-next-y-distance-top st)
;;             (state-1-next-y-distance-bottom st)
;;             (candidate-y-move-up st)
;;             (candidate-y-stay st)))
;; (pop)

(push)
(declare-const st State-1)
(assert (state-1-valid st))

(assert (not (let ((next-y (state-1-rounded-y (step-1 st))))
                (ite (<= (state-1-next-y-distance-top    st)
                         (state-1-next-y-distance-bottom st))
                     (= next-y (candidate-y-move-up st))
                     (= next-y (candidate-y-stay    st))))))

(echo "unsat expected")
(check-sat)
(pop)

(echo "--- test distance without reals")

(push)
(declare-const st State-1)
(assert (state-1-valid st))

(assert (not
           (=
             ;; die ursprüngliche Bedingung....
             (<= (state-1-next-y-distance-top    st)
                 (state-1-next-y-distance-bottom st))
             (<= 0
                 (- (* 2 (line-y (state-1-line (step-1 st))
                                 (state-1-x    (step-1 st))))
                    (* 2 (state-1-rounded-y st))
                    1)))))

(echo "unsat expected")
(check-sat)
(pop)


(push)
(declare-const st State-1)
(assert (state-1-valid st))

(assert (not
           (=
             ;; die ursprüngliche Bedingung....
             (<= (state-1-next-y-distance-top    st)
                 (state-1-next-y-distance-bottom st))

             ;; ist äquivalent zu dieser hier
             (let ((dx    (line-dx (state-1-line st)))
                   (dy    (line-dy (state-1-line st)))
                   (x     (state-1-x st))
                   (y-rnd (state-1-rounded-y st)))
                (<= 0
                    (- (* 2 (* (/ dy dx)
                               (+ 1 x)))
                       (* 2 y-rnd)
                       1))))))
(echo "unsat expected")
(check-sat)
(pop)

(push)
(declare-const st State-1)
(assert (state-1-valid st))

(assert (not
           (=
             ;; die ursprüngliche Bedingung....
             (<= (state-1-next-y-distance-top    st)
                 (state-1-next-y-distance-bottom st))

             ;; ist äquivalent zu dieser hier
             (let ((dx    (line-dx (state-1-line st)))
                   (dy    (line-dy (state-1-line st)))
                   (x     (state-1-x st))
                   (y-rnd (state-1-rounded-y st)))

               ;; nur bei dx >= 0
               (<= 0
                   (- (* 2 dy (+ 1 x))
                      (* 2 y-rnd dx)
                      dx))))))

(echo "unsat expected")
(check-sat)
(pop)

;; d = (- (* 2 dy (+ 1 x)) (* 2 y-rnd dx) dx)

(declare-datatypes ()
                   ((State-3 (mk-state-3 (state-3-dx Int)
                                         (state-3-dy Int)
                                         (state-3-x  Int)
                                         (state-3-y-rnd Int)
                                         (state-3-d Int)))))

(define-fun state-3-slope ((st State-3))
  Real
  (/ (state-3-dy st)
     (state-3-dx st)))

(define-fun state-3-valid ((st State-3))
  Bool
  (let ((dx    (state-3-dx    st))
        (dy    (state-3-dy    st))
        (slope (state-3-slope st))
        (x     (state-3-x     st))
        (y-rnd (state-3-y-rnd st))
        (d     (state-3-d     st)))
     (and (< 0 dx)
          (<= 0 dy dx)
          (>= x 0)
          (= y-rnd (round-to-nearest (* slope x)))

          (= d (- (* 2 dy (+ 1 x))
                  (* 2 y-rnd dx)
                  dx)))))

(define-fun into-state-3 ((st State-1))
  State-3
  (let ((dx (line-dx (state-1-line st)))
        (dy (line-dy (state-1-line st)))
        (x (state-1-x st)))

      (let ((y-rnd (round-to-nearest (* (/ dy dx) x))))
        (mk-state-3 dx
                    dy
                    x
                    y-rnd
                    (- (* 2 dy (+ 1 x)) (* 2 y-rnd dx) dx)))))

(define-fun step-3 ((st State-3))
  State-3

  (let ((dx    (state-3-dx    st))
        (dy    (state-3-dy    st))
        (x     (state-3-x     st))
        (y-rnd (state-3-y-rnd st))
        (d     (state-3-d     st)))
    (ite (<= 0 d)
      ;; candidate up
      (mk-state-3
         dx
         dy
         (+ x 1)
         (+ y-rnd 1)
         (+ d (- (* 2 dy)
                 (* 2 dx))))
      ;; candidate stay
      (mk-state-3
         dx
         dy
         (+ x 1)
         y-rnd
         (+ d (* 2 dy))))))


(echo "--- commutative: step-3/State-3 like step-1/State-1")

(push)
(declare-const st State-1)
(assert (state-1-valid st))

(assert (not (= (step-3 (into-state-3 st))
                (into-state-3 (step-1 st)))))
(echo "unsat expected")
(check-sat)
(pop)



;; Umformung 1
;;           ;; Die ursprüngliche Bedingung ...
;;           (<= (state-1-next-y-distance-top    st)
;;               (state-1-next-y-distance-bottom st))
;;
;;           ;; ... ist äquivalent zu dieser hier
;;           (<= 0
;;               (- (* 2 (line-y (state-1-line (step-1 st))
;;                               (state-1-x (step-1 st))))
;;                  (* 2 (state-1-rounded-y st))
;;                  1)))))
;;
;;
;; INFIX statt PREFIX
;;
;; (state-1-next-y-distance-top st) <= (state-1-next-y-distance-bottom st)  ---> | - (state-1-next-y-distance-top st)
;;
;;  0 <= (state-1-next-y-distance-bottom st) - (state-1-next-y-distance-top st) ---> | einsetzen distances
;;
;;  0 <= ((state-1-y (step-1 st)) - (candidate-y-stay st)) - ((candidate-y-move-up st) - (state-1-y (step-1 st))) ---> | einsetzen candidates
;;
;;  0 <= ((state-1-y (step-1 st)) - (state-1-rounded-y st)) - ((1 + (state-1-rounded-y st)) - (state-1-y (step-1 st))) ---> | Klammern
;;
;;  0 <= (state-1-y (step-1 st)) - (state-1-rounded-y st) - (1 + (state-1-rounded-y st)) + (state-1-y (step-1 st)) ---> | Klammern
;;
;;  0 <= (state-1-y (step-1 st)) - (state-1-rounded-y st) - 1 - (state-1-rounded-y st) + (state-1-y (step-1 st)) ---> | zusammenfassen
;;
;;  0 <= 2 * (state-1-y (step-1 st)) - 2 * (state-1-rounded-y st) - 1 ---> | einsetzen state-1-y (Achtung Argument ist (step-1 st) nicht st
;;
;;  0 <= 2 * (line-y (state-1-line (step-1 st)) (state-1-x (step-1 st))) - 2 * (state-1-rounded-y st) - 1
;;
;;
;; Umformung 2
;;
;;
;;          (=
;;
;;           ;; Die ursprüngliche Bedingung ...
;;           (<= (state-1-next-y-distance-top    st)
;;               (state-1-next-y-distance-bottom st))
;;
;;           ;; ... ist äquivalent zu dieser hier
;;           (let ((dx (line-dx (state-1-line st)))
;;                 (dy (line-dy (state-1-line st)))
;;                 (x (state-1-x st))
;;                 (y-rnd (state-1-rounded-y st)))
;;
;;            (<= 0
;;                (- (* 2 (* (/ dy dx)
;;                           (+ 1 x)))
;;                   (* 2 y-rnd)
;;                   1))))
;;
;;  0 <= 2 * (line-y (state-1-line (step-1 st)) (state-1-x (step-1 st))) - 2 * (state-1-rounded-y st) - 1 ---> | ersetzen: y-rnd = (state-1-rounded-y st)
;;
;;  0 <= 2 * (line-y (state-1-line (step-1 st)) (state-1-x (step-1 st))) - 2 * y-rnd - 1 ---> | ersetzen: line-y
;;
;;  0 <= 2 * ((line-slope (state-1-line (step-1 st))) * (state-1-x (step-1 st))) - 2 * y-rnd - 1 ---> | ersetzen: line-slope
;;
;;  0 <= 2 * (((line-dy (state-1-line (step-1 st))) / (line-dx (state-1-line (step-1 st)))) * (state-1-x (step-1 st))) - 2 * y-rnd - 1
;;  ---> | ersetzen line-dy und line-dx
;;  - step-1 reicht die line durch
;;
;;  0 <= 2 * ((dy / dx) * (state-1-x (step-1 st))) - 2 * y-rnd - 1 ---> | ersetzen (state-1-x (step-1 st))
;;
;;  0 <= 2 * ((dy / dx) * (1 + x)) - 2 * y-rnd - 1
;;
;;
;; Umformung 3
;;
;;           ;; Die ursprüngliche Bedingung ...
;;           (<= (state-1-next-y-distance-top    st)
;;               (state-1-next-y-distance-bottom st))
;;
;;           ;; ... ist äquivalent zu dieser hier
;;           (let ((dx (line-dx (state-1-line st)))
;;                 (dy (line-dy (state-1-line st)))
;;                 (x (state-1-x st))
;;                 (y-rnd (state-1-rounded-y st)))
;;
;;            ;; nur bei dx /= 0
;;            (<= 0
;;                (-
;;                 (* 2 dy (+ 1 x))
;;                 (* 2 y-rnd dx)
;;                 dx))))
;;
;;  0 <= 2 * ((dy / dx) * (1 + x)) - 2 * y-rnd - 1 ---> | * dx (für dx ungleich 0)
;;
;;  0 <= 2 * dy  * (1 + x) - 2 * y-rnd * dx - dx
