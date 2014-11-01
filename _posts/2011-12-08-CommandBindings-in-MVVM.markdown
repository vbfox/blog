---
layout: post
title:  "Using CommandBindings in MVVM"
date:   2011-12-08 00:09
tags: C# MVVM WPF
---
One sad thing in WPF currently is that the `CommandBindings` used to attach an action to a `RoutedCommand` don't support
the MVVM pattern : Their properties can't be easily bound to the DataContext, and they don't support attaching a
command represented by an `ICommand`.

One of the solutions have always been to use the command sink that Josh Smith provided in it's CodePlex article [Using
RoutedCommands with a ViewModel in WPF][1]. But it's syntax force multiple changes on the view and also force the model
to implements the `Execute` and `CanExecute` independently out of an `ICommand` and don't begin to support the
`CanExecuteChanged` event.

My solution was to roll my own classes, that you could find in [a Gist on GitHub][2] to use it instead of a
CommandBindings block in your `UIElement` you declare an attached property called `Mvvm.CommandBindings` and use it with
nearly the same syntax :

```xml
    <Window x:Class="BlackFox.SampleWindow"
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            xmlns:f="clr-namespace:BlackFox"
            >
        <f:Mvvm.CommandBindings>
            <f:MvvmCommandBindingCollection>
                <f:MvvmCommandBinding
                   Command="f:MyRoutedCommands.SomeRoutedCommand"
                     Target="{Binding MyCommandInViewModel}"
                     CanExecuteChangedSuggestRequery="True" />
            </f:MvvmCommandBindingCollection>
        </f:Mvvm.CommandBindings>
    </Window>
```

The only differences are that there is a `Target` (`ICommand`) property instead of the methods and that you could
optionally force a `CommandManager.InvalidateRequerySuggested();` when the command's `CanExecuteChanged` event is
raised.

[1]: http://www.codeproject.com/KB/WPF/VMCommanding.aspx
[2]: https://gist.github.com/1445370
