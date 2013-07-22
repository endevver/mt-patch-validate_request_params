package ValidateRequestParamsPatch;

use strict;
use warnings;
use base qw( MT::Object );

sub post_init {
	my ( $cb, $mt, $logger ) = @_;
        require Sub::Install;
        Sub::Install::reinstall_sub({
        		code => 'validate_request_params_patched',
        		from => __PACKAGE__,
        		into => 'MT::App',
        		as   => 'validate_request_params'
        });
        
}

sub validate_request_params_patched {
	my $app = shift;
        my $has_encode = eval { require Encode; 1 } ? 1 : 0;
        return 1 unless $has_encode;
        
        my $q = $app->param;
        
        # validate all parameter data matches the expected character set.
        my @p       = $q->param();
        my $charset = $app->charset;
        require Encode;
        require MT::I18N::default;
        $charset = 'UTF-8' if $charset =~ m/utf-?8/i;
        my $request_charset = $charset;
        if ( my $content_type = $q->content_type() ) {
        	if ( $content_type =~ m/charset=(.+?);/i ) {
        		$request_charset = uc $1;
        		$request_charset =~ s/^\s+|\s+$//gs;
        	}
        }
        my $transcode = $request_charset ne $charset ? 1 : 0;
        my %params;
        foreach my $p (@p) {
        	if ( $p =~ m/[^\x20-\x7E]/ ) {
        		
        		# non-ASCII parameter name
        		return $app->errtrans("Invalid request");
        	}
        	
        	my @d = $q->param($p);
        	my @param;
        	foreach my $d (@d) {
        		if ( ( !defined $d )
        			|| ( $d eq '' )
        			|| ( $d !~ m/[^\x20-\x7E]/ ) )
        		{
        			push @param, $d if $transcode;
        			next;
        		}
        		$d = MT::I18N::default->encode_text_encode( $d, $request_charset, $charset )
        		if $transcode;
        		my $saved = $d;
        		eval { Encode::decode( $charset, $d, 1 ); };
        		return $app->errtrans(
        			"Invalid request: corrupt character data for character set [_1]",
        			$charset
        			) if $@;
        		push @param, $saved if $transcode;
        	}
        	if ( $transcode && @param ) {
        		if ( 1 == scalar(@param) ) {
        			$params{ $p } = $param[0];
        		}
        		else {
        			$params{ $p } = [ @param ];
        		}
        	}
        }
        while ( my ( $key, $val ) = each %params ) {
        	if ( ref $val eq 'ARRAY') {
        		$app->param( $key, @{ $params{ $key } } ) ;
        	}
        	else {
        		$app->param( $key, $val );
        	}
        }
        
        return 1;
}

1;
