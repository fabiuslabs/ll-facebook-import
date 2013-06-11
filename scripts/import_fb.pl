#!/usr/bin/env perl
#
# Copyright (C) 2013 Mark Allen
#
# This is free software; you may distribute and modify it under the terms of the
# MIT license.

use 5.018;

use JSON;
use Text::CSV_XS;
use Path::Tiny;
use Data::Printer;

my $iter = path("../csv")->iterator();

my $data;

while ( my $fn = $iter->() ) {
    next unless $fn =~ /\.csv$/;
    my $csv = Text::CSV_XS->new({ binary => 1, auto_diag => 1 });
    my $fh = $fn->openr() or die "Couldn't open $fn: $!\n";
    $csv->column_names( $csv->getline($fh) );
    $data->{$fn->basename()} = $csv->getline_hr_all($fh);
    $fh->close() or die "Couldn't close $fn: $!\n";
}

my $json;

# map world leader information by country

map {;
    $json->{$_->{COUNTRY}}->{Leader} = $_
    } @{ $data->{'WorldLeaders_Facebook.csv'} };

# map U.S. information by state

map {; 
    delete $_->{ID}; $json->{'United States'}->{$_->{State}}->{'Governor'} = $_ 
    } @{ $data->{'governors_facebook.csv'} };

map {; 
    delete $_->{'Page ID'}; 
    ($_->{District} eq "Senate") 
        ? (push @{ $json->{'United States'}->{$_->{State}}->{Senate} }, $_)
        : ($json->{'United States'}->{$_->{State}}->{'U.S. House'}->{$_->{District}} = $_)
    } @{ $data->{'113th Congress Official Pages.csv'} };

# map US Federal agencies by type

map {;
    delete $_->{'ID'};
    push @{ $json->{'United States'}->{'Agencies'}->{'Federal'}->{$_->{'NOTES'}} }, $_
    } @{ $data->{'USFederalAgencies_Facebook.csv'} };


my $aref;

map {; push @{ $aref }, { $_ => $json->{$_} } } keys %{ $json };

say JSON->new->pretty->encode($aref);
