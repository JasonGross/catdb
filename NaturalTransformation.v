Require Import JMeq ProofIrrelevance.
Require Export Notations Functor.
Require Import Common StructureEquality FEqualDep.

Set Implicit Arguments.

Generalizable All Variables.

Local Infix "==" := JMeq.

Section SpecializedNaturalTransformation.
  Context `(C : @SpecializedCategory objC).
  Context `(D : @SpecializedCategory objD).
  Variables F G : SpecializedFunctor C D.

  (**
     Quoting from the lecture notes for 18.705, Commutative Algebra:

     A map of functors is known as a natural transformation. Namely, given two functors
     [F : C -> D], [G : C -> D], a natural transformation [T: F -> G] is a collection of maps
     [T A : F A -> G A], one for each object [A] of [C], such that [(T B) ○ (F m) = (G m) ○ (T A)]
     for every map [m : A -> B] of [C]; that is, the following diagram is commutative:

           F m
     F A -------> F B
      |            |
      |            |
      | T A        | T B
      |            |
      V    G m     V
     G A --------> G B
     **)
  Record SpecializedNaturalTransformation := {
    ComponentsOf' : forall c, D.(Morphism') (F.(ObjectOf') c) (G.(ObjectOf') c);
    Commutes' : forall s d (m : C.(Morphism') s d),
      D.(Compose') _ _ _ (ComponentsOf' d) (F.(MorphismOf') _ _ m) = D.(Compose') _ _ _ (G.(MorphismOf') _ _ m) (ComponentsOf' s)
  }.
End SpecializedNaturalTransformation.

Bind Scope natural_transformation_scope with SpecializedNaturalTransformation.

Section NaturalTransformationInterface.
  Context `(C : @SpecializedCategory objC).
  Context `(D : @SpecializedCategory objD).
  Variables F G : SpecializedFunctor C D.

  Variable T : SpecializedNaturalTransformation F G.

  Definition ComponentsOf : forall c : C, D.(Morphism) (F c) (G c) := Eval cbv beta delta [ComponentsOf'] in T.(ComponentsOf').
  Definition Commutes : forall (s d : C) (m : C.(Morphism) s d),
    Compose (ComponentsOf d) (F.(MorphismOf) m) = Compose (G.(MorphismOf) m) (ComponentsOf s)
    := T.(Commutes').
End NaturalTransformationInterface.

Arguments ComponentsOf {objC C objD D F G} T c : simpl nomatch.
Global Coercion ComponentsOf : SpecializedNaturalTransformation >-> Funclass.

Section NaturalTransformation.
  Variable C D : Category.
  Variable F G : Functor C D.

  Definition NaturalTransformation := SpecializedNaturalTransformation F G.
End NaturalTransformation.

Bind Scope natural_transformation_scope with NaturalTransformation.

Identity Coercion NaturalTransformation_SpecializedNaturalTransformation_Id : NaturalTransformation >-> SpecializedNaturalTransformation.
Definition GeneralizeNaturalTransformation `(T : @SpecializedNaturalTransformation objC C objD D F G) :
  NaturalTransformation F G := T.
Global Coercion GeneralizeNaturalTransformation : SpecializedNaturalTransformation >-> NaturalTransformation.

Arguments GeneralizeNaturalTransformation [objC C objD D F G] T /.
Hint Extern 0 => unfold GeneralizeNaturalTransformation.
Ltac fold_NT :=
  change @SpecializedNaturalTransformation with
    (fun objC (C : SpecializedCategory objC) objD (D : SpecializedCategory objD) => @NaturalTransformation C D) in *; simpl in *.

Arguments Commutes [objC C objD D F G] T _ _ _.

Hint Resolve @Commutes @Commutes'.

Ltac present_spnt := present_spcategory; present_spfunctor;
  present_obj_obj @ComponentsOf' @ComponentsOf(*;
  repeat match goal with
           | [ H : appcontext[@ObjectOf (@Object ?obj ?mor ?C)] |- _ ] => change (@Object obj mor C) with obj in H
           | [ H : appcontext[@ObjectOf _ _ (@Object ?obj ?mor ?C)] |- _ ] => change (@Object obj mor C) with obj in H
           | [ |- appcontext[@ObjectOf (@Object ?obj ?mor ?C)] ] => change (@Object obj mor C) with obj
           | [ |- appcontext[@ObjectOf _ _ (@Object ?obj ?mor ?C)] ] => change (@Object obj mor C) with obj
           | [ H : appcontext[@MorphismOf (@Object ?obj ?mor ?C)] |- _ ] => change (@Object obj mor C) with obj in H
           | [ H : appcontext[@MorphismOf _ _ (@Object ?obj ?mor ?C)] |- _ ] => change (@Object obj mor C) with obj in H
           | [ |- appcontext[@MorphismOf (@Object ?obj ?mor ?C)] ] => change (@Object obj mor C) with obj
           | [ |- appcontext[@MorphismOf _ _ (@Object ?obj ?mor ?C)] ] => change (@Object obj mor C) with obj
         end*).

Section NaturalTransformations_Equal.
  Lemma NaturalTransformations_Equal objC C objD D F G :
    forall (T U : @SpecializedNaturalTransformation objC C objD D F G),
    ComponentsOf T = ComponentsOf U
    -> T = U.
    destruct T, U; simpl; intros; repeat subst;
      f_equal; apply proof_irrelevance.
  Qed.

  Lemma NaturalTransformations_JMeq objC C objD D objC' C' objD' D' :
    forall F G F' G'
      (T : @SpecializedNaturalTransformation objC C objD D F G) (U : @SpecializedNaturalTransformation objC' C' objD' D' F' G'),
      objC = objC'
      -> objD = objD'
      -> (objC = objC' -> C == C')
      -> (objD = objD' -> D == D')
      -> (objC = objC' -> C == C' ->
        objD = objD' -> D == D' ->
        F == F')
      -> (objC = objC' -> C == C' ->
        objD = objD' -> D == D' ->
        G == G')
      -> (objC = objC' -> C == C' ->
        objD = objD' -> D == D' ->
        F == F' -> G == G' -> ComponentsOf T == ComponentsOf U)
      -> T == U.
    simpl; intros; intuition; destruct T, U; simpl in *; repeat subst;
      JMeq_eq.
    f_equal; apply proof_irrelevance.
  Qed.
End NaturalTransformations_Equal.

Ltac nt_eq_step_with tac :=
  structures_eq_step_with_tac ltac:(apply NaturalTransformations_Equal || apply NaturalTransformations_JMeq) tac.

Ltac nt_eq_with tac := repeat nt_eq_step_with tac.

Ltac nt_eq_step := nt_eq_step_with idtac.
Ltac nt_eq := nt_eq_with idtac.

Section NaturalTransformationComposition.
  Context `(C : @SpecializedCategory objC).
  Context `(D : @SpecializedCategory objD).
  Context `(E : @SpecializedCategory objE).
  Variables F F' F'' : SpecializedFunctor C D.
  Variables G G' : SpecializedFunctor D E.

  Hint Resolve @Commutes f_equal f_equal2.
  Hint Rewrite @Associativity.

  (*
     We have the diagram
          F
     C -------> D
          |
          |
          | T
          |
          V
     C -------> D
          F'
          |
          | T'
          |
          V
     C ------> D
          F''

     And we want the commutative diagram
           F m
     F A -------> F B
      |            |
      |            |
      | T A        | T B
      |            |
      V    F' m    V
     F' A -------> F' B
      |            |
      |            |
      | T' A       | T' B
      |            |
      V    F'' m   V
     F'' A ------> F'' B

  *)

  Definition NTComposeT (T' : SpecializedNaturalTransformation F' F'') (T : SpecializedNaturalTransformation F F') :
    SpecializedNaturalTransformation F F''.
    refine {| ComponentsOf' := (fun c => Compose (T' c) (T c)) |};
    (* XXX TODO: Find a way to get rid of [m] in the transitivity call *)
      abstract (intros; transitivity (Compose (T' _) (Compose (MorphismOf F' m) (T _))); try_associativity eauto).
  Defined.

  (*
     We have the diagram
          F          G
     C -------> D -------> E
          |          |
          |          |
          | T        | U
          |          |
          V          V
     C -------> D -------> E
          F'         G'

     And we want the commutative diagram
             G (F m)
     G (F A) -------> G (F B)
        |                |
        |                |
        | U (T A)        | U (T B)
        |                |
        V     G' (F' m)  V
     G' (F' A) -----> G' (F' B)

  *)
  (* XXX TODO: Automate this better *)

  Hint Rewrite @Commutes.
  Hint Resolve f_equal2.
  Hint Extern 1 (_ = _) => apply @FCompositionOf.

  Lemma FCompositionOf2 : forall `(C : @SpecializedCategory objC) `(D : @SpecializedCategory objD)
    (F : SpecializedFunctor C D) x y z u (m1 : C.(Morphism) x z) (m2 : C.(Morphism) y x) (m3 : D.(Morphism) u _),
    Compose (MorphismOf F m1) (Compose (MorphismOf F m2) m3) = Compose (MorphismOf F (Compose m1 m2)) m3.
    intros; symmetry; try_associativity eauto.
  Qed.

  Hint Rewrite @FCompositionOf2.

  Definition NTComposeF (U : SpecializedNaturalTransformation G G') (T : SpecializedNaturalTransformation F F'):
    SpecializedNaturalTransformation (ComposeFunctors G F) (ComposeFunctors G' F').
    refine (Build_SpecializedNaturalTransformation (ComposeFunctors G F) (ComposeFunctors G' F')
      (fun c => Compose (G'.(MorphismOf) (T c)) (U (F c)))
      _);
    abstract (
      simpl; intros; autorewrite with core;
        repeat rewrite <- Associativity;
          repeat rewrite <- @FCompositionOf;
            rewrite @Commutes;
              reflexivity
    ).
  Defined.
End NaturalTransformationComposition.

Section IdentityNaturalTransformation.
  Context `(C : @SpecializedCategory objC).
  Context `(D : @SpecializedCategory objD).
  Variable F : SpecializedFunctor C D.

  (* There is an identity natrual transformation. *)
  Definition IdentityNaturalTransformation : SpecializedNaturalTransformation F F.
    refine {| ComponentsOf' := (fun c => Identity (F c))
      |};
    abstract t.
  Defined.

  Hint Resolve @LeftIdentity @RightIdentity.

  Lemma LeftIdentityNaturalTransformation (F' : SpecializedFunctor C D) (T : SpecializedNaturalTransformation F' F) :
    NTComposeT IdentityNaturalTransformation T = T.
    nt_eq; auto.
  Qed.

  Lemma RightIdentityNaturalTransformation (F' : SpecializedFunctor C D) (T : SpecializedNaturalTransformation F F') :
    NTComposeT T IdentityNaturalTransformation = T.
    nt_eq; auto.
  Qed.
End IdentityNaturalTransformation.

Hint Rewrite @LeftIdentityNaturalTransformation @RightIdentityNaturalTransformation.

Section Associativity.
  Context `(B : @SpecializedCategory objB).
  Context `(C : @SpecializedCategory objC).
  Context `(D : @SpecializedCategory objD).
  Context `(E : @SpecializedCategory objE).
  Variable F : SpecializedFunctor D E.
  Variable G : SpecializedFunctor C D.
  Variable H : SpecializedFunctor B C.

  Let F0 := ComposeFunctors (ComposeFunctors F G) H.
  Let F1 := ComposeFunctors F (ComposeFunctors G H).

  Definition ComposeFunctorsAssociator1 : SpecializedNaturalTransformation F0 F1.
    refine (Build_SpecializedNaturalTransformation F0 F1
      (fun _ => Identity (C := E) _)
      _
    ); simpl; abstract t.
  Defined.

  Definition ComposeFunctorsAssociator2 : SpecializedNaturalTransformation F1 F0.
    refine (Build_SpecializedNaturalTransformation F1 F0
      (fun _ => Identity (C := E) _)
      _
    ); simpl; abstract t.
  Defined.
End Associativity.
