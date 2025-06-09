#!/bin/bash

# Проверка на запуск от root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "🚫 \e[1;31mОшибка: Этот скрипт должен запускаться с правами root!\e[0m" >&2
    exit 1
fi

# Очищаем терминал
clear

# Красивый ASCII-арт с эмодзи
echo -e "\e[1;36m"
echo "  ____   ____ ___  __  __   _   _ ____   ____ ___  ___  "
echo " / ___| / ___/ _ \|  \/  | | | | |  _ \ / ___|_ _|/ _ \ "
echo " \___ \| |  | | | | |\/| | | | | | |_) | |    | | | | | |"
echo "  ___) | |__| |_| | |  | | | |_| |  _ <| |___ | | | |_| |"
echo " |____/ \____\___/|_|  |_|  \___/|_| \_\\____|___|\___/ "
echo -e "\e[1;33m             🚀 SCRIPT BY GA1MAZ.RU \e[0m"
echo ""

# Выводим systeminfo с эмодзи
echo -e "\e[1;34m📊 System Info:\e[0m"
echo -e "🖥️  \e[1;33mIP Address:\e[0m \e[0;32m$(hostname -I 2>/dev/null || echo "N/A")\e[0m"
echo -e "🧠 \e[1;33mRAM:\e[0m \e[0;32m$(free -h | awk '/Mem/{print $3 "/" $2}')\e[0m"
echo -e "💾 \e[1;33mDisk:\e[0m \e[0;32m$(df -h / | awk 'NR==2{print $3 "/" $2}')\e[0m"
echo ""

# Информация о владельце и лицензии
echo -e "\e[1;34m👑 Owner:\e[0m \e[0;35mga1maz.ru\e[0m"
echo -e "\e[1;34m📜 License:\e[0m \e[0;35mMIT\e[0m"
echo ""

# Меню выбора с эмодзи
echo -e "\e[1;34m🔍 Select:\e[0m"
echo -e "\e[1;32m1). 🌡️ BME280 (Temperature/Humidity/Pressure)\e[0m"
echo -e "\e[1;32m2). 🎮 MPU6050 (Accelerometer/Gyroscope)\e[0m"
echo -e "\e[1;32m3). 🔄 Encoder (Rotary Encoder)\e[0m"
echo -e "\e[1;32m4). 🗑️ Удалить файлы\e[0m"
echo ""

# Добавьте здесь логику для обработки выбора пункта 4
# Например:
read -p "Выберите пункт меню (1-4): " choice

case $choice in
    1)
        echo "Выбран BME280"
        # Логика для BME280
        ;;
    2)
        echo "Выбран MPU6050"
        # Логика для MPU6050
        ;;
    3)
        echo "Выбран Encoder"
        # Логика для Encoder
        ;;
    4)
        echo "Удаление файлов..."
        # Логика для удаления файлов
        read -p "Введите путь к файлам для удаления: " filepath
        if [ -e "$filepath" ]; then
            rm -rf "$filepath"
            echo -e "\e[1;32mФайлы успешно удалены!\e[0m"
        else
            echo -e "\e[1;31mОшибка: Указанный путь не существует!\e[0m"
        fi
        ;;
    *)
        echo -e "\e[1;31mНеверный выбор!\e[0m"
        ;;
esac
