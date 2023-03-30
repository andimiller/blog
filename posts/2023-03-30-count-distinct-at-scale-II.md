---
title: Count Distinct at Scale II 
og-description: Continued exploration of Probabilistic Data Structures, introducing the Theta sketch.
tags: scala, probabilistic data structures, big data
---

([previous article on HyperLogLog]("count-distinct-at-scale-I.html"))

So all that counting zeroes stuff made our estimator kind of hard, we need to do a load of probability maths to figure out how many items we've seen, what if I told you there was a simpler way?

# Theta Sketches

The Theta sketch works on a slightly different model, this time we're going to keep track of the smallest hashes we've seen, up to a limit of `2 ^ p`, and we're going to shift our hashes into the range of `0.0` to `1.0` and call this `theta`

```scala
def hashToTheta(hash: Int): BigDecimal =
  (((BigDecimal(hash) / Int.MaxValue) / 2) + 0.5) // move into the range of 0 to 1
    .setScale(9, BigDecimal.RoundingMode.HALF_UP)         // round to 9 decimal points for nice displaying         // round to 9 decimal points for nice displaying

hashToTheta(0)
// res0: BigDecimal = 0.500000000
hashToTheta(Int.MinValue)
// res1: BigDecimal = 0E-9
hashToTheta(Int.MaxValue)
// res2: BigDecimal = 1.000000000
```

so we've worked out how to turn a hash into a theta, what does this get us?

Let's say we're willing to keep a sample of 10 unique items from our stream, and we're keeping the smallest unique hashes, it might look like this:

```scala
import cats.implicits._
import scala.util.hashing.MurmurHash3
import scala.collection.SortedSet

val SAMPLE_SIZE: Int = 10
// SAMPLE_SIZE: Int = 10


def takeSample(items: List[String]): SortedSet[BigDecimal] =
  items
  .map(MurmurHash3.stringHash)                             // hash it into a pretty unique id
  .map(hashToTheta)                                        // translate into theta values
  .foldLeft(SortedSet.empty[BigDecimal]) {
    case (values, value) if values.contains(value) =>      // it was a duplicate in our sample
      values                                               // no change
    case (values, value) if (values.size < SAMPLE_SIZE) => // we aren't at capacity yet
      values + value
    case (values, value) if (value < values.max) =>        // it's below our max theta
      values - values.max + value                          // drop our top value and add
    case (values, _) =>                                    // anything else can be dropped
      values
  }

// quick way to make demo data
def generate(i: Int): List[String] =
  (0 to i).map(_.toString).toList

takeSample(generate(1000))
// res3: SortedSet[BigDecimal] = TreeSet(
//   0.000092818,
//   0.000583520,
//   0.002820835,
//   0.003069461,
//   0.004881037,
//   0.005913540,
//   0.006197287,
//   0.006300205,
//   0.007501833,
//   0.008358628
// )
```

You can see we've got our 10 bottom theta entries, and the top theta represents our cut-off point, so we've sampled 10 items, they're in this part, and we can then estimate the rest:

```scala
def estimate(sample: SortedSet[BigDecimal]): BigDecimal =
  if (sample.size < SAMPLE_SIZE) { // if we haven't filled our sample, we know the exact number
    BigDecimal(sample.size)
  } else {
    val theta = sample.max
    (SAMPLE_SIZE - 1) / theta
  }

estimate(takeSample(List.fill(100)("example")))
// res4: BigDecimal = 1
estimate(takeSample(generate(10)))
// res5: BigDecimal = 9.215780902107950857937849607112368
estimate(takeSample(generate(100)))
// res6: BigDecimal = 81.31792062378868486614135109237209
estimate(takeSample(generate(1000)))
// res7: BigDecimal = 1076.731731571257866721667718673447
```

As you can see the accuracy's not great with 10 items, but we've given it a good try.

The number of items we keep is 

