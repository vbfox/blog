---
layout: post
title: "Fable: React you can be proud of!"
tags: Fable, React, Elmish, Performance
date: 2018-02-01
---

[Fable](http://fable.io/) when coupled with [Fable.React](https://github.com/fable-compiler/fable-react) and
[Fable.Elmish.React](https://fable-elmish.github.io/react/) are powerful tools to generate javascript applications but
when it come to optimizing the resulting code they can be tricky, especially as the potential pitfalls and possible
optimizations aren't well documented yet.

In this article I'll try to cover these subjects from the point of view of a Fable developer using React as it's primary
method to interact with the DOM, both directly and via `Fable.Elmish.React`. While I'll start with concepts that any
seasoned React developer already know I hope that by the end of the article most of you will have learnt something.

-------------------

React components in F#
----------------------

While it is possible to use react as a templating engine for HTML by using only build-in components what really unlock
the power of React and where lie the biggest potential for optimisation is in it's user-defined components.

### Components

To create an user-defined component in F# a class must be create that inherit from
`Fable.React.Component<'props,'state>` and implement at least the mandatory `render()` method that returns a
`ReactElement`.

While such a class would directly usable in JSX there is no such transforms in F# and React must be used as specified in
the [React Without JSX](https://reactjs.org/docs/react-without-jsx.html) guide. What it mean is that React elements must
be created via `React.createElement` and `Fable.React` provide mutiple helpers for that like `ofType` that we will use
here.

Here is a simple "Hello World" Component:

```fsharp
type HelloWorld(initialProps) =
    inherit Component<obj, obj>(initialProps)
    override this.render() =
        div [] [ str "Hello 🌍" ]

let inline mkHelloWorld p = ofType<HelloWorld,_,_> p []

let test() =
    ReactDom.render(
        mkHelloWorld createEmpty<obj>,
        document.getElementById("placeholder"))
```

Displaying a counter

```fsharp
type [<Pojo>] CounterDisplayProps = { counter: int }

type CounterDisplay(initialProps) =
    inherit Component<CounterDisplayProps, obj>(initialProps)
    override this.render() =
        div [] [ str "Counter = "; str this.props.counter ]

let inline mkCounterDisplay p = ofType<CounterDisplay,_,_> p []

let test() =
    ReactDom.render(
        mkCounterDisplay { counter = 0 },
        document.getElementById("placeholder"))
```

A counter that works using state only

```fsharp
type [<Pojo>] CounterDisplayProps = { counter: int }

type CounterDisplay(initialProps) =
    inherit Component<CounterDisplayProps, obj>(initialProps)
    override this.render() =
        div [] [ str "Counter = "; str this.props.counter ]

let inline mkCounterDisplay p = ofType<CounterDisplay,_,_> p []

type [<Pojo>] CounterState = { counter: int }

type Counter(initialProps) =
    inherit Component<obj, CounterState>(initialProps)
    do
        setInitState({ counter = 0})

    member this.Add() = this.setState({ counter = this.state.counter + 1 })
    override this.render() =
        div [] [
            mkCounterDisplay { CounterDisplayProps.counter = this.state.counter }
            button [OnClick this.Add] [str "👍"]
        ]

let inline mkCounter () = ofType<Counter,_,_> createEmpty<obj> []

let test() =
    ReactDom.render(
        mkCounter (),
        document.getElementById("placeholder"))
```

Functional Components
---------------------

```fsharp
type [<Pojo>] Props = { counter: int }

let CounterDisplay { counter = counter } =
    div [] [ str "Counter = "; str counter ]

let inline mkCounterDisplay p = ofFunction Counter p []

let test() =
    ReactDom.render(
        mkCounterDisplay { counter = 0 },
        document.getElementById("placeholder"))
```

## How does React works

### To `render()` or not to `render()`

* https://reactjs.org/docs/optimizing-performance.html#avoid-reconciliation
* https://reactjs.org/docs/optimizing-performance.html#shouldcomponentupdate-in-action

### Updating the DOM: The reconciliation

https://reactjs.org/docs/reconciliation.html

## Optimizations in a pure Fable React world

```fsharp
type Props = { counter: int }
type MyCoolComponent(initialProps) =
    inherit PureComponent<Props, obj>(initialProps)

```

Also

```fsharp
open Fable.Core
open Fable.Core.JsInterop

let onClick (f: unit -> unit) = ()

type Foo() as this=
    let add = this.Add
    member this.Add() = ()
    member this.Render() =
        onClick(add)
```
-------------------

## The Flux/Elm pattern, and it's complexities

* https://github.com/facebook/flux/tree/master/examples/flux-concepts

