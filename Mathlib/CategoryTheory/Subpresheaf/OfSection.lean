/-
Copyright (c) 2025 Joël Riou. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joël Riou
-/
import Mathlib.CategoryTheory.Subpresheaf.Image
import Mathlib.CategoryTheory.Yoneda

/-!
# The subpresheaf generated by a section

Given a presheaf of types `F : Cᵒᵖ ⥤ Type w` and a section `x : F.obj X`,
we define `Subpresheaf.ofSection x : Subpresheaf F` as the subpresheaf
of `F` generated by `x`.

-/

universe w v u

namespace CategoryTheory

variable {C : Type u} [Category.{v} C]

namespace Subpresheaf

section

variable {F : Cᵒᵖ ⥤ Type w} {X : Cᵒᵖ} (x : F.obj X)

/-- The subpresheaf of `F : Cᵒᵖ ⥤ Type w` that is generated
by a section `x : F.obj X`. -/
@[simps (config := .lemmasOnly)]
def ofSection : Subpresheaf F where
  obj U := setOf (fun u ↦ ∃ (f : X ⟶ U), F.map f x = u)
  map {U V} g := by
    rintro _ ⟨f, rfl⟩
    exact ⟨f ≫ g, by simp⟩

lemma mem_ofSection_obj : x ∈ (ofSection x).obj X := ⟨𝟙 _, by simp⟩

@[simp]
lemma ofSection_le_iff (G : Subpresheaf F) :
    ofSection x ≤ G ↔ x ∈ G.obj X := by
  constructor
  · intro hx
    exact hx _ (mem_ofSection_obj x)
  · rintro hx U _ ⟨f, rfl⟩
    exact G.map f hx

@[simp]
lemma ofSection_image {F' : Cᵒᵖ ⥤ Type w} (f : F ⟶ F') :
    (ofSection x).image f = ofSection (f.app _ x) := by
  apply le_antisymm
  · rw [image_le_iff, ofSection_le_iff, preimage_obj, Set.mem_preimage]
    exact ⟨𝟙 X, by simp⟩
  · simp only [ofSection_le_iff, image_obj, Set.mem_image]
    exact ⟨x, mem_ofSection_obj x, rfl⟩

end

section

variable {F : Cᵒᵖ ⥤ Type v}

lemma ofSection_eq_range {X : Cᵒᵖ} (x : F.obj X) :
    ofSection x = range (yonedaEquiv.symm x) := by
  ext U y
  simp only [ofSection_obj, Set.mem_setOf_eq, Opposite.op_unop, range_obj, yoneda_obj_obj,
    Set.mem_range]
  constructor
  · rintro ⟨f, rfl⟩
    exact ⟨f.unop, rfl⟩
  · rintro ⟨f, rfl⟩
    exact ⟨f.op, rfl⟩

lemma range_eq_ofSection {X : C} (f : yoneda.obj X ⟶ F) :
    range f = ofSection (yonedaEquiv f) := by
  rw [ofSection_eq_range, Equiv.symm_apply_apply]

end

section

variable {F : Cᵒᵖ ⥤ Type max v w}

lemma ofSection_eq_range' {X : Cᵒᵖ} (x : F.obj X) :
    ofSection x = range ((yonedaCompUliftFunctorEquiv F X.unop).symm x) := by
  ext U y
  simp only [Opposite.op_unop, range_obj, Functor.comp_obj, yoneda_obj_obj, uliftFunctor_obj,
    Set.mem_range, ULift.exists]
  constructor
  · rintro ⟨f, rfl⟩
    exact ⟨f.unop, rfl⟩
  · rintro ⟨f, rfl⟩
    exact ⟨f.op, rfl⟩

lemma range_eq_ofSection' {X : C} (f : yoneda.obj X ⋙ uliftFunctor.{w} ⟶ F) :
    range f = ofSection ((yonedaCompUliftFunctorEquiv F X) f) := by
  rw [ofSection_eq_range', Equiv.symm_apply_apply]

end

end Subpresheaf

end CategoryTheory
