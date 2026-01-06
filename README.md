# Однорядкові варіанти виклику без залишання на сервері:

## Перевірити поточні ліміти:
```bash
curl -fsSL https://raw.githubusercontent.com/Hanashiko/php-limits/master/check_php.sh | bash
```

## Зміна лімітів (з автообрахуванням при вказаному розмірі файла):

### Приклади використання
Змінити всі версії PHP FPM на ліміт для коректної роботи з файлом 512Мб
```bash
curl -fsSL https://raw.githubusercontent.com/Hanashiko/php-limits/master/increase_php.sh | bash -s -- all 512 fpm
```

Змінити PHP 8.1 одразу і FPM і Apache і Cli на ліміт для коректної роботи з файлом 1024Мб
```bash
curl -fsSL https://raw.githubusercontent.com/Hanashiko/php-limits/master/increase_php.sh | bash -s -- 8.2 1024 all
```

Змінити PHP 7.4 Apache2 ліміти на роботу з файлом 256
```bash
curl -fsSL https://raw.githubusercontent.com/Hanashiko/php-limits/master/increase_php.sh | bash -s -- 7.4 256 apache2
```

Аргументи:
- Перший аргумент - версія PHP
- Другий аргумент - розмір файла який повинен коректно завантажуватись (скрипт автоматично порахує під нього усі ліміти)
- Третій аргумент - fpm / apache2 / cli
