---
title: Count Distinct at Scale I 
og-description: Introduction to Probabilistic Data Structures, using Count Distinct and introducing HyperLogLog.
---

This is the first in a series of posts about Probabilistic Data Structures, something I use a lot as a Software Engineer.

These are algorithms and data structures that allow us to analyse large streams of data without using much RAM or CPU.

# Count Distinct

One problem we might solve with these is `Count Distinct`, we have a stream of items, and we want to estimate how many unique items there are.

We could solve this in a super simple way by hashing each item we see, and keeping track of the hash we've seen with the most leading zeroes: 


```scala
import cats.implicits._
import scodec.bits._
import scala.util.hashing.MurmurHash3

def leadingZeroes(b: BitVector): Int = b.toIndexedSeq.takeWhile(_ == false).size

(0 to 1000).map(_.toString)     // make some input we can use
  .map(MurmurHash3.stringHash)  // hash it into a pretty unique id
  .map(BitVector.fromInt(_))    // inspect it as a BitVector, for demo purposes
  .maxBy(leadingZeroes)         // find the one with the most leading zeroes
  .toBin                        // show it as a binary string for demo purpises
// res0: String = "00000000000000000101010101100100"
```

As you can guess, there's some kind of relationship between the most leading zeroes we've seen, and how many unique items we've seen; this is the main mechanic used in Count Distinct algorithms.

```scala
bin"11111111111111111111111111111111" // we've seen one unique item

bin"00000000000000000101010101100100" // we've seen a few unique items

bin"00000000000000000000000000000000" // we've seen an incredibly large number of unique items
```

Obviously this is based on probability, and we won't get much accuracy out of a single value so...

# HyperLogLog

What if we could keep track of a load of these for the same data stream?

The HyperLogLog's main mechanic is that it splits our hash into two halves, this is the number you configure a HyperLogLog with, usually between 4 and 16, because we're using a 32-bit hash.

```scala
val precision = 4 // use the first 4 bytes as a bucket index
// precision: Int = 4 // use the first 4 bytes as a bucket index

(0 to 1000).map(_.toString)       // make some input we can use
  .map(MurmurHash3.stringHash)    // hash it into a pretty unique id
  .map(BitVector.fromInt(_))      // inspect it as a BitVector, for demo purposes
  .map(_.splitAt(precision))      // split into our index, and our remaining hash
  .groupMapReduce(_._1)(_._2)(    // group by index
    Ordering[Int].contramap(leadingZeroes).max // find the item with the most leading zeroes in each bucket
  )       
  .map { case (k, v) => k.toBin -> v.toBin }  // display them as strings for demo purposes
// res4: Map[String, String] = HashMap(
//   "1101" -> "0000000000110000000000001101",
//   "0001" -> "0000000100100010101001001101",
//   "1001" -> "0000000010010010010111001101",
//   "0000" -> "0000000000000101010101100100",
//   "0011" -> "0000001001101000110010111001",
//   "0010" -> "0000000100110111011100011001",
//   "1110" -> "0000000010111010100000011101",
//   "0111" -> "0000001000010101111110011011",
//   "1100" -> "0000000110001100011101101011",
//   "0100" -> "0000000111110010000011110110",
//   "0110" -> "0000000000010100001111111101",
//   "1010" -> "0000011101100010110001101100",
//   "1111" -> "0000000011110110110111010000",
//   "1011" -> "0000001111101011000110100110",
//   "1000" -> "0000000001100001010100111010",
//   "0101" -> "0000010010010000010011101000"
// )
```

As you can see we've now got a kind of sensible amount of leading zeroes in each bucket, and this should allow us to make a much more precise estimate.

I won't cover the estimation formula here, but you can read the papers if you'd like to see it.
