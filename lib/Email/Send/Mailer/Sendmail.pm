package Email::Send::Mailer::Sendmail;

use base qw(Email::Send::Mailer);

use strict;
use warnings;

use ICG::Handy ();

sub is_available { 1 };

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};
  bless { arg => $arg } => $class;
}

sub send {
  my ($self, $message, $arg) = @_;

  my @to = ref $arg->{to} ? @{ $arg->{to} } : $arg->{to};

  eval {
    my $fh = ICG::Handy::mypipe(
      "|-",
      "sendmail",
      ($arg->{from} ? ("-f" => $arg->{from}) : ()),
      @to,
    );
    print $fh $message->as_string;
    close $fh;
  };
  if ($@) {
    return $self->exception('Email::SendX::Exception::Failure', $@);
  } else {
    return $self->exception('Email::SendX::Exception::Success');
  }
}

1;
