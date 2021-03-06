#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use FindBin qw($Bin);
use lib "$Bin/../lib";

use AnyEvent::Term;

my $term = AnyEvent::Term->instance;
$term->push_write("Say something: ");
$term->push_read( sub {
    my $buf = delete $_[0]->{rbuf};
    $term->push_write("got $buf") if $buf;
    EV::unloop() if defined $buf && $buf eq '';
    0;
});

EV::loop();
$term->DEMOLISH; # cycle i am too lazy to fix
