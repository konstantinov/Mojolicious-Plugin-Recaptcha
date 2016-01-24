#!/usr/bin/env perl
# Without any options specified, we can generate a recaptcha which links to
# Google in English-language.

use strict;
use warnings;
no warnings 'uninitialized';

use Test::More qw(no_plan);

use_ok('Mojolicious');
use_ok('Mojo::Log');
use_ok('Mojolicious::Plugin::Recaptcha');

# Set up Mojolicious and our plugin.
my $mojolicious = Mojolicious->new;
ok($mojolicious, q{Mojolicious doesn't immediately blow up});
ok(
    $mojolicious->plugin(
        recaptcha =>
            { public_key => 'Public key!', private_key => 'Private key!' }
    ),
    'We can create a recaptcha plugin'
);

# Turn off logging to avoid polluting STDERR with warnings about how our
# key is compromised.
# This test only generates a debug log message, so even on systems (e.g.
# Windows) where there isn't such a file as /dev/null, this should be safe.
my $quiet_log = Mojo::Log->new(path => '/dev/null', level => 'fatal');
$mojolicious->log($quiet_log);

# We get the sort of markup we expect.
my $html = $mojolicious->recaptcha_html;
ok($html, 'We got some HTML back');
like($html, qr{ google [.] com /recaptcha .+ k= Public . key! }x,
    q{There's a link to Google which includes our public key});
