package Email::Send::Mailer::Test;
use base qw(Email::Send::Mailer);
use base qw(Class::Accessor);

use strict;
use warnings;

use IO::Persistent::SMTP;

sub is_available { 1 };

sub new {
  my ($class, $arg) = @_;
  my $smtp = IO::Persistent::SMTP->new(%$arg);

  bless { arg => $arg, _smtp => $smtp } => $class;
}

sub send {
  my ($self, $message, $arg) = @_;
  
  my @to = @{ $arg->{to} };

  my %ok;
  {
    my @ok = $self->{_smtp}->send(
      $message->as_string,
      to   => \@to,
      from => $arg->{from},
    );

    @ok = () unless $ok[0]; # stupid api bubbling up from Net::SMTP
    return $self->exception('Email::SendX::Exception::Failure') unless @ok;

    %ok = map { $_ => 1 } @ok;
  }

  my %undeliverable = grep { not $ok{$_} } @to;

  return $self->exception(
    'Email::SendX::Exception::Success',
    failures => { map { $_ => 'rejected by smtp server' } keys %undeliverable },
  );
}

1;
