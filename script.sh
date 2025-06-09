#!/bin/bash

# Выводим ASCII-арт
echo -e "\033[34m____   ____ ___  __  __   _   _ ____   ____ ___  ___
 / ___| / ___/ _ \|  \/  | | | | |  _ \ / ___|_ _|/ _ \\
 \___ \| |  | | | | |\/| | | | | | |_) | |    | | | | | |
  ___) | |__| |_| | |  | | | |_| |  _ <| |___ | | | |_| |
 |____/ \____\___/|_|  |_|  \___/|_| \_\____|___|\___/
             \033[31m🚀 СКРИПТ ОТ GA1MAZ.RU\033[0m"

# Выводим схему подключения желтым цветом
echo -e "\n\033[33m"
cat << "EOF"
          Схема подключения BME280 к Raspberry Pi:
          -----------------------------------
          | BME280 Pin | Raspberry Pi Pin  |
          |------------|-------------------|
          |   VCC      |     3.3V (1)      |
          |   GND      |     GND (6)       |
          |   SDA      |     GPIO2 (3)     |
          |   SCL      |     GPIO3 (5)     |
          -----------------------------------
          Примечание: Адрес I2C по умолчанию: 0x76
EOF
echo -e "\033[0m"

# Выводим предупреждение о бета-тестировании
echo -e "\n\033[33mБэта тестирование (сейчас доступно только BME280, NPU6050 (Скоро добавим), Энкодер (Скоро добавим))\033[0m\n"

# Спрашиваем о подключении
read -p "Вы подключили датчик BME280 к Raspberry Pi? (y/n): " connected
if [ "$connected" != "y" ]; then
    echo "Пожалуйста, подключите датчик BME280 и запустите скрипт снова."
    exit 1
fi

# Установка пакетов
echo -e "\n\033[32mУстанавливаем необходимые пакеты...\033[0m"
sudo apt update
sudo apt install -y i2c-tools python3-smbus python3-pip nginx
sudo pip3 install --break-system-packages RPi.bme280 smbus2 flask flask-cors

# Создание Python скрипта
echo -e "\n\033[32mСоздаем скрипт для чтения данных BME280...\033[0m"
sudo tee /usr/local/bin/bme280_api.py > /dev/null <<'EOL'
#!/usr/bin/env python3

from flask import Flask, jsonify
import smbus2
import bme280
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Разрешаем запросы со всех доменов

port = 1
address = 0x76
bus = smbus2.SMBus(port)
calibration_params = bme280.load_calibration_params(bus, address)

@app.route('/api/data')
def get_data():
    data = bme280.sample(bus, address, calibration_params)
    return jsonify({
        'temperature': round(data.temperature, 1),
        'humidity': round(data.humidity, 1),
        'pressure': round(data.pressure, 1),
        'timestamp': data.timestamp.isoformat()
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOL

# Даем права на выполнение
sudo chmod +x /usr/local/bin/bme280_api.py

# Создаем службу systemd
echo -e "\n\033[32mСоздаем службу systemd для автозапуска...\033[0m"
sudo tee /etc/systemd/system/bme280_api.service > /dev/null <<'EOL'
[Unit]
Description=BME280 API Service
After=network.target

[Service]
ExecStart=/usr/local/bin/bme280_api.py
WorkingDirectory=/usr/local/bin
StandardOutput=inherit
StandardError=inherit
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOL

# Включаем и запускаем службу
sudo systemctl daemon-reload
sudo systemctl enable bme280_api.service
sudo systemctl start bme280_api.service

# Создаем веб-страницу
echo -e "\n\033[32mСоздаем веб-интерфейс...\033[0m"
sudo tee /var/www/html/index.html > /dev/null <<'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BME280 Monitor</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/moment"></script>
    <script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-moment"></script>
    <style>
        body { font-family: Arial, sans-serif; max-width: 1000px; margin: 0 auto; padding: 20px; }
        .dashboard { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .chart-container { position: relative; height: 300px; margin-bottom: 30px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        .current-data { background: #f8f9fa; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .data-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; }
        .data-card { background: white; padding: 15px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .data-card h3 { margin-top: 0; color: #555; }
        .data-value { font-size: 24px; font-weight: bold; }
    </style>
</head>
<body>
    <h1>BME280 Environmental Monitor</h1>
    
    <div class="current-data">
        <h2>Current Readings</h2>
        <div class="data-grid">
            <div class="data-card">
                <h3>Temperature</h3>
                <div class="data-value" id="current-temp">-- °C</div>
            </div>
            <div class="data-card">
                <h3>Humidity</h3>
                <div class="data-value" id="current-humidity">-- %</div>
            </div>
            <div class="data-card">
                <h3>Pressure</h3>
                <div class="data-value" id="current-pressure">-- hPa</div>
            </div>
        </div>
    </div>

    <div class="dashboard">
        <div>
            <h2>Temperature History</h2>
            <div class="chart-container">
                <canvas id="tempChart"></canvas>
            </div>
        </div>
        <div>
            <h2>Humidity History</h2>
            <div class="chart-container">
                <canvas id="humidityChart"></canvas>
            </div>
        </div>
        <div>
            <h2>Pressure History</h2>
            <div class="chart-container">
                <canvas id="pressureChart"></canvas>
            </div>
        </div>
    </div>

    <h2>Recent Readings</h2>
    <table id="readings-table">
        <thead>
            <tr>
                <th>Time</th>
                <th>Temperature (°C)</th>
                <th>Humidity (%)</th>
                <th>Pressure (hPa)</th>
            </tr>
        </thead>
        <tbody id="table-body">
            <!-- Data will be inserted here -->
        </tbody>
    </table>

    <script>
        // Store historical data
        let historyData = [];
        const maxHistory = 50;

        // Chart instances
        const tempChart = createChart('tempChart', 'Temperature', '°C', 'rgba(255, 99, 132, 0.2)', 'rgb(255, 99, 132)');
        const humidityChart = createChart('humidityChart', 'Humidity', '%', 'rgba(54, 162, 235, 0.2)', 'rgb(54, 162, 235)');
        const pressureChart = createChart('pressureChart', 'Pressure', 'hPa', 'rgba(75, 192, 192, 0.2)', 'rgb(75, 192, 192)');

        function createChart(canvasId, label, unit, bgColor, borderColor) {
            const ctx = document.getElementById(canvasId).getContext('2d');
            return new Chart(ctx, {
                type: 'line',
                data: {
                    datasets: [{
                        label: `${label} (${unit})`,
                        backgroundColor: bgColor,
                        borderColor: borderColor,
                        borderWidth: 1,
                        pointRadius: 2,
                        data: []
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        x: {
                            type: 'time',
                            time: {
                                unit: 'minute'
                            }
                        },
                        y: {
                            beginAtZero: false
                        }
                    }
                }
            });
        }

        function updateCurrentReadings(data) {
            document.getElementById('current-temp').textContent = `${data.temperature} °C`;
            document.getElementById('current-humidity').textContent = `${data.humidity} %`;
            document.getElementById('current-pressure').textContent = `${data.pressure} hPa`;
        }

        function updateCharts(data) {
            const timestamp = new Date(data.timestamp);
            
            // Add to history (limit to maxHistory entries)
            historyData.unshift({
                x: timestamp,
                temp: data.temperature,
                humidity: data.humidity,
                pressure: data.pressure
            });
            
            if (historyData.length > maxHistory) {
                historyData.pop();
            }

            // Update charts
            tempChart.data.datasets[0].data = historyData.map(d => ({x: d.x, y: d.temp}));
            humidityChart.data.datasets[0].data = historyData.map(d => ({x: d.x, y: d.humidity}));
            pressureChart.data.datasets[0].data = historyData.map(d => ({x: d.x, y: d.pressure}));
            
            tempChart.update();
            humidityChart.update();
            pressureChart.update();

            // Update table
            const tableBody = document.getElementById('table-body');
            tableBody.innerHTML = historyData.map(d => `
                <tr>
                    <td>${d.x.toLocaleTimeString()}</td>
                    <td>${d.temp}</td>
                    <td>${d.humidity}</td>
                    <td>${d.pressure}</td>
                </tr>
            `).join('');
        }

        // Fetch data initially and then every 5 seconds
        function fetchData() {
            fetch('http://' + window.location.hostname + '/api/data')
                .then(response => response.json())
                .then(data => {
                    updateCurrentReadings(data);
                    updateCharts(data);
                })
                .catch(err => console.error('Ошибка получения данных:', err));
        }
        
        // Запуск и интервал
        fetchData();
        setInterval(fetchData, 5000);

    </script>
</body>
</html>
EOL

# Настраиваем Nginx
echo -e "\n\033[32mНастраиваем Nginx...\033[0m"
server_ip=$(hostname -I | awk '{print $1}')
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOL
server {
    listen 80;
    server_name 192.168.3.21;

    location / {
        root /var/www/html;
        index index.html;
    }

    location /api {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # Добавляем CORS заголовки
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
    }

    location = /api/data {
        proxy_pass http://127.0.0.1:5000/api/data;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

# Проверяем и перезапускаем Nginx
sudo nginx -t
sudo systemctl restart nginx

echo -e "\n\033[32mУстановка завершена!\033[0m"
echo -e "\n\033[33mNGINX сайт с BME280 расположен на:\033[0m"
echo "Вы можете открыть веб-интерфейс по адресу: http://$server_ip"
