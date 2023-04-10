---
title: "Conway's Game of Life in 3D with Graphs"
og-description: A first attempt at implementing a 3D Conway's Game of Life using Graphs, using my Hedgehogs library.
tags: scala, open source, personal project, graphs, 3d
---

<script async src="https://unpkg.com/es-module-shims@1.6.3/dist/es-module-shims.js"></script>

<script type="importmap">
  {
    "imports": {
      "three": "https://unpkg.com/three@0.151.3/build/three.module.js",
      "three/addons/": "https://unpkg.com/three@0.151.3/examples/jsm/"
    }
  }
</script>

<center>
<div class="sourceCode" id="render1"></div>
</center>
<center>
<div class="sourceCode" id="render2"></div>
</center>

<script type="module">
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { TrackballControls } from 'three/addons/controls/TrackballControls.js';
import * as THREE from 'three';

window.renderBlocks = function renderBlocks(elementId, filledIn) {
                        const container = document.getElementById(elementId);
			let camera, scene, renderer;
                        let controls;


			function init() {
				scene = new THREE.Scene();

				const geometry = new THREE.BoxGeometry( 10, 10, 10 );
				const material = new THREE.MeshBasicMaterial({color: 0x698CD8});
                                const edges = new THREE.EdgesGeometry( geometry );

                                filledIn.forEach ( item => {
					     const cube = new THREE.Mesh( geometry, material );
					     cube.position.x = item.x * 10 - 25;
					     cube.position.y = item.y * 10 - 25;
					     cube.position.z = item.z * 10 - 25;
					     scene.add(cube);
                                });
                                [0,1,2,3,4].forEach( x => {
                                     [0,1,2,3,4].forEach( y => {
                                          [0,1,2,3,4].forEach( z => {
					     const line = new THREE.LineSegments( edges, new THREE.LineBasicMaterial( { color: 0xffffff } ) );
					     line.position.x = x * 10 - 25;
					     line.position.y = y * 10 - 25;
					     line.position.z = z * 10 - 25;
					     scene.add(line);
                                })})});

				renderer = new THREE.WebGLRenderer( { antialias: true } );
				renderer.setPixelRatio( window.devicePixelRatio );
				renderer.setSize( 400, 400 );
                                container.appendChild(renderer.domElement);
				camera = new THREE.PerspectiveCamera( 45, 1, 1, 1000 );
				camera.position.x = 100;
				camera.position.y = 100;
				camera.position.z = 100;

                                controls = new TrackballControls(camera, renderer.domElement) // renderer.domElement)
			}

			function animate() {
				requestAnimationFrame( animate );
                                controls.update();
				renderer.render( scene, camera );
			}

			init();
			animate();
};
</script>

To follow on from my [previous post](2023-04-05-conways-game-of-life-graph.html), I'm going to try and run conway's game of life in 3d, let's see what happens.

I'll just naievely scale the rules from 2d to 3d, we're going from 8 neighbours to 26 neighbours, to scale relative to that:

## Domain

The game is played on a <i>3D</i> grid, each cell is either alive or dead.

On each time step, the following is performed:

* Any live cell with <strike>two or three</strike> <i>six to ten</i> live neighbours survives
* Any dead cell with <strike>three</strike> <i>eight to ten</i> live neighbours becomes alive
* All other cells die

## Domain Modelling

We can just model the alive status as a `Boolean`, and our grid as `(Int, Int, Int)` tuples.

We don't need to care about weights here, so every edge can have weight 1 to keep things simple.

I'll start off with a 5x5x5 grid:

```scala
import net.andimiller.hedgehogs._

// use a 3x3x3 cube
val initialPattern = (for {
  x <- 1 to 3
  y <- 1 to 3
  z <- 1 to 3
} yield (x, y, z)).toSet
val nodes = for {
  x <- 0 to 4
  y <- 0 to 4
  z <- 0 to 4
} yield Node((x, y, z), initialPattern.contains((x,y,z)))
```

