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

(echo "--- Show draw-simple")
(simplify (draw-simple (mk-line 7 5) 4))
(simplify (draw-simple- (mk-line 7 5) 0 4))

(check-sat)
(get-value ((draw-simple (mk-line 7 5) 4)))
