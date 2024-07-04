import sys
import os
import configparser
import socket




if __name__ == '__main__':
    # check for an argument
    if len(sys.argv) < 3:
        print("Unable to resolve RADIUS DNS name in config file.  Usage:  python3 resolver.py [source_file] [dest_file]")
        quit(1)

    if not os.path.isfile(sys.argv[1]):
        print("Unable to read config file:", sys.argv[1])
        quit(1)

    print("Loading config from:", sys.argv[1])
    config = configparser.ConfigParser()
    config.read(sys.argv[1])

    if 'radius_client' not in config:
        print(f"Config file {sys.argv[1]} does not contain a 'radius_client' section.")
        quit(1)

    try:
        for key in config['radius_client']:
            if key.startswith('host'):
                temp = socket.gethostbyname(config['radius_client'][key])
                if temp != config['radius_client'][key]:
                    print(f"Resolving {config['radius_client'][key]} to {temp}")
                config['radius_client'][key] = temp
    except Exception as e:
        print(f"Error converting hostnames to addresses: {e}")
        quit(1)

    print("Writing config to:", sys.argv[2])
    with open(sys.argv[2], 'w', encoding='utf-8') as output_file:
        config.write(output_file)
    quit(0)
