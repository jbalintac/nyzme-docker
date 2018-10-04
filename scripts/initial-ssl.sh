docker run -it --rm \
-v $PWD/volume/public-server/ssl/nyzme.com/etc/letsencrypt:/etc/letsencrypt \
-v $PWD/volume/public-server/ssl/nyzme.com/var/lib/letsencrypt:/var/lib/letsencrypt \
-v $PWD/volume/public-server/ssl/nyzme.com/var/log/letsencrypt:/var/log/letsencrypt \
-v $PWD/volume/public-server/nginx/letsencrypt:/data/letsencrypt \
certbot/certbot \
certonly \
--webroot \
--webroot-path=/data/letsencrypt \
--email <email>@outlook.com --agree-tos --no-eff-email \
-d www.nyzme.com -d nyzme.com