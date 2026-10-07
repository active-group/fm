theory Mergesort
  imports Main
begin

fun merge :: "('a :: linorder) list \<Rightarrow> 'a list \<Rightarrow> 'a list"
  where
     "merge [] ys = ys"
   | "merge xs [] = xs"
   | "merge (x # xs) (y # ys) =
      (if x \<le> y
       then x # merge xs (y # ys)
       else y # merge (x # xs) ys)"

fun msort :: "('a :: linorder) list \<Rightarrow> 'a list"
  where
     "msort [] = []"
   | "msort [x] = [x]"
   | "msort xs =
      (let half = (length xs) div 2
       in merge (msort (take half xs))
                (msort (drop half xs)))"

fun le :: "('a :: linorder) \<Rightarrow> 'a list \<Rightarrow> bool"
  where
    "le x [] = True"
  | "le x (y # ys) = (x \<le> y \<and> le x ys)"

fun sorted :: "('a :: linorder) list \<Rightarrow> bool"
  where
     "sorted [] = True"
   | "sorted (x # xs) =
      (le x xs \<and> sorted xs)"

lemma le_leq : "le y ys \<Longrightarrow> x \<le> y \<Longrightarrow> le x ys"
  apply (induction ys)
  apply (auto)
  done

lemma le_merge : "le x xs \<Longrightarrow> le x ys \<Longrightarrow> le x (merge xs ys)"
  apply (induction xs ys rule: merge.induct)
  apply (auto)
  done

lemma merge_preserves_sorted : "sorted xs \<Longrightarrow> sorted ys \<Longrightarrow> sorted (merge xs ys)"
  apply (induction xs ys rule: merge.induct)
  apply (auto simp: le_merge le_leq)
  done

theorem "sorted (msort xs)"
  apply (induction xs rule: msort.induct)
  apply (auto simp: merge_preserves_sorted)
  done

end