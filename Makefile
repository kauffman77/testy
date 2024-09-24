
all:
	@echo "It's a python / bash project, what did you expect to happen?"

pyflakes :
	pyflakes testyp

pylint_opts = --disable W0311,C0301,R0902,R0903,W0719,R0914,W0511,R1732,C0302,W1203,W1309,C3001

pylint :
	pylint $(pylint_opts) testyp
