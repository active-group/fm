theory Bresenham
  imports Complex_Main
begin

section \<open>Bresenham's line drawing algorithm\<close>

record State =
  dx :: int
  dy :: int
  x :: int
  y :: int
  d :: int

fun step :: "State \<Rightarrow> State"
  where
  "step state =
    (if 0 \<le> d state
     then \<lparr> dx = dx state, dy = dy state, x = x state + 1, y = y state + 1,
            d = d state + ((2 * dy state) - (2 * dx state)) \<rparr>
     else
          \<lparr> dx = dx state, dy = dy state, x = x state + 1, y = y state,
            d = d state + (2 * dy state) \<rparr>)"

lemma step_dx [simp]: "dx (step s) = dx s"
  by (simp split: if_split)

lemma step_dy [simp]: "dy (step s) = dy s"
  by (simp split: if_split)

lemma step_x [simp]: "x (step s) = x s + 1"
  by (simp split: if_split)

lemma step_y: "y (step s) = (if d s < 0 then y s else y s + 1)"
  by (simp split: if_split)

definition initial_state :: "int \<Rightarrow> int \<Rightarrow> State"
  where
    "initial_state dx' dy' = \<lparr> dx = dx', dy = dy', x = 0, y = 0, d = 2 * dy' - dx' \<rparr>"

section \<open>The implementation invariant\<close>

named_theorems valid_defs

definition valid_line :: "int \<Rightarrow> int \<Rightarrow> bool" where [valid_defs]:
  "valid_line dx' dy' \<equiv>
    0 < dx' \<and>
    0 \<le> dy' \<and>
    dy' \<le> dx'"

definition valid :: "State \<Rightarrow> bool" where [valid_defs]:
  "valid s \<equiv>
    valid_line (dx s) (dy s) \<and>
    d s = 2 * dy s * x s - 2 * dx s * y s + 2 * dy s - dx s"

lemma valid_dx_pos: "valid s \<Longrightarrow> 0 < dx s"
  unfolding valid_defs by simp

lemma valid_dy_nonneg: "valid s \<Longrightarrow> 0 \<le> dy s"
  unfolding valid_defs by simp

lemma valid_dy_le_dx: "valid s \<Longrightarrow> dy s \<le> dx s"
  unfolding valid_defs by simp

lemma valid_d: "valid s \<Longrightarrow> d s = 2 * dy s * x s - 2 * dx s * y s + 2 * dy s - dx s"
  unfolding valid_defs by simp

lemma initial_state_valid: "valid_line dx' dy' \<Longrightarrow> valid (initial_state dx' dy')"
  unfolding valid_defs initial_state_def by simp

lemma step_valid: "valid s \<Longrightarrow> valid (step s)"
  unfolding valid_def by (auto simp: algebra_simps split: if_split)

lemma steps_valid: "valid s \<Longrightarrow> valid ((step ^^ n) s)"
  using step_valid
  by (induction n, auto)

theorem bresenham_valid:
  "valid_line dx' dy' \<Longrightarrow> valid ((step ^^ n) (initial_state dx' dy'))"
  using initial_state_valid steps_valid
  by blast

section \<open>Integer and geometric pixel bounds\<close>

named_theorems bounds_defs

definition error :: "State \<Rightarrow> int" where [bounds_defs]:
  "error s \<equiv> 2 * dy s * x s - 2 * dx s * y s"

definition upper_error_bound :: "State \<Rightarrow> bool" where [bounds_defs]:
  "upper_error_bound s \<equiv> - dx s \<le> error s"

definition lower_error_bound :: "State \<Rightarrow> bool" where [bounds_defs]:
  "lower_error_bound s \<equiv> error s < dx s"

