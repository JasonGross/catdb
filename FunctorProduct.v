Require Export ProductCategory Functor.
Require Import Common.

Set Implicit Arguments.

Generalizable All Variables.

Section FunctorProduct.
  Context `(C : @SpecializedCategory objC).
  Context `(D : @SpecializedCategory objD).
  Context `(C' : @SpecializedCategory objC').
  Context `(D' : @SpecializedCategory objD').
  Variable F : Functor C D.
  Variable F' : Functor C' D'.

  Polymorphic Definition FunctorProduct : SpecializedFunctor  (C * C') (D * D').
    match goal with
      | [ |- SpecializedFunctor ?C0 ?D0 ] =>
        refine (Build_SpecializedFunctor C0 D0
          (fun c'c : C * C' => (F (fst c'c), F' (snd c'c)) : D * D')
          (fun s d (m : Morphism (C * C') s d) => (F.(MorphismOf) (fst m), F'.(MorphismOf) (snd m)))
          _
          _
        )
    end;
    abstract (intros; simpl; simpl_eq; auto with functor).
  Defined.
End FunctorProduct.

Infix "*" := FunctorProduct : functor_scope.
