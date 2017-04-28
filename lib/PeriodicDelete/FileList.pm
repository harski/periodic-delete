package PeriodicDelete::FileList;

use v5.20;
use strict;
use version; our $VERSION = qv('0.1.0');
use warnings;

use Carp;
use List::MoreUtils qw(any);


sub add {
	my $self = shift;
	my $file_ref = shift;

	# Add to a suitable backup class
	CLASS:
	for my $class ('yearly', 'monthly', 'weekly', 'daily') {
		my ($added, $extra) = $self->_add($file_ref, $class);

		if ($added) {
			if ($extra) {
				$self->add($extra);
			}
			last CLASS;
		}
	}
}


# return an array where the first value is boolean indicating whether $file_ref
# was added or not. If the ref was not added, the second value is the same ref.
# If ref was added and something had to be removed the second value is a ref to
# the removed PeriodicFile. If ref was added and nothing needed be removed the
# second parameter is undef.
sub _add {
	my ($self, $file_ref, $class) = @_;

	# Default return values to 'failing' i.e. nothing being added.
	my $added = 0;
	my $extra_file = $file_ref;

	my $class_cnt = scalar keys %{$self->{$class}};
	my $keep_key = 'keep_' . $class;
	my $class_keep_cnt = $self->{$keep_key};
	my $file_key = $file_ref->get_key($class);
	my $existing = defined $self->{$class}->{$file_key}
		     ? $self->{$class}->{$file_key}
		     : undef;

	# Now for the tricky part
	if ($class_keep_cnt == 0) {
		# nothing is set to be kept in this class; add nothing
		$added = 0;
		$extra_file = $file_ref;
	} elsif ($class_cnt < $class_keep_cnt
		 && not defined $existing) {
		# Add if it can be done without removing or replacing anything,
		# and there's room for it in the list
		$self->{$class}->{$file_key} = $file_ref;
		$added = 1;
		$extra_file = undef;
	} elsif ($class_cnt == $class_keep_cnt
		 && not defined $existing) {
		# Current class is full, and if "oldest" is older than $file_ref
		# class should be taken out and $file_ref put in.
		my ($oldest_key, $oldest) = $self->_get_oldest($class);

		if ($oldest->get_cmp_str() < $file_ref->get_cmp_str()) {
			$added = 1;
			$extra_file = $oldest;
			delete $self->{$class}->{$oldest_key};
			$self->{$class}->{$file_key} = $file_ref;
		}
	} else {
		# Now $existing is guaranteed to be defined, so a swap should
		# be done if possible
		if ($file_ref->get_cmp_str() < $existing->get_cmp_str()) {
			$added = 1;
			$extra_file = $existing;
			$self->{$class}->{$file_key} = $file_ref;
		}
	}

	return ($added, $extra_file);
}


sub contains {
	my ($self, $file_ref) = @_;

	for my $class ('yearly', 'monthly', 'weekly', 'daily') {
		for my $pf (values %{$self->{$class}}) {
			if ($file_ref->{path} eq $pf->{path}) {
				return 1;
			}
		}
	}

	return 0;
}


sub _get_oldest {
	my ($self, $class) = @_;

	my @keys = sort keys %{$self->{$class}};
	my $oldest_key = shift @keys;
	my $oldest = $self->{$class}->{$oldest_key};

	return ($oldest_key, $oldest);
}


sub new {
	my $class = shift;
	my ($keep_yearly, $keep_monthly, $keep_weekly, $keep_daily) = @_;

	croak("PeriodicFile 'keep count' argument missing.")
		if any {!defined $_}
			$keep_yearly, $keep_monthly, $keep_weekly, $keep_daily;

	my $self = {
		yearly  => {},
		monthly => {},
		weekly  => {},
		daily   => {},

		keep_yearly  => $keep_yearly,
		keep_monthly => $keep_monthly,
		keep_weekly  => $keep_weekly,
		keep_daily   => $keep_daily,
	};

	bless($self, $class);
	return $self;
}
