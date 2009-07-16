package Email::Send::Mailer::Wrapper;
use base qw(Email::Send::Mailer);

use warnings;
use strict;

use Class::Trigger;

=head1 NAME

Email::Send::Mailer::Wrapper - a mailer that wraps a mailer for mailing mail

=head1 VERSION

version 0.023

 $Id$

=cut

our $VERSION = '0.023';

=head1 SYNOPSIS

  package Email::Send::Mailer::Backwards;
  use base qw(Email::Send::Mailer::Wrapper);

  __PACKAGE__->add_trigger(before_send => sub {
    my ($self, $message, $arg) = @_;
    $message->body_set(reverse $message->body);
  }

=head1 DESCRIPTION

=cut

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};

  eval "require $arg->{mailer};" if not ref $arg->{mailer};
  die "mailer isn't a Mailer"
    unless eval { $arg->{mailer}->isa('Email::Send::Mailer') };

  my $new_arg = { %$arg };
  delete $new_arg->{mailer};
  $arg->{mailer} = $arg->{mailer}->new($new_arg) unless ref $arg->{mailer};
  my $self = bless $arg => $class;

  return $self;
}

# for future virtual base class methods
for my $name (qw(is_available)) {
  Sub::Install::install_sub({
    code => sub { my $self = shift; $self->{mailer}->$name(@_) },
    as   => $name,
  });
}

sub AUTOLOAD {
  our $AUTOLOAD;
  my $self = shift;
  my ($class, $method) = $AUTOLOAD =~ /(.+)::([^:]+)$/;
  return if $method eq 'DESTROY';

  $self->{mailer}->$method(@_);
}

sub send {
  # my ($self, $message, $arg) = @_;
  my $self = shift;

  eval { $self->call_trigger(before_send => (@_)); };

  if (my $error = $@) {
    return $self->exception($error)
      if eval { $error->isa('Email::SendX::Exception') };
    die $error;
  }

  $self->{mailer}->send(@_);
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
