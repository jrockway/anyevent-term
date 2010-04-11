use MooseX::Declare;

class AnyEvent::Term::ReadLine {
    use AnyEvent::Subprocess;
    use AnyEvent::Term;
    use AnyEvent::Pump qw(pump);

    use Term::ReadLine;
    use Term::ReadKey;

    has 'prompt' => (
        is      => 'ro',
        isa     => 'Str',
        default => sub { '> ' },
    );

    has 'term' => (
        is      => 'ro',
        isa     => 'AnyEvent::Term',
        default => sub { AnyEvent::Term->instance },
    );

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

    has 'on_error' => (
        is      => 'ro',
        isa     => 'CodeRef',
        default => sub { sub {} },
    );

    method BUILD($) {
        $self->setup_term;
    }

    method _build_job {
        return AnyEvent::Subprocess->new(
            delegates     => ['Pty', 'CommHandle'],
            on_completion => sub {
                delete $self->run->{_guard};
                $self->comm->handle->destroy;
                $self->pty->handle->destroy;
                $self->clear_run;
                $self->setup_term;
                $self->on_error->();
            },
            code => sub {
                my $comm = $_[0]->{comm};
                my $prompt = $_[0]->{prompt};

                ReadMode 0;
                my $term = Term::ReadLine->new;
                while (1) {
                    my $line = $term->readline($prompt);
                    syswrite $comm, "$line\n" or die "write error: $!";
                }
            },
        );
    }

    method _build_run {
        warn "new run";
        return $self->job->run({ prompt => $self->prompt });
    }

    method push_readline(CodeRef $result) {
        $self->comm->handle->push_read( line => sub {
            $result->($_[1]); # just the line, with no $eol
        })
    }

    method setup_term {
        # if run is destroyed, stop reading from the terminal
        $self->run->{_guard} = pump $self->term, $self->pty->handle;
        pump $self->pty->handle, $self->term;
    }
}
