Require Import Coq.Lists.List.
Require Import Coq.omega.Omega.
Require Import Coq.Arith.Peano_dec.
Require Import Coq.Classes.Morphisms.
Require Import Crypto.Tactics.VerdiTactics.
Require Import Coq.Numbers.Natural.Peano.NPeano.
Require Import Crypto.Util.NatUtil.

Create HintDb distr_length discriminated.
Create HintDb simpl_set_nth discriminated.
Create HintDb simpl_update_nth discriminated.
Create HintDb simpl_nth_default discriminated.
Create HintDb simpl_nth_error discriminated.
Create HintDb simpl_firstn discriminated.
Create HintDb simpl_skipn discriminated.
Create HintDb simpl_fold_right discriminated.
Create HintDb simpl_sum_firstn discriminated.
Create HintDb pull_nth_error discriminated.
Create HintDb push_nth_error discriminated.
Create HintDb pull_nth_default discriminated.
Create HintDb push_nth_default discriminated.
Create HintDb pull_firstn discriminated.
Create HintDb push_firstn discriminated.
Create HintDb pull_update_nth discriminated.
Create HintDb push_update_nth discriminated.

Hint Rewrite
  @app_length
  @rev_length
  @map_length
  @seq_length
  @fold_left_length
  @split_length_l
  @split_length_r
  @firstn_length
  @combine_length
  @prod_length
  : distr_length.

Definition sum_firstn l n := fold_right Z.add 0%Z (firstn n l).

Fixpoint map2 {A B C} (f : A -> B -> C) (la : list A) (lb : list B) : list C :=
  match la with
  | nil => nil
  | a :: la' => match lb with
                | nil => nil
                | b :: lb' => f a b :: map2 f la' lb'
                end
  end.

(* xs[n] := f xs[n] *)
Fixpoint update_nth {T} n f (xs:list T) {struct n} :=
	match n with
	| O => match xs with
				 | nil => nil
				 | x'::xs' => f x'::xs'
				 end
	| S n' =>  match xs with
				 | nil => nil
				 | x'::xs' => x'::update_nth n' f xs'
				 end
  end.

(* xs[n] := x *)
Definition set_nth {T} n x (xs:list T)
  := update_nth n (fun _ => x) xs.

Definition splice_nth {T} n (x:T) xs := firstn n xs ++ x :: skipn (S n) xs.
Hint Unfold splice_nth.

Ltac boring :=
  simpl; intuition;
  repeat match goal with
           | [ H : _ |- _ ] => rewrite H; clear H
           | _ => progress autounfold in *
           | _ => progress autorewrite with core
           | _ => progress simpl in *
           | _ => progress intuition
         end; eauto.

Ltac boring_list :=
  repeat match goal with
         | _ => progress boring
         | _ => progress autorewrite with distr_length simpl_nth_default simpl_update_nth simpl_set_nth simpl_nth_error in *
         end.

Lemma nth_default_cons : forall {T} (x u0 : T) us, nth_default x (u0 :: us) 0 = u0.
Proof. auto. Qed.

Hint Rewrite @nth_default_cons : simpl_nth_default.
Hint Rewrite @nth_default_cons : push_nth_default.

Lemma nth_default_cons_S : forall {A} us (u0 : A) n d,
  nth_default d (u0 :: us) (S n) = nth_default d us n.
Proof. boring. Qed.

Hint Rewrite @nth_default_cons_S : simpl_nth_default.
Hint Rewrite @nth_default_cons_S : push_nth_default.

Lemma nth_default_nil : forall {T} n (d : T), nth_default d nil n = d.
Proof. induction n; boring. Qed.

Hint Rewrite @nth_default_nil : simpl_nth_default.
Hint Rewrite @nth_default_nil : push_nth_default.

Lemma nth_error_nil_error : forall {A} n, nth_error (@nil A) n = None.
Proof. induction n; boring. Qed.

Hint Rewrite @nth_error_nil_error : simpl_nth_error.

Ltac nth_tac' :=
  intros; simpl in *; unfold error,value in *; repeat progress (match goal with
    | [  |- context[nth_error nil ?n] ] => rewrite nth_error_nil_error
    | [ H: ?x = Some _  |- context[match ?x with Some _ => ?a | None => ?a end ] ] => destruct x
    | [ H: ?x = None _  |- context[match ?x with Some _ => ?a | None => ?a end ] ] => destruct x
    | [  |- context[match ?x with Some _ => ?a | None => ?a end ] ] => destruct x
    | [  |- context[match nth_error ?xs ?i with Some _ => _ | None => _ end ] ] => case_eq (nth_error xs i); intros
    | [ |- context[(if lt_dec ?a ?b then _ else _) = _] ] => destruct (lt_dec a b)
    | [ |- context[_ = (if lt_dec ?a ?b then _ else _)] ] => destruct (lt_dec a b)
    | [ H: context[(if lt_dec ?a ?b then _ else _) = _] |- _ ] => destruct (lt_dec a b)
    | [ H: context[_ = (if lt_dec ?a ?b then _ else _)] |- _ ] => destruct (lt_dec a b)
    | [ H: _ /\ _ |- _ ] => destruct H
    | [ H: Some _ = Some _ |- _ ] => injection H; clear H; intros; subst
    | [ H: None = Some _  |- _ ] => inversion H
    | [ H: Some _ = None |- _ ] => inversion H
    | [ |- Some _ = Some _ ] => apply f_equal
  end); eauto; try (autorewrite with list in *); try omega; eauto.
