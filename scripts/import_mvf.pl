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

my $fn = path("../csv/$ARGV[0]");

my $csv = Text::CSV_XS->new({ sep_char => "\t", binary => 1, auto_diag => 1 });
my $fh = $fn->openr() or die "Couldn't open $fn: $!\n";
$csv->column_names( $csv->getline($fh) );
my $data = $csv->getline_hr_all($fh);
$fh->close() or die "Couldn't close $fn: $!\n";

# - name
# - party affiliation
# - active status as a voter
# - address
# - phone number
# - zipcode
# - last vote that the individual cast information
 
my %fields = (
#   data structure name         output name
    szNameLast              =>  'LastName',
    szNameFirst             =>  'FirstName',
    szPartyName             =>  'PartyAffliation',
    szPartyName2            =>  'PrimaryPartyBallot',
    szSitusAddress          =>  'Address',
    szSitusCity             =>  'City',
    sSitusState             =>  'State',
    sSitusZip               =>  'Zip',
    szPhone                 =>  'Phone',
    szEmailAddress          =>  'Email',
    dtBirthDate             =>  'Birthday',
    sBirthPlace             =>  'BirthPlace',
    dtRegDate               =>  'RegistrationDate',
    sStatusCode             =>  'StatusCode',
);

my %status_codes = (
    'A' => 'Active',
    'I' => 'Inactive',
    'C' => 'Cancelled',
    'P' => 'Local Pending'
);

my @out;
foreach my $rec ( @{ $data } ) {
    my $hr = {};

    map {; $hr->{$fields{$_}} = $rec->{$_} =~ s/\s+$//r } keys %fields;

    $hr->{StatusCode} = $status_codes{$hr->{StatusCode}};

    # delete stuff that's not in the href

    push @{ $hr->{VotingHistory} }, 
        grep { defined $_ } 
        map {; 
            my $v = {};
            $v->{ElectionDesc} = $rec->{"szElectionDesc$_"};         
            $v->{ElectionType} = $rec->{"sElecTypeDesc$_"};         
            $v->{VoteMethod} = $rec->{"szVotingMethod$_"};         
            $v->{VoteCounted} = $rec->{"szCountedFlag$_"};         
            $rec->{"szCountedFlag$_"} ? $v : undef;
        } 1 .. 4;

    map { $hr->{$_} = "Unknown" } grep { ! $hr->{$_} } keys %{ $hr };

    push @out, $hr;
}

path("../json/$ARGV[0].json")->spew_utf8(JSON->new->pretty->encode(\@out)) or die "Couldn't write $ARGV[0].json: $!\n";
