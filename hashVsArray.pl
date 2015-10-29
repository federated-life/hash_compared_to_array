#!/usr/bin/perl
{
	package array;
	use strict;
	use warnings;
	use Moose;
	
	has 'key' => ( is => 'rw', isa => 'Str', reader => 'get_key',
		writer => 'set_key', default => '', );
	has 'value' => ( is => 'rw', isa => 'Str', reader => 'get_value',
		writer => 'set_value', default => '', );
	
	has 'mapping' => ( is => 'rw',
			traits  => ['Array'],
			isa => 'ArrayRef[array]',
			lazy => 1,
			default => sub { [] },
			handles => {
				add_atr => 'push',
				splice_atr => 'splice',
			},
	); 
	
	sub populate_array {
		my $arrayref = ${$_[1]};
		my $qty = $_[2];
		for (1..$qty) {
			my $key = $_;
			my $value = $_+100*2/46;
			my $obj = array->new( key => "$key" , value => "$value" );
			$arrayref->add_atr($obj);
		}
		return $arrayref;
	}
}
{
	package hash;
	use strict;
	use warnings;
	use Moose;
	
	has 'mapping' => ( is => 'rw',
			traits  => ['Hash'],
			isa => 'HashRef[Str]',
			lazy => 1,
			default => sub { {} },
			handles => {
				num_count			=> 'count',
				ids_in_mapping		=> 'keys',
				exists_in_mapping	=> 'exists',
				get_mapping			=> 'get',
				set_mapping			=> 'set',
				delete_mapping		=> 'delete',
				set_quantity		=> [ set => 'quantity' ],
			},
	); 
	
	sub populate_hash {
		my $hash = ${$_[1]};
		my $qty = $_[2];
		for (1..$qty) {
			my $value = $_+100*2/46;
			my $key = $_;
			$hash->set_mapping( $key , $value);
		}
		return $hash;
	}
}
{
	package timer;
	use strict;
	use warnings;
	use Moose;
	use Time::HiRes qw/ time gettimeofday tv_interval /;
	
	sub diff {
		my $start_time = $_[1];
		my $name = $_[2];
		my $diff = Time::HiRes::tv_interval($start_time);		
		print "time elapsed for $name was $diff seconds \n"; 
	}
}
{
	package main;
	use strict;
	use warnings;
	use Moose;
	use Time::HiRes qw/ time gettimeofday tv_interval /;
	use Data::Dumper;
	
	my ( $start , $end );
	my @start_time;
	my $timer = timer->new();
	my $qty = 100;
	my $print_debug = 0;

	### capture warnings from line 155 due to removing elements
	local $SIG{__WARN__} = sub {
		my $message = shift;
	};
	
	###
	###
	### using hashrefs - populate hash
	my $a_hash = hash->new;
	my $b_hash = hash->new;
	@start_time = [Time::HiRes::gettimeofday()];
	hash->new()->populate_hash(\$a_hash, $qty);
	hash->new()->populate_hash(\$b_hash, $qty);
	$timer->diff( @start_time , "populating hash");

	### remove random elements
	@start_time = [Time::HiRes::gettimeofday()];
	for (2..$qty) {
		my $to_remove = int(rand($_));
		$b_hash->delete_mapping(int($to_remove));
	}
	$timer->diff( @start_time , "removing elements from hash");
	
	### find missing keys
	my $count_of_missing = 0;
	@start_time = [Time::HiRes::gettimeofday()];
	foreach my $item ( keys(%{$a_hash->mapping}) ) {
		print "Missing\t\tid: $item value: ".$a_hash->get_mapping($item)."\n"
			 if ( $b_hash->exists_in_mapping($item) != 1 && $print_debug == 1 );
		$count_of_missing++;
	}
	$timer->diff( @start_time , "finding missing keys");
	print "a_hash: ".$a_hash->num_count().
		"   b_hash: ".$b_hash->num_count()."\n" if ( $print_debug == 1 );

	# remove from memory
	undef $a_hash;
	undef $b_hash;

	###
	###
	### using arrayrefs - populate arrays
	my $a_array = array->new();
	my $b_array = array->new();
	@start_time = [Time::HiRes::gettimeofday()];
	$a_array->populate_array(\$a_array, $qty);
	$b_array->populate_array(\$b_array, $qty);
	$timer->diff( @start_time , "populating arrays");
	
	### remove random elements - using a hash for some logic
	@start_time = [Time::HiRes::gettimeofday()];
	my %to_remove_list = ();
	for (2..$qty) {
		my $to_remove = int(rand($_));
		$to_remove_list{$to_remove} = "remove";
	}
	my $pos_in_array = 0;
	foreach my $b_obj ( @{ $b_array->mapping } ) {
		if ( $to_remove_list{ $b_obj->get_key() } eq "remove" ) {
			$b_array->splice_atr($pos_in_array, 1);
			$pos_in_array--;
		}
		$pos_in_array++;
	}
	$timer->diff( @start_time , "removing elements from arrays");

	### find missing elements
	@start_time = [Time::HiRes::gettimeofday()];
	foreach my $a_obj ( @{ $a_array->mapping }) {
		foreach my $b_obj ( @{ $b_array->mapping }) {
			if ( $a_obj->get_value() eq $b_obj->get_value() ) {
				$a_obj->set_value("OK");
			}
		}
	}
	
	foreach my $a_obj ( @{ $a_array->mapping }) {
		if ( $a_obj->get_value() ne "OK" ) {
			print "Missing ".$a_obj->get_key()."\n" if ( $print_debug == 1 );
		}
	}
	$timer->diff( @start_time , "finding elements in arrays");
}













