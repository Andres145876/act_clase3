import os
import subprocess

def run(cmd):
    print(f"Ejecutando: {cmd}")
    subprocess.run(cmd, shell=True, check=True)

def instalar_apache():
    # Detectar distro para usar el gestor correcto
    os_release = ""
    if os.path.exists("/etc/os-release"):
        with open("/etc/os-release") as f:
            os_release = f.read()

    if "debian" in os_release or "ubuntu" in os_release:
        run("sudo apt update")
        run("sudo apt install -y apache2")
        run("sudo systemctl start apache2")
        run("sudo systemctl enable apache2")

    elif "amzn" in os_release or "redhat" in os_release or "centos" in os_release:
        run("sudo yum install -y httpd")
        run("sudo systemctl start httpd")
        run("sudo systemctl enable httpd")

    else:
        print("Distro no soportada")
 
def crear_pagina():
    html = """
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <title>DevOps</title>
    </head>
    <body>
        <h1>¡Hola, bienvenidos al programa de tilin!</h1>

    </body>
    </html>
    """
    with open("/tmp/index.html", "w", encoding="utf-8") as f:
        f.write(html)
    run("sudo mv /tmp/index.html /var/www/html/index.html")

if __name__ == "__main__":
    instalar_apache()
    crear_pagina()
