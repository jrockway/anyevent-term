#!/usr/bin/env perl

use strict;
use warnings;
use feature ':5.10';

use FindBin qw($Bin);
use lib "$Bin/../lib";

use AnyEvent::Pump qw(pump);
use AnyEvent::Term;
use AnyEvent::Term::ReadLine;

my $stay_alive = AnyEvent->condvar;

my $term = AnyEvent::Term->instance;
my $readline = AnyEvent::Term::ReadLine->new(
    prompt   => 'test> ',
    on_error => sub { $stay_alive->send },
);

my $loop; $loop = sub {
    my $line = shift;
    $term->push_write("Got line: '$line'\n");
    $readline->push_readline($loop);
};
$readline->push_readline($loop);

my $in = pump $term, $readline, sub {
    my $char = shift;
    if($char =~ //){
        $stay_alive->send('INT');
        return 0;
    }
    return $char;
};

my $out = pump $readline, $term;

$stay_alive->recv;
undef $loop;
$readline->kill;
