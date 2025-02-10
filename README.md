# Индексация и поиск по базе данных

Библиотека Flibusta, созданная как продолжение Libruseq содержит большое количество книг на разных языках в формате fb2. Искать что-то по ней вручную не представляется возможным. Поэтому это делается при помощи специализированных программ ориентированных главным образом на операционную систему Windows. Эти программы используют индекс inpx, который представляет собой упакованный архив с файлами-индексами. Есть несколько решений, которые используют этот индекс для создания веб-приложений поиска. Беда заключается в том, что структура индекс меняется от раздачи к раздаче. Поэтому приложения ломаются.

Это приложение попытка создать собственное решение для работы с inpx-индексом. Предполагается использование его в виде Docker-контейнера на NAS Synology.

## Развертывание индекса

Файл с расширением inpx представляет собой архив inp-файлов, в которых располагаются индексы библиотек Flibusta и LibRusEq. Прежде чем запускать полноценную rake-задачу по разбору inpx-файла и переноса его содержимого в базу данных можно запустить легковесную rake-задачу inpx:ls, которая извлекает содержимое inpx-файла и выводит его в стандартный поток вывода:

```bash
bundle exec rails inpx:ls['db/data/archive.inpx']
```

Допускает запуск rake-задачи без аргумента в квадратных скобках, в этом случае путь к inpx-файлу будет взят из файла db/data/archive.inpx (его туда необходимо предварительно положить).

```bash
bundle exec rails inpx:ls
```

В случае успешного выполнения предыдущей команды можно приступать к развертыванию базы данных из inpx-файл при помощи следующей rake-задачи

```bash
bundle exec rails inpx:rebuild['db/data/archive.inpx']
```

Аргумент так же можно опустить, если по пути db/data/archive.inpx будет размещен актуальный inpx-файл

```bash
bundle exec rails inpx:rebuild
```

## Переменные окружения

Переменные окружения лучше всего устанавливать в файле `.env`, который игнорируется правилами `.gitignore`. Файл можно создать из заготовки `.sample.env`.

* INPX_PATH - путь к inpx-файлу с индексом библиотеки, необходим для перестройки индекса в базе данных. По умолчанию db/data/archive.inpx
* ARCHIVES_FOLDER - путь к папке с архивами библиотеки. По умолчанию db/data/
* SQL_DUMP_PATH - путь к SQL-дампу, который разворачивается командой `bundle exec rails db:seed`
* SECRET_KEY_BASE - соль для шифрования данных, лучше всего генерировать командой `openssl rand -hex 64`
* DOCKER_COMPOSE_ARCHIVE_FOLDER - абсолютный путь к папке с архивами библиотеки. Необходим для запуска docker-compose, например, на NAS-сервере
* SEED_EMAIL - электронный адрес для создания первого администратора. Электронный адрес за одно выступает и паролем, который можно поменять в системе админстрирования.
* INDEX_CONCURRENT_PROCESSES - количество параллельных процессов при разборе inpx-файла. По умолчанию, равно удвоенному количеству ядер центрального процессора

# Работа с базой данных

Особенности работы с базой данных PostgreSQL

## Создание и применение SQL-дампа

Каждый раз разворачивать базу данных из inpx-файла довольно трудоемкая задача, поэтому для отладочных действий создаем дамп в папке `db/data`

```bash
pg_dump library_development > db/data/development.sql
```

Для того, чтобы восстановить базу данных из дампа, рекомендуется ее предварительно уничтожить и воссоздать

```bash
bundle exec rails db:drop db:create
```

После этого можно заполнить базу данных содержимым дампа

```bash
psql development < db/data/library_development.sql
```

## Настройка кодировки и сопоставления

По умолчанию, при развертывании в PostgreSQL применяется кодировка UTF8 и сопоставление C. Из-за этого могут возникать сложности с поиском по базе данных. Лучше всего изменить кодировку и сопоставление на локальное.

Посмотреть текущие кодировки можно при помощи запроса

```bash
locale -a | grep ru
```

В macos вывод команды выше может выглядеть следующим образом:

```bash
ru_RU.ISO8859-5
ru_RU.CP866
ru_RU.CP1251
ru_RU.UTF-8
ru_RU.KOI8-R
ru_RU
```

Поправить кодировку текущей базы данных можно при пмощи UPDATE-запроса:

```sql
UPDATE pg_database
SET datcollate='ru_RU.UTF-8', datctype='ru_RU.UTF-8'
WHERE datname='library_development';
```

