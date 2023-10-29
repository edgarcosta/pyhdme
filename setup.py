#!/usr/bin/env python
## -*- encoding: utf-8 -*-

import os
import sys
from setuptools import setup
from codecs import open  # To open the README file with proper encoding
from setuptools.command.test import test as TestCommand  # for tests
from setuptools.extension import Extension
from sage.env import sage_include_directories
from Cython.Build import cythonize

# Get information from separate files (README, VERSION)
def readfile(filename):
    with open(filename, encoding="utf-8") as f:
        return f.read()


# For the tests
class SageTest(TestCommand):
    def run_tests(self):
        errno = os.system("sage -t --force-lib pyhdme")
        if errno != 0:
            sys.exit(1)


cythonize_dir = "build"

path = os.path.dirname(os.path.abspath(__file__))
lib_path = os.path.join(path, "pyhdme/lib")
allfiles_in_lib = [
    os.path.relpath(os.path.join(dp, f), path)
    for dp, _, fn in os.walk(os.path.expanduser(lib_path))
    for f in fn
]

hdme_sources = [
    elt
    for elt in allfiles_in_lib
    if elt.endswith(".c")
    and "test/" not in elt
    and "time/" not in elt
    and "examples/" not in elt
    and "programs/" not in elt
]

if sys.platform == "darwin":
    libopenmp = ["omp"]
    openmpflags = ["-Xpreprocessor", "-fopenmp"]
else:
    libopenmp = []
    openmpflags = ["-fopenmp"]


pyhdme = Extension(
    "pyhdme.hdme",
    language="c",
    sources=[
        "pyhdme/hdme.pyx",
    ]
    + hdme_sources,
    libraries=["arb", "flint", "mpfr", "gmp", "pthread", "m"] + libopenmp,
    include_dirs=sage_include_directories() + ["pyhdme/lib/"],
    extra_compile_args=["-Wno-sign-compare"] + openmpflags,
    extra_link_args=openmpflags,
)

setup(
    name="pyhdme",
    author="Edgar Costa",
    author_email="edgarc@mit.edu",
    url="https://github.com/edgarcosta/pyhdme",
    license="GNU General Public License, version 3",
    description="Wrapper for C library for evaluating higher-dimensional modular equations",
    long_description=readfile("README.md"),  # get the long description from the README
    version=readfile("VERSION").strip(),  # the VERSION file is shared with the documentation
    classifiers=[
        # How mature is this project? Common values are
        #   3 - Alpha
        #   4 - Beta
        #   5 - Production/Stable
        "Development Status :: 4 - Beta",
        "Intended Audience :: Science/Research",
        "Topic :: Scientific/Engineering :: Mathematics",
        "License :: OSI Approved :: GNU General Public License v2 or v3",
        "Programming Language :: Python :: 3.7",
    ],  # classifiers list: https://pypi.python.org/pypi?%3Aaction=list_classifiers
    keywords="sagemath hdme",
    setup_requires=[
        "cython",
        "sagemath",
    ],  # currently useless, see https://www.python.org/dev/peps/pep-0518/
    install_requires=["cython", "sagemath", "sphinx"],
    packages=["pyhdme"],
    include_package_data=False,
    ext_modules=cythonize([pyhdme]),
    cmdclass={"test": SageTest}  # adding a special setup command for tests
    # ext_modules = extensions,
    # cmdclass = {'test': SageTest, 'build_ext': Cython.Build.build_ext} # adding a special setup command for tests and build_ext
)
