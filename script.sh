#!/bin/bash

# Проверка на запуск от root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "🚫 \e[1;31mОшибка: Этот скрипт должен запускаться с правами root!\e[0m" >&2
    exit 1
fi

# Функция для отображения меню
show_menu() {
    clear
    echo -e "\e[1;36m"
    echo "  ____   ____ ___  __  __   _   _ ____   ____ ___  ___  "
    echo " / ___| / ___/ _ \|  \/  | | | | |  _ \ / ___|_ _|/ _ \ "
    echo " \___ \| |  | | | | |\/| | | | | | |_) | |    | | | | | |"
    echo "  ___) | |__| |_| | |  | | | |_| |  _ <| |___ | | | |_| |"
    echo " |____/ \____\___/|_|  |_|  \___/|_| \_\\____|___|\___/ "
    echo -e "\e[1;33m             🚀 СКРИПТ ОТ GA1MAZ.RU \e[0m"
    echo ""

    echo -e "\e[1;34m📊 Информация о системе:\e[0m"
    echo -e "🖥️  \e[1;33mIP-адрес:\e[0m \e[0;32m$(hostname -I 2>/dev/null || echo "Недоступно")\e[0m"
    echo -e "🧠 \e[1;33mОЗУ:\e[0m \e[0;32m$(free -h | awk '/Mem/{print $3 "/" $2}')\e[0m"
    echo -e "💾 \e[1;33mДиск:\e[0m \e[0;32m$(df -h / | awk 'NR==2{print $3 "/" $2}')\e[0m"
    echo ""

    echo -e "\e[1;34m👑 Владелец:\e[0m \e[0;35mga1maz.ru\e[0m"
    echo -e "\e[1;34m📜 Лицензия:\e[0m \e[0;35mMIT\e[0m"
    echo ""

    echo -e "\e[1;34m🔍 Выберите действие:\e[0m"
    echo -e "\e[1;32m1). 🌡️ BME280 (Температура/Влажность/Давление)\e[0m"
    echo -e "\e[1;32m2). 🎮 MPU6050 (Акселерометр/Гироскоп)\e[0m"
    echo -e "\e[1;32m3). 🔄 Энкодер (Ротационный энкодер)\e[0m"
    echo -e "\e[1;32m4). 🗑️ Удалить файлы\e[0m"
    echo -e "\e[1;31m0). ❌ Выход\e[0m"
    echo ""
}

# Основной цикл программы
while true; do
    show_menu
    
    read -p "Введите номер пункта (0-4): " choice
    echo ""

    case $choice in
        1)
            echo -e "\e[1;34mВыбран BME280 (Температура/Влажность/Давление)\e[0m"
            # Реальная команда для BME280
            python3 bme280_script.py 2>/dev/null || echo -e "\e[1;31mОшибка: Не удалось выполнить скрипт BME280\e[0m"
            sleep 2
            ;;
        2)
            echo -e "\e[1;34mВыбран MPU6050 (Акселерометр/Гироскоп)\e[0m"
            # Реальная команда для MPU6050
            python3 mpu6050_script.py 2>/dev/null || echo -e "\e[1;31mОшибка: Не удалось выполнить скрипт MPU6050\e[0m"
            sleep 2
            ;;
        3)
            echo -e "\e[1;34mВыбран Энкодер (Ротационный энкодер)\e[0m"
            # Реальная команда для энкодера
            python3 encoder_script.py 2>/dev/null || echo -e "\e[1;31mОшибка: Не удалось выполнить скрипт энкодера\e[0m"
            sleep 2
            ;;
        4)
            echo -e "\e[1;34m🗑️ Удаление файлов\e[0m"
            read -p "Введите путь к файлам для удаления: " filepath
            
            if [ -e "$filepath" ]; then
                echo -e "\e[1;33mВы действительно хотите удалить '$filepath'? [y/N]\e[0m"
                read -n 1 confirmation
                echo ""
                
                if [[ "$confirmation" =~ [yYдД] ]]; then
                    rm -rf "$filepath" && echo -e "\e[1;32mФайлы успешно удалены!\e[0m" || echo -e "\e[1;31mОшибка при удалении!\e[0m"
                else
                    echo -e "\e[1;33mУдаление отменено\e[0m"
                fi
            else
                echo -e "\e[1;31mОшибка: Указанный путь не существует!\e[0m"
            fi
            sleep 2
            ;;
        0)
            echo -e "\e[1;34mВыход из программы...\e[0m"
            exit 0
            ;;
        *)
            echo -e "\e[1;31mОшибка: Неверный выбор! Пожалуйста, введите число от 0 до 4.\e[0m"
            sleep 2
            ;;
    esac
done
