# 🍋 MakeCitron

This Makefile is based on the ideas from https://mattandre.ws/2016/05/makefile-inheritance/

Add `MakeCitron.Makefile` in your project then import it in the `Makefile`.

Use `-super` suffix to call for parent tasks

NB: Targets that match less specifically must have dependencies otherwise the more specific ones are ignored.
Therefore a `least-specific` target is used as dependency

It supports NODE_ONLY and PYTHON_ONLY configuration variables

## Makefiles dependency graph

```
                   Project                 +    MakeCitron
                   +-----+                 |    +--------+
                                           |
                                           |
config.Makefile  (config.custom.Makefile)  |   base.Makefile
                                           |
      ^                 ^                  |        ^
      |                 |                  |        |
      | includes (1)    | includes (2)     |        |
      |                 |                  |        |
      +                 +                  |        |
                                           |        |
      MakeCitron.Makefile +----------------+--------+
                              fetches and includes (3)
               ^                           |
               |                           |
               | includes                  |
               |                           |
               +                           |
                                           |
            Makefile                       |
                                           +
```
