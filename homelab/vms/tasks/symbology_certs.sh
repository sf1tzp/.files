#!/bin/bash

mkdir -p ~/.nginx/certs/live/symbology.lofi
step ca certificate symbology.lofi ~/.nginx/certs/live/symbology.lofi/fullchain.pem ~/.nginx/certs/live/symbology.lofi/privkey.pem --san "symbology.lofi" --not-after 24h

mkdir -p ~/.nginx/certs/live/api.symbology.lofi
step ca certificate api.symbology.lofi ~/.nginx/certs/live/api.symbology.lofi/fullchain.pem ~/.nginx/certs/live/api.symbology.lofi/privkey.pem --san "api.symbology.lofi" --not-after 24h

scp -r ~/.nginx/certs/live/symbology.lofi devbox:~/symbology/certificates/live/symbology.lofi
scp -r ~/.nginx/certs/live/api.symbology.lofi devbox:~/symbology/certificates/live/api.symbology.lofi
