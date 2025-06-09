#!/bin/bash

# 1. Создаем виртуальное окружение
python3 -m venv venv
source venv/bin/activate

# 2. Устанавливаем зависимости
pip install flask pandas matplotlib numpy plotly smbus2 mpu6050-raspberrypi bme280

# 3. Проверка наличия датчиков
python3 <<EOF
from smbus2 import SMBus
import sys

bus = SMBus(1)
def device_exists(address):
    try:
        bus.read_byte(address)
        return True
    except:
        return False

bme280_found = device_exists(0x76) or device_exists(0x77)
mpu6050_found = device_exists(0x68)

if not (bme280_found or mpu6050_found):
    print("❌ Датчики BME280 и MPU6050 не найдены. Прекращаем запуск.")
    sys.exit(1)
EOF

# 4. Создаем структуру
mkdir -p app/templates

# 5. Создаем Flask-приложение
cat > app/app.py <<EOF
from flask import Flask, render_template
import pandas as pd
import plotly.graph_objs as go
import numpy as np

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/bme280")
def bme280():
    # Подставьте сюда реальные данные с BME280
    data = pd.DataFrame({
        'Time': pd.date_range(end=pd.Timestamp.now(), periods=10, freq='T'),
        'Temperature': np.random.normal(25, 1, 10),
        'Humidity': np.random.normal(50, 5, 10),
        'Pressure': np.random.normal(1000, 10, 10),
    })
    return render_template("bme280.html", data=data)

@app.route("/mpu6050")
def mpu6050():
    # Подставьте реальные данные с MPU6050
    orientation = {'x': 0.5, 'y': 0.2, 'z': 0.3}
    data = pd.DataFrame({
        'Time': pd.date_range(end=pd.Timestamp.now(), periods=10, freq='T'),
        'AccelX': np.random.normal(0, 0.1, 10),
        'AccelY': np.random.normal(0, 0.1, 10),
        'AccelZ': np.random.normal(1, 0.1, 10),
    })
    return render_template("mpu6050.html", data=data, orientation=orientation)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

# 6. Шаблон index.html
cat > app/templates/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>Главная</title></head>
<body>
  <h1>Выберите датчик</h1>
  <a href="/bme280"><button>BME280</button></a>
  <a href="/mpu6050"><button>MPU6050</button></a>
</body>
</html>
EOF

# 7. Шаблон bme280.html
cat > app/templates/bme280.html <<EOF
<!DOCTYPE html>
<html>
<head><title>BME280</title></head>
<body>
  <h2>BME280 — Данные</h2>
  <div id="graph"></div>
  {{ data.to_html() }}
  <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
  <script>
    let trace1 = {
      x: {{ data.Time.tolist() | safe }},
      y: {{ data.Temperature.tolist() | safe }},
      type: 'scatter',
      name: 'Temperature'
    };
    Plotly.newPlot('graph', [trace1]);
  </script>
</body>
</html>
EOF

# 8. Шаблон mpu6050.html
cat > app/templates/mpu6050.html <<EOF
<!DOCTYPE html>
<html>
<head><title>MPU6050</title></head>
<body>
  <h2>MPU6050 — Данные и 3D-Куб</h2>
  <div id="cube" style="width:600px;height:600px;"></div>
  {{ data.to_html() }}
  <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
  <script>
    let cube = {
      type: 'mesh3d',
      x: [0,1,1,0,0,1,1,0],
      y: [0,0,1,1,0,0,1,1],
      z: [0,0,0,0,1,1,1,1],
      i: [0,0,0,1,1,2,2,3,4,4,5,6],
      j: [1,2,3,2,5,3,6,0,5,6,6,7],
      k: [2,3,1,3,6,6,7,1,6,7,4,4],
      opacity: 0.5,
      color: 'blue'
    };
    let layout = {
      title: '3D Orientation Cube (static)',
      scene: {
        xaxis: {range: [0,1]},
        yaxis: {range: [0,1]},
        zaxis: {range: [0,1]},
      }
    };
    Plotly.newPlot('cube', [cube], layout);
  </script>
</body>
</html>
EOF

# 9. Создаем systemd unit
cat > flask_app.service <<EOF
[Unit]
Description=Flask Sensor App
After=network.target

[Service]
User=$USER
WorkingDirectory=$(pwd)/app
Environment="PATH=$(pwd)/venv/bin"
ExecStart=$(pwd)/venv/bin/python app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Установка завершена. Запусти Flask вручную: source venv/bin/activate && python app/app.py"
echo "📦 Или установи systemd unit:"
echo "sudo cp flask_app.service /etc/systemd/system/"
echo "sudo systemctl daemon-reexec"
echo "sudo systemctl enable flask_app"
echo "sudo systemctl start flask_app"
