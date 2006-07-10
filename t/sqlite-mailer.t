
use strict;
use warnings;

use Test::More 'no_plan';

use Email::Send;
BEGIN { use_ok('Email::Send::Mailer::SQLite'); }

unlink 't/email.db';

my $mailer = Email::Send::Mailer::SQLite->new({ db_file => 't/email.db' });
isa_ok($mailer, 'Email::Send::Mailer');
isa_ok($mailer, 'Email::Send::Mailer::SQLite');

my $message = <<'END_MESSAGE';
From: sender@test.example.com
To: recipient@nowhere.example.net
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

-- 
sender
END_MESSAGE

my $sender = Email::Send->new({ mailer => $mailer });
isa_ok($sender, 'Email::Send');

cmp_ok($sender->mailer, '==', $mailer, "sender's mailer is what we asked for");

{
  my $result = $sender->send(
    $message,
    {
      to   => [ qw(recipient@nowhere.example.net)],
      from => 'nobody@nowhere.example.mil',
    }
  );

  isa_ok($result, 'Email::SendX::Exception');
  isa_ok($result, 'Email::SendX::Exception::Success');
}

{
  my $result = $sender->send(
    $message,
    {
      to   => [
        qw(recipient@nowhere.example.net dude@los-angeles.ca.mil)
      ],
      from => 'nobody@nowhere.example.mil',
    }
  );

  isa_ok($result, 'Email::SendX::Exception');
  isa_ok($result, 'Email::SendX::Exception::Success');
}

my $dbh = DBI->connect("dbi:SQLite:dbname=t/email.db", undef, undef);

my ($deliveries) = $dbh->selectrow_array("SELECT COUNT(*) FROM recipients");

is($deliveries, 3, "we delivered to 3 addresses");
