package Email::SendX::Exceptions;

use warnings;
use strict;

=head1 NAME

Email::SendX::Exceptions - exceptions used by Email::Send::Mailers

=head1 VERSION

version 0.020000

 $Id$

=cut

our $VERSION = '0.020000';

=head1 SYNOPSIS

  # ... in your own mailer
  sub send {
    Email::SendX::Exception::Failure->throw("email not invented")
      if (localtime->year < 1984);
    ...
  };

=head1 DESCRIPTION

This module provides exceptions (using L<Exception::Class>) thrown or returned
by Email::Send::Mailer mailers.

=cut

my $base_class;
BEGIN { $base_class = 'Email::SendX::Exception'; }

use Exception::Class (
  $base_class,
  "$base_class\::Failure" => { isa => $base_class },
  "$base_class\::Success" => { isa => $base_class, fields => [ 'failures' ] },
);

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
