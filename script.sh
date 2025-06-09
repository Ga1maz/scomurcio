#!/bin/bash

# Проверка, что скрипт запускается от root
if [ "$(id -u)" -ne 0 ]; then
  echo "Этот скрипт нужно запускать от root!"
  exit 1
fi

APP_DIR="/opt/bme280_dashboard"
VENV_DIR="$APP_DIR/venv"
SERVICE_FILE="/etc/systemd/system/bme280_dashboard.service"

echo "Создаем директорию приложения: $APP_DIR"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || exit 1

echo "Создаем виртуальное окружение Python"
python3 -m venv "$VENV_DIR"

echo "Активируем виртуальное окружение и устанавливаем Flask"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install flask

echo "Создаем файл app.py с Flask приложением..."

cat > app.py << 'EOF'
from flask import Flask, Response
import threading
import time
import datetime
import random

app = Flask(__name__)

data = []

def read_bme280():
    # Здесь должна быть реальная интеграция с датчиком BME280
    temperature = 20 + random.uniform(-5, 5)
    humidity = 50 + random.uniform(-20, 20)
    pressure = 1000 + random.uniform(-10, 10)
    return temperature, humidity, pressure

def data_collector():
    while True:
        t, h, p = read_bme280()
        timestamp = datetime.datetime.now().strftime("%H:%M:%S")
        if len(data) >= 100:
            data.pop(0)
        data.append({'time': timestamp, 'temp': t, 'humidity': h, 'pressure': p})
        time.sleep(5)

threading.Thread(target=data_collector, daemon=True).start()

@app.route("/")
def index():
    if data:
        current = data[-1]
    else:
        current = {'time': 'N/A', 'temp': 0, 'humidity': 0, 'pressure': 0}

    html = f"""
    <!DOCTYPE html>
    <html lang='ru'>
    <head>
        <meta charset='UTF-8'/>
        <title>BME280 Dashboard</title>
        <script src='https://cdn.jsdelivr.net/npm/chart.js'></script>
        <style>
            body {{ font-family: Arial, sans-serif; max-width: 900px; margin: 20px auto; }}
            h1 {{ text-align: center; }}
            .current {{ margin-bottom: 20px; }}
            table {{ width: 100%; border-collapse: collapse; margin-top: 20px; }}
            table, th, td {{ border: 1px solid #ccc; }}
            th, td {{ padding: 8px; text-align: center; }}
        </style>
    </head>
    <body>
        <h1>BME280 Dashboard</h1>
        <div class='current'>
            <h2>Текущие показания ({current['time']})</h2>
            <p>🌡️ Температура: {current['temp']:.2f} °C</p>
            <p>💧 Влажность: {current['humidity']:.2f} %</p>
            <p>⏲ Давление: {current['pressure']:.2f} гПа</p>
        </div>
        <canvas id='chart' width='800' height='400'></canvas>
        <table>
            <thead>
                <tr><th>Время</th><th>Температура (°C)</th><th>Влажность (%)</th><th>Давление (гПа)</th></tr>
            </thead>
            <tbody>
    """

    for d in data:
        html += f"<tr><td>{d['time']}</td><td>{d['temp']:.2f}</td><td>{d['humidity']:.2f}</td><td>{d['pressure']:.2f}</td></tr>"

    html += """
            </tbody>
        </table>
        <script>
            const times = """ + str([d['time'] for d in data]) + """;
            const temps = """ + str([d['temp'] for d in data]) + """;
            const hums = """ + str([d['humidity'] for d in data]) + """;
            const pres = """ + str([d['pressure'] for d in data]) + """;

            const ctx = document.getElementById('chart').getContext('2d');
            const chart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: times,
                    datasets: [
                        {
                            label: 'Температура (°C)',
                            data: temps,
                            borderColor: 'rgb(255, 99, 132)',
                            fill: false,
                            yAxisID: 'y',
                        },
                        {
                            label: 'Влажность (%)',
                            data: hums,
                            borderColor: 'rgb(54, 162, 235)',
                            fill: false,
                            yAxisID: 'y1',
                        },
                        {
                            label: 'Давление (гПа)',
                            data: pres,
                            borderColor: 'rgb(75, 192, 192)',
                            fill: false,
                            yAxisID: 'y2',
                        }
                    ]
                },
                options: {
                    scales: {
                        y: {
                            type: 'linear',
                            position: 'left',
                            title: { display: true, text: 'Температура (°C)' },
                        },
                        y1: {
                            type: 'linear',
                            position: 'right',
                            title: { display: true, text: 'Влажность (%)' },
                            grid: { drawOnChartArea: false },
                        },
                        y2: {
                            type: 'linear',
                            position: 'right',
                            title: { display: true, text: 'Давление (гПа)' },
                            grid: { drawOnChartArea: false },
                            offset: true,
                        },
                        x: {
                            title: { display: true, text: 'Время' }
                        }
                    },
                    interaction: {
                        mode: 'index',
                        intersect: false,
                    },
                    responsive: true,
                    maintainAspectRatio: false,
                }
            });
        </script>
    </body>
    </html>
    """

    return Response(html, mimetype='text/html')

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

echo "Создаем systemd сервис..."

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=BME280 Dashboard Flask Server
After=network.target

[Service]
User=root
WorkingDirectory=$APP_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/python3 $APP_DIR/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Перезагружаем systemd, включаем и запускаем сервис..."
systemctl daemon-reload
systemctl enable bme280_dashboard.service
systemctl restart bme280_dashboard.service

echo "Готово! Flask сервер запущен и добавлен в автозапуск."
echo "Откройте в браузере http://192.168.3.21:5000/ (замените IP на ваш)"

exit 0
