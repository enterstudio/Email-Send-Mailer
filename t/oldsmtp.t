#!perl
use strict;
use warnings;

use Test::More 'no_plan';

use File::Temp;
use Email::Simple;
use Email::Simple::FromHandle;
use Email::Send;
use ICG::TestTools::Mail;
BEGIN { use_ok('Email::Send::Mailer::OldSMTP'); }
BEGIN { use_ok('Email::Send::Mailer::SMTP'); }

my $mailer = Email::Send::Mailer::OldSMTP->new({
  host => 'mx-all.pobox.com',
  port => 31145,
});

isa_ok($mailer, 'Email::Send::Mailer');
isa_ok($mailer, 'Email::Send::Mailer::OldSMTP');

my $rcpt = "recipient+$^T\@nowhere.example.net";
my $message = <<"END_MESSAGE";
From: sender\@test.example.com
To: $rcpt
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

-- 
sender
END_MESSAGE

{
  my $sender = Email::Send->new({ mailer => $mailer });
  my $result = $sender->send(
    $message,
    {
      from => 'devnull@pobox.com',
      to   => [ 'devnull@pobox.com', 'bounce@pobox.com', ],
    }
  );

  isa_ok($result, 'Email::SendX::Exception');
  isa_ok($result, 'Email::SendX::Exception::Success')
    or diag $result;

  is_deeply(
    $result->failures,
    { 'bounce@pobox.com' => 'rejected by smtp server' },
    "delivery indicates failure to 'bounce\@pobox.com'",
  );
}

my %tmp;
for my $key (qw(handle fromhandle code)) {
  my $fh = $tmp{$key} = File::Temp->new;
  print {$fh} $message;
  seek $fh, 0, 0;
}

# XXX duplicating tests from smtpsend, but we're paranoid -- hdp, 2006-11-28
for my $sender_test (
  [ 'Email::Send::Mailer::OldSMTP' ],
  [ 'Email::Send::Mailer::SMTP' ],
) {
  my ($sender_class) = @$sender_test;
  my $sender = Email::Send->new({
    mailer => $sender_class->new({
      host => 'localhost',
      port => 25,
    }),
  });

  for my $message_test (
    [ $message, 'scalar' ],
    [ Email::Simple->new($message), 'Simple' ],
    [ Email::Simple::FromHandle->new($tmp{fromhandle}), 'FromHandle' ],
    # Email::Send doesn't recognize these yet -- hdp, 2006-11-28
  #  $tmp{handle},
  #  sub { my $fh = $tmp{code}; <$fh> },
  ) {
    my ($input, $m_label) = @$message_test;
    eval {
      $sender->send(
        $input,
        {
          from => 'devnull@pobox.com',
          # XXX stupid address to hard-code
          to   => [ 'hdp+test-tools@vex.pobox.com' ],
        },
      );
    };
    is $@, "", "$sender_class, $m_label: sending didn't die";
    my $mail = eval {
      ICG::TestTools::Mail->wait_for_message(
        [ env_to => $rcpt ],
      );
    };
    is $@, "", "$sender_class, $m_label: found message";

    my $msg_obj = Email::Simple->new($message);
    is $mail->message->header('From'),
      $msg_obj->header('From'),
      "$sender_class, $m_label: From: unchanged";

    is $mail->message->body,
      $msg_obj->body,
      "$sender_class, $m_label: body unchanged";

  }
}
