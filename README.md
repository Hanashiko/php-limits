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

Як скрипт обраховує ліміти з другого аргумента?

- `upload_max_filesize` - значення з другого аргумента переданого в скрипт
- `post_max_size` - обробляє завантаження через POST запити, але оскільки запити містять не тільки файл а ще також текстові поля, заголовки, метадані, то цей ліміт це +8M від переданого числа в другому аргументі скрипта
- `memory_limit` - php потребує оперативної памяті щоб прочитати, обробити й взаємодіяти з файлом тож число з другого параметра скрипта передається в цю зміну множачись на 2 (але  не менше 512М)
- `max_execution_time` - 300 (5хв)
- `max_input_time` - 300 (5хв)
- `max_input_vars` - 3000 

Приклад:

якщо передати 1000, тоді отримаємо:
- `upload_max_filesize` = 1000M
- `post_max_size` = 1008M
- `memory_limit` = 2000M (2GB)
