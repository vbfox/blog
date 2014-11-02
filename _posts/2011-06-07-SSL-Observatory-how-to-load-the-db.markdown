---
layout: post
title:  "SSL Observatory how to load the db"
date:   2011-06-07 21:14
tags:   Debian EFF Linux SSL-Observatory
---
The SSL Observatory is a great project from the EFF to gather all SSL
certificates available on HTTPS websites and publish them for analysis.
For more details see the [SSL Observatory][1] website.

The main problem if you don't want to analyse it using their pre-configured
Amazon EC2 configuration is that the compressed .sql file is around 3 Go
compressed using LZMA and 3 To uncompressed so you can't even un-compress the
file and need to pipe directly from 7-Zip to mysql.

To do it either on windows or linux :

```sh
7z e -so "observatory-dec-2010.sql.lzma" f | mysql -u root --password=toto42sh observatory2
```

_Note_: The 7z tools is in the `p7zip` package on a debian system.

[1]: https://www.eff.org/observatory
