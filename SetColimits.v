Require Import Setoid ProofIrrelevance FunctionalExtensionality ClassicalEpsilon.
Require Export SetCategory EquivalenceSet EquivalenceClass Grothendieck EquivalenceRelationGenerator.
Require Import Common Notations Limits Functor NaturalTransformation FunctorCategory InitialTerminalCategory.

Set Implicit Arguments.

Generalizable All Variables.

Local Ltac colimit_morphism_t chooser_respectful :=
  simpl; intros; hnf;
  repeat (apply functional_extensionality_dep; intro);
  simpl_eq;
  apply chooser_respectful;
  match goal with
    | [ m : _ |- _ ]
      => (apply gen_sym;
          apply gen_underlying;
          constructor; hnf; simpl;
          exists m; reflexivity)
    | [ m : _ |- _ ]
      => (apply gen_underlying;
          constructor; hnf; simpl;
          exists m; reflexivity)
  end.

Local Ltac colimit_t Colimit_Property_Morphism_respectful GrothendieckPair_eta :=
  repeat (repeat split; repeat intro);
  nt_eq;
  repeat (apply functional_extensionality_dep; intro);
  try apply Colimit_Property_Morphism_respectful;
  repeat subst;
  simpl;
  repeat rewrite GrothendieckPair_eta;
  destruct_sig;
  eauto;
  subst_body;
  apply f_equal;
  simpl_eq;
  intuition.
    
