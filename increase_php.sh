#!/bin/bash

# Аргументи
PHP_VER=$1
SIZE_MB=$2
PHP_TYPE=${3:-all} # за замовчуванням 'all'

if [ -z "$PHP_VER" ] || [ -z "$SIZE_MB" ]; then
  echo "Помилка: Недостатньо аргументів!"
  echo "Використання: bash $0 <версія|all> <розмір_мб> <тип|all>"
  echo "Типи: fpm, apache2, cli, all"
  echo "Приклад: bash $0 8.1 512 fpm"
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
echo "Налаштування: PHP $PHP_VER | Тип: $PHP_TYPE | Файл: $NEW_UPLOAD"
echo "-----------------------------------------------------"

case $PHP_TYPE in
fpm) TYPE_FILTER="fpm" ;;
apache2) TYPE_FILTER="apache2" ;;
cli) TYPE_FILTER="cli" ;;
all) TYPE_FILTER="fpm|apache2|cli" ;;
*)
  echo "Невідомий тип: $PHP_TYPE"
  exit 1
  ;;
esac

SEARCH_PATH="/etc/php"
[ "$PHP_VER" != "all" ] && SEARCH_PATH="/etc/php/$PHP_VER"

if [ ! -d "$SEARCH_PATH" ]; then
  echo "Помилка: Шлях $SEARCH_PATH не знайдено."
  exit 1
fi

INI_FILES=$(find $SEARCH_PATH -name "php.ini" | grep -E "$TYPE_FILTER")

if [ -z "$INI_FILES" ]; then
  echo "Файлів конфігурації не знайдено за вказаними параметрами."
  exit 1
fi

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

if [[ "$PHP_TYPE" == "fpm" || "$PHP_TYPE" == "all" ]]; then
  if [ "$PHP_VER" == "all" ]; then
    FPM_SERVICES=$(systemctl list-units --type=service --state=running | grep php | grep fpm | awk '{print $1}')
  else
    FPM_SERVICES=$(systemctl list-units --type=service --state=running | grep "php$PHP_VER-fpm" | awk '{print $1}')
  fi
  for s in $FPM_SERVICES; do systemctl restart "$s" && echo "Restarted $s"; done
fi

if [[ "$PHP_TYPE" == "apache2" || "$PHP_TYPE" == "all" ]]; then
  if systemctl is-active --quiet apache2; then
    systemctl restart apache2
    echo "Restarted Apache2"
  fi
fi

echo "-----------------------------------------------------"
echo "Готово! Нові ліміти застосовані."
