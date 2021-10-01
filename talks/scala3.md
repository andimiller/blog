---
author: Andi Miller
title: What's new in scala 3?
date: 1st October 2021
---

# What's scala 3?

* Next main version of scala
* Fixes some issues with scala 3
* Introduces cool features academics like

::: notes

So what's scala 3 about, as you can guess from the number it's the next major version of scala,

It fixes some issues with scala 3, notably around implicits, which we'll come toString

And it adds some cool things that academics like, some of these may be useful, some may not

:::


# New syntax

::: notes

We'll start off by looking at the new syntax, this was the most contentious part, but it seems like people are pretty positive on it now that it's out.

:::

## Quiet if

```scala
// Scala 2
if (x < 0)
  "negative"
else if (x == 0)
  "zero"
else
  "positive"
// Scala 3
if x < 0 then
  "negative"
else if x == 0 then
  "zero"
else
  "positive"
```

::: notes

You'll see that if now has a "then" keyword, and doesn't need the parens any more"

:::


## Quiet for

```scala
// Scala 2
for {
  x <- xs
  y <- ys
} yield x+y

// Scala 3
for
  x <- xs
  y <- ys
yield x+y
```

::: notes

You'll see the most notable change here is that the curly braces are gone, which is going to be a recurring theme

:::

## Optional Braces

```scala
// Scala 2
object SomeObject {
  val foo = 123
}

// Scala 3
object SomeObject:
  val foo = 123
end SomeObject // optional
```

::: notes

This is the big one, Scala 2 got a lot of criticism for being hard to read because it followed your standard java or C style curly braces, those are now fully optional, and you can write with python style indentation if you'd like.

As you can see you replace the opening curly brace with a colon, then indent the contents, and we've got an optional `end` marker, which can also be named, and the compiler will check that it closes something with that name.

This works for anything that had curly braces in scala 2, objects, classes, traits, groups of expressions and so on.

:::

# Implicits Rework

::: notes

Next up we've got the implicits rework, this is the biggest breaking chage from scala 2 to 3, in scala 2 implicits were added to see what people built with them, so they've become much more opinionated in scala 3, now that the community's agreed on what were good and bad uses of implicits.

:::

## Implicit Values

```scala
// Scala 2
implicit val config: Configuration =
  Configuration(name = "my-program")

def printName(implicit c: Configuration) = c.name

// Scala 3
given Configuration =
  Configuration(name = "my-program")

def printName(using c: Configuration) = c.name
```

::: notes

First up we've got implicit values, these were used to define a canonical value of a given type, as you can see in the scala 2 example here, I'm declaring that this is /the/ Configuration value for the current scope, if anything wants a value of type `Configuration`, this is it.

The method there will ask for an "implicit" config, using the same keyword.

In scala 3 we can now omit the name, and it's got it's own keyword now, we say that this part of the program is written, "given this Configuration", which is the kind of wording that makes computer scientists and mathematicians happy.

And again you'll see in scala 3, the method that uses the Configuration has a proper dedicated keyword, where we say "using" as the other half of given.

:::

## Implicit Conversions

```scala
// Scala 2
implicit def intToString(i: Int): String = i.toString
```

::: notes

In scala 2 we had the concept of implicit conversions, you can see here they're declared with the `implicit def` keywords.

This one will automatically convert any integer into a string, if you're trying to treat it as a string.

As you can probably guess, this was actually much too powerful to be used unless you were extremely specific about the types, and even then it acted as a layer of hidden magic that programmers just didn't appreciate, so in scala 3 it's gone.

:::

## Implicit Classes / Extensions

```scala
// Scala 2
implicit class DoubleIntSyntax(i: Int) {
  def double: Int = i * 2
}

// Scala 3
extension (i: Int)
  def double: Int = i*2
```

::: notes

Next up we've got implicit classes, in scala 2 these were used to add extension methods to things, you'll see I've declared something called DoubleIntSyntax which wraps an Int, and adds a method called double, often you would add conversion methods like this rather than using the previous conversions, because now you'd explicitly call a method to convert something.


In scala 3 you'll see we now have an `extension` keyword, and you just declare an extension, you could name it if you wanted, or make it generic.

:::

## First class Type Class Support

