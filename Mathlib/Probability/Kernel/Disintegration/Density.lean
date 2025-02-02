/-
Copyright (c) 2024 Rémy Degenne. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Rémy Degenne
-/
import Mathlib.Probability.Kernel.Composition.Basic
import Mathlib.Probability.Martingale.Convergence
import Mathlib.Probability.Process.PartitionFiltration

/-!
# Kernel density

Let `κ : Kernel α (γ × β)` and `ν : Kernel α γ` be two finite kernels with `Kernel.fst κ ≤ ν`,
where `γ` has a countably generated σ-algebra (true in particular for standard Borel spaces).
We build a function `density κ ν : α → γ → Set β → ℝ` jointly measurable in the first two arguments
such that for all `a : α` and all measurable sets `s : Set β` and `A : Set γ`,
`∫ x in A, density κ ν a x s ∂(ν a) = (κ a (A ×ˢ s)).toReal`.

There are two main applications of this construction (still TODO, in other files).
* Disintegration of kernels: for `κ : Kernel α (γ × β)`, we want to build a kernel
  `η : Kernel (α × γ) β` such that `κ = fst κ ⊗ₖ η`. For `β = ℝ`, we can use the density of `κ`
  with respect to `fst κ` for intervals to build a kernel cumulative distribution function for `η`.
  The construction can then be extended to `β` standard Borel.
* Radon-Nikodym theorem for kernels: for `κ ν : Kernel α γ`, we can use the density to build a
  Radon-Nikodym derivative of `κ` with respect to `ν`. We don't need `β` here but we can apply the
  density construction to `β = Unit`. The derivative construction will use `density` but will not
  be exactly equal to it because we will want to remove the `fst κ ≤ ν` assumption.

## Main definitions

* `ProbabilityTheory.Kernel.density`: for `κ : Kernel α (γ × β)` and `ν : Kernel α γ` two finite
  kernels, `Kernel.density κ ν` is a function `α → γ → Set β → ℝ`.

## Main statements

* `ProbabilityTheory.Kernel.setIntegral_density`: for all measurable sets `A : Set γ` and
  `s : Set β`, `∫ x in A, Kernel.density κ ν a x s ∂(ν a) = (κ a (A ×ˢ s)).toReal`.
* `ProbabilityTheory.Kernel.measurable_density`: the function
  `p : α × γ ↦ Kernel.density κ ν p.1 p.2 s` is measurable.

## Construction of the density

If we were interested only in a fixed `a : α`, then we could use the Radon-Nikodym derivative to
build the density function `density κ ν`, as follows.
```
def density' (κ : Kernel α (γ × β)) (ν : kernel a γ) (a : α) (x : γ) (s : Set β) : ℝ :=
  (((κ a).restrict (univ ×ˢ s)).fst.rnDeriv (ν a) x).toReal
```
However, we can't turn those functions for each `a` into a measurable function of the pair `(a, x)`.

In order to obtain measurability through countability, we use the fact that the measurable space `γ`
is countably generated. For each `n : ℕ`, we define (in the file
`Mathlib.Probability.Process.PartitionFiltration`) a finite partition of `γ`, such that those
partitions are finer as `n` grows, and the σ-algebra generated by the union of all partitions is the
σ-algebra of `γ`. For `x : γ`, `countablePartitionSet n x` denotes the set in the partition such
that `x ∈ countablePartitionSet n x`.

For a given `n`, the function `densityProcess κ ν n : α → γ → Set β → ℝ` defined by
`fun a x s ↦ (κ a (countablePartitionSet n x ×ˢ s) / ν a (countablePartitionSet n x)).toReal` has
the desired property that `∫ x in A, densityProcess κ ν n a x s ∂(ν a) = (κ a (A ×ˢ s)).toReal` for
all `A` in the σ-algebra generated by the partition at scale `n` and is measurable in `(a, x)`.

`countableFiltration γ` is the filtration of those σ-algebras for all `n : ℕ`.
The functions `densityProcess κ ν n` described here are a bounded `ν`-martingale for the filtration
`countableFiltration γ`. By Doob's martingale L1 convergence theorem, that martingale converges to
a limit, which has a product-measurable version and satisfies the integral equality for all `A` in
`⨆ n, countableFiltration γ n`. Finally, the partitions were chosen such that that supremum is equal
to the σ-algebra on `γ`, hence the equality holds for all measurable sets.
We have obtained the desired density function.

## References

The construction of the density process in this file follows the proof of Theorem 9.27 in
[O. Kallenberg, Foundations of modern probability][kallenberg2021], adapted to use a countably
generated hypothesis instead of specializing to `ℝ`.
-/

open MeasureTheory Set Filter MeasurableSpace

open scoped NNReal ENNReal MeasureTheory Topology ProbabilityTheory

namespace ProbabilityTheory.Kernel

variable {α β γ : Type*} {mα : MeasurableSpace α} {mβ : MeasurableSpace β} {mγ : MeasurableSpace γ}
    [CountablyGenerated γ] {κ : Kernel α (γ × β)} {ν : Kernel α γ}

section DensityProcess

/-- An `ℕ`-indexed martingale that is a density for `κ` with respect to `ν` on the sets in
`countablePartition γ n`. Used to define its limit `ProbabilityTheory.Kernel.density`, which is
a density for those kernels for all measurable sets. -/
noncomputable
def densityProcess (κ : Kernel α (γ × β)) (ν : Kernel α γ) (n : ℕ) (a : α) (x : γ) (s : Set β) :
    ℝ :=
  (κ a (countablePartitionSet n x ×ˢ s) / ν a (countablePartitionSet n x)).toReal

lemma densityProcess_def (κ : Kernel α (γ × β)) (ν : Kernel α γ) (n : ℕ) (a : α) (s : Set β) :
    (fun t ↦ densityProcess κ ν n a t s)
      = fun t ↦ (κ a (countablePartitionSet n t ×ˢ s) / ν a (countablePartitionSet n t)).toReal :=
  rfl

