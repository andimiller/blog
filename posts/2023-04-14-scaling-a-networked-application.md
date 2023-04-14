---
title: Scaling a Networked Application
tags: scala, architecture, functional programming
draft: true
---

The semi-recent hype around serverless has made me think, how should we be scaling networked programs?

# Daemons

The standard way to run some kind of server in scala today looks like this:

![Diagram showing a java process which contains a main thread, and multiple worker threads](/images/scaling1.svg)

This should be familiar if you've worked in other similar languages, you'll find the same pattern in python, C#, golang, the list goes on.

It's running, usually with a set number of workers spawned, using a load of RAM and CPU waiting for requests to come in.

Why do we do this? well it's all in one process so we can share memory and side-effect our way between the threads for things like caches or shared database connection pools.

Hold up, did I just say side-effect? we don't like those if we're functional programmers, can we do anything better?

# Forking Programs

Back in the early days of the web, we had scripting languages like PHP and Perl, where we'd just tell the web browser to execute scripts when people called endpoints, there was no global state and the scripts ran and exited.

![Diagram showing php-fpm launching various scripts as workers](/images/scaling2.svg)

This time in our diagram, we've got a generic component called `php-fpm`, it's a C program we don't know about the internals of, and it's launching our scripts when people want to render pages.

By this design, PHP actually can't share state between workers (although there are some rather nasty hacks for this, like shared bytecode caches and accessing shared memory owned by the php-fpm manager).

We've now got programs that launch, do some work, output a result, and exit.

# Serverless

You may notice that `php-fpm` here is doing exactly what a serverless implementation would do, it's spinning up processes when we need them, it might hold a couple open but not feed them input yet just in case.

That's great! so maybe we can become better functional programmers by using serverless patterns?

Well what do I pick... AWS Lambda? DigitalOcean Functions? Apache OpenWhisk? All of these seem to be different levels of proprietary or annoying to work with so...


# CGI

CGI is the `Common Gateway Interface`, it's the standard way for web servers to launch binaries, pass HTTP requests to them, and read HTTP responses out, we've had it since the early 90s, and it can run multiple languages just fine.

Look out for the next post in this series where I introduce the scala-native framework [http4s-cgi](https://github.com/andimiller/http4s-cgi) which allows you to build CGI binaries using http4s.

![A hit counter showing the number of times this page has been loaded, loading from a cgi-bin URL](https://andimiller.net/cgi-bin/hitcounter)
