#!/bin/bash

### DEPLOYMENT LOGGING ###
# Show commands and exit if any part of this script fails
set -ex
home="/home/ubuntu/FunctionalVote"
# Remove existing log
rm -f $home/production/deploy.log
# Set log location
exec 1>$home/production/deploy.log 2>&1

# Get new updates
git pull

### BACKEND ###
# Kill backend
pm2 stop phoenix_dev
# Run database migrations
cd $home/backend
mix ecto.migrate
# Start backend
pm2 start phoenix_dev

### FRONTEND ###
# Build frontend files in production
cd $home/frontend
# Install packages if needed
npm install
# Build in production mode
npm run build
