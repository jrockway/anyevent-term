use inc::Module::Install;
use strict;

name 'AnyEvent-Term-ReadLine';
all_from 'lib/AnyEvent/Term/ReadLine.pm';

# from my github
requires 'AnyEvent::Pump';
requires 'AnyEvent::REPL';

requires 'AnyEvent';
requires 'MooseX::Declare';
requires 'Term::ReadLine';
requires 'Term::ReadKey';
requires 'Scalar::Util';

WriteAll;