Lemma nth_error_map : forall A B (f:A->B) i xs y,
  nth_error (map f xs) i = Some y ->
  exists x, nth_error xs i = Some x /\ f x = y.
Proof.
  induction i; destruct xs; nth_tac'.
Qed.

Lemma nth_error_seq : forall i start len,
  nth_error (seq start len) i =
  if lt_dec i len
  then Some (start + i)
  else None.
  induction i; destruct len; nth_tac'; erewrite IHi; nth_tac'.
Qed.

Lemma nth_error_error_length : forall A i (xs:list A), nth_error xs i = None ->
  i >= length xs.
Proof.
  induction i; destruct xs; nth_tac'; try specialize (IHi _ H); omega.
Qed.

Lemma nth_error_value_length : forall A i (xs:list A) x, nth_error xs i = Some x ->
  i < length xs.
Proof.
  induction i; destruct xs; nth_tac'; try specialize (IHi _ _ H); omega.
Qed.

Lemma nth_error_length_error : forall A i (xs:list A),
  i >= length xs ->
  nth_error xs i = None.
Proof.
  induction i; destruct xs; nth_tac'; rewrite IHi by omega; auto.
Qed.
Hint Resolve nth_error_length_error.
Hint Rewrite @nth_error_length_error using omega : simpl_nth_error.

Lemma map_nth_default : forall (A B : Type) (f : A -> B) n x y l,
  (n < length l) -> nth_default y (map f l) n = f (nth_default x l n).
Proof.
  intros.
  unfold nth_default.
  erewrite map_nth_error.
  reflexivity.
  nth_tac'.
  pose proof (nth_error_error_length A n l H0).
  omega.
Qed.

Hint Rewrite @map_nth_default using omega : push_nth_default.

Ltac nth_tac :=
  repeat progress (try nth_tac'; try (match goal with
    | [ H: nth_error (map _ _) _ = Some _ |- _ ] => destruct (nth_error_map _ _ _ _ _ _ H); clear H
    | [ H: nth_error (seq _ _) _ = Some _ |- _ ] => rewrite nth_error_seq in H
    | [H: nth_error _ _ = None |- _ ] => specialize (nth_error_error_length _ _ _ H); intro; clear H
  end)).

Lemma app_cons_app_app : forall T xs (y:T) ys, xs ++ y :: ys = (xs ++ (y::nil)) ++ ys.
Proof. induction xs; boring. Qed.

Lemma unfold_set_nth {T} n x
  : forall xs,
    @set_nth T n x xs
    = match n with
      | O => match xs with
	     | nil => nil
	     | x'::xs' => x::xs'
	     end
      | S n' =>  match xs with
		 | nil => nil
		 | x'::xs' => x'::set_nth n' x xs'
		 end
      end.
Proof.
  induction n; destruct xs; reflexivity.
Qed.

Lemma simpl_set_nth_0 {T} x
  : forall xs,
    @set_nth T 0 x xs
    = match xs with
      | nil => nil
      | x'::xs' => x::xs'
      end.
Proof. intro; rewrite unfold_set_nth; reflexivity. Qed.

Lemma simpl_set_nth_S {T} x n
  : forall xs,
    @set_nth T (S n) x xs
    = match xs with
      | nil => nil
      | x'::xs' => x'::set_nth n x xs'
      end.
Proof. intro; rewrite unfold_set_nth; reflexivity. Qed.

Hint Rewrite @simpl_set_nth_S @simpl_set_nth_0 : simpl_set_nth.

Lemma update_nth_ext {T} f g n
  : forall xs, (forall x, nth_error xs n = Some x -> f x = g x)
               -> @update_nth T n f xs = @update_nth T n g xs.
Proof.
  induction n; destruct xs; simpl; intros H;
    try rewrite IHn; try rewrite H;
      try congruence; trivial.
Qed.

Global Instance update_nth_Proper {T}
  : Proper (eq ==> pointwise_relation _ eq ==> eq ==> eq) (@update_nth T).
Proof. repeat intro; subst; apply update_nth_ext; trivial. Qed.

Lemma update_nth_id_eq_specific {T} f n
  : forall (xs : list T) (H : forall x, nth_error xs n = Some x -> f x = x),
    update_nth n f xs = xs.
Proof.
  induction n; destruct xs; simpl; intros;
    try rewrite IHn; try rewrite H; unfold value in *;
      try congruence; assumption.
Qed.

Hint Rewrite @update_nth_id_eq_specific using congruence : simpl_update_nth.

Lemma update_nth_id_eq : forall {T} f (H : forall x, f x = x) n (xs : list T),
    update_nth n f xs = xs.
Proof. intros; apply update_nth_id_eq_specific; trivial. Qed.

Hint Rewrite @update_nth_id_eq using congruence : simpl_update_nth.

Lemma update_nth_id : forall {T} n (xs : list T),
    update_nth n (fun x => x) xs = xs.
Proof. intros; apply update_nth_id_eq; trivial. Qed.

Hint Rewrite @update_nth_id : simpl_update_nth.

Lemma nth_update_nth : forall m {T} (xs:list T) (n:nat) (f:T -> T),
  nth_error (update_nth m f xs) n =
  if eq_nat_dec n m
  then option_map f (nth_error xs n)
  else nth_error xs n.
Proof.
  induction m.
  { destruct n, xs; auto. }
  { destruct xs, n; intros; simpl; auto;
      [ | rewrite IHm ]; clear IHm;
        edestruct eq_nat_dec; reflexivity. }
Qed.

Hint Rewrite @nth_update_nth : push_nth_error.
Hint Rewrite <- @nth_update_nth : pull_nth_error.

