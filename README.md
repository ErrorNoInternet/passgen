# passgen

A program that generates passwords (combinations) using a given set of keywords. Currently the Zig version is the fastest on my machine, but optimization PRs are welcome!

For example, giving "a", "b", and "c" would generate 40 outcomes (142 bytes), including the empty new line at the start:

```

a
b
c
aa
ab
ac
[...]
cba
cbb
cbc
cca
ccb
ccc
```
