(defun lmerge (xs ys)
  (declare (xargs :guard (true-listp xs)))
  (declare (xargs :guard (true-listp ys)))
  (declare (xargs :measure
		  (+ (len xs) (len ys))))
  (cond
    ((endp xs) ys)
    ((endp ys) xs)
    (t
     (if (lexorder (car xs) (car ys))
	 (cons (car xs)
	       (lmerge (cdr xs) ys))
	 (cons (car ys)
	       (lmerge xs (cdr ys)))))))


(defun le (x xs)
  (declare (xargs :guard (true-listp xs)))
  (if (endp xs)
      t
      (and (lexorder x (car xs))
	   (le x (cdr xs)))))


(defthm le_leq
    (implies (and (le y ys)
		  (lexorder x y))
	     (le x ys)))

(defthm le_merge
    (implies (and (le x xs)
		  (le x ys))
	     (le x (lmerge xs ys))))

(defun sortedp (xs)
  (declare (xargs :guard (true-listp xs)))
  (if (endp xs)
      t
      (and (le (car xs) (cdr xs))
	   (sortedp (cdr xs)))))

(defthm merge_preserves_sorted
    (implies (and (sortedp xs)
		  (sortedp ys))
	     (sortedp
	      (lmerge xs ys))))
