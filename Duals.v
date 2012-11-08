Require Import JMeq Eqdep.
Require Export SpecializedCategory CategoryIsomorphisms Functor ProductCategory NaturalTransformation.
Require Import Common Notations FEqualDep.

Set Implicit Arguments.

Generalizable All Variables.

Local Infix "==" := JMeq.

Local Open Scope category_scope.

Section OppositeCategory.
  Context `(C : @SpecializedCategory objC).

  Definition OppositeCategory : @SpecializedCategory objC :=
    @Build_SpecializedCategory' objC (fun s d => Morphism' C d s)
    (Identity' C)
    (fun _ _ _ m1 m2 => Compose' C _ _ _ m2 m1)
    (fun _ _ _ _ _ _ _ => Associativity'_sym C _ _ _ _ _ _ _)
    (fun _ _ _ _ _ _ _ => Associativity' C _ _ _ _ _ _ _)
    (fun _ _ => RightIdentity' C _ _)
    (fun _ _ => LeftIdentity' C _ _).
End OppositeCategory.

Section DualCategories.
  Context `(C : @SpecializedCategory objC).
  Context `(D : @SpecializedCategory objD).

  Lemma op_op_id : OppositeCategory (OppositeCategory C) = C.
    unfold OppositeCategory; simpl.
    repeat change (fun a => ?f a) with f.
    case C; simpl; reflexivity.
  Qed.

  Lemma op_distribute_prod : OppositeCategory (C * D) = (OppositeCategory C) * (OppositeCategory D).
    spcat_eq.
  Qed.
End DualCategories.

Hint Rewrite @op_op_id @op_distribute_prod : category.

Section DualObjects.
  Context `(C : @SpecializedCategory objC).

  Lemma initial_opposite_terminal (o : C) :
    InitialObject o -> TerminalObject (C := OppositeCategory C) o.
    t.
  Qed.

  Lemma terminal_opposite_initial (o : C) :
    TerminalObject o -> InitialObject (C := OppositeCategory C) o.
    t.
  Qed.
End DualObjects.

Section OppositeFunctor.
  Context `(C : @SpecializedCategory objC).
  Context `(D : @SpecializedCategory objD).
  Variable F : SpecializedFunctor C D.
  Let COp := OppositeCategory C.
  Let DOp := OppositeCategory D.

  Definition OppositeFunctor : SpecializedFunctor COp DOp.
    refine (Build_SpecializedFunctor COp DOp
      (fun c : COp => F c : DOp)
      (fun (s d : COp) (m : C.(Morphism) d s) => MorphismOf F (s := d) (d := s) m)
      (fun d' d s m1 m2 => FCompositionOf F s d d' m2 m1)
      (FIdentityOf F)
    ).
  Defined.
End OppositeFunctor.

Section OppositeFunctor_Id.
  Context `(C : @SpecializedCategory objC).
  Context `(D : @SpecializedCategory objD).
  Variable F : SpecializedFunctor C D.

  Lemma op_op_functor_id : OppositeFunctor (OppositeFunctor F) == F.
    functor_eq; autorewrite with category; trivial.
  Qed.
End OppositeFunctor_Id.

(* not terribly useful, given that this would make [autorewrite with core] give "Anomaly: Uncaught exception Failure("nth"). Please report." *)
(*Hint Rewrite op_op_functor_id.*)

Section OppositeNaturalTransformation.
  Context `(C : @SpecializedCategory objC).
  Context `(D : @SpecializedCategory objD).
  Variables F G : SpecializedFunctor C D.
  Variable T : SpecializedNaturalTransformation F G.
  Let COp := OppositeCategory C.
  Let DOp := OppositeCategory D.
  Let FOp := OppositeFunctor F.
  Let GOp := OppositeFunctor G.

  Definition OppositeNaturalTransformation : SpecializedNaturalTransformation GOp FOp.
    refine (Build_SpecializedNaturalTransformation GOp FOp
      (fun c : COp => T.(ComponentsOf) c : DOp.(Morphism) (GOp c) (FOp c))
      (fun s d m => eq_sym (Commutes T d s m))
    ).
  Defined.
End OppositeNaturalTransformation.

Section OppositeNaturalTransformation_Id.
  Context `(C : @SpecializedCategory objC).
  Context `(D : @SpecializedCategory objD).
  Variables F G : SpecializedFunctor C D.
  Variable T : SpecializedNaturalTransformation F G.

  Lemma op_op_nt_id : OppositeNaturalTransformation (OppositeNaturalTransformation T) == T.
    nt_eq; intros; try functor_eq; autorewrite with category; trivial.
  Qed.
End OppositeNaturalTransformation_Id.

(* not terribly useful, given that this would make [autorewrite with core] give "Anomaly: Uncaught exception Failure("nth"). Please report." *)
(*Hint Rewrite op_op_nt_id.*)
