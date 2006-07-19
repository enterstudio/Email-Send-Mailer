package Email::Send::Mailer::OldSMTP;
use base qw(Email::Send::Mailer);
use base qw(Class::Accessor);

use strict;
use warnings;

use ICG::Handy ();

sub is_available { 1 };

sub new {
  my ($class, $arg) = @_;

  bless { arg => $arg, } => $class;
}

sub send {
  my ($self, $message, $arg) = @_;
  
  my @to = ref $arg->{to} ? @{ $arg->{to} } : ($arg->{to});

  eval {
    ICG::Handy::smtpsend(
      $message->as_string,
      to   => \@to,
      from => $arg->{from},
      ($self->{arg}{host} ? (host => $self->{arg}{host}) : ()),
      ($self->{arg}{port} ? (port => $self->{arg}{port}) : ()),
    );
  };

  if ($@) {
    return $self->exception('Email::SendX::Exception::Failure');
  } else {
    return $self->exception('Email::SendX::Exception::Success');
  };
}

1;
