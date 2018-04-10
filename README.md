# 🍋 MakeCitron

This Makefile is based on the ideas from https://mattandre.ws/2016/05/makefile-inheritance/

Your project Makefile must import `MakeCitron.Makefile` first

Use `-super` suffix to call for parent tasks

NB: Targets that match less specifically must have dependencies otherwise the more specific ones are ignored.
Therefore a `least-specific` target is used as dependency

It supports NODE_ONLY and PYTHON_ONLY configuration variables
