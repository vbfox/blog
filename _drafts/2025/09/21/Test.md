---
title: "Test"
categories: ["Test"]
is_draft: true
published_date: 2025-09-21 00:00:00 +0000
---
Hello world

```json
{
  "key": "value",
  "number": 123,
  "float": 12.34,
  "array": [1, 2, 3],
  "boolean": true,
  "null": null
}
```

```xml
<configuration>
  <system.webServer>
    <handlers>
      <add name="httpPlatformHandler" path="*" verb="*"
        modules="httpPlatformHandler"
      />
      <!-- resourceType="Unspecified" /-->
    </handlers>
  </system.webServer>
</configuration>
```

```js
/**
 * This is a sample of JS code
 *
 * @param {string} name
 */
function(name) {
    console.log("Hello, " + name + '!');
}

let _id; // Implicit Declearation
let fb_id; // Explicit Declearation
fb_id = true;
fb_id = 23423523 * 1;
fb_id_2 = 23423523.8;

const firstName = "Foo";
const lastName = 'Bar\nBaz';
const long = `first line
second line`;
let isLoading = false;

const re = /\w+/g;
```

```cs
namespace MyNamespace
{
    using System;

    public class MyClass
    {
        public int MyProperty { get; set; }

        public void MyMethod()
        {
            var greeting = "Hell" + "o";
            Console.WriteLine("{0},\r\n World{1}", greeting, '!');
            Console.WriteLine($"{greeting},\n World!");
        }
    }
}
```

```diff
--- a/file1.txt
+++ b/file2.txt
@@ -1,3 +1,3 @@
-Line 1
+Line 1 modified
 Line 2
```