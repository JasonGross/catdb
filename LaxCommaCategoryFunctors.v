Require Import ProofIrrelevance FunctionalExtensionality JMeq.
Require Export SpecializedLaxCommaCategory SpecializedCommaCategory CommaCategoryFunctors SmallCat Duals NaturalEquivalence.
Require Import Common DiscreteCategory FEqualDep DefinitionSimplification.

Set Implicit Arguments.

Generalizable All Variables.

Local Open Scope category_scope.

Local Ltac slice_t :=
  repeat match goal with
           | [ |- @JMeq (sig _) _ (sig _) _ ] => apply sig_JMeq
           | [ |- (_ -> _) = (_ -> _) ] => apply f_type_equal
           | _ => progress (intros; simpl in *; trivial; subst_body)
           | _ => progress simpl_eq
           | _ => progress (repeat rewrite Associativity; repeat rewrite LeftIdentity; repeat rewrite RightIdentity)
           | _ => progress JMeq_eq
           | _ => apply f_equal
           | [ |- JMeq (?f ?x) (?f ?y) ] =>
             apply (@f_equal1_JMeq _ _ x y f)
           | [ |- JMeq (?f ?x) (?g ?y) ] =>
             apply (@f_equal_JMeq _ _ _ _ x y f g) (*
           | _ =>
             progress (
               destruct_type @CommaSpecializedCategory_Object;
               destruct_type @CommaSpecializedCategory_Morphism;
               destruct_sig;
               present_spcategory
             ) *)
           | [ |- @eq (SpecializedFunctor _ _) _ _ ] => functor_eq
         end.

Section LaxSliceCategory.
  Local Transparent Object Morphism.
  (* [Definition]s are not sort-polymorphic. *)

  Let Index2Cat := LSUnderlyingCategory.

  Let Cat := ComputableCategory _ _ Index2Cat.

  Local Notation "'CAT' ⇓ D" := (@LaxSliceSpecializedCategory _ _ _ Index2Cat _ _ D) (at level 70, no associativity).
  Local Notation "'CAT' ⇑ D" := (@LaxCosliceSpecializedCategory _ _ _ Index2Cat _ _ D) (at level 70, no associativity).

  Variable C : Cat.

  Section LaxSlice.
    Definition LaxSliceCategoryProjection : SpecializedFunctor (CAT ⇓ C) Cat.
      refine (Build_SpecializedFunctor (CAT ⇓ C) Cat
        (fun x => fst (projT1 x))
        (fun s d m => fst (projT1 m))
        _
        _
      );
      abstract (
        intros; present_spcategory;
          destruct_type @LaxSliceSpecializedCategory_Morphism;
          destruct_sig;
          simpl in *;
            try reflexivity
      ).
    Defined.
  End LaxSlice.

  Section LaxCoslice.
    Definition LaxCosliceCategoryProjection : SpecializedFunctor (OppositeCategory (CAT ⇑ C)) Cat.
      refine (Build_SpecializedFunctor (OppositeCategory (CAT ⇑ C)) Cat
        (fun x => snd (projT1 x))
        (fun s d m => snd (projT1 m))
        _
        _
      );
      abstract (
        intros; present_spcategory;
          destruct_type @LaxSliceSpecializedCategory_Morphism;
          destruct_sig;
          simpl in *;
            try reflexivity
      ).
    Defined.
  End LaxCoslice.
End LaxSliceCategory.

