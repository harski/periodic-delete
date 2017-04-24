#!/usr/bin/perl

# Copyright 2017 Tuomo Hartikainen <tth@harski.org>.
# Licensed under the 2-clause BSD license, see LICENSE for details.

use v5.20;
use strict;
use version; our $VERSION = qv('0.0.1');
use warnings;

use File::Path qw(remove_tree);
use Getopt::Long qw(:config no_ignore_case bundling);
use POSIX qw(strftime);
use Time::Local;

use PeriodicDelete::File;
use PeriodicDelete::FileList qw(:ALL);

my %settings = (
	action_help	=> 0,
	action_version	=> 0,

	keep_yearly	=> 3,
	keep_monthly	=> 11,
	keep_weekly	=> 5,
	keep_daily	=> 3,

	pattern		=> '%Y-%m-%d',
	pretend		=> 0,
);

GetOptions (
	'keep-yearly|y=i'	=> \$settings{keep_yearly},
	'keep-monthly|m=i'	=> \$settings{keep_monthly},
	'keep-weekly|w=i'	=> \$settings{keep_weekly},
	'keep-daily|d=i'	=> \$settings{keep_daily},

	'help|h|usage'		=> \$settings{action_help},
	'pattern=s'		=> \$settings{pattern},
	'pretend|p'		=> \$settings{pretend},
	'version|V'		=> \$settings{action_version},
);


sub get_periodic_files {
	my (@files, $pattern) = @_;
	my @pfs;

	for (@files) {
		if (my $pf_ref = eval { PeriodicDelete::File->new($_) }) {
			push @pfs, $pf_ref;
		} else {
			if ($@) { print "$@"; }
		}
	}

	return @pfs;
}


sub get_dir_files {
	my $dir = shift;

	opendir(my $dh, $dir) || die $!;
	my @raw_files = grep { $_ ne '.' && $_ ne '..' } readdir($dh);
	closedir($dh);

	my @files;

	for my $file (@raw_files) {
		chomp $file;
		push @files, "$dir/$file";
	}

	return @files;
}

sub main {
	my $pf_dir = shift;

	# check that dir exists
	if (! -d $pf_dir) {
		die "Directory '$pf_dir' does not exist. Quitting...";
	}

	my $pf_list = PeriodicDelete::FileList->new(
			$settings{keep_yearly},
			$settings{keep_monthly},
			$settings{keep_weekly},
			$settings{keep_daily}
			);

	# get files
	my @file_list = get_dir_files($pf_dir);
	my @pfs = get_periodic_files(@file_list);

	for my $pf_ref (@pfs) {
		$pf_list->add($pf_ref);
	}

	for my $pf_ref (@pfs) {
		if (not $pf_list->contains($pf_ref)) {
			# Extra, delete it
			if ($settings{pretend}) {
				say "rm -rf $pf_ref->{path}";
			} else {
				remove_tree($pf_ref->{path});
			}
		}
	}

	return 0;
}


sub print_help {
	# TODO: Add info on default values
	print <<HELP_END
$0 [ACTION] [OPTION] DIR

Actions:
  -h, --help, --usage
  	Show usage information
  -V, --version
  	Show program version

Options:
  -y, --keep-yearly NUM
  	Keep NUM yearly copies
  -m, --keep-monthly NUM
  	Keep NUM monthly copies
  -w, --keep-weekly NUM
  	Keep NUM weekly copies
  -d, --keep-daily NUM
  	Keep NUM daily copies

  --pattern 'PATTERN'
	 Use PATTERN as time stamp format for files/dirs. Currently ignored.
	 (Default: '%Y-%m-%d')
  -p, --pretend
	Just pretend: show what would have been done, but don't really delete
	anything
HELP_END
}


sub print_version {
	print <<PRINT_VERSION
$0 version $VERSION
Copyright 2015 Tuomo Hartikainen <tth\@harski.org>.
Licensed under the 2-clause BSD license.
PRINT_VERSION
}

sub run {
	if ($settings{action_help}) {
		print_help();
	} elsif ($settings{action_version}) {
		print_version();
	} else {
		if (@ARGV == 0) {
			warn "Error: Specify a directory to handle.";
			print_help();
			exit 1;
		} elsif (@ARGV == 1) {
			main($ARGV[0]);
		} else {
			warn "Error: Too many arguments.";
			print_help();
			exit 2;
		}
	}
}

1;