Lemma length_update_nth : forall {T} i f (xs:list T), length (update_nth i f xs) = length xs.
Proof.
  induction i, xs; boring.
Qed.

Hint Rewrite @length_update_nth : distr_length.

(** TODO: this is in the stdlib in 8.5; remove this when we move to 8.5-only *)
Lemma nth_error_None : forall (A : Type) (l : list A) (n : nat), nth_error l n = None <-> length l <= n.
Proof.
  intros A l n.
  destruct (le_lt_dec (length l) n) as [H|H];
    split; intro H';
      try omega;
      try (apply nth_error_length_error in H; tauto);
      try (apply nth_error_error_length in H'; omega).
Qed.

(** TODO: this is in the stdlib in 8.5; remove this when we move to 8.5-only *)
Lemma nth_error_Some : forall (A : Type) (l : list A) (n : nat), nth_error l n <> None <-> n < length l.
Proof. intros; rewrite nth_error_None; split; omega. Qed.

Lemma nth_set_nth : forall m {T} (xs:list T) (n:nat) x,
  nth_error (set_nth m x xs) n =
  if eq_nat_dec n m
  then (if lt_dec n (length xs) then Some x else None)
  else nth_error xs n.
Proof.
  intros; unfold set_nth; rewrite nth_update_nth.
  destruct (nth_error xs n) eqn:?, (lt_dec n (length xs)) as [p|p];
    rewrite <- nth_error_Some in p;
    solve [ reflexivity
          | exfalso; apply p; congruence ].
Qed.

Hint Rewrite @nth_set_nth : push_nth_error.

Lemma length_set_nth : forall {T} i x (xs:list T), length (set_nth i x xs) = length xs.
Proof. intros; apply length_update_nth. Qed.

Hint Rewrite @length_set_nth : distr_length.

Lemma nth_error_length_exists_value : forall {A} (i : nat) (xs : list A),
  (i < length xs)%nat -> exists x, nth_error xs i = Some x.
Proof.
  induction i, xs; boring; try omega.
Qed.

Lemma nth_error_length_not_error : forall {A} (i : nat) (xs : list A),
  nth_error xs i = None -> (i < length xs)%nat -> False.
Proof.
  intros.
  destruct (nth_error_length_exists_value i xs); intuition; congruence.
Qed.

Lemma nth_error_value_eq_nth_default : forall {T} i (x : T) xs,
  nth_error xs i = Some x -> forall d, nth_default d xs i = x.
Proof.
  unfold nth_default; boring.
Qed.

Hint Rewrite @nth_error_value_eq_nth_default using eassumption : simpl_nth_default.

Lemma skipn0 : forall {T} (xs:list T), skipn 0 xs = xs.
Proof. auto. Qed.

Lemma firstn0 : forall {T} (xs:list T), firstn 0 xs = nil.
Proof. auto. Qed.

Lemma splice_nth_equiv_update_nth : forall {T} n f d (xs:list T),
  splice_nth n (f (nth_default d xs n)) xs =
  if lt_dec n (length xs)
  then update_nth n f xs
  else xs ++ (f d)::nil.
Proof.
  induction n, xs; boring_list.
  do 2 break_if; auto; omega.
Qed.

Lemma splice_nth_equiv_update_nth_update : forall {T} n f d (xs:list T),
  n < length xs ->
  splice_nth n (f (nth_default d xs n)) xs = update_nth n f xs.
Proof.
  intros.
  rewrite splice_nth_equiv_update_nth.
  break_if; auto; omega.
Qed.

Lemma splice_nth_equiv_update_nth_snoc : forall {T} n f d (xs:list T),
  n >= length xs ->
  splice_nth n (f (nth_default d xs n)) xs = xs ++ (f d)::nil.
Proof.
  intros.
  rewrite splice_nth_equiv_update_nth.
  break_if; auto; omega.
Qed.

Definition IMPOSSIBLE {T} : list T. exact nil. Qed.

Ltac remove_nth_error :=
  repeat match goal with
         | _ => exfalso; solve [ eauto using @nth_error_length_not_error ]
         | [ |- context[match nth_error ?ls ?n with _ => _ end] ]
           => destruct (nth_error ls n) eqn:?
         end.

Lemma update_nth_equiv_splice_nth: forall {T} n f (xs:list T),
  update_nth n f xs =
  if lt_dec n (length xs)
  then match nth_error xs n with
       | Some v => splice_nth n (f v) xs
       | None => IMPOSSIBLE
       end
  else xs.
Proof.
  induction n; destruct xs; intros;
    autorewrite with simpl_update_nth simpl_nth_default in *; simpl in *;
      try (erewrite IHn; clear IHn); auto.
  repeat break_match; remove_nth_error; try reflexivity; try omega.
Qed.

Lemma splice_nth_equiv_set_nth : forall {T} n x (xs:list T),
  splice_nth n x xs =
  if lt_dec n (length xs)
  then set_nth n x xs
  else xs ++ x::nil.
Proof. intros; rewrite splice_nth_equiv_update_nth with (f := fun _ => x); auto. Qed.

Lemma splice_nth_equiv_set_nth_set : forall {T} n x (xs:list T),
  n < length xs ->
  splice_nth n x xs = set_nth n x xs.
Proof. intros; rewrite splice_nth_equiv_update_nth_update with (f := fun _ => x); auto. Qed.

Lemma splice_nth_equiv_set_nth_snoc : forall {T} n x (xs:list T),
  n >= length xs ->
  splice_nth n x xs = xs ++ x::nil.
Proof. intros; rewrite splice_nth_equiv_update_nth_snoc with (f := fun _ => x); auto. Qed.

Lemma set_nth_equiv_splice_nth: forall {T} n x (xs:list T),
  set_nth n x xs =
  if lt_dec n (length xs)
  then splice_nth n x xs
  else xs.
Proof.
  intros; unfold set_nth; rewrite update_nth_equiv_splice_nth with (f := fun _ => x); auto.
  repeat break_match; remove_nth_error; trivial.
Qed.

Lemma combine_update_nth : forall {A B} n f g (xs:list A) (ys:list B),
  combine (update_nth n f xs) (update_nth n g ys) =
  update_nth n (fun xy => (f (fst xy), g (snd xy))) (combine xs ys).
Proof.
  induction n; destruct xs, ys; simpl; try rewrite IHn; reflexivity.
Qed.

(* grumble, grumble, [rewrite] is bad at inferring the identity function, and constant functions *)
Ltac rewrite_rev_combine_update_nth :=
  let lem := match goal with
             | [ |- appcontext[update_nth ?n (fun xy => (@?f xy, @?g xy)) (combine ?xs ?ys)] ]
               => let f := match (eval cbv [fst] in (fun y x => f (x, y))) with
                           | fun _ => ?f => f
                           end in
                  let g := match (eval cbv [snd] in (fun x y => g (x, y))) with
                           | fun _ => ?g => g
                           end in
                  constr:(@combine_update_nth _ _ n f g xs ys)
             end in
  rewrite <- lem.

Lemma combine_update_nth_l : forall {A B} n (f : A -> A) xs (ys:list B),
  combine (update_nth n f xs) ys =
  update_nth n (fun xy => (f (fst xy), snd xy)) (combine xs ys).
Proof.
  intros ??? f xs ys.
  etransitivity; [ | apply combine_update_nth with (g := fun x => x) ].
  rewrite update_nth_id; reflexivity.
Qed.

Lemma combine_update_nth_r : forall {A B} n (g : B -> B) (xs:list A) (ys:list B),
  combine xs (update_nth n g ys) =
  update_nth n (fun xy => (fst xy, g (snd xy))) (combine xs ys).
Proof.
  intros ??? g xs ys.
  etransitivity; [ | apply combine_update_nth with (f := fun x => x) ].
  rewrite update_nth_id; reflexivity.
Qed.

Lemma combine_set_nth : forall {A B} n (x:A) xs (ys:list B),
  combine (set_nth n x xs) ys =
    match nth_error ys n with
    | None => combine xs ys
    | Some y => set_nth n (x,y) (combine xs ys)
    end.
Proof.
  intros; unfold set_nth; rewrite combine_update_nth_l.
  nth_tac;
    [ repeat rewrite_rev_combine_update_nth; apply f_equal2
    | assert (nth_error (combine xs ys) n = None)
      by (apply nth_error_None; rewrite combine_length; omega * ) ];
    autorewrite with simpl_update_nth; reflexivity.
Qed.

Lemma nth_error_value_In : forall {T} n xs (x:T),
  nth_error xs n = Some x -> In x xs.
Proof.
  induction n; destruct xs; nth_tac.
Qed.

Lemma In_nth_error_value : forall {T} xs (x:T),
  In x xs -> exists n, nth_error xs n = Some x.
Proof.
  induction xs; nth_tac; break_or_hyp.
  - exists 0; reflexivity.
  - edestruct IHxs; eauto. exists (S x0). eauto.
Qed.

Lemma nth_value_index : forall {T} i xs (x:T),
  nth_error xs i = Some x -> In i (seq 0 (length xs)).
Proof.
  induction i; destruct xs; nth_tac; right.
  rewrite <- seq_shift; apply in_map; eapply IHi; eauto.
Qed.

Lemma nth_error_app : forall {T} n (xs ys:list T), nth_error (xs ++ ys) n =
  if lt_dec n (length xs)
  then nth_error xs n
  else nth_error ys (n - length xs).
Proof.
  induction n; destruct xs; nth_tac;
    rewrite IHn; destruct (lt_dec n (length xs)); trivial; omega.
Qed.

Lemma nth_default_app : forall {T} n x (xs ys:list T), nth_default x (xs ++ ys) n =
  if lt_dec n (length xs)
  then nth_default x xs n
  else nth_default x ys (n - length xs).
Proof.
  intros.
  unfold nth_default.
  rewrite nth_error_app.
  destruct (lt_dec n (length xs)); auto.
Qed.

Hint Rewrite @nth_default_app : push_nth_default.

Lemma combine_truncate_r : forall {A B} (xs : list A) (ys : list B),
  combine xs ys = combine xs (firstn (length xs) ys).
Proof.
  induction xs; destruct ys; boring.
Qed.

Lemma combine_truncate_l : forall {A B} (xs : list A) (ys : list B),
  combine xs ys = combine (firstn (length ys) xs) ys.
Proof.
  induction xs; destruct ys; boring.
Qed.

Lemma combine_app_samelength : forall {A B} (xs xs':list A) (ys ys':list B),
  length xs = length ys ->
  combine (xs ++ xs') (ys ++ ys') = combine xs ys ++ combine xs' ys'.
Proof.
  induction xs, xs', ys, ys'; boring; omega.
Qed.

Lemma firstn_nil : forall {A} n, firstn n nil = @nil A.
Proof. destruct n; auto. Qed.

Hint Rewrite @firstn_nil : simpl_firstn.

Lemma skipn_nil : forall {A} n, skipn n nil = @nil A.
Proof. destruct n; auto. Qed.

Hint Rewrite @skipn_nil : simpl_skipn.

Lemma firstn_0 : forall {A} xs, @firstn A 0 xs = nil.
Proof. reflexivity. Qed.

Hint Rewrite @firstn_0 : simpl_firstn.

Lemma skipn_0 : forall {A} xs, @skipn A 0 xs = xs.
Proof. reflexivity. Qed.

Hint Rewrite @skipn_0 : simpl_skipn.

Lemma firstn_cons_S : forall {A} n x xs, @firstn A (S n) (x::xs) = x::@firstn A n xs.
Proof. reflexivity. Qed.

Hint Rewrite @firstn_cons_S : simpl_firstn.

Lemma skipn_cons_S : forall {A} n x xs, @skipn A (S n) (x::xs) = @skipn A n xs.
Proof. reflexivity. Qed.

Hint Rewrite @skipn_cons_S : simpl_skipn.

Lemma firstn_app : forall {A} n (xs ys : list A),
  firstn n (xs ++ ys) = firstn n xs ++ firstn (n - length xs) ys.
Proof.
  induction n, xs, ys; boring.
Qed.

Lemma skipn_app : forall {A} n (xs ys : list A),
  skipn n (xs ++ ys) = skipn n xs ++ skipn (n - length xs) ys.
Proof.
  induction n, xs, ys; boring.
Qed.

Lemma firstn_app_inleft : forall {A} n (xs ys : list A), (n <= length xs)%nat ->
  firstn n (xs ++ ys) = firstn n xs.
Proof.
  induction n, xs, ys; boring; try omega.
Qed.

Lemma skipn_app_inleft : forall {A} n (xs ys : list A), (n <= length xs)%nat ->
  skipn n (xs ++ ys) = skipn n xs ++ ys.
Proof.
  induction n, xs, ys; boring; try omega.
Qed.

Lemma firstn_all : forall {A} n (xs:list A), n = length xs -> firstn n xs = xs.
Proof.
  induction n, xs; boring; omega.
Qed.

Lemma skipn_all : forall {T} n (xs:list T),
  (n >= length xs)%nat ->
  skipn n xs = nil.
Proof.
  induction n, xs; boring; omega.
Qed.

Lemma firstn_app_sharp : forall {A} n (l l': list A),
  length l = n ->
  firstn n (l ++ l') = l.
Proof.
  intros.
  rewrite firstn_app_inleft; auto using firstn_all; omega.
Qed.

Lemma skipn_app_sharp : forall {A} n (l l': list A),
  length l = n ->
  skipn n (l ++ l') = l'.
Proof.
  intros.
  rewrite skipn_app_inleft; try rewrite skipn_all; auto; omega.
Qed.

Lemma skipn_length : forall {A} n (xs : list A),
  length (skipn n xs) = (length xs - n)%nat.
Proof.
  induction n, xs; boring.
Qed.

Lemma fold_right_cons : forall {A B} (f:B->A->A) a b bs,
  fold_right f a (b::bs) = f b (fold_right f a bs).
Proof.
  reflexivity.
Qed.

Hint Rewrite @fold_right_cons : simpl_fold_right.

Lemma length_cons : forall {T} (x:T) xs, length (x::xs) = S (length xs).
  reflexivity.
Qed.

Lemma cons_length : forall A (xs : list A) a, length (a :: xs) = S (length xs).
Proof.
  auto.
Qed.

Lemma length0_nil : forall {A} (xs : list A), length xs = 0%nat -> xs = nil.
Proof.
  induction xs; boring; discriminate.
Qed.

Lemma length_snoc : forall {T} xs (x:T),
  length xs = pred (length (xs++x::nil)).
Proof.
  boring; simpl_list; boring.
Qed.

Lemma firstn_combine : forall {A B} n (xs:list A) (ys:list B),
  firstn n (combine xs ys) = combine (firstn n xs) (firstn n ys).
Proof.
  induction n, xs, ys; boring.
Qed.

Lemma combine_nil_r : forall {A B} (xs:list A),
  combine xs (@nil B) = nil.
Proof.
  induction xs; boring.
Qed.

Lemma skipn_combine : forall {A B} n (xs:list A) (ys:list B),
  skipn n (combine xs ys) = combine (skipn n xs) (skipn n ys).
Proof.
  induction n, xs, ys; boring.
  rewrite combine_nil_r; reflexivity.
Qed.

Lemma break_list_last: forall {T} (xs:list T),
  xs = nil \/ exists xs' y, xs = xs' ++ y :: nil.
Proof.
  destruct xs using rev_ind; auto.
  right; do 2 eexists; auto.
Qed.

Lemma break_list_first: forall {T} (xs:list T),
  xs = nil \/ exists x xs', xs = x :: xs'.
Proof.
  destruct xs; auto.
  right; do 2 eexists; auto.
Qed.

Lemma list012 : forall {T} (xs:list T),
  xs = nil
  \/ (exists x, xs = x::nil)
  \/ (exists x xs' y, xs = x::xs'++y::nil).
Proof.
  destruct xs; auto.
  right.
  destruct xs using rev_ind. {
    left; eexists; auto.
  } {
    right; repeat eexists; auto.
  }
Qed.

Lemma nil_length0 : forall {T}, length (@nil T) = 0%nat.
Proof.
  auto.
Qed.

Lemma nth_error_Some_nth_default : forall {T} i x (l : list T), (i < length l)%nat ->
  nth_error l i = Some (nth_default x l i).
Proof.
  intros ? ? ? ? i_lt_length.
  destruct (nth_error_length_exists_value _ _ i_lt_length) as [k nth_err_k].
  unfold nth_default.
  rewrite nth_err_k.
  reflexivity.
Qed.

Lemma update_nth_cons : forall {T} f (u0 : T) us, update_nth 0 f (u0 :: us) = (f u0) :: us.
Proof. reflexivity. Qed.

Hint Rewrite @update_nth_cons : simpl_update_nth.

Lemma set_nth_cons : forall {T} (x u0 : T) us, set_nth 0 x (u0 :: us) = x :: us.
Proof. intros; apply update_nth_cons. Qed.

Hint Rewrite @set_nth_cons : simpl_set_nth.

Hint Rewrite
  @nil_length0
  @length_cons
  @skipn_length
  @length_update_nth
  @length_set_nth
  : distr_length.
Ltac distr_length := autorewrite with distr_length in *;
  try solve [simpl in *; omega].

Lemma cons_update_nth : forall {T} n f (y : T) us,
  y :: update_nth n f us = update_nth (S n) f (y :: us).
Proof.
  induction n; boring.
Qed.

Hint Rewrite <- @cons_update_nth : simpl_update_nth.

Lemma update_nth_nil : forall {T} n f, update_nth n f (@nil T) = @nil T.
Proof.
  induction n; boring.
Qed.

Hint Rewrite @update_nth_nil : simpl_update_nth.

Lemma cons_set_nth : forall {T} n (x y : T) us,
  y :: set_nth n x us = set_nth (S n) x (y :: us).
Proof. intros; apply cons_update_nth. Qed.

Hint Rewrite <- @cons_set_nth : simpl_set_nth.

Lemma set_nth_nil : forall {T} n (x : T), set_nth n x nil = nil.
Proof. intros; apply update_nth_nil. Qed.

Hint Rewrite @set_nth_nil : simpl_set_nth.

Lemma skipn_nth_default : forall {T} n us (d : T), (n < length us)%nat ->
 skipn n us = nth_default d us n :: skipn (S n) us.
Proof.
  induction n; destruct us; intros; nth_tac.
  rewrite (IHn us d) at 1 by omega.
  nth_tac.
Qed.

Lemma nth_default_out_of_bounds : forall {T} n us (d : T), (n >= length us)%nat ->
  nth_default d us n = d.
Proof.
  induction n; unfold nth_default; nth_tac; destruct us; nth_tac.
  assert (n >= length us)%nat by omega.
  pose proof (nth_error_length_error _ n us H1).
  rewrite H0 in H2.
  congruence.
Qed.

Hint Rewrite @nth_default_out_of_bounds using omega : simpl_nth_default.

Ltac nth_error_inbounds :=
  match goal with
  | [ |- context[match nth_error ?xs ?i with Some _ => _ | None => _ end ] ] =>
    case_eq (nth_error xs i);
    match goal with
      | [ |- forall _, nth_error xs i = Some _ -> _ ] =>
          let x := fresh "x" in
          let H := fresh "H" in
          intros x H;
          repeat progress erewrite H;
          repeat progress erewrite (nth_error_value_eq_nth_default i xs x); auto
      | [ |- nth_error xs i = None -> _ ] =>
          let H := fresh "H" in
          intros H;
          destruct (nth_error_length_not_error _ _ H);
          try solve [distr_length]
    end;
    idtac
  end.
Ltac set_nth_inbounds :=
  match goal with
  | [ |- context[set_nth ?i ?x ?xs] ] =>
    rewrite (set_nth_equiv_splice_nth i x xs);
    destruct (lt_dec i (length xs));
    match goal with
    | [ H : ~ (i < (length xs))%nat |- _ ] => destruct H
    | [ H :   (i < (length xs))%nat |- _ ] => try solve [distr_length]
    end
  end.
Ltac update_nth_inbounds :=
  match goal with
  | [ |- context[update_nth ?i ?f ?xs] ] =>
    rewrite (update_nth_equiv_splice_nth i f xs);
    destruct (lt_dec i (length xs));
    match goal with
    | [ H : ~ (i < (length xs))%nat |- _ ] => destruct H
    | [ H :   (i < (length xs))%nat |- _ ] => remove_nth_error; try solve [distr_length]
    end
  end.

Ltac nth_inbounds := nth_error_inbounds || set_nth_inbounds || update_nth_inbounds.

Lemma cons_eq_head : forall {T} (x y:T) xs ys, x::xs = y::ys -> x=y.
Proof.
  intros; solve_by_inversion.
Qed.
Lemma cons_eq_tail : forall {T} (x y:T) xs ys, x::xs = y::ys -> xs=ys.
Proof.
  intros; solve_by_inversion.
Qed.

Lemma map_nth_default_always {A B} (f : A -> B) (n : nat) (x : A) (l : list A)
  : nth_default (f x) (map f l) n = f (nth_default x l n).
Proof.
  revert n; induction l; simpl; intro n; destruct n; [ try reflexivity.. ].
  nth_tac.
Qed.

Hint Rewrite @map_nth_default_always : push_nth_default.

Lemma fold_right_and_True_forall_In_iff : forall {T} (l : list T) (P : T -> Prop),
  (forall x, In x l -> P x) <-> fold_right and True (map P l).
Proof.
  induction l; intros; simpl; try tauto.
  rewrite <- IHl.
  intuition (subst; auto).
Qed.

Lemma fold_right_invariant : forall {A} P (f: A -> A -> A) l x,
  P x -> (forall y, In y l -> forall z, P z -> P (f y z)) ->
  P (fold_right f x l).
Proof.
  induction l; intros ? ? step; auto.
  simpl.
  apply step; try apply in_eq.
  apply IHl; auto.
  intros y in_y_l.
  apply (in_cons a) in in_y_l.
  auto.
Qed.

Lemma In_firstn : forall {T} n l (x : T), In x (firstn n l) -> In x l.
Proof.
  induction n; destruct l; boring.
Qed.

Lemma firstn_firstn : forall {A} m n (l : list A), (n <= m)%nat ->
  firstn n (firstn m l) = firstn n l.
Proof.
  induction m; destruct n; intros; try omega; auto.
  destruct l; auto.
  simpl.
  f_equal.
  apply IHm; omega.
Qed.

Lemma firstn_succ : forall {A} (d : A) n l, (n < length l)%nat ->
  firstn (S n) l = (firstn n l) ++ nth_default d l n :: nil.
Proof.
  induction n; destruct l; rewrite ?(@nil_length0 A); intros; try omega.
  + rewrite nth_default_cons; auto.
  + simpl.
    rewrite nth_default_cons_S.
    rewrite <-IHn by (rewrite cons_length in *; omega).
    reflexivity.
Qed.

Lemma firstn_all_strong : forall {A} (xs : list A) n, (length xs <= n)%nat ->
  firstn n xs = xs.
Proof.
  induction xs; intros; try apply firstn_nil.
  destruct n;
    match goal with H : (length (_ :: _)  <= _)%nat |- _ =>
      simpl in H; try omega end.
  simpl.
  f_equal.
  apply IHxs.
  omega.
Qed.

Lemma update_nth_out_of_bounds : forall {A} n f xs, n >= length xs -> @update_nth A n f xs = xs.
Proof.
  induction n; destruct xs; simpl; try congruence; try omega; intros.
  rewrite IHn by omega; reflexivity.
Qed.

Hint Rewrite @update_nth_out_of_bounds using omega : simpl_update_nth.


Lemma update_nth_nth_default_full : forall {A} (d:A) n f l i,
  nth_default d (update_nth n f l) i =
  if lt_dec i (length l) then
    if (eq_nat_dec i n) then f (nth_default d l i)
    else nth_default d l i
  else d.
Proof.
  induction n; (destruct l; simpl in *; [ intros; destruct i; simpl; try reflexivity; omega | ]);
    intros; repeat break_if; subst; try destruct i;
      repeat first [ progress break_if
                   | progress subst
                   | progress boring
                   | progress autorewrite with simpl_nth_default
                   | omega ].
Qed.

Hint Rewrite @update_nth_nth_default_full : push_nth_default.

Lemma update_nth_nth_default : forall {A} (d:A) n f l i, (0 <= i < length l)%nat ->
  nth_default d (update_nth n f l) i =
  if (eq_nat_dec i n) then f (nth_default d l i) else nth_default d l i.
Proof. intros; rewrite update_nth_nth_default_full; repeat break_if; boring. Qed.

Hint Rewrite @update_nth_nth_default using (omega || distr_length; omega) : push_nth_default.

Lemma set_nth_nth_default_full : forall {A} (d:A) n v l i,
  nth_default d (set_nth n v l) i =
  if lt_dec i (length l) then
    if (eq_nat_dec i n) then v
    else nth_default d l i
  else d.
Proof. intros; apply update_nth_nth_default_full; assumption. Qed.

Hint Rewrite @set_nth_nth_default_full : push_nth_default.

Lemma set_nth_nth_default : forall {A} (d:A) n x l i, (0 <= i < length l)%nat ->
  nth_default d (set_nth n x l) i =
  if (eq_nat_dec i n) then x else nth_default d l i.
Proof. intros; apply update_nth_nth_default; assumption. Qed.

Hint Rewrite @set_nth_nth_default using (omega || distr_length; omega) : push_nth_default.

Lemma nth_default_preserves_properties : forall {A} (P : A -> Prop) l n d,
  (forall x, In x l -> P x) -> P d -> P (nth_default d l n).
Proof.
  intros; rewrite nth_default_eq.
  destruct (nth_in_or_default n l d); auto.
  congruence.
Qed.

Lemma nth_error_first : forall {T} (a b : T) l,
  nth_error (a :: l) 0 = Some b -> a = b.
Proof.
  intros; simpl in *.
  unfold value in *.
  congruence.
Qed.

Lemma nth_error_exists_first : forall {T} l (x : T) (H : nth_error l 0 = Some x),
  exists l', l = x :: l'.
Proof.
  induction l; try discriminate; eexists.
  apply nth_error_first in H.
  subst; eauto.
Qed.

Lemma list_elementwise_eq : forall {T} (l1 l2 : list T),
  (forall i, nth_error l1 i = nth_error l2 i) -> l1 = l2.
Proof.
  induction l1, l2; intros; try reflexivity;
    pose proof (H 0%nat) as Hfirst; simpl in Hfirst; inversion Hfirst.
  f_equal.
  apply IHl1.
  intros i; specialize (H (S i)).
  boring.
Qed.

Lemma sum_firstn_all_succ : forall n l, (length l <= n)%nat ->
  sum_firstn l (S n) = sum_firstn l n.
Proof.
  unfold sum_firstn; intros.
  rewrite !firstn_all_strong by omega.
  congruence.
Qed.

Hint Rewrite @sum_firstn_all_succ using omega : simpl_sum_firstn.

Lemma sum_firstn_succ_default : forall l i,
  sum_firstn l (S i) = (nth_default 0 l i + sum_firstn l i)%Z.
Proof.
  unfold sum_firstn; induction l, i;
    intros; autorewrite with simpl_nth_default simpl_firstn simpl_fold_right in *;
      try reflexivity.
  rewrite IHl; omega.
Qed.

Hint Rewrite @sum_firstn_succ_default : simpl_sum_firstn.

Lemma sum_firstn_0 : forall xs,
  sum_firstn xs 0 = 0%Z.
Proof.
  destruct xs; reflexivity.
Qed.

Hint Rewrite @sum_firstn_0 : simpl_sum_firstn.

Lemma sum_firstn_succ : forall l i x,
  nth_error l i = Some x ->
  sum_firstn l (S i) = (x + sum_firstn l i)%Z.
Proof.
  intros; rewrite sum_firstn_succ_default.
  erewrite nth_error_value_eq_nth_default by eassumption; reflexivity.
Qed.

Hint Rewrite @sum_firstn_succ using congruence : simpl_sum_firstn.

Lemma sum_firstn_succ_default_rev : forall l i,
  sum_firstn l i = (sum_firstn l (S i) - nth_default 0 l i)%Z.
Proof.
  intros; rewrite sum_firstn_succ_default; omega.
Qed.

Lemma sum_firstn_succ_rev : forall l i x,
  nth_error l i = Some x ->
  sum_firstn l i = (sum_firstn l (S i) - x)%Z.
Proof.
  intros; erewrite sum_firstn_succ by eassumption; omega.
Qed.

Lemma nth_default_map2 : forall {A B C} (f : A -> B -> C) ls1 ls2 i d d1 d2,
  nth_default d (map2 f ls1 ls2) i =
    if lt_dec i (min (length ls1) (length ls2))
    then f (nth_default d1 ls1 i) (nth_default d2 ls2 i)
    else d.
Proof.
  induction ls1, ls2.
  + cbv [map2 length min].
    intros.
    break_if; try omega.
    apply nth_default_nil.
  + cbv [map2 length min].
    intros.
    break_if; try omega.
    apply nth_default_nil.
  + cbv [map2 length min].
    intros.
    break_if; try omega.
    apply nth_default_nil.
  + simpl.
    destruct i.
    - intros. rewrite !nth_default_cons.
      break_if; auto; omega.
    - intros. rewrite !nth_default_cons_S.
      rewrite IHls1 with (d1 := d1) (d2 := d2).
      repeat break_if; auto; omega.
Qed.

Lemma map2_cons : forall A B C (f : A -> B -> C) ls1 ls2 a b,
  map2 f (a :: ls1) (b :: ls2) = f a b :: map2 f ls1 ls2.
Proof.
  reflexivity.
Qed.

Lemma map2_nil_l : forall A B C (f : A -> B -> C) ls2,
  map2 f nil ls2 = nil.
Proof.
  reflexivity.
Qed.

Lemma map2_nil_r : forall A B C (f : A -> B -> C) ls1,
  map2 f ls1 nil = nil.
Proof.
  destruct ls1; reflexivity.
Qed.
Local Hint Resolve map2_nil_r map2_nil_l.

Opaque map2.

Lemma map2_length : forall A B C (f : A -> B -> C) ls1 ls2,
  length (map2 f ls1 ls2) = min (length ls1) (length ls2).
Proof.
  induction ls1, ls2; intros; try solve [cbv; auto].
  rewrite map2_cons, !length_cons, IHls1.
  auto.
Qed.

Ltac simpl_list_lengths := repeat match goal with
  | H : appcontext[length (@nil ?A)] |- _ => rewrite (@nil_length0 A) in H
  | H : appcontext[length (_ :: _)] |- _ => rewrite length_cons in H
  | |- appcontext[length (@nil ?A)] => rewrite (@nil_length0 A)
  | |- appcontext[length (_ :: _)] => rewrite length_cons
  end.

Lemma map2_app : forall A B C (f : A -> B -> C) ls1 ls2 ls1' ls2',
  (length ls1 = length ls2) ->
  map2 f (ls1 ++ ls1') (ls2 ++ ls2') = map2 f ls1 ls2 ++ map2 f ls1' ls2'.
Proof.
  induction ls1, ls2; intros; rewrite ?map2_nil_r, ?app_nil_l; try congruence;
    simpl_list_lengths; try omega.
  rewrite <-!app_comm_cons, !map2_cons.
  rewrite IHls1; auto.
Qed.

Lemma firstn_update_nth {A}
  : forall f m n (xs : list A), firstn m (update_nth n f xs) = update_nth n f (firstn m xs).
Proof.
  induction m; destruct n, xs;
    autorewrite with simpl_firstn simpl_update_nth;
    congruence.
Qed.

Hint Rewrite @firstn_update_nth : push_firstn.
Hint Rewrite @firstn_update_nth : pull_update_nth.
Hint Rewrite <- @firstn_update_nth : pull_firstn.
Hint Rewrite <- @firstn_update_nth : push_update_nth.

Require Import Coq.Lists.SetoidList.
Global Instance Proper_nth_default : forall A eq,
  Proper (eq==>eqlistA eq==>Logic.eq==>eq) (nth_default (A:=A)).
Proof.
  do 5 intro; subst; induction 1.
  + repeat intro; rewrite !nth_default_nil; assumption.
  + repeat intro; subst; destruct y0; rewrite ?nth_default_cons, ?nth_default_cons_S; auto.
Qed.