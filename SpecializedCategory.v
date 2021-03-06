Require Import JMeq ProofIrrelevance.
Require Export Notations.
Require Import Common StructureEquality FEqualDep.

Set Implicit Arguments.

Generalizable All Variables.

Set Asymmetric Patterns.

Set Universe Polymorphism.

Local Infix "==" := JMeq.

Record SpecializedCategory (obj : Type) :=
  Build_SpecializedCategory' {
      Object :> _ := obj;
      Morphism : obj -> obj -> Type;

      Identity : forall x, Morphism x x;
      Compose : forall s d d', Morphism d d' -> Morphism s d -> Morphism s d';

      Associativity : forall o1 o2 o3 o4
                             (m1 : Morphism o1 o2)
                             (m2 : Morphism o2 o3)
                             (m3 : Morphism o3 o4),
                        Compose (Compose m3 m2) m1 = Compose m3 (Compose m2 m1);
      (* ask for [eq_sym (Associativity ...)], so that C^{op}^{op} is convertible with C *)
      Associativity_sym : forall o1 o2 o3 o4
                                 (m1 : Morphism o1 o2)
                                 (m2 : Morphism o2 o3)
                                 (m3 : Morphism o3 o4),
                            Compose m3 (Compose m2 m1) = Compose (Compose m3 m2) m1;
      LeftIdentity : forall a b (f : Morphism a b), Compose (Identity b) f = f;
      RightIdentity : forall a b (f : Morphism a b), Compose f (Identity a) = f
    }.

Bind Scope category_scope with SpecializedCategory.
Bind Scope object_scope with Object.
Bind Scope morphism_scope with Morphism.

