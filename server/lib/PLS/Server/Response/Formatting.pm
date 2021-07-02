package PLS::Server::Response::Formatting;

use strict;
use warnings;

use parent q(PLS::Server::Response);

use IO::Async::Function;
use IO::Async::Loop;

use PLS::Parser::Document;

=head1 NAME

PLS::Server::Response::Formatting

=head1 DESCRIPTION

This is a message from the server to the client with the current document
after having been formatted.

=cut

# Set up formatting as a function because it can be slow
my $loop = IO::Async::Loop->new();
my $function = IO::Async::Function->new(
    max_workers => 1,
    code        => sub {
        my ($self, $request) = @_;

        my ($ok, $formatted) = PLS::Parser::Document->format(uri => $request->{params}{textDocument}{uri}, formatting_options => $request->{params}{options});
        return $ok, $formatted;
    }
);
$loop->add($function);

sub new
{
    my ($class, $request) = @_;

    my $self = bless {id => $request->{id}}, $class;
    return $function->call(args => [$self, $request])->then(
        sub {
            my ($ok, $formatted) = @_;
            if   ($ok) { $self->{result} = $formatted }
            else       { $self->{error}  = $formatted }
            return $self;
        }
    );
} ## end sub new

1;
