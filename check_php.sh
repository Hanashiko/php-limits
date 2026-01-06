#!/bin/bash

PARAMS=("memory_limit" "post_max_size" "upload_max_filesize" "max_execution_time" "max_input_vars" "max_input_time")

echo "====================================================="
echo "Звіт по лімітах PHP на сервері"
echo "====================================================="

echo -e "\n[CLI Версії]"
PHP_BINS=$(which php-config >/dev/null 2>&1 && find /usr/bin /usr/local/bin -name "php[0-9].*" -type f || which php)

for php_bin in $PHP_BINS; do
  if [[ $php_bin =~ /php([0-9]\.[0-9]+)$ ]] || [[ $php_bin == */php ]]; then
    version=$($php_bin -v | head -n 1 | cut -d " " -f 2)
    echo -e "\n--- PHP $version ($php_bin) ---"
    for param in "${PARAMS[@]}"; do
      val=$($php_bin -r "echo ini_get('$param');")
      echo "$param: $val"
    done
  fi
done

if [ -d "/etc/php" ]; then
  echo -e "\n[FPM Конфігурації (з файлів)]"
  FPM_CONFIGS=$(find /etc/php -name "php.ini" | grep "fpm")

  for ini in $FPM_CONFIGS; do
    echo -e "\n--- Шлях: $ini ---"
    for param in "${PARAMS[@]}"; do
      val=$(grep -E "^$param" "$ini" | awk -F'=' '{print $2}' | tr -d ' ')
      echo "$param: ${val:-значення за замовчуванням}"
    done
  done
fi

if [ -d "/etc/php" ]; then
  APACHE_CONFIGS=$(find /etc/php -name "php.ini" | grep "apache2")
  if [ ! -z "$APACHE_CONFIGS" ]; then
    echo -e "\n[Apache Module Конфігурації]"
    for ini in $APACHE_CONFIGS; do
      echo -e "\n--- Шлях: $ini ---"
      for param in "${PARAMS[@]}"; do
        val=$(grep -E "^$param" "$ini" | awk -F'=' '{print $2}' | tr -d ' ')
        echo "$param: ${val:-значення за замовчуванням}"
      done
    done
  fi
fi

echo -e "\n====================================================="