text \<open>
  In the SMT-based development, pixel correctness was expressed using integer
  bounds on the error term. Geometrically, however, it is more naturally stated
  as requiring the current pixel to be within half a pixel of the ideal line.

  For @{term "0 < dx s"}, the two formulations are equivalent: multiplying the
  geometric inequalities by the positive quantity @{term "2 * dx s"} yields
  exactly the integer bounds. If @{term "dx s = 0"}, this equivalence breaks
  down: division by zero is defined in Isabelle/HOL, but loses information that
  is still present in the integer error expression.

  The strict lower and non-strict upper bound are also deliberate. At exactly
  half a pixel of error, they select one of the two equally close pixels rather
  than admitting both.

  Thus, for valid lines, the integer bounds used in the SMT formulation express
  exactly the same correctness criterion as the more intuitive geometric
  formulation.
\<close>

lemma int_real_lower_bound_equiv:
  assumes "0 < dx s"
  shows "lower_error_bound s \<longleftrightarrow> (dy s / dx s) * x s - 1/2 < y s"
proof -
  from `0 < dx s` have dx_pos: "0 < real_of_int (dx s)" by simp_all
  show ?thesis
  proof auto
    assume "lower_error_bound s"
    hence
      "dx s >
        2 * real_of_int (dy s) * real_of_int (x s) -
        2 * real_of_int (dx s) * real_of_int (y s)"
      using of_int_less_iff[of "error s" "dx s"]
      unfolding bounds_defs
      by simp
    with dx_pos
    show "real_of_int (dy s) * real_of_int (x s) / real_of_int (dx s) - 1 / 2 < real_of_int (y s)"
      by (auto simp: field_simps)
  next
    assume "real_of_int (dy s) * real_of_int (x s) / real_of_int (dx s) - 1 / 2 < real_of_int (y s)"
    with dx_pos show "lower_error_bound s"
      using of_int_less_iff[of "error s" "dx s"]
      unfolding bounds_defs
      by (auto simp: field_simps)
  qed
qed

lemma int_real_upper_bound_equiv:
  assumes "0 < dx s"
  shows "upper_error_bound s \<longleftrightarrow> y s \<le> (dy s / dx s) * x s + 1/2"
proof -
  from `0 < dx s` have dx_pos: "0 < real_of_int (dx s)" by simp_all
  show ?thesis
  proof auto
    assume "upper_error_bound s"
    with dx_pos
    show "real_of_int (y s) \<le> real_of_int (dy s) * real_of_int (x s) / real_of_int (dx s) + 1 / 2"
      using of_int_le_iff[of "- dx s" "error s"]
      unfolding bounds_defs
      by (auto simp: field_simps)
  next
    assume "real_of_int (y s) \<le> real_of_int (dy s) * real_of_int (x s) / real_of_int (dx s) + 1 / 2"
    with dx_pos show "upper_error_bound s"
      using of_int_le_iff[of "- dx s" "error s"]
      unfolding bounds_defs
      by (auto simp: field_simps)
  qed
qed

subsection \<open>Pixel correctness\<close>

definition bounds_ok :: "State \<Rightarrow> bool" where [bounds_defs]:
  "bounds_ok s \<equiv> lower_error_bound s \<and> upper_error_bound s"

definition pixel_correct :: "State \<Rightarrow> bool" where
  "pixel_correct s \<equiv>
     y s \<le> (dy s / dx s) * x s + 1/2 \<and>
     y s > (dy s / dx s) * x s - 1/2"

lemma pixel_correct_equiv_bounds_ok: "0 < dx s \<Longrightarrow> pixel_correct s \<longleftrightarrow> bounds_ok s"
  using int_real_lower_bound_equiv int_real_upper_bound_equiv
  unfolding pixel_correct_def bounds_ok_def
  by auto

experiment
begin

text \<open>
  We first investigate whether the error bounds already follow from the
  properties established so far.
\<close>

lemma "bounds_ok (initial_state dx' dy')"
  unfolding initial_state_def bounds_defs
  (* nitpick *) (* counter example: dx' = 0; dy' = 0 *)
  oops

