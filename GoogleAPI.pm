package Plugins::GoogleMusic::GoogleAPI;

use strict;
use warnings;
use File::Spec::Functions;
use Slim::Utils::Prefs;
use Scalar::Util qw(blessed);

my $prefs = preferences('plugin.googlemusic');

my $inlineDir;
my $googleapi;

sub get {
    if (!blessed($googleapi)) {
        eval {
            $googleapi = Plugins::GoogleMusic::GoogleAPI::Mobileclient->new(
                $Inline::Python::Boolean::false,
                $Inline::Python::Boolean::false,
                $prefs->get('disable_ssl') ? $Inline::Python::Boolean::false : $Inline::Python::Boolean::true);
        };
    }
    return $googleapi;
}

BEGIN {
    $inlineDir = catdir(Slim::Utils::Prefs::preferences('server')->get('cachedir'), '_Inline');
    mkdir $inlineDir unless -d $inlineDir;
}

use Inline (Config => DIRECTORY => $inlineDir);
use Inline Python => <<'END_OF_PYTHON_CODE';

import gmusicapi
from gmusicapi import Mobileclient, Webclient, CallFailure

def get_version():
    return gmusicapi.__version__

END_OF_PYTHON_CODE


1;
