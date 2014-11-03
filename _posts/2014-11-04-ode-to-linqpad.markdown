---
layout: post
title:  "Ode to LINQPad"
tags:   C#
---
[LINQPad][1] is one of my favorite tools for C# development it allow for fast
development of small bits of C# to prototype or answer [StackOverflow][2]
questions.

![LINQPad UI](/assets/linqpad-overview.png)

The original feature was to allow easy scripting of databases by providing a
LINQ to SQL view of all objects of a connection directly as members of the
generated script class. But LINQPad is a lot more generic and can serve as a C#
swiss army knife for a lot of utility scripts.

### Searching for NuGet packages

The Free and Pro editions of LINQPad don't give you access to the ability to
reference [NuGet][4] packages directly and the NuGet website doesn't provide any
download link. We'll use LINQPad itself to be able to search and download any
package by Id.

The first thing we need to do is to get access to the list of packages.
If possible not in the HTML tag-soup form...

Turns out that NuGet API is partially OData-XML and partially some REST
endpoint. As LINQPad natively support OData I'll use only that. To use it, add
a new connection of type **WCF Data Services** pointing to
`https://www.nuget.org/api/v2/` and then create a *C# Program* query using
this connection.

To start exploring we'll select some data to look at what fields are available
and how they look:

```csharp
void Main()
{
    Packages.Take(10).Dump();
}
```

`Dump` is a method that display an object in the output with a graphical
representation. For tabular data (`IQueryable`, `IEnumerable`, ...) passing true
as first argument will show it in a DataGrid.

To search for a package we will want to filter by `Id` and get only the latest
non-prerelease version so the fields we are interested in are
`IsAbsoluteLatestVersion` and `IsPrerelease` in addition to `Id` :

```csharp
void Main()
{
    var search = Util.ReadLine("Id");
    var packages =
        from package in Packages
        where package.IsAbsoluteLatestVersion
            && !package.IsPrerelease
            && package.Id.StartsWith(search)
        select package;
    packages.Dump(true);
}
```

This version of the code also introduce `Util.ReadLine` a method that display an
input line at the bottom of the LINQPad output.

### Adding download links

Now that we have all info from our package we need the download URL, turns out
that it isn't directly included in the data but we should be able to build it
from the information we already have.

As NuGet is open-source we can read the [source code][5] and find how package
download urls are constructed :

```csharp
// Route to get packages
routes.MapDelegate("DownloadPackage",
                   "api/v2/package/{packageId}/{version}",
                   new { httpMethod = new HttpMethodConstraint("GET") },
                   context => CreatePackageService().DownloadPackage(context.HttpContext));
```

We know `version` and `packageId` so we can now display the download URL.

But LINQPad allow us to do a lot more:  the `Hyperlinq` type is a magic one that
when passed to `Dump` show a clickable link in the output window.

The link can be constructed with an `Action` delegate that will be executed when
clicked but for such a simple case we'll use the version taking directly an URL:

```csharp
foreach(var package in packages)
{
    var url = string.Format(@"https://www.nuget.org/api/v2/package/{0}/{1}",
        package.Id, package.Version);
    var text = string.Format(@"{0} (v{1})", package.Id, package.Version);
    new Hyperlinq(url, text).Dump();
}
```

Which give us a nice clickable list of packages starting with a string directly
in LINQPad output :

![Links in output](/assets/linqpad-nuget-packages.png)

### Pricing

Regarding the price for free you get the basic UI, the Pro versions is at
**40$** (Autocompletion) and the Premium (Direct SQL table editing + NuGet) is
at **75$**.

The price is small (and often discounted) but as [Roslyn][3] is Open Source and
make creating IDE text editors with auto-completion a lot easier I expect
movement in this space especially for the Pro version features.

[1]: http://www.linqpad.net/
[2]: https://stackoverflow.com/
[3]: https://roslyn.codeplex.com/
[4]: https://www.nuget.org
[5]: https://nuget.codeplex.com/SourceControl/latest#src/Server/DataServices/Routes.cs
