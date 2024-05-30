
pylint_opts = --disable W0311,C0301,R0902,R0903,W0719,R0914,W0511

pylint :
	pylint $(pylint_opts) testyp