lemma measurable_densityProcess_countableFiltration_aux (κ : Kernel α (γ × β)) (ν : Kernel α γ)
    (n : ℕ) {s : Set β} (hs : MeasurableSet s) :
    Measurable[mα.prod (countableFiltration γ n)] (fun (p : α × γ) ↦
      κ p.1 (countablePartitionSet n p.2 ×ˢ s) / ν p.1 (countablePartitionSet n p.2)) := by
  change Measurable[mα.prod (countableFiltration γ n)]
      ((fun (p : α × countablePartition γ n) ↦ κ p.1 (↑p.2 ×ˢ s) / ν p.1 p.2)
        ∘ (fun (p : α × γ) ↦ (p.1, ⟨countablePartitionSet n p.2, countablePartitionSet_mem n p.2⟩)))
  have h1 : @Measurable _ _ (mα.prod ⊤) _
      (fun p : α × countablePartition γ n ↦ κ p.1 (↑p.2 ×ˢ s) / ν p.1 p.2) := by
    refine Measurable.div ?_ ?_
    · refine measurable_from_prod_countable (fun t ↦ ?_)
      exact Kernel.measurable_coe _ ((measurableSet_countablePartition _ t.prop).prod hs)
    · refine measurable_from_prod_countable ?_
      rintro ⟨t, ht⟩
      exact Kernel.measurable_coe _ (measurableSet_countablePartition _ ht)
  refine h1.comp (measurable_fst.prod_mk ?_)
  change @Measurable (α × γ) (countablePartition γ n) (mα.prod (countableFiltration γ n)) ⊤
    ((fun c ↦ ⟨countablePartitionSet n c, countablePartitionSet_mem n c⟩) ∘ (fun p : α × γ ↦ p.2))
  exact (measurable_countablePartitionSet_subtype n ⊤).comp measurable_snd

lemma measurable_densityProcess_aux (κ : Kernel α (γ × β)) (ν : Kernel α γ) (n : ℕ)
    {s : Set β} (hs : MeasurableSet s) :
    Measurable (fun (p : α × γ) ↦
      κ p.1 (countablePartitionSet n p.2 ×ˢ s) / ν p.1 (countablePartitionSet n p.2)) := by
  refine Measurable.mono (measurable_densityProcess_countableFiltration_aux κ ν n hs) ?_ le_rfl
  exact sup_le_sup le_rfl (comap_mono ((countableFiltration γ).le _))

lemma measurable_densityProcess (κ : Kernel α (γ × β)) (ν : Kernel α γ) (n : ℕ)
    {s : Set β} (hs : MeasurableSet s) :
    Measurable (fun (p : α × γ) ↦ densityProcess κ ν n p.1 p.2 s) :=
  (measurable_densityProcess_aux κ ν n hs).ennreal_toReal

-- The following two lemmas also work without the `( :)`, but they are slow.
lemma measurable_densityProcess_left (κ : Kernel α (γ × β)) (ν : Kernel α γ) (n : ℕ)
    (x : γ) {s : Set β} (hs : MeasurableSet s) :
    Measurable (fun a ↦ densityProcess κ ν n a x s) :=
  ((measurable_densityProcess κ ν n hs).comp (measurable_id.prod_mk measurable_const):)

lemma measurable_densityProcess_right (κ : Kernel α (γ × β)) (ν : Kernel α γ) (n : ℕ)
    {s : Set β} (a : α) (hs : MeasurableSet s) :
    Measurable (fun x ↦ densityProcess κ ν n a x s) :=
  ((measurable_densityProcess κ ν n hs).comp (measurable_const.prod_mk measurable_id):)

lemma measurable_countableFiltration_densityProcess (κ : Kernel α (γ × β)) (ν : Kernel α γ) (n : ℕ)
    (a : α) {s : Set β} (hs : MeasurableSet s) :
    Measurable[countableFiltration γ n] (fun x ↦ densityProcess κ ν n a x s) := by
  refine @Measurable.ennreal_toReal _ (countableFiltration γ n) _ ?_
  exact (measurable_densityProcess_countableFiltration_aux κ ν n hs).comp measurable_prod_mk_left

lemma stronglyMeasurable_countableFiltration_densityProcess (κ : Kernel α (γ × β)) (ν : Kernel α γ)
    (n : ℕ) (a : α) {s : Set β} (hs : MeasurableSet s) :
    StronglyMeasurable[countableFiltration γ n] (fun x ↦ densityProcess κ ν n a x s) :=
  (measurable_countableFiltration_densityProcess κ ν n a hs).stronglyMeasurable

lemma adapted_densityProcess (κ : Kernel α (γ × β)) (ν : Kernel α γ) (a : α)
    {s : Set β} (hs : MeasurableSet s) :
    Adapted (countableFiltration γ) (fun n x ↦ densityProcess κ ν n a x s) :=
  fun n ↦ stronglyMeasurable_countableFiltration_densityProcess κ ν n a hs

lemma densityProcess_nonneg (κ : Kernel α (γ × β)) (ν : Kernel α γ) (n : ℕ)
    (a : α) (x : γ) (s : Set β) :
    0 ≤ densityProcess κ ν n a x s :=
  ENNReal.toReal_nonneg

