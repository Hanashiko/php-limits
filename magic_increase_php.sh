#!/bin/bash

SIZE_MB=${1:-256}

CLEAN_SIZE=$(echo $SIZE_MB | sed 's/[^0-9]//g')

NEW_UPLOAD="${CLEAN_SIZE}M"
NEW_POST="$((CLEAN_SIZE + 8))M"
NEW_MEMORY="$((CLEAN_SIZE * 2))M"

if [ "$CLEAN_SIZE" -lt 256 ]; then
  NEW_MEMORY="512M"
fi

NEW_EXEC_TIME="300"
NEW_INPUT_VARS="3000"
NEW_INPUT_TIME="300"

echo ">>> Налаштування під файл розміром: $NEW_UPLOAD"
echo ">>> Будуть встановлені ліміти: Memory: $NEW_MEMORY, Post: $NEW_POST"

update_param() {
  local param=$1
  local value=$2
  local file=$3

  if grep -qE "^$param =" "$file"; then
    sed -i "s/^$param =.*/$param = $value/" "$file"
  elif grep -qE "^;$param =" "$file"; then
    sed -i "s/^;$param =.*/$param = $value/" "$file"
  else
    sed -i "/^\[PHP\]/a $param = $value" "$file"
  fi
}

echo "Починаю оновлення конфігурацій PHP..."

INI_FILES=$(find /etc/php -name "php.ini" | grep -E "fpm|apache2|cli")

for ini in $INI_FILES; do
  echo "Оновлюю: $ini"
  update_param "memory_limit" "$NEW_MEMORY" "$ini"
  update_param "post_max_size" "$NEW_POST" "$ini"
  update_param "upload_max_filesize" "$NEW_UPLOAD" "$ini"
  update_param "max_execution_time" "$NEW_EXEC_TIME" "$ini"
  update_param "max_input_vars" "$NEW_INPUT_VARS" "$ini"
  update_param "max_input_time" "$NEW_INPUT_TIME" "$ini"
done

echo "-----------------------------------------------------"
echo "Перезавантаження сервісів..."

FPM_SERVICES=$(systemctl list-units --type=service --state=running | grep php | grep fpm | awk '{print $1}')
for service in $FPM_SERVICES; do
  systemctl restart "$service"
  echo "Сервіс $service перезапущено."
done

if systemctl is-active --quiet apache2; then
  systemctl restart apache2
  echo "Apache2 перезапущено."
fi

echo "Готово! Встановлено ліміт завантаження: $NEW_UPLOAD"
