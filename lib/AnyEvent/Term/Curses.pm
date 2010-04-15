use MooseX::Declare;
use Curses;

class AnyEvent::Term::Curses {
    # todo: subclass/interoperate with AnyEvent::Term
    # use Curses; # this breaks!?
    use AnyEvent;

    has 'on_keystroke' => (
        is       => 'ro',
        isa      => 'CodeRef',
        required => 1,
    );

    has 'read_watcher' => (
        is         => 'ro',
        lazy_build => 1,
    );

    method _build_read_watcher {
        my $handler = $self->on_keystroke; # so we don't leak $self
        AnyEvent->io( poll => 'r', fh => \*STDIN, cb => sub {
            my $char = Curses::getch();
            $handler->($char) if $char ne -1;
        });
    }

    method BUILD {
        # This section was stolen from POE :)
        Curses::initscr();
        Curses::start_color();
        Curses::cbreak();
        Curses::raw();
        Curses::noecho();
        Curses::nonl();
        Curses::nodelay(1);
        Curses::timeout(0);
        Curses::keypad(1);
        Curses::intrflush(0);
        Curses::meta(1);
        Curses::typeahead(-1);
        Curses::clear();
        Curses::refresh();

        $self->read_watcher;
    }

    method DEMOLISH {
        $self->clear_read_watcher;
        Curses::endwin();
    }
}
