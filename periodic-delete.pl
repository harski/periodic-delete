#!/usr/bin/perl

# Copyright 2015 Tuomo Hartikainen <tth@harski.org>.
# Licensed under the 2-clause BSD license, see LICENSE for details.

use v5.20;
use strict;
use version; our $VERSION = qv('0.0.1');
use warnings;

use Getopt::Long qw(:config no_ignore_case bundling);
use POSIX qw(strftime);
use Time::Local;

# TODO: For debug only
use Data::Dumper;

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
	'keep-weekly|m=i'	=> \$settings{keep_weekly},
	'keep-daily|d=i'	=> \$settings{keep_daily},

	'help|h|usage'		=> \$settings{action_help},
	'pattern=s'		=> \$settings{pattern},
	'pretend|p'		=> \$settings{pretend},
	'version|V'		=> \$settings{action_version},
);


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
	my $backup_dir = shift;

	my @file_list = get_dir_files($backup_dir);

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

print Dumper(%settings);

if ($settings{action_help}) {
	print_help();
} elsif ($settings{action_version}) {
	print_version();
} else {
	exit main();
}

exit 0;
