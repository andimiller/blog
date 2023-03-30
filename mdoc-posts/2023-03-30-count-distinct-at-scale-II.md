---
title: Count Distinct at Scale II 
og-description: Continued exploration of Probabilistic Data Structures, introducing the Theta sketch.
tags: scala, probabilistic data structures, big data
---

([previous article on HyperLogLog](2023-03-28-count-distinct-at-scale-I.html))

So all that counting zeroes stuff made our estimator kind of hard, we need to do a load of probability maths to figure out how many items we've seen, what if I told you there was a simpler way?

# Theta Sketches

The Theta sketch works on a slightly different model, this time we're going to keep track of the smallest hashes we've seen, up to a limit of `2 ^ p`, and we're going to shift our hashes into the range of `0.0` to `1.0` and call this `theta`

```scala mdoc
def hashToTheta(hash: Int): Double =
  (((BigDecimal(hash) / Int.MaxValue) / 2) + 0.5) // move into the range of 0 to 1
    .setScale(9, BigDecimal.RoundingMode.HALF_UP) // round to 9 decimal points for nice displaying
    .toDouble

hashToTheta(0)
hashToTheta(Int.MinValue)
hashToTheta(Int.MaxValue)
```

so we've worked out how to turn a hash into a theta, what does this get us?

Let's say we're willing to keep a sample of 10 unique items from our stream, and we're keeping the smallest unique hashes, it might look like this:

```scala mdoc
import cats.implicits._
import scala.util.hashing.MurmurHash3
import scala.collection.SortedSet

val SAMPLE_SIZE: Int = 10


def takeSample(items: List[String]): SortedSet[Double] =
  items
  .map(MurmurHash3.stringHash)                             // hash it into a pretty unique id
  .map(hashToTheta)                                        // translate into theta values
  .foldLeft(SortedSet.empty[Double]) {
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
```

You can see we've got our 10 bottom theta entries, and the top theta represents our cut-off point, so we've sampled 10 items, they're in this part, and we can then estimate the rest:

```scala mdoc
def estimate(sample: SortedSet[Double]): Double =
  if (sample.size < SAMPLE_SIZE) { // if we haven't filled our sample, we know the exact number
    sample.size.toDouble
  } else {
    val theta = sample.max
    (SAMPLE_SIZE - 1) / theta
  }

estimate(takeSample(List.fill(100)("example")))
estimate(takeSample(generate(10)))
estimate(takeSample(generate(100)))
estimate(takeSample(generate(1000)))
```

As you can see the accuracy's not great with 10 items, but we've given it a good try.

## RAM use

The number of items we keep is usually expressed as a power of 2, just like in the HyperLogLog, so configuring a theta sketch with precision `4` gives you a sample of `16` values, making this comparable to how we configure a HyperLogLog for space efficiency.

We can generate the same kind of size table we had for HyperLogLog, in this example I used a `Double` which is 64-bits, so it looks like this:

```scala mdoc
import squants.information._

// Turn a data size into something friendly for a human
def humanize(input: Information): Information =
  input.in(List(Bytes, Kilobytes, Megabytes, Gigabytes)
    .findLast(unit => unit(1) < input).getOrElse(Bits)).rounded(2)

(4 to 16).map { p =>
  val sampleSize = Math.pow(2, p).toLong             // 2 to the power of precision is how many buckets we have
  val thetaSize  = Bits(64)                          // we're using 64-bit doubles here
  val dataSize   = humanize(sampleSize * thetaSize)  // each bucket's size is still hashSize, so we just multiply
  p -> dataSize
}
```

## CPU use

Again most of what we've done is use a hash algorithm, so we're still in `O(N)` territory, as long as the `Set` or similar which you build in has efficient operations for `contains` and `add` and `remove`.
