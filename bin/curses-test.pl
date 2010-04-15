#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use FindBin qw($Bin);
use lib "$Bin/../lib";

use EV;
use AnyEvent::Term::Curses;
use Curses;

my $i = 0;
my $term = AnyEvent::Term::Curses->new( on_keystroke => sub {
    EV::unloop() if ord $_[0] < 20;
    printw($_[0]);
    refresh();
});
printw("test");
refresh();
EV::loop();

