PROJECT = "testy-command-line"

all : build

help :
	@echo 'Typical usage is:'
	@echo '  > make                          # build python package'
	@echo '  > make build                    # build python package, regenerates README.md if needed'
	@echo '  > make clean                    # remove build artifacts'
	@echo '  > make venv                     # start shell in a virtual environment with package available'
	@echo '  > make clean-venv               # remove virtual environment artifacts'
	@echo '  > make push                     # clean/build and push to PyPI'
	@echo '  > make push-testing             # clean/build and push to test.pypi.org'

################################################################################
# BUILD TARGETS
################################################################################

# directory used for python packaging
PYPADIR = pypa-package

build:  $(PYPADIR)/README.md		# build the python source/wheel packages
	python -m build $(PYPADIR)

$(PYPADIR)/README.md: README.org	# update markdown based on org
	emacs README.org --batch \
		-f org-md-export-to-markdown \
		--kill
	mv README.md $@

venv:					# start a virtual env shell with the package installed
	python -m venv .venv
	source .venv/bin/activate && \
	  pip install --editable $(PYPADIR) && \
	  bash

# note: use 'deactivate' to end a virtual environment session


################################################################################
# PUSH TARGETS
################################################################################
# Pushing relies on the API Tokens for the indexes being present in an
# entry in ~/.pypirc; instructions are on https://pypi.org
#
# As updates are made, MUST change the version number in testy source
# file as it determines the file names that will be created and pushed
# up to indices

push: 					# push code to PyPI online
	make clean && make build	# remove old versions and rebuild to avoid pushing old code
	twine upload $(PYPADIR)/dist/*

push-testing: 				# push code to test.pypi.org
	make clean && make build	# remove old versions and rebuild to avoid pushing old code
	twine upload -r testpypi $(PYPADIR)/dist/*

################################################################################
# CLEAN TARGETS
################################################################################

clean-venv:				# remove the virtual environment used in testing
	rm -rf .venv

clean: clean-venv			# clean up build artifacts
	rm -rf $(PYPADIR)/dist $(PYPADIR)/$(PROJECT).egg-info
