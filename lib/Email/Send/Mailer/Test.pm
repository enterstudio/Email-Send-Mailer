package Email::Send::Mailer::Test;
use base qw(Email::Send::Mailer);

use strict;
use warnings;

use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(qw(bad_recipients));

sub is_available { 1 };

sub fail_if { my ($self, $cond) = @_; push @{ $self->{fail_if} }, $cond; };
sub failure_conditions { @{ $self->{fail_if} } }
sub clear_failure_conditions { @{ $self->{fail_if} } = () };

sub recipient_ok {
  my ($self, $recipient) = @_;

  return 1 unless my $all_exprs = $self->bad_recipients;

  for my $re (@{ $all_exprs }) {
    return if $recipient =~ $re;
  }

  return 1;
}

sub _deliver {
  my ($self, $arg) = @_;
  $self->{deliveries} ||= [];

  push @{ $self->{deliveries} }, $arg;
}

sub deliveries {
  my ($self) = @_;
  return @{ $self->{deliveries} ||= [] };  
}

sub delivered_messages {
  my ($self) = @_;
  map { $_->{message} } $self->deliveries;
}

sub send {
  my ($self, $message, $arg) = @_;
  
  my @to = ref $arg->{to} ? @{ $arg->{to} } : ($arg->{to});

  return $self->exception('Email::SendX::Exception::Failure')
    if grep { $_->($self, $message, $arg) } $self->failure_conditions;

  # should use List::MoreUtils::part -- when released
  my @undeliverables = grep { not $self->recipient_ok($_) } @to;
  my @deliverables   = grep {     $self->recipient_ok($_) } @to;

  $self->_deliver({
    message   => $message,
    arg       => $arg,
    successes => \@deliverables,
    failures  => { map { $_ => 'bad recipient' } @undeliverables },
  });

  return $self->exception(
    'Email::SendX::Exception::Success',
    failures => { map { $_ => 'bad recipient' } @undeliverables },
  );
}

1;
