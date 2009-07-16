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

  my @undeliverable;
  my $hook = sub { @undeliverable = @{ $_[0] } };

  eval {
    ICG::Handy::smtpsend(
      $message,
      to   => \@to,
      from => $arg->{from},
      ($self->{arg}{helo} ? (helo => $self->{arg}{helo}) : ()),
      ($self->{arg}{host} ? (host => $self->{arg}{host}) : ()),
      ($self->{arg}{port} ? (port => $self->{arg}{port}) : ()),
      ($arg->{smtp}       ? (smtp => $arg->{smtp})       : ()),
      bad_to_hook => $hook,
    );
  };

  if ($@) {
    return $self->exception('Email::SendX::Exception::Failure', $@);
  } else {
    return $self->exception(
      'Email::SendX::Exception::Success',
      (@undeliverable
      ? (failures => { map { $_ => 'rejected by smtp server' } @undeliverable })
      : ()
      ),
    );
  };
}

1;
