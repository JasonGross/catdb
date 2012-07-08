Require Import ProofIrrelevance.
Require Import Common StructureEquality.

Set Implicit Arguments.

Record SpecializedCategory (obj : Type) (Morphism : obj -> obj -> Type) := {
  Object :> _ := obj;

  Identity' : forall o, Morphism o o;
  Compose' : forall s d d', Morphism d d' -> Morphism s d -> Morphism s d';

  Associativity' : forall o1 o2 o3 o4 (m1 : Morphism o1 o2) (m2 : Morphism o2 o3) (m3 : Morphism o3 o4),
    Compose' (Compose' m3 m2) m1 = Compose' m3 (Compose' m2 m1);
  LeftIdentity' : forall a b (f : Morphism a b), Compose' (Identity' b) f = f;
  RightIdentity' : forall a b (f : Morphism a b), Compose' f (Identity' a) = f
}.

Section SpecializedCategoryInterface.
  Variable obj : Type.
  Variable mor : obj -> obj -> Type.
  Variable C : @SpecializedCategory obj mor.

  Definition Morphism : forall s d : C, _ := mor.
  Definition Identity : forall o : C, Morphism o o := C.(Identity').
  Definition Compose : forall (s d d' : C) (m : Morphism d d') (m0 : Morphism s d), Morphism s d' := C.(Compose').
  Definition Associativity : forall (o1 o2 o3 o4 : C) (m1 : Morphism o1 o2) (m2 : Morphism o2 o3) (m3 : Morphism o3 o4),
    Compose (Compose m3 m2) m1 = Compose m3 (Compose m2 m1)
    := C.(Associativity').
  Definition LeftIdentity : forall (a b : C) (f : Morphism a b),
    Compose (Identity b) f = f
    := C.(LeftIdentity').
  Definition RightIdentity : forall (a b : C) (f : Morphism a b),
    Compose f (Identity a) = f
    := C.(RightIdentity').
End SpecializedCategoryInterface.
Global Opaque Morphism Identity Compose.
Global Opaque Associativity LeftIdentity RightIdentity.

Ltac present_mor_all mor_fun cat :=
  repeat match goal with
           | [ _ : appcontext[mor_fun ?s ?d] |- _ ] => progress change (mor_fun s d) with (@Morphism _ mor_fun cat s d) in *
           | [ |- appcontext[mor_fun ?s ?d] ] => progress change (mor_fun s d) with (@Morphism _ mor_fun cat s d) in *
         end.

Ltac present_mor mor_fun cat :=
  repeat match goal with
           | [ _ : mor_fun ?s ?d |- _ ] => progress change (mor_fun s d) with (@Morphism _ mor_fun cat s d) in *
         end.

Ltac present_mor_from_context cmd :=
  repeat match goal with
           | [ _ : appcontext[cmd ?obj ?mor ?C] |- _ ] => progress present_mor mor C
           | [ |- appcontext[cmd ?obj ?mor ?C] ] => progress present_mor mor C
         end.

Ltac present_obj_mor from to :=
  repeat match goal with
           | [ _ : appcontext[from ?obj ?mor ?C] |- _ ] => progress change (from obj mor) with (to obj mor) in *
           | [ |- appcontext[from ?obj ?mor ?C] ] => progress change (from obj mor) with (to obj mor) in *
         end.

Ltac present_spcategory := present_obj_mor @Identity' @Identity; present_obj_mor @Compose' @Compose;
  repeat match goal with
           | [ C : @SpecializedCategory ?obj ?mor |- _ ] => progress present_mor mor C
         end.

Arguments Compose {obj mor} [C s d d'] m m0.
Arguments Identity {obj mor} [C] o.

Hint Rewrite LeftIdentity RightIdentity.

Definition LocallySmallSpecializedCategory (obj : Type) (mor : obj -> obj -> Set) := SpecializedCategory mor.
Definition SmallSpecializedCategory (obj : Set) (mor : obj -> obj -> Set) := SpecializedCategory mor.
Identity Coercion LocallySmallSpecializedCategory_SpecializedCategory_Id : LocallySmallSpecializedCategory >-> SpecializedCategory.
Identity Coercion SmallSpecializedCategory_LocallySmallSpecializedCategory_Id : SmallSpecializedCategory >-> SpecializedCategory.

Section Categories_Equal.
  Lemma SpecializedCategories_Equal obj mor : forall (C D : @SpecializedCategory obj mor),
    @Identity' _ _ C = @Identity' _ _ D
    -> @Compose' _ _ C = @Compose' _ _ D
    -> C = D.
    Transparent Object Morphism.
    destruct C, D; unfold Object, Morphism in *; simpl in *; intros; firstorder; repeat subst;
      f_equal; apply proof_irrelevance.
  Qed.
End Categories_Equal.

Ltac spcat_eq_step_with tac := structures_eq_step_with SpecializedCategories_Equal tac.

Ltac spcat_eq_with tac := present_spcategory; repeat spcat_eq_step_with tac.

Ltac spcat_eq_step := spcat_eq_step_with idtac.
Ltac spcat_eq := spcat_eq_with idtac.

Ltac solve_for_identity :=
  match goal with
    | [ |- @Compose _ _ ?C ?s ?s ?d ?a ?b = ?b ] => cut (a = @Identity C s);
      try solve [ let H := fresh in intro H; rewrite H; apply LeftIdentity ]
    | [ |- @Compose _ _ ?C ?s ?d ?d ?a ?b = ?a ] => cut (b = @Identity C d );
      try solve [ let H := fresh in intro H; rewrite H; apply RightIdentity ]
  end.

(** * Version of [Associativity] that avoids going off into the weeds in the presence of unification variables *)

Definition NoEvar T (_ : T) := True.

Lemma AssociativityNoEvar obj mor (C : @SpecializedCategory obj mor) : forall (o1 o2 o3 o4 : C) (m1 : C.(Morphism) o1 o2)
  (m2 : C.(Morphism) o2 o3) (m3 : C.(Morphism) o3 o4),
  NoEvar (m1, m2) \/ NoEvar (m2, m3) \/ NoEvar (m1, m3)
  -> Compose (Compose m3 m2) m1 = Compose m3 (Compose m2 m1).
  intros; apply Associativity.
Qed.

Ltac noEvar := match goal with
                 | [ |- context[NoEvar ?X] ] => cut (NoEvar X);
                   (intro; tauto) ||
                     ((has_evar X; fail 1) || constructor)
               end.

Hint Rewrite AssociativityNoEvar using noEvar.

Ltac try_associativity tac := try_rewrite_by AssociativityNoEvar ltac:(idtac; noEvar) tac.

Ltac find_composition_to_identity :=
  match goal with
    | [ H : @Compose _ _ _ _ _ _ ?a ?b = @Identity _ _ _ _ |- context[@Compose ?A ?B ?C ?D ?E ?F ?c ?d] ]
      => let H' := fresh in
        assert (H' : b = d /\ a = c) by (split; reflexivity); clear H';
          assert (H' : @Compose A B C D E F c d = @Identity _ _ _ _) by (unfold Object in H |- *; simpl in H |- *; rewrite H; reflexivity);
            rewrite H'; clear H'
  end.

(** * Back to the main content.... *)

Section Category.
  Variable obj : Type.
  Variable mor : obj -> obj -> Type.
  Variable C : SpecializedCategory mor.

  (* Quoting Wikipedia,
    In category theory, an epimorphism (also called an epic
    morphism or, colloquially, an epi) is a morphism [f : X → Y]
    which is right-cancellative in the sense that, for all
    morphisms [g, g' : Y → Z],
    [g ○ f = g' ○ f -> g = g']

    Epimorphisms are analogues of surjective functions, but they
    are not exactly the same. The dual of an epimorphism is a
    monomorphism (i.e. an epimorphism in a category [C] is a
    monomorphism in the dual category [OppositeCategory C]).
    *)
  Definition Epimorphism x y (m : C.(Morphism) x y) : Prop :=
    forall z (m1 m2 : C.(Morphism) y z), Compose m1 m = Compose m2 m ->
      m1 = m2.
  Definition Monomorphism x y (m : C.(Morphism) x y) : Prop :=
    forall z (m1 m2 : C.(Morphism) z x), Compose m m1 = Compose m m2 ->
      m1 = m2.

  (* [m'] is the inverse of [m] if both compositions are
     equivalent to the relevant identity morphisms. *)
  Definition InverseOf' s d (m : mor s d) (m' : mor d s) : Prop :=
    Compose m' m = @Identity _ _ C s /\
    Compose m m' = @Identity _ _ C d.
  Definition InverseOf s d (m : C.(Morphism) s d) (m' : C.(Morphism) d s) : Prop := InverseOf' m m'.
  Global Identity Coercion InverseOf_InverseOf'_Id : InverseOf >-> InverseOf'.

  Lemma InverseOf_sym s d m m' : @InverseOf s d m m' -> @InverseOf d s m' m.
    firstorder.
  Qed.

  (* A morphism is an isomorphism if it has an inverse *)
  Definition IsCategoryIsomorphism s d (m : C.(Morphism) s d) : Prop :=
    exists m', InverseOf m m'.

  (* As per David's comment, everything is better when we supply a witness rather
     than an assertion.  (In particular the [exists m' -> m'] transformation is only
     permissible for [m' : Prop].  Trying it on other with
       refine match H with
                | ex_intro x x0 => _ x x0
              end
     gives
       Error:
       Incorrect elimination of "H" in the inductive type "ex":
       the return type has sort "Type" while it should be "Prop".
       Elimination of an inductive object of sort Prop
       is not allowed on a predicate in sort Type
       because proofs can be eliminated only to build proofs.
     ) *)
  Definition CategoryIsomorphism' (s d : obj) (m : mor s d) := { m' | InverseOf' m m' }.
  Definition CategoryIsomorphism (s d : C) (m : C.(Morphism) s d) := @CategoryIsomorphism' s d m.
  Global Identity Coercion CategoryIsomorphism_CategoryIsomorphism'_Id : CategoryIsomorphism >-> CategoryIsomorphism'.

  (* XXX Outside of this section, why does
     [[
     Set Printing Universes.
     Check (@CategoryIsomorphism' nat).
     Check (@CategoryIsomorphism' nat (fun _ _ => unit : Set)).
     ]]
     give
     [[
     CategoryIsomorphism' (obj:=nat)
     : forall mor : nat -> nat -> Type (* Top.15911 *),
       SpecializedCategory mor ->
       forall s d : nat, mor s d -> Type (* Top.15911 *)
     CategoryIsomorphism' (mor:=fun _ _ : nat => unit:Set)
     : SpecializedCategory (fun _ _ : nat => unit:Set) ->
       forall s d : nat,
       (fun _ _ : nat => unit:Set) s d -> Type (* Top.15911 *)
     ]]
     ?  Shouldn't fake universe polymorphism make it give
     [Set] in the second [Check]?
     *)

  Hint Unfold InverseOf InverseOf' CategoryIsomorphism' IsCategoryIsomorphism CategoryIsomorphism.

  Lemma InverseOf1 : forall (s d : C) (m : _ s d) m', InverseOf m m'
    -> Compose m' m = Identity s.
    firstorder.
  Qed.

  Lemma InverseOf2 : forall (s d : C) (m : _ s d) m', InverseOf m m'
    -> Compose m m' = Identity d.
    firstorder.
  Qed.

  Lemma CategoryIsomorphism2Isomorphism' s d (m : _ s d) : CategoryIsomorphism m -> IsCategoryIsomorphism m.
    firstorder.
  Qed.

  Hint Rewrite <- InverseOf1 InverseOf2 using assumption.

  (* XXX TODO: Automate this better. *)
  Lemma iso_is_epi s d (m : _ s d) : CategoryIsomorphism m -> Epimorphism m.
    destruct 1 as [ x [ i0 i1 ] ]; intros z m1 m2 e.
    transitivity (Compose m1 (Compose m x)). t.
    transitivity (Compose m2 (Compose m x)); repeat (rewrite <- Associativity); t.
  Qed.

  Lemma InverseOf1' : forall x y z (m : C.(Morphism) x y) (m' : C.(Morphism) y x) (m'' : C.(Morphism) z _),
    InverseOf m m'
    -> Compose m' (Compose m m'') = m''.
    unfold InverseOf, InverseOf'; intros; destruct_hypotheses; repeat rewrite <- Associativity; t.
  Qed.

  Hint Rewrite InverseOf1' using assumption.

  (* XXX TODO: Automate this better. *)
  Lemma iso_is_mono s d (m : _ s d) : CategoryIsomorphism m -> Monomorphism m.
    destruct 1 as [ x [ i0 i1 ] ]; intros z m1 m2 e.
    transitivity (Compose (Compose x m) m1). t_with t'.
    transitivity (Compose (Compose x m) m2); solve [ repeat rewrite Associativity; t_with t' ] || t_with t'.
  Qed.

  Theorem CategoryIdentityInverse (o : C) : InverseOf (Identity o) (Identity o).
    hnf; t.
  Qed.

  Hint Resolve CategoryIdentityInverse.

  Theorem CategoryIdentityIsomorphism (o : C) : CategoryIsomorphism (Identity o).
    eexists; t.
  Qed.
End Category.

Arguments IsCategoryIsomorphism {obj mor} [C s d] m.
Arguments CategoryIsomorphism' {obj mor} [C s d] m.
Arguments CategoryIsomorphism {obj mor} [C s d] m.
Arguments Epimorphism {obj mor} [C x y] m.
Arguments Monomorphism {obj mor} [C x y] m.
Arguments InverseOf {obj mor} [C s d] m m'.

Hint Resolve CategoryIsomorphism2Isomorphism'.

Ltac post_compose_to_identity :=
  eapply iso_is_epi; try_associativity ltac:(idtac; find_composition_to_identity) || eauto; try rewrite RightIdentity.
Ltac pre_compose_to_identity :=
  eapply iso_is_mono; try_associativity ltac:(idtac; find_composition_to_identity) || eauto; try rewrite LeftIdentity.

Section AssociativityComposition.
  Variable obj : Type.
  Variable mor : obj -> obj -> Type.
  Variable C : SpecializedCategory mor.
  Variables o0 o1 o2 o3 o4 : C.

  Lemma compose4associativity_helper
    (a : Morphism _ o3 o4) (b : Morphism _ o2 o3)
    (c : Morphism _ o1 o2) (d : Morphism _ o0 o1) :
    Compose (Compose a b) (Compose c d) = (Compose a (Compose (Compose b c) d)).
    repeat rewrite Associativity; reflexivity.
  Qed.
End AssociativityComposition.

Ltac compose4associativity' a b c d := transitivity (Compose a (Compose (Compose b c) d)); try solve [ apply compose4associativity_helper ].
Ltac compose4associativity :=
  match goal with
    | [ |- Compose (Compose ?a ?b) (Compose ?c ?d) = _ ] => compose4associativity' a b c d
    | [ |- _ = Compose (Compose ?a ?b) (Compose ?c ?d) ] => compose4associativity' a b c d
  end.

Section CategoryIsomorphismEquivalenceRelation.
  Variable obj : Type.
  Variable mor : obj -> obj -> Type.
  Variable C : SpecializedCategory mor.
  Variable s d d' : C.

  Theorem CategoryIsomorphismComposition (m : C.(Morphism) s d) (m' : C.(Morphism) d d') :
    CategoryIsomorphism m -> CategoryIsomorphism m' -> CategoryIsomorphism (Compose m' m).
    repeat destruct 1; unfold InverseOf, InverseOf' in *; destruct_hypotheses;
      match goal with
        | [ m : Morphism _ _ _, m' : Morphism _ _ _ |- _ ] => exists (Compose m m')
        | [ m : mor _ _, m' : mor _ _ |- _ ] => exists (@Compose _ _ C _ _ _ m m')
      end;
      split;
        compose4associativity; t.
  Qed.
End CategoryIsomorphismEquivalenceRelation.

Section CategoryObjects1.
  Variable obj : Type.
  Variable mor : obj -> obj -> Type.
  Variable C : SpecializedCategory mor.

  Definition UniqueUpToUniqueIsomorphism' (P : C.(Object) -> Prop) : Prop :=
    forall o, P o -> forall o', P o' -> exists m : C.(Morphism) o o', IsCategoryIsomorphism m /\ is_unique m.

  Definition UniqueUpToUniqueIsomorphism (P : C.(Object) -> Type) :=
    forall o, P o -> forall o', P o' -> { m : C.(Morphism) o o' | IsCategoryIsomorphism m & is_unique m }.

  (* A terminal object is an object with a unique morphism from every other object. *)
  Definition TerminalObject' (o : C) : Prop :=
    forall o', exists! m : C.(Morphism) o' o, True.

  Definition TerminalObject (o : C) :=
    forall o', { m : C.(Morphism) o' o | is_unique m }.

  (* An initial object is an object with a unique morphism from every other object. *)
  Definition InitialObject' (o : C) : Prop :=
    forall o', exists! m : C.(Morphism) o o', True.

  Definition InitialObject (o : C) :=
    forall o', { m : C.(Morphism) o o' | is_unique m }.
End CategoryObjects1.

Arguments UniqueUpToUniqueIsomorphism' {obj mor} [C] P.
Arguments UniqueUpToUniqueIsomorphism {obj mor} [C] P.
Arguments InitialObject' {obj mor} [C] o.
Arguments InitialObject {obj mor} [C] o.
Arguments TerminalObject' {obj mor} [C] o.
Arguments TerminalObject {obj mor} [C] o.

Section CategoryObjects2.
  Variable obj : Type.
  Variable mor : obj -> obj -> Type.
  Variable C : SpecializedCategory mor.

  Hint Unfold TerminalObject InitialObject InverseOf.

  Ltac unique := hnf; intros; specialize_all_ways; destruct_sig;
    unfold is_unique, unique, uniqueness in *;
      repeat (destruct 1);
      repeat match goal with
               | [ x : _ |- _ ] => exists x
             end; eauto; try split; try solve [ etransitivity; eauto ].

  (* The terminal object is unique up to unique isomorphism. *)
  Theorem TerminalObjectUnique : UniqueUpToUniqueIsomorphism (@TerminalObject _ _ C).
    unique.
  Qed.

  (* The initial object is unique up to unique isomorphism. *)
  Theorem InitialObjectUnique : UniqueUpToUniqueIsomorphism (@InitialObject _ _ C).
    unique.
  Qed.
End CategoryObjects2.
