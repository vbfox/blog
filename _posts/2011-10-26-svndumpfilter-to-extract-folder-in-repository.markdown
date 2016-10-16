---
layout: post
title: "Using svndumpfilter to extract a folder in it's own repository"
date: 2011-10-26 21:29
tags: Linux, SVN
---
What i'll explain here is how to use the
[`svndumpfilter`](http://svnbook.red-bean.com/en/1.5/svn.ref.svndumpfilter.html)
program to extract a folder of an SVN repository in it's own repository and
make it disappear from the history of the original one.

### What you'll need

You will need direct access to the server and to warn all your users that they'll
need to checkout again everything you will move (if you don't renumber the revisions
otherwise all users will need to checkout again any part of the repository they use)

### Knowing what to filter

You will need to include all the folders you want along with all the folders where
something moved, for example if you want `/some/dir` but it was at some point in the
history named `/somedir` and renamed later you need to include both in the filter.

The same apply if only some of the files moved from there in this case you need to
include each file that moved.

You'll end up with a list of files and directories representing all the history of
the files that will be extracted.

### Dump the repository

The first step is to dump the repository as `svndumpfilter` only act on dumps and
not on directories themselves

```sh
svnadmin dump repo > repo.dump
```

### Filter the history and load it in a new repository

To create a dump that contains only the change in our chosen directories the
command is :

```sh
svndumpfilter include --drop-empty-revs --renumber-revs /some/dir /somedir < repo.dump > repo-only-some-dir.dump
```

The two options `--drop-empty-revs` and `--renumber-revs` are what you'll need in
99% of the cases but anyway you'll either want both or none :

* Both will give you a clean new repository with new revisions starting at zero
  and no empty revisions. It's clean but if you had anywhere else (in the
  source code comments, in your issue tracker or in some commit message)
  something referencing "r3628" it will now be incorrect.
* None will give you a chance to have the same revision numbers (Only if you
  don't need to create new directories otherwise all revision numbers will move,
  see next paragraph)

Then you'll need to create a new repository

```sh
mkdir newrepo
svnadmin create newrepo
```

If some of the directories you included had a parent that wasn't himself
included (like our `/some/dir` directory) you need to create them back

```sh
svn checkout "file:////path/to/newrepo/" newrepocheckout
mkdir newrepocheckout/some
svn add newrepocheckout/some
svn commit newrepocheckout -m "Prepare to load filtered history"
rm -R newrepocheckout
```

Then finally load your filtered history :

```sh
svnadmin load newrepo < repo-only-some-dir.dump
```

### Remove the files from the originating repository history

It's simplier as you normally won't have to create any directory, just load the dump
in place of the old repo.

The same choice is offered to you regarding removing the now-empty revs from the
history and renumbering the other revisions but in this case it's more logical to
keep the revisions as it will allow for all users that hadn't checked out the removed
directories to continue to work with their checkouts. Otherwise they'll need a clean
new checkout.

```sh
rm -R repo
svndumpfilter include /some/dir /somedir < repo.dump > repo-without-some-dir.dump
mkdir repo
svnadmin create repo
svnadmin load repo < repo-without-some-dir.dump
```
