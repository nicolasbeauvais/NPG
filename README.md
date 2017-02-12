# NPG

NPG is a small tool written in bash that help you easily generate and manage web projects that use NGINX.

![screenshot-2017-02-12_18-15-36](https://cloud.githubusercontent.com/assets/2951704/22864331/b6169010-f14f-11e6-97d8-aaa3b9f297d6.png)


## Installation

Download npg.sh anywhere you want
```bash
wget https://raw.githubusercontent.com/nicolasbeauvais/npg/master/npg.sh
```

Modify the script accordingly:
```bash
# You nginx vhost directory
NGINX_VHOSTS_DIR="/etc/nginx/sites-available"

# You working directory
WORKING_DIR="/your/work/directory"

# The command to restart nginxa
RESTART_NGINX="service nginx restart"

# Username to use when creating directories
USERNAME="yourusername"
```

Create a symlink:
```bash
ln -s npg.sh /usr/bin/npg
```

## Usage

```bash
npg --help # list all available commands
```
