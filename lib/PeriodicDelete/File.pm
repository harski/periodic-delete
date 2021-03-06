#!/usr/bin/perl

# Copyright 2015 Tuomo Hartikainen <tth@harski.org>.
# Licensed under the 2-clause BSD license, see LICENSE for details.

package PeriodicDelete::File;

use v5.20;
use strict;
use version; our $VERSION = qv('0.1.0');
use warnings;

use Carp qw(croak);
use POSIX qw(strftime);
use Time::Local;


sub pfcmp {
	my $self = shift;
	my $other = shift;

	my $a = $self->get_cmp_str();
	my $b = $other->get_cmp_str();

	return $a cmp $b;
}


sub parse_basename {
	my $path = shift;

	if ($path =~ m{/(.*?)/?$}) {
		return $1;
	} else {
		croak("Could not parse basename for path '$path'");
	}
}


sub get_cmp_str {
	my $self = shift;
	return $self->{year}
	     . $self->{month}
	     . $self->{day};
}


sub get_key {
	my $self = shift;
	my $class = shift;
	my $key;

	# match 'class' or 'classly'
	if ($class =~ /year/) {
		$key = $self->{year};
	} elsif ($class =~ /month/) {
		$key = $self->{year} . $self->{month};
	} elsif ($class =~ /week/) {
		$key = $self->{year} . '-' . $self->{week};
	} elsif ($class eq 'day' or $class eq 'daily') {
		$key = $self->{year} . $self->{month} . $self->{day};
	} else {
		croak("No key found for class '$class'");
	}

	return $key;
}


sub new {
	my ($class, $path) = @_;
	my $filename = eval { parse_basename($path) };

	if ($@) {
		croak($@);
	}

	my $self = {
		path => $path,
		name => $filename,
		};

	if ($filename =~ m{
			(\d{4})	# year
			-	# separator
			(\d{2})	# month
			-	# separator
			(\d{2})	# day
			}xms) {
		$self->{year}	= $1,
		$self->{month}	= $2,
		$self->{day}	= $3,
		$self->{week}	= parse_week($1, $2, $3),
	} else {
		croak("Could not initialize PeriodicFile from path '$path'");
	}

	bless($self, $class);
	return $self;
}


sub parse_week {
	my ($year, $month, $day) = @_;
	my $epoch = timelocal( 0, 0, 0, $day, $month - 1, $year - 1900 );
	return strftime("%W", localtime($epoch));
}

1;