Arguments Object {obj%type} C%category / : rename.
Arguments Morphism {obj%type} !C%category s d : rename. (* , simpl nomatch. *)
Arguments Identity {obj%type} [!C%category] x%object : rename.
Arguments Compose {obj%type} [!C%category s%object d%object d'%object] m1%morphism m2%morphism : rename.

Section SpecializedCategoryInterface.
  Definition Build_SpecializedCategory (obj : Type)
             (Morphism : obj -> obj -> Type)
             (Identity' : forall o : obj, Morphism o o)
             (Compose' : forall s d d' : obj, Morphism d d' -> Morphism s d -> Morphism s d')
             (Associativity' : forall (o1 o2 o3 o4 : obj) (m1 : Morphism o1 o2) (m2 : Morphism o2 o3) (m3 : Morphism o3 o4),
                                 Compose' o1 o2 o4 (Compose' o2 o3 o4 m3 m2) m1 = Compose' o1 o3 o4 m3 (Compose' o1 o2 o3 m2 m1))
             (LeftIdentity' : forall (a b : obj) (f : Morphism a b), Compose' a b b (Identity' b) f = f)
             (RightIdentity' : forall (a b : obj) (f : Morphism a b), Compose' a a b f (Identity' a) = f)
  : @SpecializedCategory obj
    := @Build_SpecializedCategory' obj
                                   Morphism
                                   Identity'
                                   Compose'
                                   Associativity'
                                   (fun _ _ _ _ _ _ _ => eq_sym (Associativity' _ _ _ _ _ _ _))
                                   LeftIdentity'
                                   RightIdentity'.
End SpecializedCategoryInterface.

(* create a hint db for all category theory things *)
Create HintDb category discriminated.
(* create a hint db for morphisms in categories *)
Create HintDb morphism discriminated.

Hint Extern 1 => symmetry : category morphism. (* TODO(jgross): Why do I need this? *)

Ltac spcategory_hideProofs :=
  repeat match goal with
             | [ |- context[{|
                               Associativity := ?pf0;
                               Associativity_sym := ?pf1;
                               LeftIdentity := ?pf2;
                               RightIdentity := ?pf3
                             |}] ] =>
               hideProofs pf0 pf1 pf2 pf3
         end.

Hint Resolve @LeftIdentity @RightIdentity @Associativity : category morphism.
Hint Rewrite @LeftIdentity @RightIdentity : category.
Hint Rewrite @LeftIdentity @RightIdentity : morphism.

(* eh, I'm not terribly happy.  meh. *)
Definition LocallySmallSpecializedCategory (obj : Type) (*mor : obj -> obj -> Set*) := SpecializedCategory obj.
Definition SmallSpecializedCategory (obj : Set) (*mor : obj -> obj -> Set*) := SpecializedCategory obj.
Identity Coercion LocallySmallSpecializedCategory_SpecializedCategory_Id : LocallySmallSpecializedCategory >-> SpecializedCategory.
Identity Coercion SmallSpecializedCategory_LocallySmallSpecializedCategory_Id : SmallSpecializedCategory >-> SpecializedCategory.

Section Categories_Equal.
  Lemma SpecializedCategory_contr_eq' `(C : @SpecializedCategory objC) `(D : @SpecializedCategory objC)
        (C_morphism_proof_irrelevance
         : forall s d (m1 m2 : Morphism C s d) (pf1 pf2 : m1 = m2),
             pf1 = pf2)
  : forall (HM : @Morphism _ C = @Morphism _ D),
      match HM in (_ = y) return (forall x : objC, y x x) with
        | eq_refl => Identity (C := C)
      end = Identity (C := D)
      -> match
        HM in (_ = y) return (forall s d d' : objC, y d d' -> y s d -> y s d')
      with
        | eq_refl => Compose (C := C)
      end = Compose (C := D)
      -> C = D.
    intros.
    destruct C, D;
      subst_body;
      intros;
      simpl in *.
    subst.
    repeat f_equal;
      repeat (apply functional_extensionality_dep; intro);
      trivial.
  Qed.

  Lemma SpecializedCategory_contr_eq `(C : @SpecializedCategory objC) `(D : @SpecializedCategory objC)
        (C_morphism_proof_irrelevance
         : forall s d (m1 m2 : Morphism C s d) (pf1 pf2 : m1 = m2),
             pf1 = pf2)
        (C_morphism_type_contr
         : forall s d (pf1 pf2 : Morphism C s d = Morphism C s d),
             pf1 = pf2)
  : forall (HM : forall s d, @Morphism _ C s d = @Morphism _ D s d),
      (forall x,
         match HM x x in (_ = y) return y with
           | eq_refl => Identity (C := C) x
         end = Identity (C := D) x)
      -> (forall s d d' (m : Morphism D d d') (m' : Morphism D s d),
            match HM s d' in (_ = y) return y with
              | eq_refl =>
                match HM s d in (_ = y) return (y -> Morphism C s d') with
                  | eq_refl =>
                    match
                      HM d d' in (_ = y) return (y -> Morphism C s d -> Morphism C s d')
                    with
                      | eq_refl => Compose (d':=d')
                    end m
                end m'
            end = Compose m m')
      -> C = D.
    intros HM HI HC.
    assert (HM' : @Morphism _ C = @Morphism _ D)
      by (repeat (apply functional_extensionality_dep; intro); trivial).
    apply (SpecializedCategory_contr_eq' _ _ C_morphism_proof_irrelevance HM');
      revert HI HC C_morphism_proof_irrelevance C_morphism_type_contr;
      destruct C, D; simpl in *; clear;
      intros;
      subst_body;
      simpl in *;
      repeat (subst || intro || apply functional_extensionality_dep);
      rewrite_rev_hyp;
      generalize_eq_match;
      subst_eq_refl_dec;
      trivial.
  Qed.

  Lemma SpecializedCategory_eq `(C : @SpecializedCategory objC) `(D : @SpecializedCategory objC) :
    @Morphism _ C = @Morphism _ D
    -> @Identity _ C == @Identity _ D
    -> @Compose _ C == @Compose _ D
    -> C = D.
    intros.
    destruct_head @SpecializedCategory;
    simpl in *; repeat subst;
    f_equal; apply proof_irrelevance.
  Qed.

  Lemma SpecializedCategory_JMeq `(C : @SpecializedCategory objC) `(D : @SpecializedCategory objD) :
    objC = objD
    -> @Morphism _ C == @Morphism _ D
    -> @Identity _ C == @Identity _ D
    -> @Compose _ C == @Compose _ D
    -> C == D.
    intros; destruct_head @SpecializedCategory;
    simpl in *; repeat subst; JMeq_eq;
    f_equal; apply proof_irrelevance.
  Qed.
End Categories_Equal.

Ltac spcat_eq_step_with tac :=
  structures_eq_step_with_tac ltac:(apply SpecializedCategory_eq || apply SpecializedCategory_JMeq) tac.

Ltac spcat_eq_with tac := repeat spcat_eq_step_with tac.

Ltac spcat_eq_step := spcat_eq_step_with idtac.
Ltac spcat_eq := spcategory_hideProofs; spcat_eq_with idtac.

Ltac solve_for_identity :=
  match goal with
    | [ |- @Compose _ ?C ?s ?s ?d ?a ?b = ?b ]
      => cut (a = @Identity _ C s);
        [ try solve [ let H := fresh in intro H; rewrite H; apply LeftIdentity ] | ]
    | [ |- @Compose _ ?C ?s ?d ?d ?a ?b = ?a ]
      => cut (b = @Identity _ C d );
        [ try solve [ let H := fresh in intro H; rewrite H; apply RightIdentity ] | ]
  end.

(** * Version of [Associativity] that avoids going off into the weeds in the presence of unification variables *)

Definition NoEvar T (_ : T) := True.

Lemma AssociativityNoEvar `(C : @SpecializedCategory obj) : forall (o1 o2 o3 o4 : C) (m1 : C.(Morphism) o1 o2)
  (m2 : C.(Morphism) o2 o3) (m3 : C.(Morphism) o3 o4),
  NoEvar (m1, m2) \/ NoEvar (m2, m3) \/ NoEvar (m1, m3)
  -> Compose (Compose m3 m2) m1 = Compose m3 (Compose m2 m1).
  intros; apply Associativity.
Qed.

Ltac noEvar := match goal with
                 | [ |- context[NoEvar ?X] ] => (has_evar X; fail 1)
                                                  || cut (NoEvar X); [ intro; tauto | constructor ]
               end.

Hint Rewrite @AssociativityNoEvar using noEvar : category.
Hint Rewrite @AssociativityNoEvar using noEvar : morphism.

Ltac try_associativity_quick tac := try_rewrite Associativity tac.
Ltac try_associativity tac := try_rewrite_by AssociativityNoEvar ltac:(idtac; noEvar) tac.

Ltac find_composition_to_identity :=
  match goal with
    | [ H : @Compose _ _ _ _ _ ?a ?b = @Identity _ _ _ |- context[@Compose ?A ?B ?C ?D ?E ?c ?d] ]
      => let H' := fresh in
        assert (H' : b = d /\ a = c) by (split; reflexivity); clear H';
          assert (H' : @Compose A B C D E c d = @Identity _ _ _) by (
            exact H ||
              (unfold Object; simpl in H |- *; exact H || (rewrite H; reflexivity))
          );
          first [
            rewrite H'
            | simpl in H' |- *; rewrite H'
            | let H'T := type of H' in fail 2 "error in rewriting a found identity" H "[" H'T "]"
          ]; clear H'
  end.

(** * Back to the main content.... *)

Section Category.
  Context `(C : @SpecializedCategory objC).

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
  Definition IsEpimorphism x y (m : C.(Morphism) x y) : Prop :=
    forall z (m1 m2 : C.(Morphism) y z), Compose m1 m = Compose m2 m ->
      m1 = m2.
  Definition IsMonomorphism x y (m : C.(Morphism) x y) : Prop :=
    forall z (m1 m2 : C.(Morphism) z x), Compose m m1 = Compose m m2 ->
      m1 = m2.

  Section properties.
    Lemma IdentityIsEpimorphism x : IsEpimorphism _ _ (Identity x).
      repeat intro; autorewrite with category in *; trivial.
    Qed.

    Lemma IdentityIsMonomorphism x : IsMonomorphism _ _ (Identity x).
      repeat intro; autorewrite with category in *; trivial.
    Qed.

    Lemma EpimorphismComposition s d d' m0 m1 :
      IsEpimorphism _ _ m0
      -> IsEpimorphism _ _ m1
      -> IsEpimorphism _ _ (Compose (C := C) (s := s) (d := d) (d' := d') m0 m1).
      repeat intro.
      repeat match goal with | [ H : _ |- _ ] => rewrite <- Associativity in H end.
      intuition.
    Qed.

    Lemma MonomorphismComposition s d d' m0 m1 :
      IsMonomorphism _ _ m0
      -> IsMonomorphism _ _ m1
      -> IsMonomorphism _ _ (Compose (C := C) (s := s) (d := d) (d' := d') m0 m1).
      repeat intro.
      repeat match goal with | [ H : _ |- _ ] => rewrite Associativity in H end.
      intuition.
    Qed.
  End properties.
End Category.

Hint Immediate @IdentityIsEpimorphism @IdentityIsMonomorphism @MonomorphismComposition @EpimorphismComposition : category morphism.

Arguments IsEpimorphism {objC} [C x y] m.
Arguments IsMonomorphism {objC} [C x y] m.

Section AssociativityComposition.
  Context `(C : @SpecializedCategory obj).
  Variables o0 o1 o2 o3 o4 : C.

  Lemma compose4associativity_helper
    (a : Morphism C o3 o4) (b : Morphism C o2 o3)
    (c : Morphism C o1 o2) (d : Morphism C o0 o1) :
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
