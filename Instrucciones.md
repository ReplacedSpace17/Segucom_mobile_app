#Intrucciones para generar mis claves de firmado

alias: 
segucom-dev

Contraseña de firmado: 
s3Guc0m

keytool -genkey -v -keystore ~/my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias segucom-dev
mv ~/my-release-key.jks /home/rs17/GitHub/Segucom/segucom_app/android/app/




Configurar el Archivo key.properties:
En la raíz de tu proyecto Flutter, crea un archivo llamado key.properties con el siguiente contenido, actualizando las rutas y contraseñas según corresponda:

storePassword=<tu-store-password>
keyPassword=<tu-key-password>
keyAlias=segucom-dev
storeFile=android/app/my-release-key.jks


