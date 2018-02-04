---
layout: post
title: "Fable: React you can be proud of ! Part 1: React in Fable land"
tags: Fable, React, Elmish, Performance
date: 2018-02-05
---

[Fable][] coupled with [Fable.React][] and [Fable.Elmish.React][] are powerful tools to generate javascript applications. But generating good and performant React code is an already complex task that isn't made simpler by using a different language and a transpiler.

[Fable]: http://fable.io/
[Fable.React]: https://github.com/fable-compiler/fable-react
[Fable.Elmish.React]: https://fable-elmish.github.io/react/

In this series of posts I plan to show how some common React constructs are done in F# and what
to look for when optimizing them.

The posts will be:

1. [React in Fable land]({{ site.baseurl }}{% link _drafts/fable-react-1-react-in-fable-land.md %}) (This one)
1. Optimizing React
1. Applying to Elmish

Starting a sample Fable React project
-------------------------------------

If you want to try the code for yourself you'll need a sample

* Start with the fable template as in the [Getting started guide][getting-started]
* Replace the `h1` and `canvas` tags in `public/index.html` with `<div id="root"></div>`
* Ensure that we have the latest stable version of everything: `.paket\paket.exe update`
* Add `Fable.React` using paket: `.paket/paket.exe add Fable.React -p src/FableApp.fsproj`
* Add the necessary JS libs with `yarn add react react-dom`
* Change the `App.fs` file to look like that:

[getting-started]: http://fable.io/docs/getting-started.html

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

![Hello 🌍]({{"/assets/fable-react/hello-world.png" | absolute_url}})

Creating HTML elements
----------------------

As F# doesn't have any JSX-like transform creating React elements is done as explained in the [React Without JSX][react-without-jsx] article, except that instead of directly using
`createElement` a bunch of helpers are available in the
[`Fable.Helpers.React` module][react-helpers].

For HTML elements the resulting syntax is strongly inspired by the [Elm][] one.

[react-without-jsx]: https://reactjs.org/docs/react-without-jsx.html
[react-helpers]: https://github.com/fable-compiler/fable-react/blob/master/src/Fable.React/Fable.Helpers.React.fs
[Elm]: http://elm-lang.org/

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
            li [] [ str "The answer is: "; ofInt 42 ]
            li [] [ str "π="; ofFloat 3.14 ]

            // ofOption can be used to return either null or something
            li [] [ str "🤐"; ofOption (Some (str "🔫")) ]
            // And it can also be used to unconditionally return null, rendering nothing
            li [] [ str "😃"; ofOption None ]

            // ofList allow to expose a list to react, as with any list of elements
            // in React each need an unique and stable key
            [1;2;3]
                |> List.map(fun i ->
                    let si = i.ToString()
                    li [Key si] [str "🎯 "; str si])
                |> ofList

            // fragment is the <Fragment/> element introduced in React 16 to return
            // multiple elements
            [1;2;3]
                |> List.map(fun i ->
                    let si = i.ToString()
                    li [Key si] [str "🎲 "; str si])
                |> fragment []
        ]
```

![Output of helpers demonstration]({{"/assets/fable-react/helpers.png" | absolute_url}})

## React components

While it is possible to use react as a templating engine for HTML by using only built-in components what really unlock
the power of React and where lie the biggest potential for optimization is in it's user-defined components.

Creating Components in F# is really similar to how they are created in modern JavaScript. The main difference come when
consuming them as we'll use the `ofType` and `ofFunction` helpers (Instead of using JSX or `React.createElement`).

### Functional Components

The easiest to use F# components are Functional ones, they don't need a class, a simple function taking props and returning a `ReactElement` will do. They can then be created using the `ofType` helper.

Let's see how they are created in JavaScript:

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

![Hello, 🌍]({{"/assets/fable-react/components-h1.png" | absolute_url}})

Some notes:
* We had to declare `WelcomeProps` while JavaScript could do without, and in addition we had to declare it as `[<Pojo>]`
  to ensure that Fable generate an anonymous JS object instead of creating a class (React reject props passed as class
  instances)
* Using `sprintf` in the F# sample could have seemed natural but using React for it is a lot better on a performance
  standpoint as we'll see later.

*Note: Due to some peculiarities of the Fable transform there can be negative performance impact of using them but they are avoidable if you know what to look for. I'll detail this some more in the second post*

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

![Hello, 🌍]({{"/assets/fable-react/components-h1.png" | absolute_url}})

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

All features of React are available in Fable and while the more "Functional" approach of re-rendering with new props
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
    let element = counter createEmpty
    ReactDom.render(element, document.getElementById("root"))
```

![Counter = 42]({{"/assets/fable-react/state-counter.png" | absolute_url}})

*Note: This sample use a few react-friendly optimizations that will be the subject of the second post.*

## That's all folks

Nothing special this time and for anyone that know both React and Fable there was not a lot of
new information but we'll expand it next time !