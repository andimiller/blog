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

```scala
import net.andimiller.hedgehogs._

// We could store some data in these nodes, but for now it's Unit
val nodes: List[Node[String, Unit]] =
  List("A", "B", "C").map(name => Node(name, ()))
// nodes: List[Node[String, Unit]] = List(
//   Node(id = "A", data = ()),
//   Node(id = "B", data = ()),
//   Node(id = "C", data = ())
// )

// And these are our edges
val edges: List[Edge[String, Int]] =
  List(
    Edge("A", "B", 3),
    Edge("A", "C", 5),
    Edge("B", "C", 1)
  )
// edges: List[Edge[String, Int]] = List(
//   Edge(from = "A", to = "B", weight = 3),
//   Edge(from = "A", to = "C", weight = 5),
//   Edge(from = "B", to = "C", weight = 1)
// )

Graph.fromIterables(nodes, edges, bidirectional = false)
// res0: cats.data.package.ValidatedNel[String, Graph[String, Unit, Int]] = Valid(
//   a = Graph(
//     nodes = Map("A" -> (), "B" -> (), "C" -> ()),
//     edges = Map("A" -> Vector(("B", 3), ("C", 5)), "B" -> Vector(("C", 1)))
//   )
// )
```

You'll see it validated the graph as we made it, and it would've returned errors if we did something wrong:

```scala
val badNodes: List[Node[String, Unit]] =
  List("A", "A", "B", "C").map(name => Node(name, ()))
// badNodes: List[Node[String, Unit]] = List(
//   Node(id = "A", data = ()),
//   Node(id = "A", data = ()),
//   Node(id = "B", data = ()),
//   Node(id = "C", data = ())
// )

Graph.fromIterables(badNodes, edges, bidirectional = false)
// res1: cats.data.package.ValidatedNel[String, Graph[String, Unit, Int]] = Invalid(
//   e = NonEmptyList(head = "A has 2 nodes, required at most 1", tail = List())
// )

val badEdges: List[Edge[String, Int]] =
  List(
    Edge("A", "B", 3),
    Edge("A", "D", 5),
    Edge("Y", "Z", 1)
  )
// badEdges: List[Edge[String, Int]] = List(
//   Edge(from = "A", to = "B", weight = 3),
//   Edge(from = "A", to = "D", weight = 5),
//   Edge(from = "Y", to = "Z", weight = 1)
// )

Graph.fromIterables(nodes, badEdges, bidirectional = false)
// res2: cats.data.package.ValidatedNel[String, Graph[String, Unit, Int]] = Invalid(
//   e = NonEmptyList(
//     head = "Y is not a known node",
//     tail = List("D is not a known node")
//   )
// )
```

So, returning to our valid graph:


```scala
graph
// res3: Graph[String, Unit, Int] = Graph(
//   nodes = Map("A" -> (), "B" -> (), "C" -> ()),
//   edges = Map("A" -> Vector(("B", 3), ("C", 5)), "B" -> Vector(("C", 1)))
// )
```

## Routefinding

`Hedgehogs` comes with an implementation of [Dijkstra's Algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) for finding routes between nodes.

The first way you can use it is to ask for the optimal path between two nodes:

```scala
Dijkstra(graph)("A", "C")
// res4: Option[(Int, List[String])] = Some(value = (4, List("A", "B", "C")))
```

As you can see this returned us the distance of `4` between the two nodes, and tells us the path is `List("A", "B", "C")`.

Since Dijkstra's calculates optimal routes from the origin to any number of nodes, there is also a `multi` version where we can ask for the optimal routes to multiple destinations at once:

```scala
Dijkstra.multi(graph)("A", Set("B", "C"))
// res5: Map[String, (Int, List[String])] = Map(
//   "B" -> (3, List("A", "B")),
//   "C" -> (4, List("A", "B", "C"))
// )
```

You can see this returns a map with our optimal routes to `B` and `C`.

## Why?

I originally made this library to solve a few problems in tooling for [EVE Online](https://eveonline.com), it is fairly common to need to measure routes between places and so one of the examples in the hedgehogs repo is in fact the solar system for EVE Online:

Once the graph's been loaded we have thousands of solar systems and stargates:

```scala
val solarSystems = eveOnlineMap.nodes.size
// solarSystems: Int = 8485
val stargates    = eveOnlineMap.edges.size
// stargates: Int = 5214
````

And `Hedgehogs` allows us to routefind optimally around the graph very quickly, even in javascript:

```scala
Dijkstra(eveOnlineMap)(karan, jita)
// res6: Option[(Int, List[Long])] = Some(
//   value = (
//     34,
//     List(
//       30004306L,
//       30004309L,
//       30004626L,
//       30004625L,
//       30004624L,
//       30004562L,
//       30004561L,
//       30004560L,
//       30004559L,
//       30004557L,
//       30004555L,
//       30004553L,
//       30004552L,
//       30004554L,
//       30004584L,
//       30004586L,
//       30004589L,
//       30004040L,
//       30004042L,
//       30004043L,
//       30004044L,
//       30004046L,
//       30003841L,
//       30003836L,
//       30003837L,
//       30045344L,
//       30045338L,
//       30045353L,
//       30045345L,
//       30045346L,
//       30002813L,
//       30001376L,
//       30001379L,
//       30000143L,
//       30000142L
//     )
//   )
// )
Dijkstra.multi(eveOnlineMap)(karan, Set(jita, amarr))
// res7: Map[Long, (Int, List[Long])] = Map(
//   30002187L -> (
//     29,
//     List(
//       30004306L,
//       30004303L,
//       30004296L,
//       30004293L,
//       30004288L,
//       30004287L,
//       30004286L,
//       30004285L,
//       30004283L,
//       30004280L,
//       30004270L,
//       30004268L,
//       30004267L,
//       30004240L,
//       30004242L,
//       30004244L,
//       30004245L,
//       30004246L,
//       30005055L,
//       30005054L,
//       30005052L,
//       30005050L,
//       30003881L,
//       30003880L,
//       30003878L,
//       30003877L,
//       30003876L,
//       30005043L,
//       30005038L,
//       30002187L
//     )
//   ),
//   30000142L -> (
//     34,
//     List(
//       30004306L,
//       30004309L,
//       30004626L,
//       30004625L,
//       30004624L,
//       30004562L,
//       30004561L,
//       30004560L,
//       30004559L,
//       30004557L,
// ...
```
