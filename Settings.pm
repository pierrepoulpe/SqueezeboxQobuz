package Plugins::Qobuz::Settings;

use strict;
use Digest::MD5 qw(md5_hex);

use base qw(Slim::Web::Settings);

use Slim::Utils::Prefs;
use Slim::Utils::Log;

my $cache = Plugins::Qobuz::API::Common->getCache();
my $log   = logger('plugin.qobuz');
my $prefs = preferences('plugin.qobuz');

sub name {
	return Slim::Web::HTTP::CSRF->protectName('PLUGIN_QOBUZ');
}

sub page {
	return Slim::Web::HTTP::CSRF->protectURI('plugins/Qobuz/settings/basic.html');
}

sub prefs {
	return ($prefs, 'filterSearchResults', 'playSamples', 'showComposerWithArtist', 'labelHiResAlbums', 'dontImportPurchases',
			'appendVersionToTitle', 'sortFavsAlphabetically', 'sortArtistAlbums', 'showYearWithAlbum', 'useClassicalEnhancements',
			'classicalGenres', 'workPlaylistPosition', 'parentalWarning', 'showDiscs', 'preferredFormat');
}

sub handler {
 	my ($class, $client, $params, $callback, @args) = @_;

	if ( $params->{pref_logout} ) {
		$prefs->remove('token');
		$prefs->remove('userdata');
	}
	elsif ( $params->{saveSettings} ) {
		$params->{'pref_filterSearchResults'} ||= 0;
		$params->{'pref_playSamples'}         ||= 0;
		$params->{'pref_dontImportPurchases'} ||= 0;

		if ($params->{'username'} && $params->{'password'}) {
			my $username = $params->{'username'};
			my $password = md5_hex($params->{'password'});

			Plugins::Qobuz::API->login($username, $password, sub {
				my $token = shift;

				if ($token) {
					$prefs->set('username', "$username");
					$prefs->remove('password_md5_hash');
				}
				else {
					$params->{'warning'} = Slim::Utils::Strings::string('PLUGIN_QOBUZ_AUTH_FAILED');
				}

				my $body = $class->SUPER::handler($client, $params);
				$callback->( $client, $params, $body, @args );
			});

			return;
		}
	}

	$class->SUPER::handler($client, $params);
}

sub beforeRender {
	my ($class, $params, $client) = @_;

	$params->{'prefs'}->{'username'} = $prefs->get('username');
	$params->{'has_session'} = $prefs->get('token') && $prefs->get('userdata') && 1;
}

1;

__END__