text \<open>
  Observation: The counterexample has @{term dx'} = 0, so the admissible
  error interval collapses in a way that is incompatible with the strict
  lower bound.

  Insight: A positive horizontal extent is therefore essential already for
  the initial bounds.  In particular, @{term "0 < dx'"} is not merely a
  technical side condition needed later for division; it is part of what
  makes the error bounds meaningful.
\<close>

lemma "valid s \<Longrightarrow> upper_error_bound s"
  (* nitpick *) (* counter example: s = \<lparr>dx = 1, dy = 1, x = 0, y = 1, d = - 1\<rparr> *)
  oops

lemma "valid s \<Longrightarrow> lower_error_bound s"
  (* nitpick *) (* counter example: s = \<lparr>dx = 2, dy = 1, x = 1, y = 0, d = 2\<rparr> *)
  oops

text \<open>
  Observation: @{const valid} permits states whose pixels lie outside the
  admissible error interval in either direction.

  Insight: The equation for @{term d} relates @{term d} to the current position,
  but does not restrict that position: for any @{term x} and @{term y},
  @{term d} can take the corresponding value. Consistency of the decision
  variable therefore cannot by itself establish pixel correctness; the error
  bounds contain additional information about which positions are admissible.
\<close>

lemma "valid s \<Longrightarrow> pixel_correct (step s)"
  (* nitpick *) (* counter example: s = \<lparr>dx = 1, dy = 1, x = 1, y = 0, d = 3\<rparr> *)
  oops

text \<open>
  Observation: The counterexample satisfies all algorithmic consistency
  conditions, but it starts from a pixel that is already outside the allowed
  error interval.

  Insight: One step of Bresenham is designed to preserve a good approximation,
  not to recover from an arbitrarily bad one.  Pixel correctness therefore has
  to be part of the induction hypothesis rather than something established
  from @{const valid} by a single step.
\<close>

lemma "pixel_correct s \<Longrightarrow> pixel_correct (step s)"
  (* nitpick *) (* counter example: s = \<lparr>dx = 2, dy = 1, x = 0, y = 0, d = - 1\<rparr> *)
  oops

text \<open>
  Observation: The current pixel is correct, but @{term "d s"} does not match
  the error determined by @{term "x s"} and @{term "y s"}.

  Insight: Pixel correctness constrains only the visible position of the
  current pixel.  The next step, however, is chosen from @{term "d s"}.
  Therefore preservation also requires the decision variable to faithfully
  represent the current geometric error; otherwise the algorithm can make the
  wrong branch decision even from a correct pixel.
\<close>

lemma
  assumes
    "pixel_correct s"
    "d s = 2 * dy s * x s - 2 * dx s * y s + 2 * dy s - dx s"
  shows "pixel_correct (step s)"
  (* nitpick *) (* counter example: s = \<lparr>dx = - 1, dy = - 1, x = - 1, y = - 1, d = - 1\<rparr> *)
  oops

text \<open>
  Observation: Once @{term "d s"} is tied to the current geometric error, the
  remaining counterexample exploits values with negative @{term "dx s"} and
  @{term "dy s"}.

  Insight: The preservation argument depends not only on the current error and
  decision variable, but also on the directional assumptions of the basic
  Bresenham algorithm.  Its update rules are derived for lines with positive
  horizontal extent and the corresponding slope restrictions; outside that
  domain, the same branch conditions no longer have the intended geometric
  meaning.
\<close>

end

lemma initial_state_pixel_correct: "0 < dx' \<Longrightarrow> pixel_correct (initial_state dx' dy')"
  using pixel_correct_equiv_bounds_ok
  unfolding initial_state_def bounds_defs by simp

lemma step_pixel_correct: "\<lbrakk> valid s; pixel_correct s \<rbrakk> \<Longrightarrow> pixel_correct (step s)"
  using pixel_correct_equiv_bounds_ok
  unfolding bounds_defs valid_defs
  by (auto simp: field_simps)

lemma steps_pixel_correct:
  assumes "valid s" "pixel_correct s"
  shows "pixel_correct ((step ^^ n) s)"
  using assms
proof (induction n)
  case 0 thus ?case by simp
next
  case (Suc n)
  note valid_n = steps_valid[OF `valid s`, of n]
  from Suc.IH Suc.prems
  have "pixel_correct ((step ^^ n) s)" by blast
  from step_pixel_correct[OF valid_n this]
  show ?case by (simp only: funpow.simps(2) o_apply)
qed

section \<open>What is needed for correctness?\<close>

text \<open>
  The preceding results establish correctness for the concrete definition of
  @{const step}. We now take a different perspective and ask what properties
  of @{const step} are actually needed to establish this result. To separate
  these properties from the particular implementation, we consider arbitrary
  functions that satisfy the basic structural requirements of a step and
  reason about the states reachable by repeatedly applying such a function.

  This allows us to compare two ways of ensuring pixel correctness. One is to
  specify how @{const step} updates @{const y}, thereby directly constraining
  the result of the function for every valid input state. The other is to
  require pixel correctness as an invariant of the states reached during
  execution. The following results clarify the relationship between these two
  approaches.
\<close>

definition step_like :: "(State \<Rightarrow> State) \<Rightarrow> bool" where
  "step_like f \<equiv>
     (\<forall>s. valid s \<longrightarrow> valid (f s)) \<and>
     (\<forall>s. valid s \<longrightarrow> dx (f s) = dx s) \<and>
     (\<forall>s. valid s \<longrightarrow> dy (f s) = dy s) \<and>
     (\<forall>s. valid s \<longrightarrow> x (f s) = x s + 1)"

lemma step_like_preserves_valid: "step_like f \<Longrightarrow> \<forall>s. valid s \<longrightarrow> valid (f s)"
  unfolding step_like_def by simp

lemma step_like_preserves_dx: "step_like f \<Longrightarrow> \<forall>s. valid s \<longrightarrow> dx (f s) = dx s"
  unfolding step_like_def by simp

lemma step_like_preserves_dy: "step_like f \<Longrightarrow> \<forall>s. valid s \<longrightarrow> dy (f s) = dy s"
  unfolding step_like_def by simp

lemma step_like_increments_x: "step_like f \<Longrightarrow> \<forall>s. valid s \<longrightarrow> x (f s) = x s + 1"
  unfolding step_like_def by simp


definition reachable :: "(State \<Rightarrow> State) \<Rightarrow> State \<Rightarrow> bool" where
  "reachable f s \<equiv> \<exists>dx' dy' n. valid_line dx' dy' \<and> s = (f ^^ n) (initial_state dx' dy')"

lemma reachable_induct [consumes 1, case_names initial step]:
  assumes "reachable f s"
      and initial:
        "\<And>dx' dy'. valid_line dx' dy' \<Longrightarrow> P (initial_state dx' dy')"
      and step:
        "\<And>s. \<lbrakk> reachable f s; P s \<rbrakk> \<Longrightarrow> P (f s)"
      shows "P s"
proof -
  from `reachable f s` obtain n dx' dy'
    where "valid_line dx' dy'" and s_def: "s = (f ^^ n) (initial_state dx' dy')"
    unfolding reachable_def
    by blast

  have "P ((f ^^ n) (initial_state dx' dy'))"
  proof (induction n)
    case 0 from initial[OF `valid_line dx' dy'`]
    show ?case by simp
  next
    case (Suc k)
    have "reachable f ((f ^^ k) (initial_state dx' dy'))"
      unfolding reachable_def
      using `valid_line dx' dy'`
      by blast
    from step[OF this Suc.IH]
    show ?case by simp
  qed
  with s_def show ?thesis by simp
qed

lemma reachable_valid:
  assumes
    "reachable f s"
    "\<forall>s. valid s \<longrightarrow> valid (f s)"
  shows "valid s"
  using assms
proof (induction rule: reachable_induct)
  case (initial dx' dy')
  from initial_state_valid[OF `valid_line dx' dy'`]
  show ?case .
next
  case (step s) with assms(2) show ?case
    by blast
qed

subsection \<open>The y-update is sufficient\<close>

text \<open>
  If a step preserves the basic structural properties and updates @{const y}
  according to the sign of the decision variable, then pixel correctness
  follows for every reachable state. Thus, pixel correctness need not itself
  be included in the invariant if the behaviour of the step function is
  specified precisely enough.

  In a deductive verification of an implementation, the update rule can
  therefore be expressed as a postcondition of the step function: for every
  valid input state, the result must leave @{const y} unchanged when
  @{term "d s < 0"} and increment it otherwise. Together with the remaining
  properties of a step, this is sufficient to establish pixel correctness
  throughout the execution.
\<close>

theorem y_step_sufficient_for_pixel_correctness:
  assumes
    "step_like f"
    "\<forall>s. valid s \<longrightarrow> y (f s) = (if d s < 0 then y s else y s + 1)"
  shows
    "\<forall>s. reachable f s \<longrightarrow> pixel_correct s"
proof (intro allI impI)
  fix s assume "reachable f s"
  hence "lower_error_bound s \<and> upper_error_bound s"
    using assms
  proof (induction rule: reachable_induct)
    case (initial dx' dy') thus ?case
      unfolding bounds_defs valid_defs initial_state_def
      by simp
  next
    case (step s) with reachable_valid[OF step.hyps]
    show ?case
      unfolding bounds_defs valid_defs step_like_def
      by (auto simp: algebra_simps)
  qed
  moreover
  note reachable_valid[OF `reachable f s` step_like_preserves_valid[OF `step_like f`]]
  note pixel_correct_equiv_bounds_ok[OF valid_dx_pos[OF `valid s`]]
  ultimately
  show "pixel_correct s"
    unfolding bounds_ok_def
    by simp
qed

subsection \<open>The y-update is necessary along executions\<close>

text \<open>
  Conversely, suppose pixel correctness is maintained as an invariant.
  Together with the basic properties of a step, this forces the same choice
  for @{const y} whenever a reachable state is advanced: preserving pixel
  correctness leaves no alternative to keeping @{const y} unchanged when
  @{term "d s < 0"} and incrementing it otherwise.

  There is an important difference between the two statements. An invariant
  only describes states that can occur during an execution and can therefore
  constrain the behaviour of the step function only on reachable states. A
  postcondition of the step function, by contrast, specifies its behaviour
  for every state satisfying its precondition. Pixel correctness as an
  invariant is consequently sufficient for verifying an execution, but it
  does not characterise the behaviour of the step function on valid states
  that are never reached.
\<close>

lemma unique_integer_in_pixel_interval: "\<exists>!z :: int. r - 1/2 < z \<and> z \<le> r + 1/2"
  by (metis of_int_round_gt of_int_round_le round_unique)

lemma reachable_step:
  assumes "reachable f s"
  shows "reachable f (f s)"
proof -
  from `reachable f s` obtain n dx' dy' where
    "valid_line dx' dy'" "s = (f ^^ n) (initial_state dx' dy')"
    unfolding reachable_def
    by blast
  thus ?thesis
    unfolding reachable_def
    by (rule_tac x = dx' in exI, rule_tac x = dy' in exI, rule_tac x = "Suc n" in exI, simp)
qed

theorem y_step_necessary_for_pixel_correctness:
  assumes
    "step_like f"
    "\<forall>s. reachable f s \<longrightarrow> pixel_correct s"
  shows
    "\<forall>s. reachable f s \<longrightarrow> y (f s) = (if d s < 0 then y s else y s + 1)"
proof (intro allI impI)
  note pixel_correct = assms(2)[rule_format]

  fix s assume "reachable f s"
  note (* valid s *) reachable_valid[OF this step_like_preserves_valid[OF `step_like f`]]

  have d_neg_iff:
    "d s < 0 \<longleftrightarrow>
      real_of_int (dy s) / real_of_int (dx s) * (real_of_int (x s) + 1) - 1/2 <
      real_of_int (y s)"
  proof -
    from valid_dx_pos[OF `valid s`] have "0 < real_of_int (dx s)" by simp
    moreover
    from valid_d[OF `valid s`]
    have "d s = 2 * dy s * (x s + 1) - 2 * dx s * y s - dx s"
      by (auto simp: field_simps)
    hence
      "real_of_int (d s) =
        2 * real_of_int (dy s) * (real_of_int (x s) + 1) -
        2 * real_of_int (dx s) * real_of_int (y s) - real_of_int (dx s)"
      by simp
    ultimately
    show ?thesis
      by (auto simp: field_simps)
  qed

  (*
    We need to show that y (f s) is either y s or y s + 1 depending on d.
    In both cases we show that the candidate pixel and y (f s) both lie in the same interval
    \<I> := ( dy s / dx s * (x s + 1) - 1/2, dy s / dx s * (x s + 1) + 1/2 ], since this
    interval contains exactly one integer (see lemma unique_integer_in_pixel_interval).
  *)

  let ?line_y = "real_of_int (dy s) * (real_of_int (x s) + 1) / real_of_int (dx s)"

  { from `valid s` `step_like f`
    have
      "dx (f s) = dx s"
      "dy (f s) = dy s"
      "x (f s) = x s + 1"
      unfolding step_like_def
      by simp_all
    with pixel_correct[OF reachable_step[OF `reachable f s`]]
    have
      "?line_y - 1 / 2 < real_of_int (y (f s))"
      "real_of_int (y (f s)) \<le> ?line_y + 1 / 2"
      unfolding pixel_correct_def
      by simp_all
    moreover
    fix i :: int assume "?line_y - 1/2 < i \<and> i \<le> ?line_y + 1/2"
    ultimately
    have "y (f s) = i"
      using unique_integer_in_pixel_interval
      by simp
  } note eq_y_fs_if = this

  show "y (f s) = (if d s < 0 then y s else y s + 1)"
  proof (cases "d s < 0", auto split: if_split)
    assume "d s < 0" show "y (f s) = y s"
    proof (rule eq_y_fs_if, auto)
      from `d s < 0` d_neg_iff
      show "?line_y - 1 / 2 < real_of_int (y s)"
        by simp
    next
      from pixel_correct[OF `reachable f s`]
      have "real_of_int (y s) \<le> real_of_int (dy s) * real_of_int (x s) / real_of_int (dx s) + 1 / 2"
        unfolding pixel_correct_def
        by simp
      thus "real_of_int (y s) \<le> ?line_y + 1 / 2"
      proof (rule order_trans, simp)
        from valid_dx_pos[OF `valid s`] valid_dy_nonneg[OF `valid s`]
        have "0 \<le> real_of_int (dy s) / real_of_int (dx s)" by simp
        from mult_left_mono[OF _ this]
        show "real_of_int (dy s) * real_of_int (x s) / real_of_int (dx s) \<le> ?line_y"
          by auto
      qed
    qed
  next
    assume "\<not> d s < 0" show "y (f s) = y s + 1"
    proof (rule eq_y_fs_if, auto)
      show "?line_y - 1 / 2 < real_of_int (y s) + 1"
      proof (rule le_less_trans)
        from pixel_correct[OF `reachable f s`]
        show "real_of_int (dy s) * real_of_int (x s) / real_of_int (dx s) + 1 / 2 < real_of_int (y s) + 1"
          unfolding pixel_correct_def
          by simp
      next
        from valid_dx_pos[OF `valid s`] valid_dy_le_dx[OF `valid s`]
        show "?line_y - 1 / 2 \<le> real_of_int (dy s) * real_of_int (x s) / real_of_int (dx s) + 1 / 2"
          by (auto simp: field_simps)
      qed
    next
      from `\<not> d s < 0` d_neg_iff
      have "real_of_int (y s) \<le> ?line_y - 1 / 2"
        by simp
      thus "real_of_int (y s) + 1 \<le> ?line_y + 1 / 2"
        by simp
    qed
  qed
qed

end
