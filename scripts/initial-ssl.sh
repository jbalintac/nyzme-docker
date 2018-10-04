$ docker run -it --rm \
-v $PWD/volume/letsencrypt/etc/letsencrypt:/etc/letsencrypt \
-v $PWD/volume/letsencrypt/var/lib/letsencrypt:/var/lib/letsencrypt \
-v $PWD/volume/letsencrypt/var/log/letsencrypt:/var/log/letsencrypt \
-v $PWD/volume/nginx/letsencrypt:/data/letsencrypt \
certbot/certbot \
certonly \
--webroot \
--webroot-path=/data/letsencrypt \
--email _prv@outlook.com --agree-tos --no-eff-email \
-d www.nyzme.com -d nyzme.com \