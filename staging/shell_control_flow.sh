dev_env="dev"
hml_env="hml"
prod_env="prod"
log_file="move_store.log"

ingestion_flow() {
  file=$1
  file_env=$(jq -r '.properties.environment.value' "$file") # -r is jq --raw-output
  file_name=$(basename "$file")

  if test "$file_env" = "$dev_env"; then # checking environment passed
    echo "$(date "+%Y-%m-%d %T") [INFO] Processing "$file" in "$dev_env""
  elif [ "$file_env" = "$hml_env" ]; then
    echo "$(date "+%Y-%m-%d %T") [INFO] Processing "$file" in "$hml_env""
  elif [ "$file_env" = "$prod_env" ]; then
    echo "$(date "+%Y-%m-%d %T") [INFO] Processing "$file" in "$prod_env""
  else
    invalid_env_message="$(date "+%Y-%m-%d %T") [ERROR] Invalid environment in "$file""
    echo "$invalid_env_message" >> "$log_file" # creating failed log
    echo "$invalid_env_message"
    exit 1
  fi

  case $file_env in # move the file to the right environment
    $dev_env)
      cp "$file" "$dev_env"
    ;;
    $hml_env)
      cp "$file" "$hml_env"
    ;;
    *)
      cp "$file" "$prod_env"
    ;;
  esac
  processed_message="$(date "+%Y-%m-%d %T") [INFO] "$file_name" processed in $file_env"
  echo $processed_message >> "$log_file" # creating success log
  echo $processed_message

  rm -f "$file"  # removing staging file
  echo "$(date "+%Y-%m-%d %T") [INFO] "$file_name" cleaned in staging layer."
}

ingestion_flow staging/run_01.json
ingestion_flow staging/run_02.json
ingestion_flow staging/run_03.json
ingestion_flow staging/run_04.json
