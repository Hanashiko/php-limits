#!/bin/bash

# Читаємо аргументи
# $1 - версія (наприклад 8.1)
# $2 - розмір у МБ (наприклад 500)
PHP_VER=$1
SIZE_MB=${2:-256}

if [ -z "$PHP_VER" ]; then
  echo "Помилка: Не вказано версію PHP!"
  echo "Використання: bash $0 <версія|all> <розмір_мб>"
  echo "Приклад: bash $0 8.1 500"
  exit 1
fi

CLEAN_SIZE=$(echo $SIZE_MB | sed 's/[^0-9]//g')

NEW_UPLOAD="${CLEAN_SIZE}M"
NEW_POST="$((CLEAN_SIZE + 8))M"
NEW_MEMORY="$((CLEAN_SIZE * 2))M"
[ "$CLEAN_SIZE" -lt 256 ] && NEW_MEMORY="512M"

NEW_EXEC_TIME="300"
NEW_INPUT_VARS="3000"
NEW_INPUT_TIME="300"

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

echo "-----------------------------------------------------"
echo "Конфігурація: PHP $PHP_VER | Файл: $NEW_UPLOAD"
echo "-----------------------------------------------------"

if [ "$PHP_VER" == "all" ]; then
  SEARCH_PATH="/etc/php"
else
  SEARCH_PATH="/etc/php/$PHP_VER"
  if [ ! -d "$SEARCH_PATH" ]; then
    echo "Помилка: Версія $PHP_VER не знайдена в $SEARCH_PATH"
    exit 1
  fi
fi

INI_FILES=$(find $SEARCH_PATH -name "php.ini" | grep -E "fpm|apache2|cli")

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

if [ "$PHP_VER" == "all" ]; then
  FPM_SERVICES=$(systemctl list-units --type=service --state=running | grep php | grep fpm | awk '{print $1}')
else
  FPM_SERVICES=$(systemctl list-units --type=service --state=running | grep "php$PHP_VER-fpm" | awk '{print $1}')
fi

for service in $FPM_SERVICES; do
  systemctl restart "$service"
  echo "Сервіс $service перезапущено."
done

if systemctl is-active --quiet apache2; then
  systemctl restart apache2
  echo "Apache2 перезапущено."
fi

echo "Готово!"
