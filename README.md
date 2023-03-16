## Aho Corasick in Lua

A Lua implementation of the Aho-Corasick string matching algorithm.

This library can handle UTF-8 strings.

### Usage

```lua
local ahocorasick = require "ahocorasick"
local ac = ahocorasick:new()

local dict = {"she", "her", "his"}
local word = "he"

ac:add(dict)
ac:add(word)
```
Storing strings in a hash format often requires more memory space than an array. Therefore, it is preferable to store all child nodes of the current character in an array format first. If the number of child nodes exceeds the array limit, then they should be stored in a hash format. The default length for the array is 6, but you can change it as needed.

```lua
local arrayLengthLimit = 10
local ac = ahocorasick:new(arrayLengthLimit)
```

By default, the `match` function returns a table that contains the matched string and its beginning index and ending index.

Below is an example:

```lua
local str = "ushera"
local t = ac:match(str)
-- {{words="she", from = 2, to = 4},{words="he", from = 3, to = 4},{words="her", from = 3, to = 5}}
```

If you only need to obtain the matched string, you can pass the second parameter of the `match` function with a value of `true`.

```lua
local t = ac:match(str, true)
-- {"she", "he", "her"}
```


### Copyright and License

This library is licensed under the Apache License, Version 2.

Copyright 2023 bukale2022@163.com

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
