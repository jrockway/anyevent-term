use MooseX::Declare;

class AnyEvent::Term {
    use MooseX::Singleton;
    use Term::ReadKey;
    use AnyEvent::Handle;

    use Scalar::Util qw(refaddr);

    has 'stdin_handle' => (
        is         => 'ro',
        isa        => 'AnyEvent::Handle',
        lazy_build => 1,
        handles    => ['push_read'],
    );

    has 'stdout_handle' => (
        is         => 'ro',
        isa        => 'AnyEvent::Handle',
        lazy_build => 1,
        handles    => ['push_write'],
    );

    method BUILD {
        ReadMode 4;
    }

    method _build_stdin_handle {
        AnyEvent::Handle->new(
            fh => \*STDIN,
        );
    }

    method _build_stdout_handle {
        AnyEvent::Handle->new(
            fh => \*STDOUT,
        );
    }

    method clear {
        $self->clear_stdin_handle;
        $self->clear_stdout_handle;
    }

    method kill_reader(CodeRef $reader){
        $self->stdin_handle->{_queue} = [
            grep { refaddr $_ != refaddr $reader }
              @{$self->stdin_handle->{_queue} || []}
        ];
    }

    method DEMOLISH {
        ReadMode 0;
    }
}