Section LaxSliceCategoryFunctor.
  Local Transparent Object Morphism.
  (* [Definition]s are not sort-polymorphic. *)

  Let Index2Cat := LSUnderlyingCategory.

  Let Cat := ComputableCategory _ _ Index2Cat.

  Local Notation "'CAT' ⇓ D" := (@LaxSliceSpecializedCategory _ _ _ Index2Cat _ _ D) (at level 70, no associativity).
  Local Notation "'CAT' ⇑ D" := (@LaxCosliceSpecializedCategory _ _ _ Index2Cat _ _ D) (at level 70, no associativity).

  Variable C D : Cat.
  Variable F : SpecializedFunctor C D.

  Section LaxSlice.
    Local Notation "F ↓ A" := (SliceSpecializedCategory A F) (at level 70, no associativity).

    Local Notation "C / c" := (@SliceSpecializedCategoryOver _ _ C c).

    Let LaxSliceCategoryProjectionFunctor_ObjectOf (d : D) : CAT ⇓ C.
      constructor.
      exact (SliceCategoryProjectionFunctor C D F d).
    Defined.

    Definition LaxSliceCategoryProjectionFunctor_MorphismOf s d (m : Morphism D s d) :
      Morphism (CAT ⇓ C)
      (LaxSliceCategoryProjectionFunctor_ObjectOf s)
      (LaxSliceCategoryProjectionFunctor_ObjectOf d).
      constructor.
      exists (proj1_sig (MorphismOf (SliceCategoryProjectionFunctor C D F) m)).
      simpl.
      match goal with
        | [ C : _ |- SpecializedNaturalTransformation ?F ?G ] =>
          refine (Build_SpecializedNaturalTransformation F G
            (fun _ => Identity (C := C) _)
            _
          )
      end.
      abstract (
        present_spnt; intros; simpl;
          repeat rewrite LeftIdentity; repeat rewrite RightIdentity;
            f_equal;
            match goal with
              | [ |- proj1_sig ?x = projT1 _ ] => destruct x; simpl; reflexivity
            end
      ).
    Defined.

    Let LaxSliceCategoryProjectionFunctor' : Functor D (CAT ⇓ C).
      refine (Build_SpecializedFunctor D (CAT ⇓ C)
        (@LaxSliceCategoryProjectionFunctor_ObjectOf)
        (@LaxSliceCategoryProjectionFunctor_MorphismOf)
        _
        _
      ).
      intros; present_spnt.
      match goal with
        | [ |- @eq ?T ?a ?b ] => let T' := eval hnf in T in let T'' := eval simpl in T' in change (@eq T'' a b)
      end.
      match goal with
        | [ |- @eq (LaxSliceSpecializedCategory_Morphism _ _) ?a ?b ] =>
          cut (LaxSliceSpecializedCategory_Morphism_Member a = LaxSliceSpecializedCategory_Morphism_Member b);
            [
              generalize a b;
                let A := fresh in let B := fresh in
                  intros A B; destruct A, B; simpl; intro; subst; reflexivity
              | ]
      end.
      match goal with
        | [ |- @eq ?T ?a ?b ] => let T' := eval hnf in T in let T'' := eval simpl in T' in change (@eq T'' a b)
      end.
      simpl_eq'; unfold sigT_of_sig.
      simpl.
      simpl_eq'; simpl; trivial.
      pose proof (FCompositionOf (SliceCategoryProjectionFunctor C D F) s d d' m1 m2).
      match type of H with
        | @eq ?T ?a ?b => let a' := eval hnf in a in let b' := eval hnf in b in change (a' = b') in H
      end.
      pose proof (f_equal (@CommaSpecializedCategory_Morphism_Member _ _ _ _ _ _ _ _ _ _ _ _ _) H).
      pose proof (f_equal (@proj1_sig _ _) H0).
      match type of H1 with
        | @eq ?T ?a ?b => let a' := eval hnf in a in let b' := eval hnf in b in change (a' = b') in H1
      end.
      clear H H0.
      present_spcategory.
      apply (f_equal (@fst _ _)) in H1.
      unfold fst at 1 in H1.
      match goal with
        | [ |- @eq ?T _ _ ] => pose T
      end.
      match type of H1 with
        | @eq ?T _ _ => pose T
      end.
      match type of H1 with
        | ?a = ?b => transitivity a; [ reflexivity | rewrite H1; reflexivity ]
      end.
      (***** HERE ******)
      reflexivity.
      rewrite H1.
      simpl in H1 |-
      rewrite H1.
      unfold MorphismOf, SliceCategoryProjectionFunctor in H1.
      cbv beta iota zeta in H1.
      unfold proj1_sig, fst in H1.
      unfold CommaSpecializedCategory_Morphism_Member in H1.
      cbv beta in H1.

      simpl
      unfold MorphismOf at 1 in H.
      simpl in *.
      pose proof (f_equal (@proj1_sig _ _) H).
      rewrite LeftIdentityFunctor in *.
      simpl_eq.
      Local Ltac slice_t' :=
        match goal with
          | _ => progress (intros; trivial)
          | _ => progress subst_body
          | _ => progress clear_refl_eq
          | _ => progress cbv beta iota zeta in *
          | [ |- @JMeq (sig _) _ (sig _) _ ] => apply sig_JMeq
          | [ |- (_ -> _) = (_ -> _) ] => apply f_type_equal
          | _ => progress nt_eq
          | _ => progress functor_eq
          | _ => progress simpl_eq
          | _ => progress (repeat rewrite LeftIdentity in *; repeat rewrite RightIdentity in *; repeat rewrite Associativity in *)
          | _ => progress JMeq_eq
          | _ => apply f_equal
          | [ |- JMeq (?f ?x) (?f ?y) ] =>
            apply (@f_equal1_JMeq _ _ x y f)
          | [ |- JMeq (?f ?x) (?g ?y) ] =>
            apply (@f_equal_JMeq _ _ _ _ x y f g)
          | _ =>
            progress (
              destruct_type @CommaSpecializedCategory_Object;
              destruct_type @CommaSpecializedCategory_Morphism;
              destruct_sig;
              present_spcategory
            )
          | [ |- ?a = ?b ] => let a' := eval hnf in a in let b' := eval hnf in b in change (a' = b')
(*          | _ => progress simpl in * *)
        end.
      Time do 2 slice_t'.
      Time do 2 slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      Time slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      nt_eq.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      JMeq_eq.
      slice_t'.
      present_spcategory.
      change LSMorphism with (fun C => @Morphism (LSObject C) (LSMorphism C) C).
      change LSObject with (fun C => @Object (LSObject C) (LSMorphism C) C).
      simpl.
      present_spcategory.
      JMeq_eq.
      slice_t'.
      slice_t'.
      slice_t'.
      simpl.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      destruct_type @CommaSpecializedCategory_Object.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      destruct_type @CommaSpecializedCategory_Object.
      destruct_all_hypotheses.
      simpl in *.
      slice_t'.
      slice_t'.
      slice_t'.
      destruct_type @CommaSpecializedCategory_Object.
      destruct_all_hypotheses.
      simpl in *.
      slice_t'.
      slice_t'.
      slice_t'.
      destruct_type @CommaSpecializedCategory_Object.
      destruct_all_hypotheses.
      simpl in *.
      slice_t'.
      slice_t'.
      destruct_type @CommaSpecializedCategory_Morphism.
      destruct_all_hypotheses.
      simpl in *.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      apply functional_extensionality_dep; intro.
      slice_t'.
      slice_t'.
      Focus 2.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      Focus 2.
      slice_t'.
      slice_t'.
      slice_t'.
      progress repeat (apply functional_extensionality_dep; intro).
      destruct_type @CommaSpecializedCategory_Object.
      simpl in *.
      destruct_all_hypotheses.
      slice_t'.
      destruct_type @CommaSpecializedCategory_Object.
      simpl in *.
      destruct_all_hypotheses.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      progress nt_eq.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      destruct_type @CommaSpecializedCategory_Object.
      destruct_all_hypotheses.
      slice_t'.
      slice_t'.
      slice_t'.
      destruct_type @CommaSpecializedCategory_Object.
      destruct_all_hypotheses.
      slice_t'.
      slice_t'.
      slice_t'.
      destruct_type @CommaSpecializedCategory_Object.
      destruct_all_hypotheses.
      slice_t'.
      slice_t'.
      slice_t'.
      destruct_type @CommaSpecializedCategory_Object.
      destruct_all_hypotheses.
      slice_t'.
      slice_t'.
      destruct_type @CommaSpecializedCategory_Object.
      destruct_all_hypotheses.
      slice_t'.
      destruct_type @CommaSpecializedCategory_Object.
      destruct_all_hypotheses.
      destruct_type @CommaSpecializedCategory_Morphism.
      destruct_all_hypotheses.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      slice_t'.
      progress slice_t'.
      progress slice_t'.
      progress slice_t'.
      progress slice_t'.
      progress slice_t'.
      progress slice_t'.
      progress slice_t'.
      progress slice_t'.
      progress slice_t'.



          abstract slice_t.
    Defined.

    Let LaxSliceCategoryProjectionFunctor'' : Functor D (LocallySmallCat / C).
      simpl_definition_by_tac_and_exact LaxSliceCategoryProjectionFunctor' ltac:(unfold LaxSliceCategoryProjectionFunctor_MorphismOf in *; subst_body; eta_red).
    Defined.

    Definition LaxSliceCategoryProjectionFunctor : Functor D (LocallySmallCat / C)
      := Eval cbv beta iota zeta delta [LaxSliceCategoryProjectionFunctor''] in LaxSliceCategoryProjectionFunctor''.
  End LaxSlice.

  Section LaxCoslice.
    Local Notation "A ↓ F" := (LaxCosliceSpecializedCategory A F) (at level 70, no associativity).
    Local Notation "C / c" := (@LaxSliceSpecializedCategoryOver _ _ C c).

    Let DOp := OppositeCategory D.

    Let LaxCosliceCategoryProjectionFunctor_ObjectOf (d : D) : LocallySmallCat / C.
      constructor.
      exact (existT (fun _ => _) ((d ↓ F : LocallySmallSpecializedCategory _) : LocallySmallCategory, tt) (LaxCosliceCategoryProjection d F)).
    Defined.

    Let LaxCosliceCategoryInducedFunctor_ObjectOf s d (m : Morphism DOp s d) :
      CommaSpecializedCategory_Object (LaxSliceSpecializedCategory_Functor D s) F ->
      CommaSpecializedCategory_Object (LaxSliceSpecializedCategory_Functor D d) F.
      intro x; constructor.
      exact (existT _ (projT1 x) (Compose (projT2 x) m)).
    Defined.

    Let LaxCosliceCategoryInducedFunctor_MorphismOf s d (m : Morphism DOp s d) : forall
      (s0 d0 : CommaSpecializedCategory_Object (LaxSliceSpecializedCategory_Functor D s) F)
      (m0 : CommaSpecializedCategory_Morphism s0 d0),
      CommaSpecializedCategory_Morphism
      (@LaxCosliceCategoryInducedFunctor_ObjectOf s d m s0)
      (@LaxCosliceCategoryInducedFunctor_ObjectOf s d m d0).
      subst_body.
      intros s0 d0 m0.
      constructor; simpl.
      exists (projT1 m0).
      abstract (
        destruct m0 as [ [ ? ? ] ]; simpl in *;
          rewrite RightIdentity in *;
            repeat rewrite <- Associativity;
              f_equal;
              assumption
      ).
    Defined.

    Let LaxCosliceCategoryInducedFunctor' (s d : D) (m : Morphism DOp s d) :
      SpecializedFunctor (s ↓ F) (d ↓ F).
      refine (Build_SpecializedFunctor (s ↓ F) (d ↓ F)
        (@LaxCosliceCategoryInducedFunctor_ObjectOf s d m)
        (@LaxCosliceCategoryInducedFunctor_MorphismOf s d m)
        _
        _
      );
      subst_body; simpl; intros;
      abstract (
        present_spcategory;
        subst_body;
        simpl in *;
          apply f_equal; simpl_eq; trivial;
            present_spcategory;
            repeat match goal with
                     | [ H : CommaSpecializedCategory_Morphism _ _ |- _ ] => destruct H as [ [ ] ]; simpl in *
                   end;
            reflexivity
      ).
    Defined.

    Let LaxCosliceCategoryInducedFunctor'' (s d : D) (m : Morphism DOp s d) :
      SpecializedFunctor (s ↓ F) (d ↓ F).
      simpl_definition_by_tac_and_exact (@LaxCosliceCategoryInducedFunctor' s d m) ltac:(subst_body; eta_red).
    Defined.

    Definition LaxCosliceCategoryInducedFunctor (s d : D) (m : Morphism DOp s d) :
      SpecializedFunctor (s ↓ F) (d ↓ F)
      := Eval cbv beta iota zeta delta [LaxCosliceCategoryInducedFunctor''] in @LaxCosliceCategoryInducedFunctor'' s d m.

    Definition LaxCosliceCategoryProjectionFunctor_MorphismOf (s d : D) (m : Morphism DOp s d) :
      CommaSpecializedCategory_MorphismT
      (LaxCosliceCategoryProjectionFunctor_ObjectOf s)
      (LaxCosliceCategoryProjectionFunctor_ObjectOf d).
      Transparent Morphism.
      subst_body; hnf; simpl.
      exists (@LaxCosliceCategoryInducedFunctor s d m, tt).
      simpl; intros.
      abstract (
        functor_eq;
        f_equal;
        match goal with
          | [ |- proj1_sig ?x = projT1 _ ] => destruct x; simpl; reflexivity
        end
      ).
    Defined.

    Let LaxCosliceCategoryProjectionFunctor' : Functor DOp (LocallySmallCat / C).
      refine (Build_SpecializedFunctor DOp (LocallySmallCat / (C : LocallySmallCategory))
        (@LaxCosliceCategoryProjectionFunctor_ObjectOf)
        (@LaxCosliceCategoryProjectionFunctor_MorphismOf)
        _
        _
      );
      unfold LaxCosliceCategoryProjectionFunctor_MorphismOf, LaxCosliceCategoryInducedFunctor in *; subst_body;
        abstract slice_t.
    Defined.

    Let LaxCosliceCategoryProjectionFunctor'' : Functor DOp (LocallySmallCat / C).
      simpl_definition_by_tac_and_exact LaxCosliceCategoryProjectionFunctor' ltac:(unfold LaxCosliceCategoryProjectionFunctor_MorphismOf in *; subst_body; eta_red).
    Defined.

    Definition LaxCosliceCategoryProjectionFunctor : Functor DOp (LocallySmallCat / C)
      := Eval cbv beta iota zeta delta [LaxCosliceCategoryProjectionFunctor''] in LaxCosliceCategoryProjectionFunctor''.
  End LaxCoslice.
End LaxSliceCategoryFunctor.
