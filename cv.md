---
title: "Andi Miller - Big Data Systems Engineer"
title-meta: "Andi Miller - CV"
pdf-header: "Andi Miller - CV" 
author-meta: "Andi Miller"
date: "27th August 2026"
link: "https://andimiller.net/"
papersize: "a4"
---

|
---|---|---|---
Email|Website|Citizenships|Portfolio
[andi@andimiller.net](mailto:andi@andimiller.net)|[andimiller.net](https://andimiller.net)|NZ, UK|[github.com/andimiller/](https://github.com/andimiller/)

# Skills and Experience

## Languages

|
- | -----------
Scala   | {yearsSince(2013-06)} years of experience, with {yearsSince(2016-06)} years of purely functional development, current main language.
Java    | Experience with backend Java; Apache Pinot contributions
C       | Commercial experience writing patches for OpenSIPS and Asterisk while at Gradwell.
Python  | Used for many projects including open source infrastructure for EVE Online alliances.
Haskell | Personal projects and small work tooling.

## Technologies

|
--- | ---------
Functional Programming  | Experience writing purely functional software in multiple languages.
Stream Processing       | Kafka, zeromq, RabbitMQ, Pulsar and other high throughput streaming technologies.
Big Data                | Druid, Pinot, Elastic, Cassandra and Spark for storage and aggregation.
Data Sketches           | HyperLogLog plus variants, Theta, Tuple, etc.
Artificial Intelligence | Classification and Regression model training, building with LLMs, MCP, etc.
Distributed Systems     | Have built concurrent distributed systems with actors and consensus systems.
Language Development    | Experience implementing domain specific languages with technologies including ANTLR, fastparse and droste.
Observability           | Metrics, tracing, alerting, etc.


\twocolstart

# Interesting Work

## Patent US10579827B2

- Optimisation for HyperLogLog which reduces memory use by sharding around the cluster.
- Included lazy bucketing and pre-allocation of the sharded data. 

## [IDML](https://idml.io/)

- Open source JSON processing language used for data processing at DataSift and Meltwater
- JVM first, integrated with Kafka Streams, Hadoop and ElasticSearch.
- Implemented with ANTLR and Scala.

\vfill
\columnbreak

# Open Source Contributions

## [http4s](https://github.com/http4s/http4s)

- added OkHttp client
- Header class QoL improvements

## [apache/pinot](https://github.com/apache/pinot)

- expanded Theta Sketch support
- expanded HyperLogLog support
- added Tuple Sketch support
- added UltraLogLog support

## [typelevel/cats](https://github.com/typelevel/cats)

- added extra syntax for Bitraverse

## [typelevel/cats-effect](https://github.com/typelevel/cats-effect)

- added `mapK` to `Resource`

\twocolend

\newpage

# Employment

## Senior Software Engineer, Permutive, 2022 - Present

- Scala / Typelevel / Agile
- Extended insights products, rebuilt on Pinot, average query time 30s => 1s, costs 4x lower.
- Rebuilt data query layers around Pinot and Iceberg.
- Built out MCP product for customers.
- Added LLM embedding-based advertising cohorts to contextual product.

## Senior Software Engineer, Meltwater UK, 2018 - 2022

- Scala / Typelevel / Agile
- Practiced DevOps maintaining our own infrastructure and being on call.
- Practiced Type Driven Development and Test Driven Development.
- Maintained an in-house Domain Specific Language for transforming JSON at scale in Scala.
- Worked on ingestion of firehoses into Meltwater's systems.
- Helped improve and develop the Meltwater Public API

## Platform Engineer, DataSift, 2013 - 2018

- Developed microservices in Scala with a combination of Dropwizard and scalaz-based stacks, switching to typelevel later.
- Worked in agile teams using scrum development practices.
- Co-developed an in-house Domain Specific Language for transforming JSON at scale in Scala.
- Worked on privacy-first analysis of Facebook data in Facebook's datacentre.
- Worked on the DataSift open source client libraries, with a focus on the Python one

## VoIP Engineer, Gradwell dot com Limited, Placement Year, 2011 - 2012

- Maintained and developed a large award-winning Open Source VoIP stack
- Regularly worked with both Support and Sysadmin departments
- Worked in a variety of languages, including Perl, C, Python and Ruby
- Helped migrate from CVS to Mercurial
- Helped move to and administer Jira
- Re-engineered the VoIP platform to work across multiple datacentres.
- Developed deployment infrastructure with puppet to reduce deployment time from 10 hours to 1.

## Freelance Coder (Google Summer of Code), Google, 2010

- Did some experimental work on integrating open source video and audio editors Pitivi and Jokosher
- Worked with GTK and DBus

# Education

## B. Eng. Software Engineering, University of Wales Aberystwyth, 2009 - 2013

- 2:1
- Averaged over 70% in Programming modules.
- Opted into Open Source and Artificial Intelligence modules.
