#!/bin/sh

ERLANG_VERSION=24.1-1
ELIXIR_VERSION=1.6.1
NODE_VERSION=16

# Note: password is for postgres user "postgres"
POSTGRES_DB_PASS=postgres
POSTGRES_VERSION=9.5

# Set language and locale
apt-get install -y language-pack-en
locale-gen --purge en_US.UTF-8
echo "LC_ALL='en_US.UTF-8'" >> /etc/environment
dpkg-reconfigure locales

# Install basic packages
# inotify is installed because it's a Phoenix dependency
apt-get -qq update
apt-get install -y \
wget \
git \
unzip \
build-essential \
ntp \
inotify-tools

# Install Erlang
#echo "deb https://binaries2.erlang-solutions.com/ubuntu trusty contrib" >> /etc/apt/sources.list && \
# wget https://binaries2.erlang-solutions.com/GPG-KEY-pmanager.asc && \
# apt-key adv --fetch-keys http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc && \
# sudo apt-key add GPG-KEY-pmanager.asc
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && sudo dpkg -i erlang-solutions_2.0_all.deb  && \
apt-get -qq update && \
apt-get install -y -f \
esl-erlang="1:${ERLANG_VERSION}"

# Install Elixir
cd / && mkdir -p elixir && cd elixir && \
wget -q https://github.com/elixir-lang/elixir/releases/download/v1.14.4/elixir-otp-24.zip && \
unzip elixir-otp-24.zip && \
rm -f elixir-otp-24.zip && \
ln -s /elixir/bin/elixirc /usr/local/bin/elixirc && \
ln -s /elixir/bin/elixir /usr/local/bin/elixir && \
ln -s /elixir/bin/mix /usr/local/bin/mix && \
ln -s /elixir/bin/iex /usr/local/bin/iex

# # Install local Elixir hex and rebar for the ubuntu user
su - ubuntu -c '/usr/local/bin/mix local.hex --force && /usr/local/bin/mix local.rebar --force'

# Postgres
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib
# echo $POSTGRES_DB_PASS | passwd --stdin postgres
echo "postgres:$POSTGRES_DB_PASS" | chpasswd


# # Install nodejs and npm
# curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -
# apt-get install -y \
# nodejs

# # Install imagemagick
# apt-get install -y imagemagick

# If seeds.exs exists we assume it is a Phoenix project
if [ -f /vagrant/priv/repo/seeds.exs ]
  then
    # Set up and migrate database
    su - ubuntu -c 'cd /vagrant && mix deps.get && mix ecto.create && mix ecto.migrate'
    # Run Phoenix seed data script
    su - ubuntu -c 'cd /vagrant && mix run priv/repo/seeds.exs'
fi