Section SetColimits.
  (* An element of the colimit is an pair [c : C] and [x : F c] with
     (c, x) ~ (c', x') an equivalence relation generated by the
     existance of a morphism [m : c -> c'] with m c x = m c x'. *)
  Context `(C : @SmallSpecializedCategory objC).
  Variable F : SpecializedFunctor C SetCat.
  Let F' : SpecializedFunctorToType _ := F : SpecializedFunctorToSet _.

  Definition SetColimit_Object_pre := SetGrothendieckPair F. (* { c : objC & F.(ObjectOf') c }.*)
  Global Arguments SetColimit_Object_pre /.
  Definition SetColimit_Object_equiv_sig :=
    generateEquivalence (fun x y : SetColimit_Object_pre => inhabited (Morphism (CategoryOfElements F') x y)).
  Definition SetColimit_Object_equiv :=
    proj1_sig SetColimit_Object_equiv_sig.
  Definition SetColimit_Object_equiv_Equivalence :=
    proj2_sig SetColimit_Object_equiv_sig.

  Local Infix "~=" := SetColimit_Object_equiv.

  Lemma SetColimit_Property_Morphism_respectful (S : SetCat) (m : Morphism (SetCat ^ C) F (DiagonalFunctor SetCat C S)) c x c' x'
    (a := Build_SetGrothendieckPair F c x) (b := Build_SetGrothendieckPair F c' x') :
    a ~= b
    -> m c x = m c' x'.
    change c with (SetGrothendieckC a).
    change x with (SetGrothendieckX a).
    change c' with (SetGrothendieckC b).
    change x' with (SetGrothendieckX b).
    clearbody a b; clear c x c' x'.
    intro H; induction H; try solve [ etransitivity; eauto ].
    destruct H as [ [ p H ] ].
    pose (fg_equal (m.(Commutes') _ _ p)) as e; simpl in *.
    unfold SetGrothendieckC, SetGrothendieckX.
    t_rev_with t'.
  Qed.

  Section chooser.
    Variable chooser : SetColimit_Object_pre -> SetColimit_Object_pre.
    Hypothesis chooser_respectful : forall x y, x ~= y <-> chooser x = chooser y.
    Hypothesis chooser_idempotent : forall x, chooser (chooser x) = chooser x.

    Let chooser_respectful1 x y : x ~= y -> chooser x = chooser y := proj1 (chooser_respectful x y).
    Let chooser_respectful2 x y : chooser x = chooser y -> x ~= y := proj2 (chooser_respectful x y).

    Hint Resolve chooser_respectful1 chooser_respectful2 chooser_idempotent.

    Definition SetColimit_Object : SetCat := { x | chooser x = x }.

    Let chooser' (x : SetColimit_Object_pre) : SetColimit_Object.
      exists (chooser x); abstract trivial.
    Defined.

    (* TODO: Automate better. *)
    Definition SetColimit_Morphism : Morphism (SetCat ^ C) F ((DiagonalFunctor SetCat C) SetColimit_Object).
      hnf; simpl.
      match goal with
        | [ |- SpecializedNaturalTransformation ?F ?G ] =>
          refine (Build_SpecializedNaturalTransformation F G
            (fun c : objC =>
              (fun S : F c =>
                chooser' (Build_SetGrothendieckPair F c S)
              )
            )
            _
          )
      end.
      abstract colimit_morphism_t chooser_respectful.
    Defined.

    Definition SetColimit_Property_Morphism A' (φ' : Morphism (SetCat ^ C)%functor F ((DiagonalFunctor SetCat C) A')) :
      SetColimit_Object -> A'
      := fun x => φ' (SetGrothendieckC (proj1_sig x)) (SetGrothendieckX (proj1_sig x)).

    Definition SetColimit : Colimit F.
      apply (Build_InitialMorphism (C := SetCat ^ C) F (DiagonalFunctor SetCat C) SetColimit_Object SetColimit_Morphism).
      intros A' φ'.
      exists (SetColimit_Property_Morphism φ').
      abstract colimit_t @SetColimit_Property_Morphism_respectful @SetGrothendieckPair_eta.
    Defined.
  End chooser.

  Section axiom.
    Hypothesis inhabited_dec : forall x y : SetColimit_Object_pre, {x ~= y} + {~(x ~= y)}.

    Hint Resolve setOf_mor.

    Let chooserSet (x : SetColimit_Object_pre) := setOf SetColimit_Object_equiv_Equivalence inhabited_dec x.

    Let chooser (x : SetColimit_Object_pre) : SetColimit_Object_pre
      := proj1_sig (constructive_indefinite_description _ (SetInhabited (chooserSet x))).

    Local Ltac solve_chooser_eq :=
      match goal with
        | [ |- chooser ?x = chooser ?y ] =>
          cut (sameSet (chooserSet x) (chooserSet y));
            unfold chooser, chooserSet in *;
              [
                let H := fresh in intro H; apply sameSet_eq in H; rewrite H; reflexivity
                | try solve [ apply eq_sameSet; unfold chooserSet; auto ]
              ]
      end.

    Let chooser_respectful x y : x ~= y <-> chooser x = chooser y.
      split; intro; try solve_chooser_eq;
        match goal with
          | [ H : chooser ?x = chooser ?y |- ?x ~= ?y ] =>
            cut (sameSet (chooserSet x) (chooserSet y));
              unfold chooser, chooserSet in *;
                [
                  intro H'; apply sameSet_eq in H'; apply setOf_eq in H'; auto
                  | apply notDisjointSets_sameSet; intro_proj2_sig; rewrite H in *;
                    eexists; split; eauto
                ]
        end.
    Qed.

    Let chooser_idempotent x : chooser (chooser x) = chooser x.
      solve_chooser_eq.
      apply notDisjointSets_sameSet; exists x; intro_proj2_sig; split; clear_InSet; eauto.
    Qed.

    Lemma SetHasColimits : Colimit F.
      exact (@SetColimit chooser chooser_respectful chooser_idempotent).
    Qed.
  End axiom.
End SetColimits.

Section TypeColimits.
  (* An element of the colimit is an pair [c : C] and [x : F c] with
     (c, x) ~ (c', x') an equivalence relation generated by the
     existance of a morphism [m : c -> c'] with m c x = m c x'. *)
  Context `(C : @SpecializedCategory objC).
  Variable F : SpecializedFunctor C TypeCat.

  Definition TypeColimit_Object_pre := GrothendieckPair F. (* { c : objC & F.(ObjectOf') c }. *)
  Global Arguments TypeColimit_Object_pre /.
  Definition TypeColimit_Object_equiv_sig :=
    generateEquivalence (fun x y : TypeColimit_Object_pre => inhabited (Morphism (CategoryOfElements F) x y)).
  Definition TypeColimit_Object_equiv :=
    proj1_sig TypeColimit_Object_equiv_sig.
  Definition TypeColimit_Object_equiv_Equivalence :=
    proj2_sig TypeColimit_Object_equiv_sig.

  Local Infix "~=" := TypeColimit_Object_equiv.

  Lemma TypeColimit_Property_Morphism_respectful (S : TypeCat) (m : Morphism (TypeCat ^ C) F (DiagonalFunctor TypeCat C S)) c x c' x'
    (a := Build_GrothendieckPair F c x) (b := Build_GrothendieckPair F c' x') :
    a ~= b
    -> m c x = m c' x'.
    change c with (GrothendieckC a).
    change x with (GrothendieckX a).
    change c' with (GrothendieckC b).
    change x' with (GrothendieckX b).
    clearbody a b; clear c x c' x'.
    intro H; induction H; try solve [ etransitivity; eauto ].
    destruct H as [ [ p H ] ].
    pose (fg_equal (m.(Commutes') _ _ p)) as e; simpl in *.
    unfold GrothendieckC, GrothendieckX in *.
    t_rev_with t'.
  Qed.

  Section chooser.
    Variable chooser : TypeColimit_Object_pre -> TypeColimit_Object_pre.
    Hypothesis chooser_respectful : forall x y, x ~= y <-> chooser x = chooser y.
    Hypothesis chooser_idempotent : forall x, chooser (chooser x) = chooser x.

    Let chooser_respectful1 x y : x ~= y -> chooser x = chooser y := proj1 (chooser_respectful x y).
    Let chooser_respectful2 x y : chooser x = chooser y -> x ~= y := proj2 (chooser_respectful x y).

    Hint Resolve chooser_respectful1 chooser_respectful2 chooser_idempotent.

    Definition TypeColimit_Object : TypeCat := { x | chooser x = x }.

    Let chooser' (x : TypeColimit_Object_pre) : TypeColimit_Object.
      exists (chooser x); abstract trivial.
    Defined.

    (* TODO: Automate better. *)
    Definition TypeColimit_Morphism : Morphism (TypeCat ^ C) F ((DiagonalFunctor TypeCat C) TypeColimit_Object).
      hnf; simpl.
      match goal with
        | [ |- SpecializedNaturalTransformation ?F ?G ] =>
          refine (Build_SpecializedNaturalTransformation F G
            (fun c : objC =>
              (fun S : F c =>
                chooser' (Build_GrothendieckPair F c S)
              )
            )
            _
          )
      end.
      abstract colimit_morphism_t chooser_respectful.
    Defined.

    Definition TypeColimit_Property_Morphism A' (φ' : Morphism (TypeCat ^ C)%functor F ((DiagonalFunctor TypeCat C) A')) :
      TypeColimit_Object -> A'
      := fun x => φ' (GrothendieckC (proj1_sig x)) (GrothendieckX (proj1_sig x)).

    Definition TypeColimit : Colimit F.
      apply (Build_InitialMorphism (C := TypeCat ^ C) F (DiagonalFunctor TypeCat C) TypeColimit_Object TypeColimit_Morphism).
      intros A' φ'.
      exists (TypeColimit_Property_Morphism φ').
      abstract colimit_t @TypeColimit_Property_Morphism_respectful @GrothendieckPair_eta.
    Defined.
  End chooser.

  Section axiom.
    Hint Resolve classOf_mor.

    Let chooserClass (x : TypeColimit_Object_pre) := classOf TypeColimit_Object_equiv_Equivalence x.

    Let chooser (x : TypeColimit_Object_pre) : TypeColimit_Object_pre
      := proj1_sig (constructive_indefinite_description _ (ClassInhabited (chooserClass x))).

    Local Ltac solve_chooser_eq :=
      match goal with
        | [ |- chooser ?x = chooser ?y ] =>
          cut (sameClass (chooserClass x) (chooserClass y));
            unfold chooser, chooserClass in *;
              [
                let H := fresh in intro H; apply sameClass_eq in H; rewrite H; reflexivity
                | try solve [ apply eq_sameClass; unfold chooserClass; auto ]
              ]
      end.

    Let chooser_respectful x y : x ~= y <-> chooser x = chooser y.
      split; intro; try solve_chooser_eq.
        match goal with
          | [ H : chooser ?x = chooser ?y |- ?x ~= ?y ] =>
            cut (sameClass (chooserClass x) (chooserClass y));
              unfold chooser, chooserClass in *;
                [
                  intro H'; apply sameClass_eq in H'; apply classOf_eq in H'; auto
                  | apply notDisjointClasses_sameClass; intro_proj2_sig; rewrite H in *;
                    eexists; split; eauto
                ]
        end.
    Qed.

    Let chooser_idempotent x : chooser (chooser x) = chooser x.
      solve_chooser_eq.
      apply notDisjointClasses_sameClass; exists x; intro_proj2_sig_from_goal'; split; replace_InClass; simpl in *; clear_InClass;
        eauto || symmetry; eauto.
    Qed.

    Lemma TypeHasColimits : Colimit F.
      exact (@TypeColimit chooser chooser_respectful chooser_idempotent).
    Qed.
  End axiom.
End TypeColimits.
