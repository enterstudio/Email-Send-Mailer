package Email::Send::Mailer::SQLite;
use base qw(Email::Send::Mailer);

use strict;
use warnings;

use DBI;

sub is_available { 1 };

sub dbh {
  my ($self) = @_;

  if (not($self->{dbh}) or not($self->{pid}) or ($self->{pid} != $$)) {
    return $self->{dbh} = $self->_get_dbh;
  } else {
    return $self->{dbh};
  }
}

sub db_file { shift->{db_file} || 'email.db' }

sub _get_dbh {
  my ($self) = @_;

  my $must_setup = ! -e $self->db_file;
  my $dbh = DBI->connect("dbi:SQLite:dbname=" . $self->db_file);

  $self->_setup_dbh($dbh) if $must_setup;

  return $dbh;
}

sub _setup_dbh {
  my ($self, $dbh) = @_;
  $dbh->do('
    CREATE TABLE emails (
      id INTEGER PRIMARY KEY,
      body varchar NOT NULL,
      env_from varchar NOT NULL
    );
  ');
  $dbh->do('
    CREATE TABLE recipients (
      id INTEGER PRIMARY KEY,
      email_id integer NOT NULL,
      env_to varchar NOT NULL
    );
  ');
}

sub _deliver {
  my ($self, $arg) = @_;

  my $message = $arg->{message}->as_string;
  my $to   = $arg->{to};
  my $from = $arg->{from};

  my $dbh = $self->dbh;

  $dbh->do(
    "INSERT INTO emails (body, env_from) VALUES (?, ?)",
    undef,
    $message, $from,
  );

  my $id = $dbh->last_insert_id((undef) x 4);

  for my $addr (@$to) {
    $dbh->do(
      "INSERT INTO recipients (email_id, env_to) VALUES (?, ?)",
      undef,
      $id, $addr,
    );
  }
}

sub send {
  my ($self, $message, $arg) = @_;
  
  my @to = ref $arg->{to} ? @{ $arg->{to} } : $arg->{to};

  $self->_deliver({
    message   => $message,
    to        => \@to,
    from      => $arg->{from},
  });

  return $self->exception(
    'Email::SendX::Exception::Success',
    failures => { },
  );
}

1;