And we'd like them to connect to all adjacent cells, including diagonally, so we need some edges:

```scala
val validRange = (0 to 4).toSet
val edges = for {
  x <- 0 to 4
  y <- 0 to 4
  z <- 0 to 4
  tx <- x-1 to x+1
  ty <- y-1 to y+1
  tz <- z-1 to z+1
  if ((x,y,z) != (tx, ty, tz)) // don't connect to itself
  if (validRange(tx))          // stay in the grid
  if (validRange(ty))
  if (validRange(tz))
} yield Edge((x,y,z), (tx, ty, tz),  weight = 1)
```

We can combine these into our graph:
```scala
type LifeGraph = Graph[(Int, Int, Int), Boolean, Int]
val graph: LifeGraph = Graph.fromIterables(nodes, edges, bidirectional = true)
                            .getOrElse(throw new Exception("invalid graph"))
```

And we'd like some way to render out our <i>3D</i> grid, so let's do some quick string creation:

```scala
import cats.implicits._
def render(nodes: Map[(Int, Int, Int), Boolean]): String = nodes.toList.mapFilter { 
  case ((x, y, z), true) => Some(s"""{x:$x, y:$y, z:$z}""")
  case (_, false)        => None
}.mkString_("[", ", ", "]")

render(graph.nodes)
// res0: String = "[{x:2, y:1, z:3}, {x:3, y:1, z:2}, {x:2, y:2, z:1}, {x:3, y:2, z:2}, {x:2, y:3, z:2}, {x:3, y:2, z:1}, {x:2, y:3, z:1}, {x:3, y:3, z:3}, {x:1, y:1, z:3}, {x:1, y:2, z:2}, {x:1, y:2, z:3}, {x:1, y:3, z:1}, {x:2, y:2, z:2}, {x:2, y:1, z:1}, {x:1, y:3, z:3}, {x:1, y:1, z:2}, {x:3, y:2, z:3}, {x:2, y:3, z:3}, {x:3, y:1, z:1}, {x:3, y:3, z:1}, {x:1, y:1, z:1}, {x:3, y:1, z:3}, {x:2, y:2, z:3}, {x:2, y:1, z:2}, {x:3, y:3, z:2}, {x:1, y:2, z:1}, {x:1, y:3, z:2}]"
```

<center>
  <div id="exampleRender"></div>
</center>



<script type="module">
window.renderBlocks('exampleRender', [{x:2, y:1, z:3}, {x:3, y:1, z:2}, {x:2, y:2, z:1}, {x:3, y:2, z:2}, {x:2, y:3, z:2}, {x:3, y:2, z:1}, {x:2, y:3, z:1}, {x:3, y:3, z:3}, {x:1, y:1, z:3}, {x:1, y:2, z:2}, {x:1, y:2, z:3}, {x:1, y:3, z:1}, {x:2, y:2, z:2}, {x:2, y:1, z:1}, {x:1, y:3, z:3}, {x:1, y:1, z:2}, {x:3, y:2, z:3}, {x:2, y:3, z:3}, {x:3, y:1, z:1}, {x:3, y:3, z:1}, {x:1, y:1, z:1}, {x:3, y:1, z:3}, {x:2, y:2, z:3}, {x:2, y:1, z:2}, {x:3, y:3, z:2}, {x:1, y:2, z:1}, {x:1, y:3, z:2}]);
</script>


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
def aliveNeighbours(g: LifeGraph)(id: (Int, Int, Int)): Int =
  g.neighbours(id).map(_._1).map(g.nodes).count(identity)
