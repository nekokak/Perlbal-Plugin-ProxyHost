package Perlbal::Plugin::ProxyHost;
use strict;
use warnings;
use URI;
use URI::QueryParam;

our $VERSION = '0.01';

sub load {
    my $class = shift;

    Perlbal::register_global_hook('manage_command.proxyhost', sub {
        my $mc = shift->parse(qr/proxyhost\s+(?:(\w+)\s+)?(\S+)\s*=\s*(\S+)$/,
                              "usage: ProxyHost [<service>] <source path> = <dest path>");
        my ($selname, $source, $target) = $mc->args;
        unless ($selname ||= $mc->{ctx}{last_created}) {
            return $mc->err("omitted service name not implied from context");
        }

        my $ss = Perlbal->service($selname);
        return $mc->err("Service '$selname' is not a reverse_proxy service")
            unless $ss && $ss->{role} eq "reverse_proxy";

        $ss->{extra_config}->{_proxyhost} ||= [];
        push @{$ss->{extra_config}->{_proxyhost}}, [ $source, $target ];

        return $mc->ok;
    });

    return 1;
}

sub register {
    my ($class, $svc) = @_;
    unless ($svc && $svc->{role} eq "reverse_proxy") {
        die "You can't load the proxyhost plugin on a service not of role reverse_proxy.\n";
    }

    $svc->register_hook(
        'ProxyHost' => 'start_proxy_request', sub {
            my Perlbal::ClientProxy $client = shift;
            for my $proxyhost ( @{ $svc->{extra_config}->{_proxyhost} } ) {
                my $source = $proxyhost->[0];
                my $target = $proxyhost->[1];
                my $uri = URI->new($client->{req_headers}->request_uri);

                if ( $uri->query_param('hoge') && $client->{req_headers}->header("Host") eq $source ) {
                    $client->{req_headers}->header("Host" => $target);
                }
            }
            return 0;
        }
    );

    return 1;
}

=head1 NAME

Perlbal::Plugin::ProxyHost - Module abstract (<= 44 characters) goes here

=head1 SYNOPSIS

    LOAD ProxyHost
    CREATE SERVICE example
        SET role    = reverse_proxy
        SET pool    = example_pool
        SET plugins = ProxyHost
        ProxyHost test.intra = proxy.test.intra
    ENABLE example

=head1 DESCRIPTION

reproxy to another host

=head1 AUTHOR

Atsushi Kobayashi <nekokak __at__ gmail.com>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
