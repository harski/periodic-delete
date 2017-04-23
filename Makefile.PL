#!/usr/bin/perl

# Copyright 2017 Tuomo Hartikainen <tth@harski.org>.
# Licensed under the 2-clause BSD license, see LICENSE for details.

use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME            => 'PeriodicDelete',
	VERSION_FROM    => 'lib/PeriodicDelete.pm',
	EXE_FILES	=> [ 'bin/periodic-delete' ],
);
