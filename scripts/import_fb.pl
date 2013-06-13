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
#use Data::Printer;

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
    my $country = delete $_->{COUNTRY};
    $json->{$country}->{Leader} = $_
    } @{ $data->{'WorldLeaders_Facebook.csv'} };

# map U.S. information by state

map {; 
    delete $_->{ID}; 
    my $state = delete $_->{State};

    $json->{'United States'}->{$state}->{'Governor'} = $_ 
    } @{ $data->{'governors_facebook.csv'} };

map {; 
    delete $_->{'Page ID'}; 
    my $state = delete $_->{State};
    my $district = delete $_->{District};

    ($district eq "Senate") 
        ? (push @{ $json->{'United States'}->{$state}->{Senate} }, $_)
        : (push @{ $json->{'United States'}->{$state}->{'U.S. House'} }, { 'District' => $district, %{ $_ } } )
    } @{ $data->{'113th Congress Official Pages.csv'} };

# map US Federal agencies by type

map {;
    delete $_->{'ID'};
    my $notes = delete $_->{'NOTES'};

    push @{ $json->{'United States'}->{'Agencies'}->{$notes} }, $_
    } @{ $data->{'USFederalAgencies_Facebook.csv'} };



my $us = delete $json->{'United States'};
my $agencies = delete $us->{'Agencies'};
my $leader = delete $us->{Leader};

# us_states.json formatting
my $ar;
map {; push @{ $ar }, { "State" => $_, %{ $us->{$_} } } } keys %{ $us };

# federal_agencies.json formatting
my $fa;
map {; push @{ $fa }, { "Agency Type" => $_, "Agencies" => $agencies->{$_} } }  keys %{ $agencies };

# world_leaders.json formatting
my $aref;
$json->{'United States'}->{Leader} = $leader;
map {; push @{ $aref }, { "Country" => $_, "Leader" => { %{ $json->{$_}->{Leader} } } } } keys %{ $json };

my $json_encoder = JSON->new->pretty();

path("../json/world_leaders.json")->spew_utf8($json_encoder->encode($aref)) or die "Couldn't write world_leaders.json: $!\n";
path("../json/us_states.json")->spew_utf8($json_encoder->encode($ar)) or die "Couldn't write us_states.json: $!\n";
path("../json/us_agencies.json")->spew_utf8($json_encoder->encode($fa)) or die "Couldn't write us_agencies.json: $!\n";