Примененные изменения могут не сохраниться, если мы будем удалять базу данных, например, при помощи команды `rails db:drop`. Чтобы изменения были дологовременными, можно изменить кодировку базы данных template1, которая выступает шаблоном по умолчанию для новых баз данных:

```sql
UPDATE pg_database
SET datcollate='ru_RU.UTF-8', datctype='ru_RU.UTF-8'
WHERE datname='template1';
```

# Запуск в docker-контейнере

Запуск приложения с базой данных в docker

```bash
docker compose up
```

Запуск с пересборкой образов

```bash
docker compose up --build
```

Развертывание базы данных из дампа

```bash
docker compose run web bundle exec rails db:seed
```

# Запуск на NAS

Скачиваем на NAS данный репозиторий и указываем к нему путь к Docker-проекте. В папку проекта обязательно добавляем .env-файл, можно скопировать его из .sample.env. В переменной окружения DOCKER_COMPOSE_ARCHIVE_FOLDER указываем абсолютный путь к папке с файлами библиотеки.

Когда приложение Container Manager предложит использовать docker-compose.yml, следует согласиться и дождаться запуска docker-проекта.

TODO: Опираемся на инструкцию тут https://sites.google.com/site/copsfb2/ver1-1-3/docker-install?authuser=0
TODO: Адаптируем ее потом для своих целей

Если запускаем первый раз, то база данных PostgreSQL будет пустой, в ней даже не будет самой базы данных. Проще всего создать базу данных и заполнить ее содержимым, проникнув в RoR-контейнер library. Для этого выполняем команду 

```bash
$ sudo docker ps
CONTAINER ID   IMAGE                       COMMAND
85c3fa1262ab   library                     ...
03e06441ca72   postgres:17                 ...
...
```

Нас интересует конейнер с названием library, в примере выше у него идентификатор 85c3fa1262ab, однако у вас он будет другой. Этот идентификатор необходимо подставить в следующую команду:

```bash
sudo docker exec -it 85c3fa1262ab bash
```

После этого, мы оказываемся внутри docker-контейнера. Нужно создать базу данных и выполнить миграции, воспользовавшись следующей командой:

```bash
bundle exec rails db:create db:migrate
```

Далее, необходимо заполнить базу данных. Если у вас уже есть SQL-дамп, расположенный по пути, на который указывает переменная окружения SQL_DUMP_PATH, то можно воспользоваться командой:

```bash
bundle exec rails db:seed
```

Если дампа нет, то придется построить его из inpx-файла, путь к которому указывается при помощи переменной окружения INPX_PATH. Для этого следует выполнить следующую команду:

```bash
bundle exec rails inpx:rebuild
```

Это длительная операция, которая занимает несколько часов (обрабатывается порядка 750 000 книг).

Лучше сразу поменять учетной записи, чтобы его не могли подобрать злоумышленники. Для этого невыходя из docker-контейнера, заходим в рельсовую консоль

```bash
bundle exec rails c
```

Ищем по email учетную запись и назначаем ей новый пароль:

```ruby
u = AdminUser.find_by(email: 'igor@softtime.ru')
u.update(password: '...')
```

# План работ

1. Сверстать страницу входа на реакте
2. Сверстать основную страницу поиска на реакте
3. При поиске книг нужна фильтрация по языку (а может и на странице автора)
4. Управление пользователями нужно перенести в active_admin
5. Подготовить docker-compose под фронтовую часть
6. Реализовать frontend-часть
7. Реализовать вход в систему на базе React
8. Реализовать поиск на базе React-компонентов
9. Реализовать постраничную навигацию на базе React-компонентов

# Разработка

## Зависимости

На начало разработки использовались актуальные версии Ruby 3.3.0 и Rails 8.0
В качестве базы данных используется PostgreSQL версии 17

Для запуска в продакшен окружении, потребуется установить переменную окружения SECRET_KEY_BASE. В docker-compose значение этой переменной устанавливается автоматически при помощи команды `openssl rand -hex 64`. При запуске в командной строке эту переменную лучше всего определить в файле .env.

## Схема проброса порта по SSH

```bash
ssh -L local_port:local_host:remote_port remote_host
```

Для Ruby on Rails проекта, порт можно пробросить следующим образом:

```bash
ssh -L 3000:localhost:3000 ubuntu
```

## Диаграммы

В папке docs находятся PlantUML-диаграмма для rake-задачи `inpx:rebuild`. Посмотреть диаграмму можно в [online-редакторе](https://www.planttext.com/).

* [docs/inpx-rebuild.md](docs/inpx-rebuild.md) - схема распараллеливания задач в rake-задаче `inpx:rebuild`
