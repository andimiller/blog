---
title: Semigroups and Distributed Systems
og-description: What are the different types of Semigroup and how can they help me build Distributed Systems? 
tags: scala, distributed systems, category theory
---

## Semigroups?

So, what's a semigroup? There are multiple types we'll be talking about but the basic semigroup is:

```scala mdoc
import cats.kernel.laws._

trait Semigroup[T] {
  def combine(a: T, b: T): T
}

trait SemigroupLaws[T] {
  def S: Semigroup[T]

  def associative(a: T, b: T, c: T) =
    S.combine(S.combine(a, b), c) <-> S.combine(a, S.combine(b, c))
}
```

There are a few more laws in cats, but `associative` is the one we care about, you can see it wants `((a, b), c)` to be equivalent to `(a, (b, c))`.

This allows us to merge results in any order, which is a nice property to have for a distributed system if we want to perform intermediate merges during a map/reduce style operation.

## Commutative Semigroups?

Our next step up is when we add `commuatative`:

```scala mdoc
trait CommutativeSemigroup[T] extends Semigroup[T] {}

trait CommutativeSemigroupLaws[T] extends SemigroupLaws[T] {
  override def S: CommutativeSemigroup[T]

  def commutative(a: T, b: T) = 
    S.combine(a, b) <-> S.combine(b, a)
}
```

This now allows us to merge in any order, we don't need to keep track of ordering at all during reduce.

## Semilattice?

Next we can add `idempotent`:

```scala mdoc
trait Semilattice[T] extends CommutativeSemigroup[T] {}

trait SemilatticeLaws[T] extends CommutativeSemigroupLaws[T] {
  override def S: Semilattice[T]

  def idempotent(a: T, b: T) =
    S.combine(a, b) <-> S.combine(a, S.combine(a, b))
}
```

This then allows us to this then allows us to consume the same item twice without changing the result, this is mostly needed when you can't guarantee `exactly-once` delivery.

