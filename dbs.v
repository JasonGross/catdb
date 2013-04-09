Require Import List Setoid Classes.RelationClasses.

Set Implicit Arguments.


(** * Types *)

(** Every cell in a row has a [Type]; a row is an ordered list of cells *)
Definition RowType := list Type.

(** A [Column] is a fancy way of indexing into a [Row].  It's typed
    with the type of the relevant cell in the row, for convenience *)
Inductive Column (T : Type) : RowType -> Type :=
| CFirst : forall Ts, Column T (T :: Ts)
| CNext : forall T' Ts, Column T Ts -> Column T (T' :: Ts).

(** A [Row] is a list of cells, each cell having the type specified by the [RowType] *)
Inductive Row : RowType -> Type :=
| RNil : Row nil
| RCons : forall T Ts, T -> Row Ts -> Row (T :: Ts).

(** A [Table] of a particular [RowType] is a list of [Row]s of that type. *)
Definition Table (R : RowType) := list (Row R).
(* Might be nicer to use a multiset type instead of [list]. *)

(** A database is typed as a collection of [Table]s, each having a [RowType] *)
Definition DatabaseType := list RowType.

(** A [TableName] is a fancy way of indexing into a [Database]. *)
Inductive TableName (R : RowType) : DatabaseType -> Type :=
| TFirst : forall Rs, TableName R (R :: Rs)
| TNext : forall R' Rs, TableName R Rs -> TableName R (R' :: Rs).

(** A database is a list of tables *)
Inductive Database : DatabaseType -> Type :=
| DNil : Database nil
| DCons : forall R Rs, Table R -> Database Rs -> Database (R :: Rs).


(** * Operations *)

Definition RowHead T Ts (r : Row (T :: Ts)) : T :=
  match r with
    | RCons _ _ v _ => v
  end.

Definition RowTail T Ts (r : Row (T :: Ts)) : Row Ts :=
  match r with
    | RCons _ _ _ r' => r'
  end.

Lemma RowEta T Ts r : RCons (@RowHead T Ts r) (@RowTail T Ts r) = r.
  refine match r with
           | RCons _ _ v r' => _
         end.
  reflexivity.
Qed.

Fixpoint getColumn T R (c : Column T R) : Row R -> T :=
  match c with
    | CFirst _ => fun r => RowHead r
    | CNext _ _ c' => fun r => getColumn c' (RowTail r)
  end.

Definition DatabaseHead R Rs (d : Database (R :: Rs)) : Table R :=
  match d with
    | DCons _ _ r _ => r
  end.

Definition DatabaseTail R Rs (d : Database (R :: Rs)) : Database Rs :=
  match d with
    | DCons _ _ _ d' => d'
  end.

Fixpoint getTable R Rs (tn : TableName R Rs) : Database Rs -> Table R :=
  match tn with
    | TFirst _ => fun d => DatabaseHead d
    | TNext _ _ tn' => fun d => getTable tn' (DatabaseTail d)
  end.

(** A [ColumnList] on an [r : RowType] is a list of columns in [r];
    the types of these columns gives a new [RowType], which must be
    passed as the second parameter to this type. *)
Inductive ColumnList : RowType -> RowType -> Type :=
| CNil : ColumnList nil nil
| CCons : forall T fromTs toTs, Column T fromTs -> ColumnList fromTs toTs -> ColumnList fromTs (T :: toTs).

(** [SelectFromTable fromR toR cs] is the SQL query [SELECT cs FROM
    fromR], and [toR] is the resulting schema.  This operation is
    specific to a single table. *)
