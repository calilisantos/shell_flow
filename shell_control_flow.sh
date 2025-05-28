staging_env="staging"
dev_env="dev"
hml_env="hml"
prod_env="prod"
log_file="move_store.log"

ingestion_flow() {
  file=$1
  file_env=$(jq -r '.properties.environment.value' "$file") # -r is jq --raw-output
  file_name=$(basename "$file")
  dir_name=$(dirname "$file")


  if test "$file_env" = "$staging_env"; then # checking environment passed
    echo "$(date "+%Y-%m-%d %T") [INFO] Starting the ingestion of "$file_name" in "$staging_env""
  elif [ "$file_env" = "$dev_env" ]; then
    echo "$(date "+%Y-%m-%d %T") [INFO] Starting the ingestion of "$file_name" in "$dev_env""
  elif [ "$file_env" = "$hml_env" ]; then
    echo "$(date "+%Y-%m-%d %T") [INFO] Starting the ingestion of "$file_name" in "$hml_env""
  elif [ "$file_env" = "$prod_env" ]; then
    echo "$(date "+%Y-%m-%d %T") [INFO] Starting the ingestion of "$file_name" in "$prod_env""
  else
    invalid_env_message="$(date "+%Y-%m-%d %T") [ERROR] Invalid environment in "$file_name""
    echo "$invalid_env_message" >> "$log_file" # creating failed log
    echo "$invalid_env_message"
    exit 1
  fi

  if test "$dir_name" != "$file_env"; then
    echo "$(date "+%Y-%m-%d %T") [ERROR] Invalid environment value passed in "$file_name".The staging folder must be used"
    exit 1
  else
    echo "$(date "+%Y-%m-%d %T") [INFO] Processing "$file_name" in "$file_env""
  fi

  # running ingestion

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
}

ingestion_flow staging/run_01.json
ingestion_flow staging/run_02.json
ingestion_flow staging/run_03.json
ingestion_flow staging/run_04.json
