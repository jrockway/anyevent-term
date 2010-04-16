use MooseX::Declare;

class AnyEvent::Term::ReadLine
  with (AnyEvent::Pump::Role::To, AnyEvent::Pump::Role::From) {
    use AnyEvent::Subprocess;
    use AnyEvent::Term;

    use Term::ReadLine;
    use Term::ReadKey;
    use Scalar::Util qw(refaddr);

    has 'prompt' => (
        is      => 'ro',
        isa     => 'Str',
        default => sub { '> ' },
    );

    has '_job' => (
        reader     => 'job',
        lazy_build => 1,
    );

    has 'on_error' => (
        is      => 'ro',
        isa     => 'CodeRef',
        default => sub { sub {} },
    );

    has '_run' => (
        isa        => 'AnyEvent::Subprocess::Running',
        lazy_build => 1,
        handles    => {
            'comm' => ['delegate', 'comm'],
            'pty'  => ['delegate', 'pty'],
            kill   => 'kill',
        },
    );

    method _build__job {
        return AnyEvent::Subprocess->new(
            delegates     => ['Pty', 'CommHandle'],
            on_completion => sub {
                $self->comm->handle->destroy;
                $self->pty->handle->destroy;
                $self->clear_run;
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

    method _build__run {
        return $self->job->run({ prompt => $self->prompt });
    }

    method push_readline(CodeRef $result) {
        $self->comm->handle->push_read( line => sub {
            $result->($_[1]); # just the line, with no $eol
        })
    }

    # implementation details for AE::Pump

    method consume {
        delete $self->pty->handle->{rbuf};
    }

    method push_read(@args) {
        $self->pty->handle->push_read(@args);
    }

    method push_write(@args) {
        $self->pty->handle->push_write(@args);
    }

    method kill_reader(CodeRef $ref){
        my $from = $self->pty->handle;
        $from->{_queue} = [
            grep { refaddr $_ != refaddr $ref } @{$from->{_queue} || []}
        ];
        return;
    }
}
