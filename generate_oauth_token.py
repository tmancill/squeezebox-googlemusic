#!/usr/bin/env python

import argparse
from gmusicapi import Mobileclient

def main():
    parser = argparse.ArgumentParser(description = 'Generate oauth credentials for Google Play Music')

    #parser.add_argument('username', help = 'Your Google Play Music username')
    #parser.add_argument('password', help = 'Your password')
    #
    #args = parser.parse_args()

    api = Mobileclient()
    oauth_credentials = api.perform_oauth();
    print('if successful, credentials can be found in ~/.local/share/gmusicapi/mobileclient.cred')
    print('Install this file in /usr/share/squeezeboxserver/.local/share/gmusicapi on your LMS machine')


if __name__ == '__main__':
    main()
