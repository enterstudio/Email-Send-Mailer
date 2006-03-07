package Email::Send::Mailer::DevNull;
use base qw(Email::Send::Mailer);

use strict;
use warnings;

sub is_available { 1 };

sub send {
  my ($self, $message, $arg) = @_;

  return $self->exception('Email::SendX::Exception::Success');
}

1;
