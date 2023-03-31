---
title: Count Distinct at Scale I 
og-description: Introduction to Probabilistic Data Structures, using Count Distinct and introducing HyperLogLog.
tags: scala, probabilistic data structures, big data
---

This is the first in a series of posts about Probabilistic Data Structures, something I use a lot as a Software Engineer specialising in Big Data.

These are algorithms and data structures that allow us to analyse large streams of data without using much RAM or CPU, relying on statistics and probabilities to do work for us.

# Count Distinct

One problem we might solve with these is `Count Distinct`, we have a stream of items, and we want to estimate how many unique items there are.

We could solve this in a super simple way by hashing each item we see, and keeping track of the hash we've seen with the most leading zeroes: 


```scala mdoc
import cats.implicits._
import scodec.bits._
import scala.util.hashing.MurmurHash3

def leadingZeroes(b: BitVector): Int = b.toIndexedSeq.takeWhile(_ == false).size

(0 to 1000).map(_.toString)     // make some input we can use
  .map(MurmurHash3.stringHash)  // hash it into a pretty unique id
  .map(BitVector.fromInt(_))    // inspect it as a BitVector, for demo purposes
  .maxBy(leadingZeroes)         // find the one with the most leading zeroes
  .toBin                        // show it as a binary string for demo purposes
```

As you can guess, there's some kind of relationship between the most leading zeroes we've seen, and how many unique items we've seen; this is the main mechanic used in Count Distinct algorithms.

```scala mdoc:silent
bin"11111111111111111111111111111111" // we've seen one unique item

bin"00000000000000000101010101100100" // we've seen a few unique items

bin"00000000000000000000000000000000" // we've seen an incredibly large number of unique items
```

Obviously this is based on probability, and we won't get much accuracy out of a single value so...

# HyperLogLog

What if we could keep track of a load of these for the same data stream?

The HyperLogLog's main mechanic is that it splits our hash into two halves, the split point is the number you configure a HyperLogLog with, usually between 4 and 16, because we're using a 32-bit hash.

```scala mdoc
val precision = 4 // use the first 4 bytes as a bucket index

(0 to 1000).map(_.toString)       // make some input we can use
  .map(MurmurHash3.stringHash)    // hash it into a pretty unique id
  .map(BitVector.fromInt(_))      // inspect it as a BitVector, for demo purposes
  .map(_.splitAt(precision))      // split into our index, and our remaining hash
  .groupMapReduce(_._1)(_._2)(    // group by index
    Ordering[Int].contramap(leadingZeroes).max // find the item with the most leading zeroes in each bucket
  )
  .toList
  .sortBy(_._1)       
  .map { case (k, v) => k.toBin -> v.toBin }  // display them as strings for demo purposes
```

As you can see we've now got a kind of sensible amount of leading zeroes in each bucket, and this should allow us to make a much more precise estimate.

I won't cover the estimation formula here, but you can read the papers if you'd like to see it.

## RAM use

This actually uses a constant amount of RAM, based on the precision:

```scala mdoc
import squants.information._

// Turn a data size into something friendly for a human
def humanize(input: Information): Information =
  input.in(List(Bytes, Kilobytes, Megabytes, Gigabytes)
    .findLast(unit => unit(1) < input).getOrElse(Bits)).rounded(2)

(4 to 16).map { p =>
  val bucketCount = Math.pow(2, p).toLong          // 2 to the power of precision is how many buckets we have
  val hashSize = Bits(32)                          // we're using 32-bit hashes here, you could use 64-bit
  val dataSize = humanize(bucketCount * hashSize)  // each bucket's size is still hashSize, so we just multiply
  p -> dataSize
}
```

I've ommitted any extra overhead from your programming language of choice, there's a bit extra for your array or similar data structure.


## CPU use

All we've really done is use a hash algorithm and compare some numbers, so this is `O(N)` time complexity with the main variability coming from the hash algorithm, which will be `O(N)` based on length of the item being hashed usually. 
