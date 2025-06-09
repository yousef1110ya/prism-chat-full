FROM ejabberd/ecs:latest

USER root
# RUN apk add --no-cache nodejs npm
RUN apk add --no-cache \
    perl \
    perl-utils \
    perl-app-cpanminus \
    build-base \
    musl-dev \
    linux-headers \ 
    perl-json \
    perl-mime-base64

# Install required Perl modules from CPAN
RUN cpanm --notest \
    Dotenv \
    JWT::Decode \
    JSON \
    MIME::Base64
# RUN apk add --no-cache nodejs npm 

# for auth script
# RUN cpanm Unix::Syslog


# Copy config and auth script
COPY docker/ejabberd.yml /home/ejabberd/conf/ejabberd.yml
COPY auth/check_pass_null.pl /home/ejabberd/check_pass_null.pl

RUN chmod +x /home/ejabberd/check_pass_null.pl && \
    chown ejabberd:ejabberd /home/ejabberd/check_pass_null.pl && \
    chown ejabberd:ejabberd /home/ejabberd/conf/ejabberd.yml && \
    chmod 644 /home/ejabberd/conf/ejabberd.yml

    
RUN apk add --no-cache dos2unix
RUN dos2unix /home/ejabberd/check_pass_null.pl
    

# Ensure external auth dir exists
# RUN mkdir -p /home/ejabberd/auth


# Copy your custom auth script
# COPY auth/auth_script_jwt.js /home/ejabberd/auth/auth_script_jwt.js
# Copy your custom auth script
# COPY auth/auth_script_jwt.js /home/ejabberd/auth/auth_script_jwt.js
# RUN chown ejabberd:ejabberd /home/ejabberd/auth/auth_script_jwt.js
# RUN chmod +x /home/ejabberd/auth/auth_script_jwt.js

# Copy custom config
# COPY docker/ejabberd.yml /home/ejabberd/conf/ejabberd.yml
# RUN touch /home/ejabberd/check_pass_null.pl
# COPY auth/check_pass_null.pl /home/ejabberd/check_pass_null.pl
# RUN chmod +x /home/ejabberd/check_pass_null.pl
# RUN chown ejabberd:ejabberd /home/ejabberd/check_pass_null.pl

# copu jwt secret
# COPY jwt/secret.jwk /home/ejabberd/auth/secret.jwk


RUN ls -l /home/ejabberd

# RUN chown ejabberd:ejabberd /home/ejabberd/auth/secret.jwk && \
#     chmod 600 /home/ejabberd/auth/secret.jwk

# RUN chown ejabberd:ejabberd /home/ejabberd/conf/ejabberd.yml

# RUN chmod 644 /home/ejabberd/conf/ejabberd.yml


USER ejabberd

