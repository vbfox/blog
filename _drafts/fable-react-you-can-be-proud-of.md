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

TODO:

* Tweaking Should component update
* Using components as delimiters in react diff algorithm
* Use ofList/ofArray
* Concatenation in React vs sprintf
* Capturing lambdas (Avoiding in pure components & class ones)
* Test samples
* Make JSX work on my blog.

-------------------

React components in F#
----------------------

While it is possible to use react as a templating engine for HTML by using only build-in components what really unlock
the power of React and where lie the biggest potential for optimisation is in it's user-defined components.

Creating Components in F# is really similar to how they are created in modern Javascript. The main difference come when
consuming them as their prevalent usage is via JSX in the Javascript world but there is no such transforms in F# and
React must be used as specified in the [React Without JSX](https://reactjs.org/docs/react-without-jsx.html) guide.

What it mean is that React elements must be created via `React.createElement` sometimes directly but most often via one
of the helpers provided by `Fable.React`: `ofType`, `ofFunction`...

### Class Component hello world

To create an user-defined component in F# a class must be create that inherit from
`Fable.React.Component<'props,'state>` and implement at least the mandatory `render()` method that returns a
`ReactElement`.

Here is a simple "Hello World" Component in Javascript (with JSX):

```jsx
class Welcome extends React.Component {
  render() {
    return <h1>Hello, {this.props.name}</h1>;
  }
}

function test() {
    const element = <Welcome name="🌍" />
    ReactDOM.render(element, document.getElementById("root"))
}
```

The same in Javascript (without JSX):

```javascript
class Welcome extends React.Component {
  render() {
    return React.createElement("h1", null, "Hello, ", this.props.name);
  }
}

function test() {
  const element = React.createElement(Welcome, { name: "🌍" });
  ReactDOM.render(element, document.getElementById("root"));
}
```

An now the equivalent F# :

```fsharp
type [<Pojo>] WelcomeProps = { name: string }

type Welcome(initialProps) =
    inherit Component<WelcomeProps, obj>(initialProps)
    override this.render() =
        h1 [] [ str "Hello "; str this.props.name ]

let test() =
    let element = createElement(typedefof<Welcome>, { name = "🌍" })
    ReactDom.render(element, document.getElementById("root"))
```

A few notes here:

* The F# version looks a lot like the no-JSX version
* We had to declare `WelcomeProps` while Javascript could do without, and in addition we had to declare it as `[<Pojo>]`
  to ensure that Fable generate an anonymous JS object instead of creating a class (React reject props passed as class
  instances)
* Using `sprintf` in the F# sample could have seemed natural but using React for it is a lot better on a performance
  standpoint as we'll see later.
* I used `createElement(typedefof<Welcome>, ...` to mimic the Javascript syntax but the `ofType` is a lot more common as
  it allow a syntax similar to the one used in the `h1` component and strongly type it's parameters.

### Class Component with state

All features of React are available in Fable and while the more "Functionnal" approach of re-rendering with new props
is more natural using mutable state is totally possible :

```fsharp
type [<Pojo>] CounterDisplayProps = { counter: int }

type CounterDisplay(initialProps) =
    inherit PureStatelessComponent<CounterDisplayProps>(initialProps)
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
    ReactDom.render(mkCounter (), document.getElementById("root"))
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

