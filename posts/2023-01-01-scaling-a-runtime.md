---
title: Scaling a Runtime
---

# Introduction

Lately we've seen a big surge in cloud computing, and patterns where you only pay for the compute value you've used.

This got me thinking, many of us backend engineers got used to the fact that we run a server daemon which can serve requests, and the more requests we get, the more of these we run in parallel.

This is certainly still the common pattern for languages like Java or C#, but what can we learn from the 1990s about scaling?

Languages that usually use a daemon:
* JVM languages (Java, Scala, Kotlin, etc.)
* CLR languages (C#, F#)
* Python
* Ruby
