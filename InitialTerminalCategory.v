Require Export SpecializedCategory Functor.
Require Import Common Notations NatCategory.

Set Implicit Arguments.

Generalizable All Variables.

Section InitialTerminal.
   Definition InitialCategory : SmallSpecializedCategory _ := 0.
   Definition TerminalCategory : SmallSpecializedCategory _ := 1.
End InitialTerminal.

Section Functors.
  Context `(C : SpecializedCategory objC).

  Definition FunctorTo1 : SpecializedFunctor C 1
    := Build_SpecializedFunctor C 1 (fun _ => tt) (fun _ _ _ => eq_refl) (fun _ _ _ _ _ => eq_refl) (fun _ => eq_refl).
  Definition FunctorToTerminal : SpecializedFunctor C TerminalCategory := FunctorTo1.

  Definition FunctorFrom1 (c : C) : SpecializedFunctor 1 C
    := Build_SpecializedFunctor 1 C (fun _ => c) (fun _ _ _ => Identity c) (fun _ _ _ _ _ => eq_sym (@RightIdentity _ _ _ _ _ _)) (fun _ => eq_refl).
  Definition FunctorFromTerminal (c : C) : SpecializedFunctor TerminalCategory C := FunctorFrom1 c.

  Definition FunctorFrom0 : SpecializedFunctor 0 C
    := Build_SpecializedFunctor 0 C (fun x => match x with end) (fun x _ _ => match x with end) (fun x _ _ _ _ => match x with end) (fun x => match x with end).
  Definition FunctorFromInitial : SpecializedFunctor InitialCategory C := FunctorFrom0.
End Functors.