```scala
// Scala 2
trait SemiGroup[T] {
  def combine(a: T, b: T): T
}
trait Monoid[T] extends SemiGroup[T] {
  def unit: T
}
implicit class MonoidSyntax[T](t: T)(implicit m: Monoid[T]) {
  def combine(other: T) = m.combine(t, other)
}
implicit val stringMonad: Monoid[String] = new Monoid[String] {
  def combine(a: String, b: String) = a + b
  def unit = ""
}
```

::: notes

And if we put all this together, what was this all for? where did we end up?

Here's the scala 2 encoding for a Type Class, which is a way of doing ad-hoc polymorphism.

You'll see we declare the traits to represent the behaviour, then the implicit class to add the syntax, then declare an instance for string.

:::


## First class Type Class Support

```scala
// Scala 3
trait SemiGroup[T]:
  extension (x: T) def combine (y: T): T

trait Monoid[T] extends SemiGroup[T]:
  def unit: T

given Monoid[String] with
  extension (x: String)
    def combine (y: String): String = x + y
  def unit: String = ""
```

::: notes

Over here in scala 3, you'll see that we can now just define a SemiGroup as having an extension as part of it's interface, and in general this is just a lot cleaner.

You'll note I don't need to name my string monoid any more, so there's less redundancy going on.

:::


# Strict Equality

```scala
// Scala 2
1 == "123" // false
1 != "123" // true

// Scala 3 with scala.language.strictEquality
1 == "123" // compiler error
1 != "123" // also a compiler error
```

::: notes

Because Scala is so linked to java, in scala 2 we'd use the java `equals` method to compare things with `==`, this was widely regarded as a bad move, and there were libraries to add a `===` which checks that both sides are the same type before allowing it to compile.

In scala 3 we can get this out of the box by enabling strict equality.

:::


# Types

## Opaque types

```scala
opaque type Name = String
```

::: notes

We've got opaque types in scala 3, which let us declare a wrapper type that's only known as a wrapper in the file where you've declared the type.

This makes it easy to make what haskell calls "newtypes", a wrapper that effectively compiles out, and only exists at build time.

:::


## Opaque types in action

```scala
opaque type NonEmptyString = String

// Code inside here is allowed to know it's a String
object NonEmptyString:
  def fromString(s: String): Option[NonEmptyString] =
    Option(s).filter(_.nonEmpty)
  extension (nes: NonEmptyString)
    def toString: String = nes
```

::: notes

Here in my example we're implementing `NonEmptyString`, a `String` which is never empty.

In scala 2 we'd have to put that inside some kind of class wrapper, or do some trickery with macros, but here we can just declare that it's an opaque type;

Then give it a companion object that can create one and patch methods onto it with extension

As you can see in the comment, only code inside this object is allowed to treat a `NonEmptyString` as if it's a standard `String`, and it's not boxed at runtime.

:::


## Context Functions

::: notes

Following on from the theme of creating purpose-built abstractions, next we've got a type of Dependency Injection called a Context Function

:::

## Context Functions in Action

```scala
"Thing I am testing" should {
  "add one and two" in {
    thing.add(1,2).assertEquals(3)
  }
  "add numbers in general" in {
    forAll { (a: Int, b: Int) =>
      thing.add(a, b) == a+b
    }
  }
}
```

::: notes

This one's a real example I was building, you'll see here there's a little DSL for building tests, this is the real DSL used by scalatest, a popular testing framework.

I wanted to reimplement a more lightweight version of this on top of a functional testing library, so I wanted to recreate this syntax.

You'll note that on the outside we've got the name of the thing we're testing, and that should probably be passed in.. somehow.
:::


## Context Function Usage

```scala
opaque type TestSubject = String
extension (s: String)
  def in(body: Any)(using subject: TestSubject) =
    registerTest(subject, s, body)
  def should(body: TestSubject ?=> Any) =
    given TestSubject = s
    body()
```
::: notes

I've simplified this a bit, but you'll see I've declared an opaque type, so a little wrapper around String that is a TestSubject.

We're then declaring some extension methods on strings, the `in` method, used to write our inner tests, will take a `TestSubject` with the `using` keyword we saw earlier, then use that to register the test with the right outer and inner names.

