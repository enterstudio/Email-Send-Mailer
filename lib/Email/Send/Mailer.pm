package Email::Send::Mailer;

use warnings;
use strict;

use Sub::Install;
use Sub::Uplevel;
use Email::SendX::Exceptions;

=head1 NAME

Email::Send::Mailer - a standard, extended interface for Email::Send mailers

=head1 VERSION

version 0.01

 $Id$

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  package Email::Send::Mailer::DevNull;
  use base qw(Email::Send::Mailer);

  sub is_available { 1; }
  sub send {
    my ($self, $message, $arg) = @_;
    return $self->exception('Email::SendX::Exception::Success');
  }

  ...

  my $mailer = Email::Send::Mailer::DevNull->new;
  my $sender = Email::Send->new({ mailer => $mailer });
  $sender->send($message, { to => [ $recipient, ... ], from => $from });

=head1 DESCRIPTION

This module provides an extended API for Email::Send plugins.

=cut

# this should return the class name, croak on args, etc, for singletonian
# mailers..?
sub new {
  my ($class, $arg) = @_;
  $arg ||= {};
  return bless $arg => $class;
}

sub _virtual_method {
  my ($method) = @_;

  sub {
    my $class = ref $_[0] ? ref $_[0] : $_[0];
    die "virtual method $method not implemented on $class";
  }
}

for (qw(send is_available)) {
  Sub::Install::install_sub({
    code => _virtual_method($_),
    as   => $_
  });
}

sub _validated_accessor_with_default {
  my ($field, $valid_values, $default) = @_;

  sub {
    my $self = shift;
    return $self->{$field} || $default unless @_;

    my $value = shift;
    die "$value is not a valid value for $field"
      unless (not defined $value) or (grep { $value eq $_ } @$valid_values);

    $self->{$field} = $value;
    return $self->{$field} || $default;
  }
}

# send args:
#   message
#   to
#   from
#   on_error?

for (qw(on_failure on_success)) {
  Sub::Install::install_sub({
    code => _validated_accessor_with_default($_, [qw(throw return)], 'return'),
    as   => $_
  });
}

sub exception {
  my ($self, $class, @arg) = @_;

  # the exception method should be a transparent abstraction
  my $exception = Sub::Uplevel::uplevel(2, sub { $class->new(@arg) });
  $self->handle_exception($exception);
}

sub handle_exception {
  my ($self, $exception) = @_;
  my $handle = 'throw';

  if ($exception->isa('Email::SendX::Exception::Success')) {
    $handle = $self->on_success; 
  } elsif ($exception->isa('Email::SendX::Exception::Failure')) {
    $handle = $self->on_failure; 
  }

  die    $exception if $handle eq 'throw';
  return $exception if $handle eq 'return';
}

=head1 AUTHOR

Ricardo Signes, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-email-send-mailer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2006 Ricardo Signes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
