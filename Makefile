.PHONY: clean \
	clean-dev update-dev-req install-dev-req install install-kernel touch-dev \
	check format check-format lint check-typing clean-test test-wo-install test \
	clean-doc doc \
	clean-build build-release check-release release

VIRTUAL_ENV = .venv

DEV_BUILD_FLAG = $(VIRTUAL_ENV)/DEV_BUILD_FLAG



clean: clean-dev clean-test clean-doc clean-build



# init

clean-dev:
	rm -rf $(VIRTUAL_ENV)

update-dev-req: $(DEV_BUILD_FLAG)
	$(VIRTUAL_ENV)/bin/pip-compile --upgrade dev-requirements.in

install-dev-req:
	python3 -m venv $(VIRTUAL_ENV)
	$(VIRTUAL_ENV)/bin/python -m pip install --upgrade pip
	$(VIRTUAL_ENV)/bin/pip install -r dev-requirements.txt
	$(VIRTUAL_ENV)/bin/pre-commit install --hook-type pre-commit --hook-type pre-push

install:
	$(VIRTUAL_ENV)/bin/python setup.py install

install-kernel:
	$(VIRTUAL_ENV)/bin/ipython kernel install --name ".venv" --user

touch-dev:
	touch $(DEV_BUILD_FLAG)

dev: $(DEV_BUILD_FLAG)

$(DEV_BUILD_FLAG):
	$(MAKE) -f Makefile install-dev-req
	$(MAKE) -f Makefile install
	$(MAKE) -f Makefile install-kernel
	$(MAKE) -f Makefile touch-dev



# ci

check: check-format lint check-typing test

format: $(DEV_BUILD_FLAG)
	$(VIRTUAL_ENV)/bin/black src tests docs setup.py

check-format: $(DEV_BUILD_FLAG)
	$(VIRTUAL_ENV)/bin/black --check src tests docs setup.py

lint: $(DEV_BUILD_FLAG)
	$(VIRTUAL_ENV)/bin/pylint src tests setup.py

check-typing: $(DEV_BUILD_FLAG)
	$(VIRTUAL_ENV)/bin/mypy src tests setup.py

clean-test:
	rm -rf .coverage
	rm -rf htmlcov

test-wo-install: $(DEV_BUILD_FLAG)
	$(VIRTUAL_ENV)/bin/coverage run --branch --source ipyvizzustory -m unittest discover tests
	$(VIRTUAL_ENV)/bin/coverage html
	$(VIRTUAL_ENV)/bin/coverage report -m --fail-under=100

test: $(DEV_BUILD_FLAG) install test-wo-install



# doc

clean-doc:
	rm -rf docs/index.md
	rm -rf docs/**/*.html

doc: $(DEV_BUILD_FLAG)
	cp README.md docs/index.md
	$(VIRTUAL_ENV)/bin/jupyter nbconvert --to html --template classic --execute ./docs/examples/readme/index.ipynb
	$(VIRTUAL_ENV)/bin/jupyter nbconvert --to html --template classic --execute ./docs/examples/readme_complex/index.ipynb



# release

clean-build:
	rm -rf build
	rm -rf dist
	rm -rf **/*.egg-info
	rm -rf **/__pycache__

build-release: $(DEV_BUILD_FLAG)
	$(VIRTUAL_ENV)/bin/python -m build

check-release: $(DEV_BUILD_FLAG)
	$(VIRTUAL_ENV)/bin/python -m twine check dist/*.tar.gz dist/*.whl

release: clean-build build-release check-release
