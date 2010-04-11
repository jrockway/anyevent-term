use MooseX::Declare;

class AnyEvent::Term::ReadLine {
    use AnyEvent::Subprocess;
    use Term::Readline;
    use Term::ReadKey;

    has 'job' => (
        is         => 'ro',
        lazy_build => 1,
    );

    has 'run' => (
        is         => 'ro',
        isa        => 'AnyEvent::Subprocess::Running',
        lazy_build => 1,
        handles    => {
            'comm' => ['delegate', 'comm'],
            'pty'  => ['delegate', 'pty'],
        },
    );

    method _build_job {
        return AnyEvent::Subprocess->new(
            on_completion => sub { $self->clear_run; $self->run; $self->attach_to_term },
            delegates     => ['Pty', 'CommHandle'],
            code          => sub {
                my $comm = $_[0]->{comm};
                my $prompt = $_[0]->{prompt};
                my $term = Term::Readline->new;
                while (1) {
                    my $line = $term->readline($prompt);
                    syswrite $comm, $line or die "write error: $!";
                }
            },
        );
    }

    method _build_run {
        return $self->job->run;
    }

    method readline(CodeRef $result) {
        $self->comm->push_read( line => sub {
            $result->($_[1]); # just the line, with no $eol
        })
    }
}
