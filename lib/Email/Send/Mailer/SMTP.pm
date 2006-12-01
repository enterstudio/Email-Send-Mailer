package Email::Send::Mailer::SMTP;
use base qw(Email::Send::Mailer::OldSMTP);
use base qw(Class::Accessor);

use strict;
use warnings;

use Net::SMTP;
use ICG::Handy ();
use Sys::Hostname::Long ();

sub _new_smtp {
  my ($self, $arg) = @_;
  return Net::SMTP->new(
    Host => $arg->{host} || 'localhost',
    Port => $arg->{port} || 25,
    Hello => $arg->{helo} || Sys::Hostname::Long::hostname_long,
    Timeout => $arg->{timeout} || 60,
  );
}

sub new {
  my ($class, $arg) = @_;

  my $smtp = $class->_new_smtp($arg);

  bless { arg => $arg, _smtp => $smtp } => $class;
}

sub send {
  my ($self, $message, $arg) = @_;

  eval { 
    $self->{_smtp}->reset;
  };
  if ($@) {
    # XXX should this be something else?
    warn $@;
    $self->{_smtp} = $self->_new_smtp($self->{arg});
  }

  $arg->{smtp} = $self->{_smtp};

  $self->SUPER::send($message, $arg);
}

1;
