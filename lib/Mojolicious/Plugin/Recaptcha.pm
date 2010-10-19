package Mojolicious::Plugin::Recaptcha;

use strict;
use Mojo::ByteStream;

use base 'Mojolicious::Plugin';
our $VERSION = '0.11';

sub register {
	my ($self,$app,$conf) = @_;
	
	$app->renderer->add_helper(
		recaptcha_html => sub {
			my $self = shift;
			my ($error) = map { $_ ? "&error=$_" : "" } $self->stash('recaptcha_error');
			return Mojo::ByteStream->new(<<HTML);
  <script type="text/javascript"
     src="http://www.google.com/recaptcha/api/challenge?k=$conf->{public_key}$error">
  </script>
  <noscript>
     <iframe src="http://www.google.com/recaptcha/api/noscript?k=$conf->{public_key}"
         height="300" width="500" frameborder="0"></iframe><br>
     <textarea name="recaptcha_challenge_field" rows="3" cols="40">
     </textarea>
     <input type="hidden" name="recaptcha_response_field"
         value="manual_challenge">
  </noscript>
HTML

		},
	);
	$app->renderer->add_helper(
		recaptcha => sub {
			my ($self,$challenge, $response) = @_;
			$response ||= 'manual_challenge';
			my $result;
			$self->client->post_form(
				'http://www.google.com/recaptcha/api/verify', 
				{
					privatekey => $conf->{'private_key'},
					remoteip   => 
						$self->req->headers->header('X-Real-IP')
						 ||
						$self->tx->{remote_address},
					challenge  => $self->req->param('recaptcha_challenge_field'),
					response   => $self->req->param('recaptcha_response_field')
				},
				sub {
					my $content; $content = "$_" for $_[1]->res;
					$result = $content =~ /true/;
					
					$self->stash(recaptcha_error => $content =~ m{false\s*(.*)$}si)
						unless $result
					;
				}
			)->process;
			
			$result;
		}
	);
}

1;

=head1 NAME

Mojolicious::Plugin::Recaptcha - ReCaptcha plugin for Mojolicious framework

=head1 VERSION

0.11

=head1 SYNOPSIS

   # Mojolicious::Lite
   plugin recaptcha => { 
      public_key  => '...', 
      private_key => '...'
   };
   
   # Mojolicious
   $self->plugin(recaptcha => { 
      public_key  => '...', 
      private_key => '...'
   });
   
   # template 
   <form action="" method="post">
      <%= recaptcha_html %>
      <input type="submit" value="submit" name="submit" />
   </form>
   
   # checking
   if ($self->helper('recaptcha')) {
      # all ok
   }
   

=head1 SUPPORT

=over 4

=item * Repository

L<http://github.com/konstantinov/Mojolicious-Plugin-Recaptcha>

=back

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin>, L<Mojolicious::Lite>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Dmitry Konstantinov. All right reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.