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

Multiple articles :

* React in Fable
* Optimizing React in Fable

TODO:

* Tweaking Should component update
* Using components as delimiters in react diff algorithm
* Use ofList/ofArray
* Concatenation in React vs sprintf
* Capturing lambdas (Avoiding in pure components & class ones)
* Test samples
* Make JSX work on my blog.
* Functional components in other modules

-------------------

Part 1 - React in Fable land
-------------------

-------------------

Starting a sample Fable React project
-------------------------------------

If you want to try the code for yourself you'll need a sample

* Start with the fable template as in the [Getting started guide](http://fable.io/docs/getting-started.html)
* Replace the `h1` and `canvas` tags in `public/index.html` with `<div id="root"></div>`
* Ensure that we have the latest stable version of everything: `.paket\paket.exe update`
* Add `Fable.React` using paket: `.paket/paket.exe add Fable.React -p src/FableApp.fsproj`
* Add the necessary JS libs with `yarn add react react-dom`
* Change the `App.fs` file to look like that:

```fsharp
module FableApp

open Fable.Core
open Fable.Core.JsInterop
open Fable.Import
open Fable.Import.Browser
open Fable.Import.React
open Fable.Helpers.React
open Fable.Helpers.React.Props

let init() =
    let element = str "Hello 🌍"
    ReactDom.render(element, document.getElementById("root"))

init()
```

Creating HTML elements
----------------------

As F# doesn't have any JSX-like transform creating React elements is done as explained in the [React Without JSX](https://reactjs.org/docs/react-without-jsx.html) article, except that instead of directly using `createElement` a
bunch of helpers are available in the
[`Fable.Helpers.React` module](https://github.com/fable-compiler/fable-react/blob/master/src/Fable.React/Fable.Helpers.React.fs).

For HTML elements the resulting syntax is strongly inspired by the [Elm](http://elm-lang.org/) one.

Here is a small sample of the more common ones :

```fsharp
let element =
    // Each HTML element has an helper with the same name
    ul
        // The first parameter is the properties of the elements.
        // For html elements they are specified as a list and for custom
        // elements it's more typical to find a record creation
        [ClassName "my-ul"; Id "unique-ul"]

        // The second parameter is the list of children
        [
            // str is the helper for exposing a string to React as an element
            li [] [ str "Hello 🌍" ]

            // Helpers exists also for other primitive types
            li [] [ str "Answer is: "; ofInt 42 ]
            li [] [ ofFloat 1.42 ]

            // ofOption can be used to return either null or something
            li [] [ ofOption (Some (str "Hello 🌍")) ]
            // And it can also be used to unconditionally return null, rendering nothing
            li [] [ ofOption None ]

            // ofList allow to expose a list to react, as with any list of elements
            // in React each need an unique and stable key
            [1;2;3]
                |> List.map(fun i ->
                    let si = i.ToString()
                    li [Key si] [str si])
                |> ofList

            // fragment is the <Fragment/> element introduced in React 16 to return
            // multiple elements
            [1;2;3]
                |> List.map(fun i ->
                    let si = i.ToString()
                    li [Key si] [str si])
                |> fragment []
        ]
```

React components
----------------------

While it is possible to use react as a templating engine for HTML by using only built-in components what really unlock
the power of React and where lie the biggest potential for optimisation is in it's user-defined components.

Creating Components in F# is really similar to how they are created in modern Javascript. The main difference come when
consuming them as we'll use the `ofType` and `ofFunction` helpers (Instead of using JSX or `React.createElement`).

### Functional Components

The easiest to use F# components are Functional ones, they don't need a class, a simple function taking props and returning a `ReactElement` will do. They can then be created using the `ofType` helper.

Let's see how they are created in javascript:

```jsx
function Welcome(props) {
  return <h1>Hello, {props.name}</h1>;
}

function init() {
    const element = <Welcome name="🌍" />;
    ReactDOM.render(element, document.getElementById("root"));
}
```

And the equivalent in F#:

```fsharp
type [<Pojo>] WelcomeProps = { name: string }

let Welcome { name = name } =
    h1 [] [ str "Hello, "; str name ]

let inline welcome name = ofFunction Welcome { name = name } []

let init() =
    let element = welcome "🌍"
    ReactDom.render(element, document.getElementById("root"))
```

Some notes:
* We had to declare `WelcomeProps` while Javascript could do without, and in addition we had to declare it as `[<Pojo>]`
  to ensure that Fable generate an anonymous JS object instead of creating a class (React reject props passed as class
  instances)
* Using `sprintf` in the F# sample could have seemed natural but using React for it is a lot better on a performance
  standpoint as we'll see later.

*Note: Due to some pecularities of the Fable transform there can be negative performance impact of using them but they are avoidable if you know what to look for.*

<div style="background-color:red;text-align:center">LINK TO PERF EXPLANATION</div>

### Class Components

To create an user-defined component in F# a class must be created that inherit from
`Fable.React.Component<'props,'state>` and implement at least the mandatory `render()` method that returns a
`ReactElement`.

Let's port our "Hello World" Component:

```fsharp
type [<Pojo>] WelcomeProps = { name: string }

type Welcome(initialProps) =
    inherit Component<WelcomeProps, obj>(initialProps)
    override this.render() =
        h1 [] [ str "Hello "; str this.props.name ]

let inline welcome name = ofType<Welcome,_,_> { name = name } []

let init() =
    let element = welcome "🌍"
    ReactDom.render(element, document.getElementById("root"))
```

Nothing special here, the only gotcha is that the props passed in the primary constructor while they are in scope in
the `render()` method should not be used. It can be avoided at the price of a little more complex syntax:

```fsharp
type Welcome =
    inherit Component<WelcomeProps, obj>
    new(props) = { inherit Component<_, _>(props) }
    override this.render() =
        h1 [] [ str "Hello "; str this.props.name ]
```

### Class Component with state

All features of React are available in Fable and while the more "Functionnal" approach of re-rendering with new props
is more natural using mutable state is totally possible :

```fsharp
// A pure, stateless component that will simply display the counter
type [<Pojo>] CounterDisplayProps = { counter: int }

type CounterDisplay(initialProps) =
    inherit PureStatelessComponent<CounterDisplayProps>(initialProps)
    override this.render() =
        div [] [ str "Counter = "; ofInt this.props.counter ]

let inline counterDisplay p = ofType<CounterDisplay,_,_> p []

// Another pure component displaying the buttons
type [<Pojo>] AddRemoveProps = { add: MouseEvent -> unit; remove: MouseEvent -> unit }

type AddRemove(initialProps) =
    inherit PureStatelessComponent<AddRemoveProps>(initialProps)
    override this.render() =
        div [] [
            button [OnClick this.props.add] [str "👍"]
            button [OnClick this.props.remove] [str "👎"]
        ]

let inline addRemove props = ofType<AddRemove,_,_> props []

// The counter itself using state to keep the count
type [<Pojo>] CounterState = { counter: int }

type Counter(initialProps) as this =
    inherit Component<obj, CounterState>(initialProps)
    do
        this.setInitState({ counter = 0})

    // This is the equivalent of doing `this.add = this.add.bind(this)`
    // in javascript (Except for the fact that we can't reuse the name)
    let add = this.Add
    let remove = this.Remove

    member this.Add(_:MouseEvent) =
        this.setState({ counter = this.state.counter + 1 })

    member this.Remove(_:MouseEvent) =
        this.setState({ counter = this.state.counter - 1 })

    override this.render() =
        div [] [
            counterDisplay { CounterDisplayProps.counter = this.state.counter }
            addRemove { add = add; remove = remove }
        ]

let inline counter props = ofType<Counter,_,_> props []

// createEmpty is used to emit '{}' in javascript, an empty object
let init() =
    let element = counter createEmpty<obj>
    ReactDom.render(element, document.getElementById("root"))

init()
```

------------------------

Part 2 - React, how does it work and how to optimize it
-------------------

------------------------

## How does React works

The mechanism is described in a lot of details on the [Reconciliation](https://reactjs.org/docs/reconciliation.html)
page of React documentation, I won't repeat all of the details but it can be summarized like this:

1. Starting from the root element
1. Determine what high level operation is needed: addition, deletion, update or re-creation
   * If there was no previous element a new one is created (First call to `ReactDom.render`)
   * If the type of the previous element is different it is destroyed and a new one created (`<div/>` to `<table/>`)
   * Otherwise it is updated
1. Determine if the element should really be updated
   * Always if there was no other elements before at this position
   * Always if the element that was previously there was of a different type
   * True by default for `Component` instance, Functional components ones
   * Can be overrident by `shouldComponentUpdate` like `PureComponent` does
1. Call it's `render` method
   * Or the function itself for functional components
   * This will recurse an apply the same steps for all elements returned by render

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