```

And now we can write our main step function:

```scala
def step(g: LifeGraph): LifeGraph = g.mapData {
  case (id, true)  if Set(6,7,8,9,10).contains(aliveNeighbours(g)(id)) => true
  case (id, false) if Set(8,9,10).contains(aliveNeighbours(g)(id))     => true
  case _                                                               => false
}
```

## Results

```scala
render(graph.nodes)
// res2: String = "[{x:2, y:1, z:3}, {x:3, y:1, z:2}, {x:2, y:2, z:1}, {x:3, y:2, z:2}, {x:2, y:3, z:2}, {x:3, y:2, z:1}, {x:2, y:3, z:1}, {x:3, y:3, z:3}, {x:1, y:1, z:3}, {x:1, y:2, z:2}, {x:1, y:2, z:3}, {x:1, y:3, z:1}, {x:2, y:2, z:2}, {x:2, y:1, z:1}, {x:1, y:3, z:3}, {x:1, y:1, z:2}, {x:3, y:2, z:3}, {x:2, y:3, z:3}, {x:3, y:1, z:1}, {x:3, y:3, z:1}, {x:1, y:1, z:1}, {x:3, y:1, z:3}, {x:2, y:2, z:3}, {x:2, y:1, z:2}, {x:3, y:3, z:2}, {x:1, y:2, z:1}, {x:1, y:3, z:2}]"
```

<center>
  <div id="result0"></div>
</center>



<script type="module">
window.renderBlocks('result0', [{x:2, y:1, z:3}, {x:3, y:1, z:2}, {x:2, y:2, z:1}, {x:3, y:2, z:2}, {x:2, y:3, z:2}, {x:3, y:2, z:1}, {x:2, y:3, z:1}, {x:3, y:3, z:3}, {x:1, y:1, z:3}, {x:1, y:2, z:2}, {x:1, y:2, z:3}, {x:1, y:3, z:1}, {x:2, y:2, z:2}, {x:2, y:1, z:1}, {x:1, y:3, z:3}, {x:1, y:1, z:2}, {x:3, y:2, z:3}, {x:2, y:3, z:3}, {x:3, y:1, z:1}, {x:3, y:3, z:1}, {x:1, y:1, z:1}, {x:3, y:1, z:3}, {x:2, y:2, z:3}, {x:2, y:1, z:2}, {x:3, y:3, z:2}, {x:1, y:2, z:1}, {x:1, y:3, z:2}]);
</script>


```scala
render(step(graph).nodes)
// res4: String = "[{x:2, y:4, z:2}, {x:0, y:2, z:2}, {x:3, y:3, z:3}, {x:1, y:1, z:3}, {x:1, y:3, z:1}, {x:2, y:2, z:4}, {x:1, y:3, z:3}, {x:3, y:1, z:1}, {x:3, y:3, z:1}, {x:1, y:1, z:1}, {x:3, y:1, z:3}, {x:2, y:2, z:0}, {x:4, y:2, z:2}, {x:2, y:0, z:2}]"
```

<center>
  <div id="result1"></div>
</center>



<script type="module">
window.renderBlocks('result1', [{x:2, y:4, z:2}, {x:0, y:2, z:2}, {x:3, y:3, z:3}, {x:1, y:1, z:3}, {x:1, y:3, z:1}, {x:2, y:2, z:4}, {x:1, y:3, z:3}, {x:3, y:1, z:1}, {x:3, y:3, z:1}, {x:1, y:1, z:1}, {x:3, y:1, z:3}, {x:2, y:2, z:0}, {x:4, y:2, z:2}, {x:2, y:0, z:2}]);
</script>


```scala
render(step(step(graph)).nodes)
// res6: String = "[{x:2, y:2, z:2}]"
```

<center>
  <div id="result2"></div>
</center>



<script type="module">
window.renderBlocks('result2', [{x:2, y:2, z:2}]);
</script>


```scala
render(step(step(step(graph))).nodes)
// res8: String = "[]"
```

<center>
  <div id="result3"></div>
</center>



<script type="module">
window.renderBlocks('result3', []);
</script>


Well that exploded then fizzled out, maybe we can find a more stable pattern, or iterate on the rules...
