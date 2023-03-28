---
title: Functional Dependency Injection
tags: scala
---

# Introduction

On the topic of Dependency Injection in scala, there's a picture that sticks in my mind that I saw from the [scalar 2018 conference blog post](https://blog.softwaremill.com/scalar-2018-whiteboard-voting-results-c6f50f8fb16d)


![A whiteboard showing votes on how people do Dependency Injection in Scala, with Constructors winning by a large margin](/images/whiteboard-injection.jpeg)

As we can see, the winner by a large margin is constructors, and that makes sense from a functional point of view, make everything as simple as possible.

You can see that the other functional option that has some traction is the Reader Monad, and that’s what we’ll be looking at in this post.

# So what's Reader?

```scala
type ReaderT[F[_], I, O] = I => F[O]
```

Using the extremely simplistic defenition, `ReaderT` is just a function that has some input and creates some output inside an effect.

It has a `Monad` instance for `ReaderT[F[_], I, *]` so we can compose these together as long as they all take the same input type.

Maybe we’d write our program with something like:

```scala
case class Config(host: String, port: Int)
type MyMonad[O] = ReaderT[IO, Config, O]
```

So every action in my program takes a `Config` now, which makes sense, but it’s not very nice to use:

```scala
def run() =
  for {
    _ <- ReaderT { (c: Config) => IO { println(s"Starting a server on ${c.host}:${c.port}" } }
    _ <- ReaderT.liftF(IO { println("started") })
  } yield()
```