lemma meas_countablePartitionSet_le_of_fst_le (hκν : fst κ ≤ ν) (n : ℕ) (a : α) (x : γ)
    (s : Set β) :
    κ a (countablePartitionSet n x ×ˢ s) ≤ ν a (countablePartitionSet n x) := by
  calc κ a (countablePartitionSet n x ×ˢ s)
    ≤ fst κ a (countablePartitionSet n x) := by
        rw [fst_apply' _ _ (measurableSet_countablePartitionSet _ _)]
        refine measure_mono (fun x ↦ ?_)
        simp only [mem_prod, mem_setOf_eq, and_imp]
        exact fun h _ ↦ h
  _ ≤ ν a (countablePartitionSet n x) := hκν a _

lemma densityProcess_le_one (hκν : fst κ ≤ ν) (n : ℕ) (a : α) (x : γ) (s : Set β) :
    densityProcess κ ν n a x s ≤ 1 := by
  refine ENNReal.toReal_le_of_le_ofReal zero_le_one (ENNReal.div_le_of_le_mul ?_)
  rw [ENNReal.ofReal_one, one_mul]
  exact meas_countablePartitionSet_le_of_fst_le hκν n a x s

lemma eLpNorm_densityProcess_le (hκν : fst κ ≤ ν) (n : ℕ) (a : α) (s : Set β) :
    eLpNorm (fun x ↦ densityProcess κ ν n a x s) 1 (ν a) ≤ ν a univ := by
  refine (eLpNorm_le_of_ae_bound (C := 1) (ae_of_all _ (fun x ↦ ?_))).trans ?_
  · simp only [Real.norm_eq_abs, abs_of_nonneg (densityProcess_nonneg κ ν n a x s),
      densityProcess_le_one hκν n a x s]
  · simp

lemma integrable_densityProcess (hκν : fst κ ≤ ν) [IsFiniteKernel ν] (n : ℕ)
    (a : α) {s : Set β} (hs : MeasurableSet s) :
    Integrable (fun x ↦ densityProcess κ ν n a x s) (ν a) := by
  rw [← memℒp_one_iff_integrable]
  refine ⟨Measurable.aestronglyMeasurable ?_, ?_⟩
  · exact measurable_densityProcess_right κ ν n a hs
  · exact (eLpNorm_densityProcess_le hκν n a s).trans_lt (measure_lt_top _ _)

lemma setIntegral_densityProcess_of_mem (hκν : fst κ ≤ ν) [hν : IsFiniteKernel ν]
    (n : ℕ) (a : α) {s : Set β} (hs : MeasurableSet s) {u : Set γ}
    (hu : u ∈ countablePartition γ n) :
    ∫ x in u, densityProcess κ ν n a x s ∂(ν a) = (κ a (u ×ˢ s)).toReal := by
  have : IsFiniteKernel κ := isFiniteKernel_of_isFiniteKernel_fst (h := isFiniteKernel_of_le hκν)
  have hu_meas : MeasurableSet u := measurableSet_countablePartition n hu
  simp_rw [densityProcess]
  rw [integral_toReal]
  rotate_left
  · refine Measurable.aemeasurable ?_
    change Measurable ((fun (p : α × _) ↦ κ p.1 (countablePartitionSet n p.2 ×ˢ s)
      / ν p.1 (countablePartitionSet n p.2)) ∘ (fun x ↦ (a, x)))
    exact (measurable_densityProcess_aux κ ν n hs).comp measurable_prod_mk_left
  · refine ae_of_all _ (fun x ↦ ?_)
    by_cases h0 : ν a (countablePartitionSet n x) = 0
    · suffices κ a (countablePartitionSet n x ×ˢ s) = 0 by simp [h0, this]
      have h0' : fst κ a (countablePartitionSet n x) = 0 :=
        le_antisymm ((hκν a _).trans h0.le) zero_le'
      rw [fst_apply' _ _ (measurableSet_countablePartitionSet _ _)] at h0'
      refine measure_mono_null (fun x ↦ ?_) h0'
      simp only [mem_prod, mem_setOf_eq, and_imp]
      exact fun h _ ↦ h
    · exact ENNReal.div_lt_top (measure_ne_top _ _) h0
  congr
  have : ∫⁻ x in u, κ a (countablePartitionSet n x ×ˢ s) / ν a (countablePartitionSet n x) ∂(ν a)
      = ∫⁻ _ in u, κ a (u ×ˢ s) / ν a u ∂(ν a) := by
    refine setLIntegral_congr_fun hu_meas (ae_of_all _ (fun t ht ↦ ?_))
    rw [countablePartitionSet_of_mem hu ht]
  rw [this]
  simp only [MeasureTheory.lintegral_const, MeasurableSet.univ, Measure.restrict_apply, univ_inter]
  by_cases h0 : ν a u = 0
  · simp only [h0, mul_zero]
    have h0' : fst κ a u = 0 := le_antisymm ((hκν a _).trans h0.le) zero_le'
    rw [fst_apply' _ _ hu_meas] at h0'
    refine (measure_mono_null ?_ h0').symm
    intro p
    simp only [mem_prod, mem_setOf_eq, and_imp]
    exact fun h _ ↦ h
  rw [div_eq_mul_inv, mul_assoc, ENNReal.inv_mul_cancel h0, mul_one]
  exact measure_ne_top _ _

open scoped Function in -- required for scoped `on` notation
lemma setIntegral_densityProcess (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    (n : ℕ) (a : α) {s : Set β} (hs : MeasurableSet s) {A : Set γ}
    (hA : MeasurableSet[countableFiltration γ n] A) :
    ∫ x in A, densityProcess κ ν n a x s ∂(ν a) = (κ a (A ×ˢ s)).toReal := by
  have : IsFiniteKernel κ := isFiniteKernel_of_isFiniteKernel_fst (h := isFiniteKernel_of_le hκν)
  obtain ⟨S, hS_subset, rfl⟩ := (measurableSet_generateFrom_countablePartition_iff _ _).mp hA
  simp_rw [sUnion_eq_iUnion]
  have h_disj : Pairwise (Disjoint on fun i : S ↦ (i : Set γ)) := by
    intro u v huv
    #adaptation_note /-- nightly-2024-03-16
    Previously `Function.onFun` unfolded in the following `simp only`,
    but now needs a `rw`.
    This may be a bug: a no import minimization may be required.
    simp only [Finset.coe_sort_coe, Function.onFun] -/
    rw [Function.onFun]
    refine disjoint_countablePartition (hS_subset (by simp)) (hS_subset (by simp)) ?_
    rwa [ne_eq, ← Subtype.ext_iff]
  rw [integral_iUnion, iUnion_prod_const, measure_iUnion,
      ENNReal.tsum_toReal_eq (fun _ ↦ measure_ne_top _ _)]
  · congr with u
    rw [setIntegral_densityProcess_of_mem hκν _ _ hs (hS_subset (by simp))]
  · intro u v huv
    simp only [Finset.coe_sort_coe, Set.disjoint_prod, disjoint_self, bot_eq_empty]
    exact Or.inl (h_disj huv)
  · exact fun _ ↦ (measurableSet_countablePartition n (hS_subset (by simp))).prod hs
  · exact fun _ ↦ measurableSet_countablePartition n (hS_subset (by simp))
  · exact h_disj
  · exact (integrable_densityProcess hκν _ _ hs).integrableOn

lemma integral_densityProcess (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    (n : ℕ) (a : α) {s : Set β} (hs : MeasurableSet s) :
    ∫ x, densityProcess κ ν n a x s ∂(ν a) = (κ a (univ ×ˢ s)).toReal := by
  rw [← setIntegral_univ, setIntegral_densityProcess hκν _ _ hs MeasurableSet.univ]

lemma setIntegral_densityProcess_of_le (hκν : fst κ ≤ ν)
    [IsFiniteKernel ν] {n m : ℕ} (hnm : n ≤ m) (a : α) {s : Set β} (hs : MeasurableSet s)
    {A : Set γ} (hA : MeasurableSet[countableFiltration γ n] A) :
    ∫ x in A, densityProcess κ ν m a x s ∂(ν a) = (κ a (A ×ˢ s)).toReal :=
  setIntegral_densityProcess hκν m a hs ((countableFiltration γ).mono hnm A hA)

lemma condExp_densityProcess (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    {i j : ℕ} (hij : i ≤ j) (a : α) {s : Set β} (hs : MeasurableSet s) :
    (ν a)[fun x ↦ densityProcess κ ν j a x s | countableFiltration γ i]
      =ᵐ[ν a] fun x ↦ densityProcess κ ν i a x s := by
  refine (ae_eq_condExp_of_forall_setIntegral_eq ?_ ?_ ?_ ?_ ?_).symm
  · exact integrable_densityProcess hκν j a hs
  · exact fun _ _ _ ↦ (integrable_densityProcess hκν _ _ hs).integrableOn
  · intro x hx _
    rw [setIntegral_densityProcess hκν i a hs hx,
      setIntegral_densityProcess_of_le hκν hij a hs hx]
  · exact StronglyMeasurable.aestronglyMeasurable
      (stronglyMeasurable_countableFiltration_densityProcess κ ν i a hs)

@[deprecated (since := "2025-01-21")] alias condexp_densityProcess := condExp_densityProcess

lemma martingale_densityProcess (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    (a : α) {s : Set β} (hs : MeasurableSet s) :
    Martingale (fun n x ↦ densityProcess κ ν n a x s) (countableFiltration γ) (ν a) :=
  ⟨adapted_densityProcess κ ν a hs, fun _ _ h ↦ condExp_densityProcess hκν h a hs⟩

lemma densityProcess_mono_set (hκν : fst κ ≤ ν) (n : ℕ) (a : α) (x : γ)
    {s s' : Set β} (h : s ⊆ s') :
    densityProcess κ ν n a x s ≤ densityProcess κ ν n a x s' := by
  unfold densityProcess
  obtain h₀ | h₀ := eq_or_ne (ν a (countablePartitionSet n x)) 0
  · simp [h₀]
  · gcongr
    simp only [ne_eq, ENNReal.div_eq_top, h₀, and_false, false_or, not_and, not_not]
    exact eq_top_mono (meas_countablePartitionSet_le_of_fst_le hκν n a x s')

lemma densityProcess_mono_kernel_left {κ' : Kernel α (γ × β)} (hκκ' : κ ≤ κ')
    (hκ'ν : fst κ' ≤ ν) (n : ℕ) (a : α) (x : γ) (s : Set β) :
    densityProcess κ ν n a x s ≤ densityProcess κ' ν n a x s := by
  unfold densityProcess
  by_cases h0 : ν a (countablePartitionSet n x) = 0
  · rw [h0, ENNReal.toReal_div, ENNReal.toReal_div]
    simp
  have h_le : κ' a (countablePartitionSet n x ×ˢ s) ≤ ν a (countablePartitionSet n x) :=
    meas_countablePartitionSet_le_of_fst_le hκ'ν n a x s
  gcongr
  · simp only [ne_eq, ENNReal.div_eq_top, h0, and_false, false_or, not_and, not_not]
    exact fun h_top ↦ eq_top_mono h_le h_top
  · apply hκκ'

lemma densityProcess_antitone_kernel_right {ν' : Kernel α γ}
    (hνν' : ν ≤ ν') (hκν : fst κ ≤ ν) (n : ℕ) (a : α) (x : γ) (s : Set β) :
    densityProcess κ ν' n a x s ≤ densityProcess κ ν n a x s := by
  unfold densityProcess
  have h_le : κ a (countablePartitionSet n x ×ˢ s) ≤ ν a (countablePartitionSet n x) :=
    meas_countablePartitionSet_le_of_fst_le hκν n a x s
  by_cases h0 : ν a (countablePartitionSet n x) = 0
  · simp [le_antisymm (h_le.trans h0.le) zero_le', h0]
  gcongr
  · simp only [ne_eq, ENNReal.div_eq_top, h0, and_false, false_or, not_and, not_not]
    exact fun h_top ↦ eq_top_mono h_le h_top
  · apply hνν'

@[simp]
lemma densityProcess_empty (κ : Kernel α (γ × β)) (ν : Kernel α γ) (n : ℕ) (a : α) (x : γ) :
    densityProcess κ ν n a x ∅ = 0 := by
  simp [densityProcess]

lemma tendsto_densityProcess_atTop_empty_of_antitone (κ : Kernel α (γ × β)) (ν : Kernel α γ)
    [IsFiniteKernel κ] (n : ℕ) (a : α) (x : γ)
    (seq : ℕ → Set β) (hseq : Antitone seq) (hseq_iInter : ⋂ i, seq i = ∅)
    (hseq_meas : ∀ m, MeasurableSet (seq m)) :
    Tendsto (fun m ↦ densityProcess κ ν n a x (seq m)) atTop
      (𝓝 (densityProcess κ ν n a x ∅)) := by
  simp_rw [densityProcess]
  by_cases h0 : ν a (countablePartitionSet n x) = 0
  · simp_rw [h0, ENNReal.toReal_div]
    simp
  refine (ENNReal.tendsto_toReal ?_).comp ?_
  · rw [ne_eq, ENNReal.div_eq_top]
    push_neg
    simp
  refine ENNReal.Tendsto.div_const ?_ (.inr h0)
  have : Tendsto (fun m ↦ κ a (countablePartitionSet n x ×ˢ seq m)) atTop
      (𝓝 ((κ a) (⋂ n_1, countablePartitionSet n x ×ˢ seq n_1))) := by
    apply tendsto_measure_iInter_atTop
    · measurability
    · exact fun _ _ h ↦ prod_mono_right <| hseq h
    · exact ⟨0, measure_ne_top _ _⟩
  simpa only [← prod_iInter, hseq_iInter] using this

lemma tendsto_densityProcess_atTop_of_antitone (κ : Kernel α (γ × β)) (ν : Kernel α γ)
    [IsFiniteKernel κ] (n : ℕ) (a : α) (x : γ)
    (seq : ℕ → Set β) (hseq : Antitone seq) (hseq_iInter : ⋂ i, seq i = ∅)
    (hseq_meas : ∀ m, MeasurableSet (seq m)) :
    Tendsto (fun m ↦ densityProcess κ ν n a x (seq m)) atTop (𝓝 0) := by
  rw [← densityProcess_empty κ ν n a x]
  exact tendsto_densityProcess_atTop_empty_of_antitone κ ν n a x seq hseq hseq_iInter hseq_meas

lemma tendsto_densityProcess_limitProcess (hκν : fst κ ≤ ν)
    [IsFiniteKernel ν] (a : α) {s : Set β} (hs : MeasurableSet s) :
    ∀ᵐ x ∂(ν a), Tendsto (fun n ↦ densityProcess κ ν n a x s) atTop
      (𝓝 ((countableFiltration γ).limitProcess
      (fun n x ↦ densityProcess κ ν n a x s) (ν a) x)) := by
  refine Submartingale.ae_tendsto_limitProcess (martingale_densityProcess hκν a hs).submartingale
    (R := (ν a univ).toNNReal) (fun n ↦ ?_)
  refine (eLpNorm_densityProcess_le hκν n a s).trans_eq ?_
  rw [ENNReal.coe_toNNReal]
  exact measure_ne_top _ _

lemma memL1_limitProcess_densityProcess (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    (a : α) {s : Set β} (hs : MeasurableSet s) :
    Memℒp ((countableFiltration γ).limitProcess
      (fun n x ↦ densityProcess κ ν n a x s) (ν a)) 1 (ν a) := by
  refine Submartingale.memℒp_limitProcess (martingale_densityProcess hκν a hs).submartingale
    (R := (ν a univ).toNNReal) (fun n ↦ ?_)
  refine (eLpNorm_densityProcess_le hκν n a s).trans_eq ?_
  rw [ENNReal.coe_toNNReal]
  exact measure_ne_top _ _

lemma tendsto_eLpNorm_one_densityProcess_limitProcess (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    (a : α) {s : Set β} (hs : MeasurableSet s) :
    Tendsto (fun n ↦ eLpNorm ((fun x ↦ densityProcess κ ν n a x s)
      - (countableFiltration γ).limitProcess (fun n x ↦ densityProcess κ ν n a x s) (ν a))
      1 (ν a)) atTop (𝓝 0) := by
  refine Submartingale.tendsto_eLpNorm_one_limitProcess ?_ ?_
  · exact (martingale_densityProcess hκν a hs).submartingale
  · refine uniformIntegrable_of le_rfl ENNReal.one_ne_top ?_ ?_
    · exact fun n ↦ (measurable_densityProcess_right κ ν n a hs).aestronglyMeasurable
    · refine fun ε _ ↦ ⟨2, fun n ↦ le_of_eq_of_le ?_ (?_ : 0 ≤ ENNReal.ofReal ε)⟩
      · suffices {x | 2 ≤ ‖densityProcess κ ν n a x s‖₊} = ∅ by simp [this]
        ext x
        simp only [mem_setOf_eq, mem_empty_iff_false, iff_false, not_le]
        refine (?_ : _ ≤ (1 : ℝ≥0)).trans_lt one_lt_two
        rw [Real.nnnorm_of_nonneg (densityProcess_nonneg _ _ _ _ _ _)]
        exact mod_cast (densityProcess_le_one hκν _ _ _ _)
      · simp

lemma tendsto_eLpNorm_one_restrict_densityProcess_limitProcess [IsFiniteKernel ν]
    (hκν : fst κ ≤ ν) (a : α) {s : Set β} (hs : MeasurableSet s) (A : Set γ) :
    Tendsto (fun n ↦ eLpNorm ((fun x ↦ densityProcess κ ν n a x s)
      - (countableFiltration γ).limitProcess (fun n x ↦ densityProcess κ ν n a x s) (ν a))
      1 ((ν a).restrict A)) atTop (𝓝 0) :=
  tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds
    (tendsto_eLpNorm_one_densityProcess_limitProcess hκν a hs) (fun _ ↦ zero_le')
    (fun _ ↦ eLpNorm_restrict_le _ _ _ _)

end DensityProcess

section Density

/-- Density of the kernel `κ` with respect to `ν`. This is a function `α → γ → Set β → ℝ` which
is measurable on `α × γ` for all measurable sets `s : Set β` and satisfies that
`∫ x in A, density κ ν a x s ∂(ν a) = (κ a (A ×ˢ s)).toReal` for all measurable `A : Set γ`. -/
noncomputable
def density (κ : Kernel α (γ × β)) (ν : Kernel α γ) (a : α) (x : γ) (s : Set β) : ℝ :=
  limsup (fun n ↦ densityProcess κ ν n a x s) atTop

lemma density_ae_eq_limitProcess (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    (a : α) {s : Set β} (hs : MeasurableSet s) :
    (fun x ↦ density κ ν a x s)
      =ᵐ[ν a] (countableFiltration γ).limitProcess
        (fun n x ↦ densityProcess κ ν n a x s) (ν a) := by
  filter_upwards [tendsto_densityProcess_limitProcess hκν a hs] with t ht using ht.limsup_eq

lemma tendsto_m_density (hκν : fst κ ≤ ν) (a : α) [IsFiniteKernel ν]
    {s : Set β} (hs : MeasurableSet s) :
    ∀ᵐ x ∂(ν a),
      Tendsto (fun n ↦ densityProcess κ ν n a x s) atTop (𝓝 (density κ ν a x s)) := by
  filter_upwards [tendsto_densityProcess_limitProcess hκν a hs, density_ae_eq_limitProcess hκν a hs]
    with t h1 h2 using h2 ▸ h1

lemma measurable_density (κ : Kernel α (γ × β)) (ν : Kernel α γ)
    {s : Set β} (hs : MeasurableSet s) :
    Measurable (fun (p : α × γ) ↦ density κ ν p.1 p.2 s) :=
  .limsup (fun n ↦ measurable_densityProcess κ ν n hs)

lemma measurable_density_left (κ : Kernel α (γ × β)) (ν : Kernel α γ) (x : γ)
    {s : Set β} (hs : MeasurableSet s) :
    Measurable (fun a ↦ density κ ν a x s) := by
  change Measurable ((fun (p : α × γ) ↦ density κ ν p.1 p.2 s) ∘ (fun a ↦ (a, x)))
  exact (measurable_density κ ν hs).comp measurable_prod_mk_right

lemma measurable_density_right (κ : Kernel α (γ × β)) (ν : Kernel α γ)
    {s : Set β} (hs : MeasurableSet s) (a : α) :
    Measurable (fun x ↦ density κ ν a x s) := by
  change Measurable ((fun (p : α × γ) ↦ density κ ν p.1 p.2 s) ∘ (fun x ↦ (a, x)))
  exact (measurable_density κ ν hs).comp measurable_prod_mk_left

lemma density_mono_set (hκν : fst κ ≤ ν) (a : α) (x : γ) {s s' : Set β} (h : s ⊆ s') :
    density κ ν a x s ≤ density κ ν a x s' := by
  refine limsup_le_limsup ?_ ?_ ?_
  · exact Eventually.of_forall (fun n ↦ densityProcess_mono_set hκν n a x h)
  · exact isCoboundedUnder_le_of_le atTop (fun i ↦ densityProcess_nonneg _ _ _ _ _ _)
  · exact isBoundedUnder_of ⟨1, fun n ↦ densityProcess_le_one hκν _ _ _ _⟩

lemma density_nonneg (hκν : fst κ ≤ ν) (a : α) (x : γ) (s : Set β) :
    0 ≤ density κ ν a x s := by
  refine le_limsup_of_frequently_le ?_ ?_
  · exact Frequently.of_forall (fun n ↦ densityProcess_nonneg _ _ _ _ _ _)
  · exact isBoundedUnder_of ⟨1, fun n ↦ densityProcess_le_one hκν _ _ _ _⟩

lemma density_le_one (hκν : fst κ ≤ ν) (a : α) (x : γ) (s : Set β) :
    density κ ν a x s ≤ 1 := by
  refine limsup_le_of_le ?_ ?_
  · exact isCoboundedUnder_le_of_le atTop (fun i ↦ densityProcess_nonneg _ _ _ _ _ _)
  · exact Eventually.of_forall (fun n ↦ densityProcess_le_one hκν _ _ _ _)

section Integral

lemma eLpNorm_density_le (hκν : fst κ ≤ ν) (a : α) (s : Set β) :
    eLpNorm (fun x ↦ density κ ν a x s) 1 (ν a) ≤ ν a univ := by
  refine (eLpNorm_le_of_ae_bound (C := 1) (ae_of_all _ (fun t ↦ ?_))).trans ?_
  · simp only [Real.norm_eq_abs, abs_of_nonneg (density_nonneg hκν a t s),
      density_le_one hκν a t s]
  · simp

lemma integrable_density (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    (a : α) {s : Set β} (hs : MeasurableSet s) :
    Integrable (fun x ↦ density κ ν a x s) (ν a) := by
  rw [← memℒp_one_iff_integrable]
  refine ⟨Measurable.aestronglyMeasurable ?_, ?_⟩
  · exact measurable_density_right κ ν hs a
  · exact (eLpNorm_density_le hκν a s).trans_lt (measure_lt_top _ _)

lemma tendsto_setIntegral_densityProcess (hκν : fst κ ≤ ν)
    [IsFiniteKernel ν] (a : α) {s : Set β} (hs : MeasurableSet s) (A : Set γ) :
    Tendsto (fun i ↦ ∫ x in A, densityProcess κ ν i a x s ∂(ν a)) atTop
      (𝓝 (∫ x in A, density κ ν a x s ∂(ν a))) := by
  refine tendsto_setIntegral_of_L1' (μ := ν a) (fun x ↦ density κ ν a x s)
    (integrable_density hκν a hs) (F := fun i x ↦ densityProcess κ ν i a x s) (l := atTop)
    (Eventually.of_forall (fun n ↦ integrable_densityProcess hκν _ _ hs)) ?_ A
  refine (tendsto_congr fun n ↦ ?_).mp (tendsto_eLpNorm_one_densityProcess_limitProcess hκν a hs)
  refine eLpNorm_congr_ae ?_
  exact EventuallyEq.rfl.sub (density_ae_eq_limitProcess hκν a hs).symm

/-- Auxiliary lemma for `setIntegral_density`. -/
lemma setIntegral_density_of_measurableSet (hκν : fst κ ≤ ν)
    [IsFiniteKernel ν] (n : ℕ) (a : α) {s : Set β} (hs : MeasurableSet s) {A : Set γ}
    (hA : MeasurableSet[countableFiltration γ n] A) :
    ∫ x in A, density κ ν a x s ∂(ν a) = (κ a (A ×ˢ s)).toReal := by
  suffices ∫ x in A, density κ ν a x s ∂(ν a) = ∫ x in A, densityProcess κ ν n a x s ∂(ν a) by
    exact this ▸ setIntegral_densityProcess hκν _ _ hs hA
  suffices ∫ x in A, density κ ν a x s ∂(ν a)
      = limsup (fun i ↦ ∫ x in A, densityProcess κ ν i a x s ∂(ν a)) atTop by
    rw [this, ← limsup_const (α := ℕ) (f := atTop) (∫ x in A, densityProcess κ ν n a x s ∂(ν a)),
      limsup_congr]
    simp only [eventually_atTop]
    refine ⟨n, fun m hnm ↦ ?_⟩
    rw [setIntegral_densityProcess_of_le hκν hnm _ hs hA,
      setIntegral_densityProcess hκν _ _ hs hA]
  -- use L1 convergence
  have h := tendsto_setIntegral_densityProcess hκν a hs A
  rw [h.limsup_eq]

lemma integral_density (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    (a : α) {s : Set β} (hs : MeasurableSet s) :
    ∫ x, density κ ν a x s ∂(ν a) = (κ a (univ ×ˢ s)).toReal := by
  rw [← setIntegral_univ, setIntegral_density_of_measurableSet hκν 0 a hs MeasurableSet.univ]

lemma setIntegral_density (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    (a : α) {s : Set β} (hs : MeasurableSet s) {A : Set γ} (hA : MeasurableSet A) :
    ∫ x in A, density κ ν a x s ∂(ν a) = (κ a (A ×ˢ s)).toReal := by
  have : IsFiniteKernel κ := isFiniteKernel_of_isFiniteKernel_fst (h := isFiniteKernel_of_le hκν)
  have hgen : ‹MeasurableSpace γ› =
      .generateFrom {s | ∃ n, MeasurableSet[countableFiltration γ n] s} := by
    rw [setOf_exists, generateFrom_iUnion_measurableSet (countableFiltration γ),
      iSup_countableFiltration]
  have hpi : IsPiSystem {s | ∃ n, MeasurableSet[countableFiltration γ n] s} := by
    rw [setOf_exists]
    exact isPiSystem_iUnion_of_monotone _
      (fun n ↦ @isPiSystem_measurableSet _ (countableFiltration γ n))
      fun _ _ ↦ (countableFiltration γ).mono
  induction A, hA using induction_on_inter hgen hpi with
  | empty => simp
  | basic s hs =>
    rcases hs with ⟨n, hn⟩
    exact setIntegral_density_of_measurableSet hκν n a hs hn
  | compl A hA hA_eq =>
    have h := integral_add_compl hA (integrable_density hκν a hs)
    rw [hA_eq, integral_density hκν a hs] at h
    have : Aᶜ ×ˢ s = univ ×ˢ s \ A ×ˢ s := by
      rw [prod_diff_prod, compl_eq_univ_diff]
      simp
    rw [this, measure_diff (by intro; simp) (hA.prod hs).nullMeasurableSet (measure_ne_top (κ a) _),
      ENNReal.toReal_sub_of_le (measure_mono (by intro x; simp)) (measure_ne_top _ _)]
    rw [eq_tsub_iff_add_eq_of_le, add_comm]
    · exact h
    · gcongr <;> simp
  | iUnion f hf_disj hf h_eq =>
    rw [integral_iUnion hf hf_disj (integrable_density hκν _ hs).integrableOn]
    simp_rw [h_eq]
    rw [← ENNReal.tsum_toReal_eq (fun _ ↦ measure_ne_top _ _)]
    congr
    rw [iUnion_prod_const, measure_iUnion]
    · exact hf_disj.mono fun _ _ h ↦ h.set_prod_left _ _
    · exact fun i ↦ (hf i).prod hs

lemma setLIntegral_density (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    (a : α) {s : Set β} (hs : MeasurableSet s) {A : Set γ} (hA : MeasurableSet A) :
    ∫⁻ x in A, ENNReal.ofReal (density κ ν a x s) ∂(ν a) = κ a (A ×ˢ s) := by
  have : IsFiniteKernel κ := isFiniteKernel_of_isFiniteKernel_fst (h := isFiniteKernel_of_le hκν)
  rw [← ofReal_integral_eq_lintegral_ofReal]
  · rw [setIntegral_density hκν a hs hA,
      ENNReal.ofReal_toReal (measure_ne_top _ _)]
  · exact (integrable_density hκν a hs).restrict
  · exact ae_of_all _ (fun _ ↦ density_nonneg hκν _ _ _)

lemma lintegral_density (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    (a : α) {s : Set β} (hs : MeasurableSet s) :
    ∫⁻ x, ENNReal.ofReal (density κ ν a x s) ∂(ν a) = κ a (univ ×ˢ s) := by
  rw [← setLIntegral_univ]
  exact setLIntegral_density hκν a hs MeasurableSet.univ

end Integral

lemma tendsto_integral_density_of_monotone (hκν : fst κ ≤ ν) [IsFiniteKernel ν]
    (a : α) (seq : ℕ → Set β) (hseq : Monotone seq) (hseq_iUnion : ⋃ i, seq i = univ)
    (hseq_meas : ∀ m, MeasurableSet (seq m)) :
    Tendsto (fun m ↦ ∫ x, density κ ν a x (seq m) ∂(ν a)) atTop (𝓝 (κ a univ).toReal) := by
  have : IsFiniteKernel κ := isFiniteKernel_of_isFiniteKernel_fst (h := isFiniteKernel_of_le hκν)
  simp_rw [integral_density hκν a (hseq_meas _)]
  have h_cont := ENNReal.continuousOn_toReal.continuousAt (x := κ a univ) ?_
  swap
  · rw [mem_nhds_iff]
    refine ⟨Iio (κ a univ + 1), fun x hx ↦ ne_top_of_lt (?_ : x < κ a univ + 1), isOpen_Iio, ?_⟩
    · simpa using hx
    · simp only [mem_Iio]
      exact ENNReal.lt_add_right (measure_ne_top _ _) one_ne_zero
  refine h_cont.tendsto.comp ?_
  convert tendsto_measure_iUnion_atTop (monotone_const.set_prod hseq)
  rw [← prod_iUnion, hseq_iUnion, univ_prod_univ]

lemma tendsto_integral_density_of_antitone (hκν : fst κ ≤ ν) [IsFiniteKernel ν] (a : α)
    (seq : ℕ → Set β) (hseq : Antitone seq) (hseq_iInter : ⋂ i, seq i = ∅)
    (hseq_meas : ∀ m, MeasurableSet (seq m)) :
    Tendsto (fun m ↦ ∫ x, density κ ν a x (seq m) ∂(ν a)) atTop (𝓝 0) := by
  have : IsFiniteKernel κ := isFiniteKernel_of_isFiniteKernel_fst (h := isFiniteKernel_of_le hκν)
  simp_rw [integral_density hκν a (hseq_meas _)]
  rw [← ENNReal.zero_toReal]
  have h_cont := ENNReal.continuousAt_toReal ENNReal.zero_ne_top
  refine h_cont.tendsto.comp ?_
  have h : Tendsto (fun m ↦ κ a (univ ×ˢ seq m)) atTop
      (𝓝 ((κ a) (⋂ n, (fun m ↦ univ ×ˢ seq m) n))) := by
    apply tendsto_measure_iInter_atTop
    · measurability
    · exact antitone_const.set_prod hseq
    · exact ⟨0, measure_ne_top _ _⟩
  simpa [← prod_iInter, hseq_iInter] using h

lemma tendsto_density_atTop_ae_of_antitone (hκν : fst κ ≤ ν) [IsFiniteKernel ν] (a : α)
    (seq : ℕ → Set β) (hseq : Antitone seq) (hseq_iInter : ⋂ i, seq i = ∅)
    (hseq_meas : ∀ m, MeasurableSet (seq m)) :
    ∀ᵐ x ∂(ν a), Tendsto (fun m ↦ density κ ν a x (seq m)) atTop (𝓝 0) := by
  refine tendsto_of_integral_tendsto_of_antitone ?_ (integrable_const _) ?_ ?_ ?_
  · exact fun m ↦ integrable_density hκν _ (hseq_meas m)
  · rw [integral_zero]
    exact tendsto_integral_density_of_antitone hκν a seq hseq hseq_iInter hseq_meas
  · exact ae_of_all _ (fun c n m hnm ↦ density_mono_set hκν a c (hseq hnm))
  · exact ae_of_all _ (fun x m ↦ density_nonneg hκν a x (seq m))

section UnivFst

/-! We specialize to `ν = fst κ`, for which `density κ (fst κ) a t univ = 1` almost everywhere. -/

lemma densityProcess_fst_univ [IsFiniteKernel κ] (n : ℕ) (a : α) (x : γ) :
    densityProcess κ (fst κ) n a x univ
      = if fst κ a (countablePartitionSet n x) = 0 then 0 else 1 := by
  rw [densityProcess]
  split_ifs with h
  · simp only [h]
    by_cases h' : κ a (countablePartitionSet n x ×ˢ univ) = 0
    · simp [h']
    · rw [ENNReal.div_zero h']
      simp
  · rw [fst_apply' _ _ (measurableSet_countablePartitionSet _ _)]
    have : countablePartitionSet n x ×ˢ univ = {p : γ × β | p.1 ∈ countablePartitionSet n x} := by
      ext x
      simp
    rw [this, ENNReal.div_self]
    · simp
    · rwa [fst_apply' _ _ (measurableSet_countablePartitionSet _ _)] at h
    · exact measure_ne_top _ _

lemma densityProcess_fst_univ_ae (κ : Kernel α (γ × β)) [IsFiniteKernel κ] (n : ℕ) (a : α) :
    ∀ᵐ x ∂(fst κ a), densityProcess κ (fst κ) n a x univ = 1 := by
  rw [ae_iff]
  have : {x | ¬ densityProcess κ (fst κ) n a x univ = 1}
      ⊆ {x | fst κ a (countablePartitionSet n x) = 0} := by
    intro x hx
    simp only [mem_setOf_eq] at hx ⊢
    rw [densityProcess_fst_univ] at hx
    simpa using hx
  refine measure_mono_null this ?_
  have : {x | fst κ a (countablePartitionSet n x) = 0}
      ⊆ ⋃ (u) (_ : u ∈ countablePartition γ n) (_ : fst κ a u = 0), u := by
    intro t ht
    simp only [mem_setOf_eq, mem_iUnion, exists_prop] at ht ⊢
    exact ⟨countablePartitionSet n t, countablePartitionSet_mem _ _, ht,
      mem_countablePartitionSet _ _⟩
  refine measure_mono_null this ?_
  rw [measure_biUnion]
  · simp
  · exact (finite_countablePartition _ _).countable
  · intro s hs t ht hst
    simp only [disjoint_iUnion_right, disjoint_iUnion_left]
    exact fun _ _ ↦ disjoint_countablePartition hs ht hst
  · intro s hs
    by_cases h : fst κ a s = 0
    · simp [h, measurableSet_countablePartition n hs]
    · simp [h]

lemma tendsto_densityProcess_fst_atTop_univ_of_monotone (κ : Kernel α (γ × β)) (n : ℕ) (a : α)
    (x : γ) (seq : ℕ → Set β) (hseq : Monotone seq) (hseq_iUnion : ⋃ i, seq i = univ) :
    Tendsto (fun m ↦ densityProcess κ (fst κ) n a x (seq m)) atTop
      (𝓝 (densityProcess κ (fst κ) n a x univ)) := by
  simp_rw [densityProcess]
  refine (ENNReal.tendsto_toReal ?_).comp ?_
  · rw [ne_eq, ENNReal.div_eq_top]
    push_neg
    simp_rw [fst_apply' _ _ (measurableSet_countablePartitionSet _ _)]
    constructor
    · refine fun h h0 ↦ h (measure_mono_null (fun x ↦ ?_) h0)
      simp only [mem_prod, mem_setOf_eq, and_imp]
      exact fun h _ ↦ h
    · refine fun h_top ↦ eq_top_mono (measure_mono (fun x ↦ ?_)) h_top
      simp only [mem_prod, mem_setOf_eq, and_imp]
      exact fun h _ ↦ h
  by_cases h0 : fst κ a (countablePartitionSet n x) = 0
  · rw [fst_apply' _ _ (measurableSet_countablePartitionSet _ _)] at h0 ⊢
    suffices ∀ m, κ a (countablePartitionSet n x ×ˢ seq m) = 0 by
      simp only [this, h0, ENNReal.zero_div, tendsto_const_nhds_iff]
      suffices κ a (countablePartitionSet n x ×ˢ univ) = 0 by
        simp only [this, ENNReal.zero_div]
      convert h0
      ext x
      simp only [mem_prod, mem_univ, and_true, mem_setOf_eq]
    refine fun m ↦ measure_mono_null (fun x ↦ ?_) h0
    simp only [mem_prod, mem_setOf_eq, and_imp]
    exact fun h _ ↦ h
  refine ENNReal.Tendsto.div_const ?_ ?_
  · convert tendsto_measure_iUnion_atTop (monotone_const.set_prod hseq)
    rw [← prod_iUnion, hseq_iUnion]
  · exact Or.inr h0

lemma tendsto_densityProcess_fst_atTop_ae_of_monotone (κ : Kernel α (γ × β)) [IsFiniteKernel κ]
    (n : ℕ) (a : α) (seq : ℕ → Set β) (hseq : Monotone seq) (hseq_iUnion : ⋃ i, seq i = univ) :
    ∀ᵐ x ∂(fst κ a), Tendsto (fun m ↦ densityProcess κ (fst κ) n a x (seq m)) atTop (𝓝 1) := by
  filter_upwards [densityProcess_fst_univ_ae κ n a] with x hx
  rw [← hx]
  exact tendsto_densityProcess_fst_atTop_univ_of_monotone κ n a x seq hseq hseq_iUnion

lemma density_fst_univ (κ : Kernel α (γ × β)) [IsFiniteKernel κ] (a : α) :
    ∀ᵐ x ∂(fst κ a), density κ (fst κ) a x univ = 1 := by
  have h := fun n ↦ densityProcess_fst_univ_ae κ n a
  rw [← ae_all_iff] at h
  filter_upwards [h] with x hx
  simp [density, hx]

lemma tendsto_density_fst_atTop_ae_of_monotone [IsFiniteKernel κ]
    (a : α) (seq : ℕ → Set β) (hseq : Monotone seq) (hseq_iUnion : ⋃ i, seq i = univ)
    (hseq_meas : ∀ m, MeasurableSet (seq m)) :
    ∀ᵐ x ∂(fst κ a), Tendsto (fun m ↦ density κ (fst κ) a x (seq m)) atTop (𝓝 1) := by
  refine tendsto_of_integral_tendsto_of_monotone ?_ (integrable_const _) ?_ ?_ ?_
  · exact fun m ↦ integrable_density le_rfl _ (hseq_meas m)
  · rw [MeasureTheory.integral_const, smul_eq_mul, mul_one]
    convert tendsto_integral_density_of_monotone (κ := κ) le_rfl a seq hseq hseq_iUnion hseq_meas
    rw [fst_apply' _ _ MeasurableSet.univ]
    simp only [mem_univ, setOf_true]
  · exact ae_of_all _ (fun c n m hnm ↦ density_mono_set le_rfl a c (hseq hnm))
  · exact ae_of_all _ (fun x m ↦ density_le_one le_rfl a x (seq m))

end UnivFst

end Density

end Kernel

end ProbabilityTheory
