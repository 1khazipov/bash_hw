#!/bin/bash
# Задача 6. Массовая обработка файлов

usage() { echo "Использование: $0 [--path dirpath] [--mask mask] [--number number] command"; exit 1; }
error() { echo "Ошибка: $1"; exit 1; }

dirpath=$(pwd)
mask="*"
number=$(nproc)

# если после ключа нет значения, shift 2 не сработает - выводим подсказку
while [[ $# -gt 0 ]]; do
    case "$1" in
        --path) dirpath=$2; shift 2 || usage ;;
        --mask) mask=$2; shift 2 || usage ;;
        --number) number=$2; shift 2 || usage ;;
        *) cmd=$1; shift ;;
    esac
done

if [[ -z "$cmd" ]]; then usage; fi
if [[ ! -d "$dirpath" ]]; then error "каталог $dirpath не существует"; fi
if [[ -z "$mask" ]]; then error "маска не может быть пустой"; fi
if [[ ! "$number" =~ ^[1-9][0-9]*$ ]]; then error "number должно быть целым числом больше нуля"; fi
# если указали просто имя команды (например gzip) - ищем ее путь
if [[ "$cmd" != */* ]]; then cmd=$(command -v "$cmd"); fi
if [[ ! -f "$cmd" || ! -x "$cmd" ]]; then error "команда не найдена или не исполняемая"; fi

dirpath=$(realpath "$dirpath")
shopt -s nullglob
running=0
for file in "$dirpath"/$mask; do
    # только обычные файлы, без ссылок
    if [[ ! -f "$file" || -L "$file" ]]; then continue; fi
    # если уже запущено number процессов - ждем, пока один завершится
    if ((running >= number)); then
        wait -n
        ((running--))
    fi
    "$cmd" "$file" &
    ((running++))
done
wait
