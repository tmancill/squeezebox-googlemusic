package Plugins::GoogleMusic::ProtocolHandler;

use strict;
use warnings;
use base qw(Slim::Player::Protocols::HTTP);

use Scalar::Util qw(blessed);
use Slim::Player::Playlist;
use Slim::Utils::Log;
use Slim::Utils::Misc;
use Slim::Utils::Prefs;

use Plugins::GoogleMusic::Plugin;
use Plugins::GoogleMusic::GoogleAPI;
use Plugins::GoogleMusic::Image;
use Plugins::GoogleMusic::Library;

my $log = logger('plugin.googlemusic');
my $prefs = preferences('plugin.googlemusic');
my $googleapi = Plugins::GoogleMusic::GoogleAPI::get();

Slim::Player::ProtocolHandlers->registerHandler('googlemusic', __PACKAGE__);

# To support remote streaming (synced players), we need to subclass Protocols::HTTP
sub new {
	my $class  = shift;
	my $args   = shift;

	my $client = $args->{client};
	
	my $song      = $args->{song};
	my $streamUrl = $song->streamUrl() || return;
	my $track     = $song->pluginData('info') || {};
	
	main::DEBUGLOG && $log->debug( 'Remote streaming Google Music track: ' . $streamUrl );

	my $sock = $class->SUPER::new( {
		url     => $streamUrl,
		song    => $song,
		client  => $client,
	} ) || return;
	
	${*$sock}{contentType} = 'audio/mpeg';

	return $sock;
}

# Always MP3
sub getFormatForURL {
	return 'mp3';
}

# Source for AudioScrobbler
sub audioScrobblerSource {
	# P = Chosen by the user
	return 'P';
}

sub scanStream {
	my ($class, $url, $track, $args) = @_;
	my $cb = $args->{cb} || sub {};
 
	my $googleTrack = Plugins::GoogleMusic::Library::get_track($url);

	# To support seeking set duration and bitrate
	$track->secs($googleTrack->{'secs'});
	# Always 320k at Google Music
	$track->bitrate(320000);

	$track->content_type('mp3');
	$track->artistname($googleTrack->{'artist'});
	$track->albumname($googleTrack->{'album'});
	$track->coverurl($googleTrack->{'cover'});
	$track->title($googleTrack->{'title'});
	$track->tracknum($googleTrack->{'trackNumber'});
	$track->filesize($googleTrack->{'filesize'});
	$track->audio(1);
	$track->year($googleTrack->{'year'});
	$track->cover($googleTrack->{'cover'});

	$cb->( $track );

	return;
}

sub getNextTrack {
	my ($class, $song, $successCb, $errorCb) = @_;

	my $url = $song->currentTrack()->url;
	my ($type, $id) = $url =~ m{^googlemusic:(track|all_access_track):(.*)$}x;

	my $trackURL = $googleapi->get_stream_url($id, $prefs->get('device_id'));

	if (!$trackURL) {
		$log->error("Looking up stream url for ID $id failed.");
		$errorCb->();
	}

	$song->streamUrl($trackURL);

	$successCb->();

	return;
}

sub canDirectStreamSong {
	my ( $class, $client, $song ) = @_;
	
	# We need to check with the base class (HTTP) to see if we
	# are synced or if the user has set mp3StreamingMethod
	return $class->SUPER::canDirectStream( $client, $song->streamUrl(), $class->getFormatForURL($song->track->url()) );
}

sub getMetadataFor {
	my ($class, $client, $url) = @_; 

	my $track = Plugins::GoogleMusic::Library::get_track($url);

	return {
		title    => $track->{'title'},
		artist   => $track->{'artist'},
		album    => $track->{'album'},
		duration => $track->{'secs'},
		cover    => $track->{'cover'},
		icon     => $track->{'cover'},
		bitrate  => '320k CBR',
		type     => 'MP3 (Google Music)',
	};
}


1;

__END__
