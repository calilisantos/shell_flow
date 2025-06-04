#!/bin/bash
staging_env="staging"
dev_env="dev"
hml_env="hml"
prod_env="prod"
working_dir="*"
log_file="move_store.log"
layers=$(for layer in $working_dir; do if [ -d $layer ]; then printf "%s " "$layer"; fi done)

for file in $(find $working_dir -name *.json); do
  file_env=$(jq -r '.properties.environment.value' "$file") # -r is jq --raw-output
  file_name=$(basename "$file")
  dir_name=$(dirname "$file")

  if [[ " $layers " =~ " $file_env " && "$file_env" = "$dir_name" ]]; then
    echo "$(date "+%Y-%m-%d %T") [INFO] Starting the ingestion of "$file_name" in "$file_env""
    echo "$(date "+%Y-%m-%d %T") [INFO] Processing "$file_name" in "$file_env""
    case $file_env in # move the file to the next environment
      $staging_env)
        jq --arg next_env "$dev_env" '.properties.environment.value = $next_env' "$file" > tmp && mv tmp "$file"
        mv "$file" "$dev_env/"
      ;;
      $dev_env)
        jq --arg next_env "$hml_env" '.properties.environment.value = $next_env' "$file" > tmp && mv tmp "$file"
        mv "$file" "$hml_env/"
      ;;
      $hml_env)
        jq --arg next_env "$prod_env" '.properties.environment.value = $next_env' "$file" > tmp && mv tmp "$file"
        mv "$file" "$prod_env/"
      ;;
    esac
    processed_message="$(date "+%Y-%m-%d %T") [INFO] "$file_name" processed in $file_env"
    echo $processed_message >> "$log_file" # creating success log
    echo $processed_message
  else
    invalid_env_message="$(date "+%Y-%m-%d %T") [ERROR] Invalid environment in "$file_name""
    echo "$invalid_env_message" >> "$log_file" # creating failed log
    echo "$invalid_env_message"
  fi
done
