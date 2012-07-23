#!/bin/bash

# Filter out livecss requests
python run_server.py 2> >(grep --line-buffered -v "cache_bust=")
