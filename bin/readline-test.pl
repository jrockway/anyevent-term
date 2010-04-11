#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use FindBin qw($Bin);
use lib "$Bin/../lib";

use AnyEvent::Pump qw(pump);
use AnyEvent::Term;
use AnyEvent::Term::ReadLine;

my $loop;
my $term; $term = AnyEvent::Term::ReadLine->new(
    prompt   => 'test> ',
    on_error => sub { $term->push_readline($loop) },
);

$loop = sub {
    my $line = shift;

    $term->term->push_write("Got line: '$line'\n");
    $term->push_readline($loop);
};

$term->push_readline($loop);

EV::loop();

$term->kill