I've then declared the `should` keyword, but I've used this new symbol, the questionmark arrow, which says the body is a `Context Function` and our context is a `TestSubject`, then in the body, I just set it with given, then run the body.

This gives us a very powerful way to inject dependencies, since we can now ask for lambdas that take context.

:::


## Enums (Algebraic Data Types)

```scala
// Scala 2
sealed trait Option[+T]
sealed class Some(t: T)
case object None extends Option[Nothing]

// Scala 3
enum Option[+T]
  case Some(t: T)
  case None
```

::: notes

Now for a more simple one, enum types, or, Algebraic Data Types, you'll see here back in scala 2 we'd define a sealed trait, then implement the trait for each branch of our ADT.

In scala 3 there's now a specific enum keyword which will take care of this for us and we just list out all of the cases, you would be surprised how much boilerplate this saves you.

This will also handle generics nicely.

:::


## Intersection and Union Types

```scala
// Scala 3
def run(config: AppConfig & DatabaseConfig) = ???
def add(input: Int | Double | BigDecimal) = ???
```

::: notes

For another pretty simple one we've got Intersection and Union types, you can see there the and sign lets you say that something is multiple types at once, and the or sign lets you say that something is one of these types.

These can both be very powerful abstractions if used right, and give you a bit of an escape hatch if you do need to operate over a quick set of types but don't want to declare a load of wrappers.

Think about dealing with something like JSON, where it's String, or Int or Float or Array or Object, you don't necessarily want a ton of wrappers to express that and keep track of it.

:::

## Explicit Nulls

```scala
// Scala 3 with -Yexplicit-nulls
val x: String = null
  // error: found `Null`, but required `String`

val y: String | Null // compiles
```

::: notes

Another change to the type system is that you can opt into removing Null from the normal type hierarchy.

If you do the compiler won't allow you to assign null to anything unless you've marked it as nullable using an intersection type like here.

This is huge for preventing errors in more unruly or object-oriented codebases, and is a feature I plan to enable in most codebases.

:::

## Match Types

```scala
// Scala 3
type Elem[X] = X match
  case String      => Char
  case Array[t]    => t
  case Iterable[t] => t
```

::: notes

A type system feature that people have been asking for for a while are dependent types, depending on one type, pick another type.

This has been implemented in scala 3 as Match Types, they let you match on some incoming type and say what the output type is.

In this example you'll see that you could use it to abstract over container types, including String, which would usually be kind of awkward due to String not taking a generic parameter.

:::

# Metaprogramming

::: notes

And for our last big category, metaprogramming, macros became a bit of a mess in scala 2 so they've been simplified in scala 3 with much more intentional features.

:::

## Inline

```scala
inline val hello = "hello world"

inline def double(i: Int) = i*2
```

::: notes

We've got a new keyword, it's called inline, and it guarantees that the compiler will always inline the value, this is actually quite important when it comes to macros, but it can help speed up your own code if you're really getting into profiling.

As you can see I've got an inline value there, and an inline method, that method body will just be expanded into the callsite, at runtime there will never actually be a method called double.

:::

## Inline Parameters

```scala
inline def timed[T](inline body: T): T =
  val start = System.nanoTime()
  val result = body
  val end = System.nanoTime()
  println(s"operation took ${end-start} nanos")
  result
```

::: notes

Inlines are cool, but to really restart getting stuff done, we've got inline parameters, this guarantees that the body will be inlined into this method, and then this method will be inlined into it's call site, for when you really care about performance

:::

## Basic Macros on Literals

```scala
inline def logIfEnabled[T](
    inline enabled: Boolean & Singleton,
    inline body: T): T =
  val result = body
  if (enabled) then
    println(result)
  result
```

::: notes

And for a quick look at what this means, here's a macro.

You'll see this is a logger that compiles out when it's disabled.

The `enabled` argument is both a boolean and a singleton, so we know it's value at compile time, and the body is inlined.

If that boolean is set to true, this will compile down to an extra println, and if it's set to false, this will completely compile out.

:::


# Conclusion

* Scala 3 is switching to intention-based abstractions
* There's a lot of cool stuff, some of which will filter back into Java or Kotlin

# Any Questions?
