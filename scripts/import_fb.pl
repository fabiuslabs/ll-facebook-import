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
    my $csv = Text::CSV_XS->new();
    my $fh = $fn->openr() or die "Couldn't open $fn: $!\n";
    $csv->column_names( $csv->getline($fh) );
    $data->{$fn->basename()} = $csv->getline_hr_all($fh);
    $fh->close() or die "Couldn't close $fn: $!\n";
}

p $data;

