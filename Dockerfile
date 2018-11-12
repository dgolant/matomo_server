FROM richarvey/nginx-php-fpm
WORKDIR /var/www/html

RUN wget -q https://builds.piwik.org/piwik.zip && unzip piwik.zip