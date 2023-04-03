---
title: "Hedgehogs: They Have a Lot of Edges"
og-description: Hedgehogs is an open source Scala library for traversing graphs
tags: scala, open source, personal project, graphs
---

This is a quick introduction to a library I made canned [Hedgehogs](https://github.com/andimiller/hedgehogs), it's for cyclic graph traversal, and is cross-built for scala.js for use in frontends.

## Creation 

So, to show off what we can do, let's make a quick graph:

![A graph showing 3 nodes, A, B and C, with A->B weight 3, A->C weight 5 and B->C weight 1](/images/hedgehogs1.svg)

It's your classic graph where there's an expensive route from `A` to `C`, or a cheaper route via `B`.

So let's construct it with `hedgehogs`:

```scala mdoc
import net.andimiller.hedgehogs._

// We could store some data in these nodes, but for now it's Unit
val nodes: List[Node[String, Unit]] =
  List("A", "B", "C").map(name => Node(name, ()))

// And these are our edges
val edges: List[Edge[String, Int]] =
  List(
    Edge("A", "B", 3),
    Edge("A", "C", 5),
    Edge("B", "C", 1)
  )

Graph.fromIterables(nodes, edges, bidirectional = false)
```

You'll see it validated the graph as we made it, and it would've returned errors if we did something wrong:

```scala mdoc
val badNodes: List[Node[String, Unit]] =
  List("A", "A", "B", "C").map(name => Node(name, ()))

Graph.fromIterables(badNodes, edges, bidirectional = false)

val badEdges: List[Edge[String, Int]] =
  List(
    Edge("A", "B", 3),
    Edge("A", "D", 5),
    Edge("Y", "Z", 1)
  )

Graph.fromIterables(nodes, badEdges, bidirectional = false)
```

So, returning to our valid graph:

```scala mdoc:invisible
val graph = Graph.fromIterables(nodes, edges, bidirectional = false).toOption.get
```

```scala mdoc
graph
```

## Routefinding

`Hedgehogs` comes with an implementation of [Dijkstra's Algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) for finding routes between nodes.

The first way you can use it is to ask for the optimal path between two nodes:

```scala mdoc
Dijkstra(graph)("A", "C")
```

As you can see this returned us the distance of `4` between the two nodes, and tells us the path is `List("A", "B", "C")`.

Since Dijkstra's calculates optimal routes from the origin to any number of nodes, there is also a `multi` version where we can ask for the optimal routes to multiple destinations at once:

```scala mdoc
Dijkstra.multi(graph)("A", Set("B", "C"))
```

You can see this returns a map with our optimal routes to `B` and `C`.

## Why?

I originally made this library to solve a few problems in tooling for [EVE Online](https://eveonline.com), it is fairly common to need to measure routes between places and so one of the examples in the hedgehogs repo is in fact the solar system for EVE Online:

```scala mdoc:invisible
import cats.effect.IO
import cats.implicits._
import fs2.io.file.Path
import io.circe.Decoder
import net.andimiller.hedgehogs._
import net.andimiller.hedgehogs.circe._

def loadJsonByLine[T: Decoder](s: String): IO[Vector[T]] = fs2.io.file
  .Files[IO]
  .readAll(Path(s))
  .through(fs2.text.utf8.decode)
  .through(fs2.text.lines)
  .filter(_.nonEmpty)
  .evalMap { s =>
    IO.fromEither(io.circe.parser.parse(s))
  }
  .evalMap { j =>
    IO.fromEither(Decoder[T].decodeJson(j))
  }
  .compile
  .toVector

val graphIO = for {
  systems <- loadJsonByLine[Node[Long, String]]("./mdoc-posts/hedgehogs-examples/systems.json")
  gates   <- loadJsonByLine[Edge[Long, Int]]("./mdoc-posts/hedgehogs-examples/gates.json")
  graph    = Graph.fromIterables(systems, gates, bidirectional = false).toOption.get
} yield graph

import cats.effect.unsafe.implicits.global
val eveOnlineMap = graphIO.unsafeRunSync()


val karan = eveOnlineMap.nodes.toList.find(_._2 == "Karan").map(_._1).get
val jita  = eveOnlineMap.nodes.toList.find(_._2 == "Jita").map(_._1).get
val amarr = eveOnlineMap.nodes.toList.find(_._2 == "Amarr").map(_._1).get
```
Once the graph's been loaded we have thousands of solar systems and stargates:

```scala mdoc
val solarSystems = eveOnlineMap.nodes.size
val stargates    = eveOnlineMap.edges.size
````

And `Hedgehogs` allows us to routefind optimally around the graph very quickly, even in javascript:

```scala mdoc
Dijkstra(eveOnlineMap)(karan, jita)
Dijkstra.multi(eveOnlineMap)(karan, Set(jita, amarr))
```
