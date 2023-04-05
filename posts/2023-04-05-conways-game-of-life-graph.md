---
title: "Conway's Game of Life with Graphs"
og-description: A quick run-through of how to implement Conway's Game of Life using Graphs, using my Hedgehogs library.
tags: scala, open source, personal project, graphs
---

A friend of mine mentioned [Conway's Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) in a group chat today, so I ended up thinking, most people implement this with arrays, can we do it in a graph?

I just wrote the introduction post for [Hedgehogs](https://github.com/andimiller/hedgehogs), so let's give it a go:

## Domain

The game is played on a grid, each cell is either alive or dead.

On each time step, the following is performed:

* Any live cell with two or three live neighbours survives
* Any dead cell with three live neighbours becomes alive
* All other cells die

## Domain Modelling

We can just model the alive status as a `Boolean`, and our grid as `(Int, Int)` tuples.

We don't need to care about weights here, so every edge can have weight 1 to keep things simple.

I'll start off with a 5x5 grid:


And we'd like them to connect to all adjacent cells, including diagonally, so we need some edges:


We can combine these into our graph:

And we'd like some way to render out our grid, so let's do some quick string creation:

```scala
def render(nodes: Map[(Int, Int), Boolean]): String = nodes.toList
  .sortBy(_._1)
  .groupBy(_._1._2)
  .toList
  .sortBy(_._1)
  .map { case (_, cells) =>
    cells.map(_._2).map(alive => if (alive) "#" else " ").mkString
  }
  .mkString("\n")

render(graph.nodes)
// res0: String = """      
//   #   
//   #   
//   #   
//       
//       """
```

## The Algorithm

Okay, I listed the 3 steps we need to perform above, we're going to want a helper function to map the data inside a graph, maybe I should add this into the base `Hedgehogs` library, but we're adding it as an extension for now:

```scala
implicit class GraphOps[Idx, Data, Distance](g: Graph[Idx, Data, Distance]) {
  def mapData[NewData](f: (Idx, Data) => NewData): Graph[Idx, NewData, Distance] =
    g.copy(nodes = g.nodes.map { case (k, v) => k -> f(k, v) })
}
```

This just lets us map the data, taking in the index and data, returning the new data.

We're going to want to ask how many alive neighbours a cell has in a graph:

```scala
def aliveNeighbours(g: LifeGraph)(id: (Int, Int)): Int = 
  g.neighbours(id).map(_._1).map(g.nodes).count(identity)
```

And now we can write our main step function:

```scala
def step(g: LifeGraph): LifeGraph = g.mapData {
  case (id, true) if Set(2, 3).contains(aliveNeighbours(g)(id)) => true
  case (id, false) if aliveNeighbours(g)(id) == 3               => true
  case _                                                        => false
}
```

## Result

```scala
render(graph.nodes)
// res1: String = """      
//   #   
//   #   
//   #   
//       
//       """

render(step(graph).nodes)
// res2: String = """      
//       
//  ###  
//       
//       
//       """
```

Get rotated nerd.
