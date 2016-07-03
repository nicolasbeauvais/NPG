#!/bin/bash

#
# NPG: simple web project manager
#

# You nginx vhost directory
NGINX_VHOSTS_DIR="/etc/nginx/sites-available"

# You working directory
WORKING_DIR="/home/nicolas/work"

# The command to restart nginxa
RESTART_NGINX="service nginx restart"

# Username to use when creating directories
USERNAME="nicolas"

# Parse arguments
declare -a args=();

while [[ $# -gt 0 ]]
do

key="$1"
args=("${args[@]}" ${key})

case $key in
    -h|--help)
    HELP=true
    shift
    ;;
    *)
    # unknown option
    ;;
esac
shift
done

# Define simple colors helper
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
bold=$'\e[1m'
end=$'\e[0m'

# If no args display help message
if [[ ${#args[@]} = 0 ]]; then
  HELP=true
fi

# Print help if request
if [ ${HELP} ]; then
cat << "EOF"
 _______ ______ _______
|    |  |   __ \     __|
|       |    __/    |  |
|__|____|___|  |_______|
EOF

  printf "%s\n\n" "${grn}NPG:${end} NGINX Project Generator"

  printf "%s\n" "${yel}Usage:${end}"
  printf "  %s\n\n" "npg [options] [arguments]"

  printf "%s\n" "${yel}Options:${end}"
  printf "  %-25s %s\n\n" "${grn}-h, --help${end}" "Display this help message"

  printf "%s\n" "${yel}Available commands:${end}"
  printf "  %-25s %s\n" "${grn}list${end}"   "List all current projects"
  printf "  %-25s %s\n" "${grn}test${end}"   "Test all projects status"
  printf "  %-25s %s\n" "${grn}create${end}" "Create a new project"
  printf "  %-25s %s\n" "${grn}rename${end}" "Rename a project"
  printf "  %-25s %s\n" "${grn}delete${end}" "Delete a project"
  exit
fi

# List
if [[ " ${args[*]} " == *" list "* ]]; then
  vhosts=($(ls ${NGINX_VHOSTS_DIR}))

  printf "%s\n" "${yel}List of current projects:${end}"

  printf "  %s\n" "${grn}${vhosts[@]}${end}"
  exit
fi

# Test
if [[ " ${args[*]} " == *" test "* ]]; then
  printf "%s\n" "${yel}List of current projects:${end}"
  printf "  ${bold}%-40s %-40s %-40s %-40s${end}\n" "Project" "NGINX vhost" "Working directory" "Status"

  sites_enabled=$(ls "$NGINX_VHOSTS_DIR/../sites-enabled")
  projects_directory=$(ls "$WORKING_DIR")

  for project in $(ls ${NGINX_VHOSTS_DIR}); do

    project_name=${project%%.*}

    project_enabled='no'
    project_directory='no'

    if [[ ${sites_enabled[@]} =~ ${project} ]]; then
      project_enabled='yes'
    fi

    if [[ ${projects_directory[@]} =~ ${project_name} ]]; then
      project_directory='yes'
    fi

    status=$(curl -I  --stderr /dev/null http://${project} | head -1 | cut -d' ' -f2)
    if [ -z "${status}" ]; then
      status="Could not resolve host"
    fi

    [[ ${project_enabled} = 'yes' ]] && c1="${grn}" || c1="${red}"
    [[ ${project_directory} = 'yes' ]] && c2="${grn}" || c2="${red}"
    [[ ${status} = "200" ]] && c3="${grn}" || c3="${red}"

    printf "  ${grn}%-40s${end} ${c1}%-40s${end} ${c2}%-40s${end} ${c3}%-40s${end}\n" "${project}" "${project_enabled}" "${project_directory}" "${status}"
  done
  exit
fi

# Create
if [[ " ${args[*]} " == *" create "* ]]; then

  if [ -z "${args[1]}" ]; then
    printf "%s\n" "${red}[ERROR] You need to specify a project name.${end}"
    printf "%s\n" "${yel}Usage:${end}"
    printf "  %s\n\n" "npg create project.dev"
    printf "%s\n" "Type ${grn}npg --help${end} to display the help message"
    exit
  fi

  projects=($(ls ${NGINX_VHOSTS_DIR}))
  project=${args[1]}

  if [[ ${projects[@]} =~ ${project} ]]; then
    printf "%s\n" "${red}[ERROR] Project ${project} already exist.${end}"
    printf "%s\n" "Type ${grn}npg list${end} to list all projects"
    exit
  fi

  printf "%s\n" "${yel}Creating new ${args[1]} project:${end}"
  printf "  ${grn}%-40s${end} %-40s\n" "Creating vhost:${end}" "${NGINX_VHOSTS_DIR}/${project}"

  touch ${NGINX_VHOSTS_DIR}/${project}
  cat <<< "
#
# ${args[1]}
#
server {

    listen 80;
    server_name ${project} *.${project};

    root /var/www/work/${project}/public;

    index index.php index.html;

    # Logging
    access_log /var/log/nginx/${project}.access.log;
    error_log  /var/log/nginx/${project}.error.log;

    # Allow access

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;

        fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
        fastcgi_index index.php;
        include fastcgi.conf;
    }

    location = /favicon.ico {
         access_log off;
         log_not_found off;
    }

    location = /robots.txt {
         access_log off;
         log_not_found off;
    }
}" > ${NGINX_VHOSTS_DIR}/${project}

  printf "  ${grn}%-40s${end} %-40s\n" "Activating vhost with symbolic link:${end}" "${NGINX_VHOSTS_DIR}/../sites-enabled/${project}"
  if [[ -h "${NGINX_VHOSTS_DIR}/../sites-enabled/${project}" ]]; then
    rm "${NGINX_VHOSTS_DIR}/../sites-enabled/${project}"
  fi
  ln -s "${NGINX_VHOSTS_DIR}/${project}" "${NGINX_VHOSTS_DIR}/../sites-enabled/${project}"

  if [[ -d "${WORKING_DIR}/${project}" ]]; then
    printf "  ${grn}%-40s${end} %-40s\n" "Working directory already exist:${end}" "${WORKING_DIR}/${project}"
  else
    printf "  ${grn}%-40s${end} %-40s\n" "Creation of the working directory:${end}" "${WORKING_DIR}/${project}"
    mkdir "${WORKING_DIR}/${project}"
    chown -R "${USERNAME}:${USERNAME}" "${WORKING_DIR}/${project}"
  fi

  printf "${yel}%s${end}\n" "Restarting nginx"
  eval ${RESTART_NGINX}
  exit
fi

# Delete
if [[ " ${args[*]} " == *" delete "* ]]; then

  if [ -z "${args[1]}" ]; then
    printf "%s\n" "${red}[ERROR] You need to specify a project name.${end}"
    printf "%s\n" "${yel}Usage:${end}"
    printf "  %s\n\n" "npg delete project.dev"
    printf "%s\n" "Type ${grn}npg --help${end} to display the help message"
    exit
  fi

  projects=($(ls ${NGINX_VHOSTS_DIR}))
  project=${args[1]}

  if [[ ! ${projects[@]} =~ ${project} ]]; then
    printf "%s\n" "${red}[ERROR] Couldn't find any project ${project}.${end}"
    printf "%s\n" "Type ${grn}npg list${end} to list all projects"
    exit
  fi

  read -p "Are you sure? (Y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    exit 1
  fi

  printf "%s\n" "${yel}Deleting ${args[1]} project:${end}"
  printf "  ${grn}%-40s${end} %-40s\n" "Deleting vhost symbolic link:${end}" "${NGINX_VHOSTS_DIR}/../sites-enabled/${project}"
  unlink "${NGINX_VHOSTS_DIR}/../sites-enabled/${project}"

  printf "  ${grn}%-40s${end} %-40s\n" "Deleting vhost:${end}" "${NGINX_VHOSTS_DIR}/${project}"
  rm "${NGINX_VHOSTS_DIR}/${project}"

  if [[ -d "${WORKING_DIR}/${project}" ]]; then
    printf "  ${grn}%-40s${end} %-40s\n" "Deleting working directory:${end}" "${WORKING_DIR}/${project}"
    rm -rf "${WORKING_DIR}/${project}"
  else
    printf "  ${grn}%-40s${end} %-40s\n" "No working directory:${end}" "${WORKING_DIR}/${project}"
  fi

  printf "${yel}%s${end}\n" "Restarting nginx"
  eval ${RESTART_NGINX}
  exit
fi

# Rename
if [[ " ${args[*]} " == *" rename "* ]]; then

  if [ -z "${args[1]}" ]; then
    printf "%s\n" "${red}[ERROR] You need to specify a project to rename.${end}"
    printf "%s\n" "${yel}Usage:${end}"
    printf "  %s\n\n" "npg create project.dev newproject.dev"
    printf "%s\n" "Type ${grn}npg --help${end} to display the help message"
    exit
  fi

  if [ -z "${args[2]}" ]; then
    printf "%s\n" "${red}[ERROR] You need to specify the project new name.${end}"
    printf "%s\n" "${yel}Usage:${end}"
    printf "  %s\n\n" "npg create project.dev newproject.dev"
    printf "%s\n" "Type ${grn}npg --help${end} to display the help message"
    exit
  fi

  projects=($(ls ${NGINX_VHOSTS_DIR}))
  project=${args[1]}
  newproject=${args[2]}

  if [[ ! ${projects[@]} =~ ${project} ]]; then
    printf "%s\n" "${red}[ERROR] Couldn't find any project ${project}.${end}"
    printf "%s\n" "Type ${grn}npg list${end} to list all projects"
    exit
  fi

  if [[ ${projects[@]} =~ ${newproject} ]]; then
    printf "%s\n" "${red}[ERROR] Project ${newproject} already exist.${end}"
    printf "%s\n" "Type ${grn}npg list${end} to list all projects"
    exit
  fi
  printf "%s\n" "${yel}Renaming ${project} into ${newproject}:${end}"

  printf "  ${grn}%-40s${end} %-40s\n" "Renaming vhost:${end}" "${NGINX_VHOSTS_DIR}/${project}"
  mv "${NGINX_VHOSTS_DIR}/${project}" "${NGINX_VHOSTS_DIR}/${newproject}"

  printf "  ${grn}%-40s${end} %-40s\n" "Updating vhost content:${end}" "${NGINX_VHOSTS_DIR}/${newproject}"
  sed -i -e "s/${project}/${newproject}/g" "${NGINX_VHOSTS_DIR}/${newproject}"

  printf "  ${grn}%-40s${end} %-40s\n" "Update vhost symlink:${end}" "${NGINX_VHOSTS_DIR}/../sites-enabled/${project}"
  if [[ -h "${NGINX_VHOSTS_DIR}/../sites-enabled/${project}" ]]; then
    rm "${NGINX_VHOSTS_DIR}/../sites-enabled/${project}"
  fi
  ln -s "${NGINX_VHOSTS_DIR}/${newproject}" "${NGINX_VHOSTS_DIR}/../sites-enabled/${newproject}"

  if [[ -d "${WORKING_DIR}/${project}" ]]; then
    printf "  ${grn}%-40s${end} %-40s\n" "Updating working directory:${end}" "${WORKING_DIR}/${project}"
    mv "${WORKING_DIR}/${project}" "${WORKING_DIR}/${newproject}"
  else
    printf "  ${grn}%-40s${end} %-40s\n" "No working directory:${end}" "${WORKING_DIR}/${project}"
  fi

  printf "${yel}%s${end}\n" "Restarting nginx"
  eval ${RESTART_NGINX}
  exit
fi

printf "%s\n" "${red}[ERROR] Unknown command ${args[0]}.${end}"
printf "%s\n" "Type ${grn}npg --help${end} to display the help message"
