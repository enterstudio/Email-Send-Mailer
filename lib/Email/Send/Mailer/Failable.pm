package Email::Send::Mailer::Failable;
use base qw(Email::Send::Mailer::Wrapper);

use strict;
use warnings;

sub fail_if { my ($self, $cond) = @_; push @{ $self->{fail_if} }, $cond; };
sub failure_conditions { @{ $_[0]->{fail_if} ||= [] } }
sub clear_failure_conditions { @{ $_[0]->{fail_if} } = () };

__PACKAGE__->add_trigger(before_send => sub {
  my ($self, $message, $arg) = @_;

  die $self->exception('Email::SendX::Exception::Failure')
    if grep { $_->($self, $message, $arg) } $self->failure_conditions;
});

1;