Fixpoint SelectFromTable fromR toR (cs : ColumnList fromR toR) : Row fromR -> Row toR
  := match cs in (ColumnList fromR toR) return (Row fromR -> Row toR) with
       | CNil =>
         fun r => r
       | CCons T fromTs toTs c cs' =>
         fun r => RCons (getColumn c r) (SelectFromTable cs' r)
     end.

(** [UnionAllTables2 r t1 t2] is the SQL query [SELECT *
    FROM t1 UNION ALL SELECT * FROM t2]. *)
Definition UnionAllTables2 (r : RowType) (t1 t2 : Table r) : Table r
  := t1 ++ t2.

(** [UnionAllTables r [t1, t2, ..., tn]] is the SQL query [SELECT *
    FROM t1 UNION ALL SELECT * FROM t2 UNION ALL ... UNION ALL SELECT
    * FROM tn]. *)
Definition UnionAllTables (r : RowType) (ts : list (Table r)) : Table r
  := match ts with
       | nil => nil
       | t :: ts => fold_left (@UnionAllTables2 r) ts t
     end.

Lemma RNil_unique : forall x : Row nil, x = RNil.
  intros; refine (match x in Row Ts return match Ts return Row Ts -> Prop with
                                             | nil => fun x => x = RNil
                                             | _ => fun _ => True
                                           end x with
                    | RNil => eq_refl
                    | _ => I
                  end).
Qed.

Lemma RowNil_unique : forall x y : Row nil, x = y.
  intros x y.
  rewrite (RNil_unique x).
  rewrite (RNil_unique y).
  reflexivity.
Qed.

Local Hint Immediate RowNil_unique.

(** Equality of rows is decidable if equality of all constituent types
    is decidable. *)
Inductive RowTypeDecidable (P : forall T, relation T) `(forall T, Equivalence (P T))
: RowType -> Type :=
| RTDecNil : RowTypeDecidable P _ nil
| RTDecCons : forall T Ts, (forall t0 t1 : T,
                              {P T t0 t1} + {~P T t0 t1})
                           -> RowTypeDecidable P _ Ts
                           -> RowTypeDecidable P _ (T :: Ts).

Definition RowTypeDecHead P H T Ts (r : RowTypeDecidable P H (T :: Ts))
: forall t0 t1 : T, {P T t0 t1} + {~ P T t0 t1} :=
  match r with
    | RTDecCons _ _ v _ => v
  end.

Definition RowTypeDecTail P H T Ts (r : RowTypeDecidable P H (T :: Ts))
: RowTypeDecidable P H Ts :=
  match r with
    | RTDecCons _ _ _ r' => r'
  end.

Lemma RowTypeDecidableEta P H T Ts (r : RowTypeDecidable P H (T :: Ts))
: RTDecCons (@RowTypeDecHead P H T Ts r) (@RowTypeDecTail P H T Ts r) = r.
  refine match r with
           | RTDecCons _ _ v r' => _
         end.
  reflexivity.
Qed.

Lemma Cons_not_eq
: forall T Ts (h1 : T) (t1 : Row Ts) h2 t2,
    (h1 <> h2 \/ t1 <> t2)
    -> RCons h1 t1 <> RCons h2 t2.
  intuition;
  match goal with
    | [ H : RCons _ _ = RCons _ _ |- _ ] => (apply (f_equal (@RowHead _ _)) in H; tauto)
                                              || (apply (f_equal (@RowTail _ _)) in H; tauto)
  end.
Qed.

Hint Resolve Cons_not_eq.

Fixpoint Row_eq Ts
: RowTypeDecidable (@eq) _ Ts -> forall r1 r2 : Row Ts, {r1 = r2} + {r1 <> r2}.
Proof.
  refine match Ts return RowTypeDecidable _ _ Ts -> forall r1 r2 : Row Ts, {r1 = r2} + {r1 <> r2} with
           | nil => fun _ _ _ => left _
           | _ :: Ts' => fun D r1 r2 =>
                           if (RowTypeDecHead D) (RowHead r1) (RowHead r2)
                           then if Row_eq _ (RowTypeDecTail D) (RowTail r1) (RowTail r2)
                                then left _
                                else right _
                           else right _
         end;
  clear Row_eq;
  abstract (repeat match goal with
                     | [ r : Row nil |- _ ] => (generalize (RNil_unique r); intro; subst)
                     | [ r : Row (_ :: _) |- _ ] => progress (rewrite <- (RowEta r) in *; simpl in *; idtac)
                   end; auto; congruence).
Defined.

(** If a type has decidable equality, so does [In] *)
Fixpoint In_dec A (eq_dec : forall x y : A, {x = y} + {x <> y}) (l : list A)
: forall x, {In x l} + {~In x l}
  := match l as l return forall x, {In x l} + {~In x l} with
       | nil
         => fun _ => right (fun x : False => match x with end)
       | b :: m
         => fun x
            => match eq_dec b x with
                 | left H
                   => left (or_introl H)
                 | right not_eq
                   => match In_dec eq_dec m x with
                        | left H
                          => left (or_intror H)
                        | right not_in
                          => right (fun H'
                                    => match H' return False with
                                         | or_introl H''
                                           => not_eq H''
                                         | or_intror H''
                                           => not_in H''
                                       end)
                      end
               end
     end.

(** Takes in a list, and returns the list of unique elements in that list *)
Fixpoint unique_from A (eq_dec : forall x y : A, {x = y} + {x <> y})
         (l : list A) : list A :=
  match l with
    | nil => nil
    | b :: t => if In_dec eq_dec t b
                then unique_from eq_dec t
                else b :: unique_from eq_dec t
  end.
Arguments unique_from _ _ !l / .

Inductive list_duplicate_free A : list A -> Prop :=
| nil_duplicate_free : list_duplicate_free nil
| cons_duplicate_free : forall x l, list_duplicate_free l -> ~In x l -> list_duplicate_free (x :: l).

Lemma unique_no_change_in A (l : list A) eq_dec
: forall x, In x l <-> In x (@unique_from  A eq_dec l).
  intro x; split; intro;
  induction l;
  repeat match goal with
           | _ => easy
           | _ => solve [ intuition ]
           | _ => solve [ exfalso; intuition ]
           | [ H : _ \/ _ |- _ ] => destruct H
           | _ => progress (simpl in *; subst)
           | [ H : appcontext[match ?E with _ => _ end] |- _ ] => destruct E
           | [ |- appcontext[match ?E with _ => _ end] ] => destruct E
         end.
Qed.

Lemma unique_from_no_duplicates A (l : list A) eq_dec
: list_duplicate_free l -> @unique_from A eq_dec l = l.
  intro H.
  induction H; [ reflexivity | ].
  simpl.
  match goal with
    | [ |- appcontext[match ?E with _ => _ end] ] => destruct E
  end;
    try solve [ exfalso; abstract intuition ].
  f_equal.
  assumption.
Qed.

Lemma no_duplicates_unique_from A (l : list A) eq_dec
: list_duplicate_free (@unique_from A eq_dec l).
  induction l; [ simpl; constructor | ].
  repeat match goal with
           | _ => progress simpl in *
           | _ => assumption
           | [ |- appcontext[match ?E with _ => _ end] ] => destruct E
           | _ => intro
           | _ => progress intuition
           | _ => constructor
           | [ H : _ |- _ ] => apply <- unique_no_change_in in H
         end.
Qed.

(** [UnionTables2 r t1 t2] is the SQL query [SELECT *
    FROM t1 UNION SELECT * FROM t2]; it removes duplicates *)
Definition UnionTables2 (r : RowType) (H : RowTypeDecidable _ _ r) (t1 t2 : Table r) : Table r
  := unique_from (Row_eq H) (UnionAllTables2 t1 t2).

(** [UnionTables r [t1, t2, ..., tn]] is the SQL query [SELECT * FROM
    t1 UNION SELECT * FROM t2 UNION ... UNION SELECT * FROM tn].  It
    removes duplicates. *)
Definition UnionTables (r : RowType) (H : RowTypeDecidable _ _ r) (ts : list (Table r)) : Table r
  := unique_from (Row_eq H) (UnionAllTables ts).
