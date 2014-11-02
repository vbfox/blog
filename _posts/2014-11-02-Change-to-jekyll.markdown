---
layout: post
title:  "Blog engine changed to Jekyll"
date:   2014-11-02 11:49
tags: blog ruby
---

This weekend I wanted to blog about [libgit2sharp][1] but I realised that my
setup for blogging wasn't really practical. I used [dotclear][2] but by
insisting on markdown and refusing the graphical editor it was only an hindrance
for me.

In response I investigated the domain of the simple blogging plaforms running
only locally and generating html files.
The one I ended up using is a ruby tool named [Jekyll][3]; the one that is used
by GitHub for their GitHub pages.

What is nice is that using a web-hook on my [blog repository][4] the simple fact
of pushing a new markdown file or modifying a sass file will re-generate all my
blog with the changes.

[1]: https://github.com/libgit2/libgit2sharp
[2]: http://dotclear.org/
[3]: http://jekyllrb.com/
[4]: https://github.com/vbfox/blog
