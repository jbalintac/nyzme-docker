## The Goal
The main requirement is it need be to _cheap_.

It also need to be a general purpose infrastracture that can be utilize by a varities of roles, and of course to make it fair with negligible traffic and hardware load.
Server capabilities should be open enough for customization to serve as a database, backend, to frontend server on any platform and language as needed.

## The cheapest VPS
Following are the considered options are:

- Z.com
    > Priced at $1.00 for a webhosting however it has the typical cPanel controlled server which lacks customization and mostly offers PHP stack.

- Vultr VPS
    > Offers $2.50 as the lowest however only available only for IPv6 and the one at $3.50 has 512MB memory, 20GB SSD, and 0.5TB transfer. 

- DigitalOcean
    > Offers $5.00 as the lowest with 1G memory, 25G SSD, and 1TB transfer.

- Amazon Lightsail
    > Offers $3.50 as the lowest with 512MB memory, 20G SSD, and 1TB transfer.

The offering of _Amazon Lightsail_ is cheapest one in terms of value with a price of $3.50 and a hardware of 512MB memory, 20G SSD, and 1TB transfer.
Lightsail and Vultr has a small margin of difference especially with its first trial free benefits on which Vultr offers an annual $40 allowance while Lightsail only offer one month free. 

Aside from the affordability ─ I have chosen Lightsail as an opportunity on starting with the AWS platform.

## Exploiting Docker and Nginx Reverse Proxy
To futher utilize our VPS we can use it to server multiple domain or subdomain by using an reverse proxy to direct traffic to our subsystem on which we will host on a Docker Container on the same VPS.

Having a Docker Container virtually makes our VPS a hypervisor for multiple VMs which we can further exploit for hosting low hardware requiring server setup.

### Setting up Docker

**Installing docker and docker-compose**

```bash
$ curl -fsSL https://get.docker.com -o get-docker.sh
$ sudo sh get-docker.sh
$ sudo usermod -aG docker $USR
```

```bash
$ sudo curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
$ sudo chmod +x /usr/local/bin/docker-compose
```

### Reverse-proxy Nginx Container

**Our docker compose setup**

```yaml
version: '2'

services:
    public-server:
        image: nginx:alpine
        ports:
            - 80:80            
            - 443:443
        volumes:
            - ./volume/public-server/nginx/nginx.conf:/etc/nginx/nginx.conf
            - ./volume/public-server/ssl/dhparam-2048.pem:/etc/ssl/certs/dhparam-2048.pem
            - ./volume/public-server/ssl/nyzme.com/etc/letsencrypt/live/nyzme.com/fullchain.pem:/etc/letsencrypt/live/nyzme.com/fullchain.pem
            - ./volume/public-server/ssl/nyzme.com/etc/letsencrypt/live/nyzme.com/privkey.pem:/etc/letsencrypt/live/nyzme.com/privkey.pem
            - ./volume/public-server/nginx/letsencrypt:/data/letsencrypt
        restart: always

    nyzme-blog:
        depends_on:
            - public-server
        image: nginx:alpine
        volumes:
            - ./volume/nyzme-blog/html:/usr/share/nginx/html
        restart: always
```

## Using Let's Encrypts free SSL
We can also get a free SSL for securing and complying to the internet HTTPS standard to our Reverse Proxy by using Let's Encrypt free SSL.

### Getting our SSL keys

**Initial command to get our SSL keys**

```bash
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
```

**Generating our dhparam**

```bash
sudo openssl dhparam -out $PWD/volume/public-server/ssl/dhparam-2048.pem 2048
```

**nginx.conf for reverse proxy and https**

```
worker_processes 1;

events { worker_connections 1024; }

http {

    sendfile on;

    upstream docker-nginx {
        server nyzme-blog:80;
    }

    server {
        listen      80;
        listen [::]:80;
        server_name nyzme.com www.nyzme.com;

        location / {
            rewrite ^ https://$host$request_uri? permanent;
        }

        #for certbot challenges (renewal process)
        location ~ /.well-known/acme-challenge {
	    
            allow all;
            root /data/letsencrypt;
        }
    }

    # for https
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name www.nyzme.com nyzme.com;

        server_tokens off;

        ssl_certificate /etc/letsencrypt/live/nyzme.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/nyzme.com/privkey.pem;

        ssl_buffer_size 8k;

        ssl_dhparam /etc/ssl/certs/dhparam-2048.pem;

        ssl_protocols TLSv1.2 TLSv1.1 TLSv1;
        ssl_prefer_server_ciphers on;
    
        ssl_ciphers ECDH+AESGCM:ECDH+AES256:ECDH+AES128:DH+3DES:!ADH:!AECDH:!MD5;

        ssl_ecdh_curve secp384r1;
        ssl_session_tickets off;   

        # OCSP stapling
        ssl_stapling on;
        ssl_stapling_verify on;
        resolver 8.8.8.8 8.8.4.4;

        ssl on;

        location / {
            proxy_pass         http://docker-nginx;
            proxy_redirect     off;
            proxy_set_header   Host $host;
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Host $server_name;
        }
    }
}

```

### Scheduled Renewal of SSL

```
0 0 1 * * docker run --rm -it --name certbot -v /home/ubuntu/nyzme-docker/volume/public-server/ssl/www.nyzme.com/etc/letsencrypt:/etc/letsencrypt -v /home/ubuntu/nyzme-docker/volume/public-server/ssl/www.nyzme.com/var/lib/letsencrypt:/var/lib/letsencrypt -v /home/ubuntu/nyzme-docker/volume/public-server/ssl/www.nyzme.com/var/log/letsencrypt:/var/log/letsencrypt -v /home/ubuntu/nyzme-docker/volume/public-server/nginx/letsencrypt:/data/letsencrypt certbot/certbot renew --webroot -w /data/letsencrypt && docker-compose -f /home/ubuntu/nyzme-docker/docker-compose.yml exec public-server nginx -s reload
```

