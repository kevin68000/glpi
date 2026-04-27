# GLPI sur GitHub Codespaces

## Démarrage rapide

Au lancement du Codespace, tout s’installe automatiquement via `.devcontainer/setup.sh`.
Il suffit d’ouvrir l’onglet **PORTS** et de cliquer sur l’URL du port **8080**.

-----

## Connexion à la base de données

|Champ      |Valeur   |
|-----------|---------|
|Hôte       |127.0.0.1|
|Utilisateur|glpi     |
|Base       |glpi     |

-----

## Commandes utiles

### Démarrer les services (si éteints)

```bash
sudo service mariadb start
sudo service apache2 start
```

### Redémarrer Apache

```bash
sudo service apache2 restart
```

### Vérifier que tout tourne

```bash
sudo service apache2 status
sudo service mariadb status
```

-----

## Sauvegarde de la base de données

### Faire un backup (avant d’éteindre le Codespace)

```bash
sudo mysqldump -u root glpi > /workspaces/glpi/.devcontainer/glpi_backup.sql
git add .devcontainer/glpi_backup.sql
git commit -m "backup: sauvegarde base GLPI"
git push
```

### Restaurer un backup manuellement

```bash
sudo service mariadb start
sudo mysql -e "CREATE DATABASE IF NOT EXISTS glpi;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'glpi'@'localhost' IDENTIFIED BY 'glpi';"
sudo mysql -e "GRANT ALL ON glpi.* TO 'glpi'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
sudo mysql glpi < /workspaces/glpi/.devcontainer/glpi_backup.sql
```

-----

## Réinstallation complète de GLPI

Si GLPI ne s’affiche plus du tout :

```bash
# 1. Réextraire les fichiers
sudo rm -rf /var/www/html/glpi
sudo tar -xzf /workspaces/glpi/glpi-10.0.15.tgz -C /var/www/html/
sudo chown -R www-data:www-data /var/www/html/glpi

# 2. Recréer le .htaccess
sudo bash -c 'cat > /var/www/html/glpi/public/.htaccess <<EOF
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php [QSA,L]
EOF'
sudo chown www-data:www-data /var/www/html/glpi/public/.htaccess

# 3. Redémarrer Apache
sudo service apache2 restart

# 4. Restaurer la base
sudo mysql glpi < /workspaces/glpi/.devcontainer/glpi_backup.sql
```

-----

## Problèmes fréquents

### Page “Not Found” sur le port 8080

```bash
sudo a2dissite 000-default.conf
sudo service apache2 restart
```

### Erreur “Access denied” sur la base de données

```bash
sudo mysql -e "DROP USER IF EXISTS 'glpi'@'localhost';"
sudo mysql -e "CREATE USER 'glpi'@'localhost' IDENTIFIED BY 'glpi';"
sudo mysql -e "GRANT ALL ON glpi.* TO 'glpi'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
```

### Apache ne démarre pas (erreur de config)

```bash
sudo bash -c 'echo "Listen 8080" > /etc/apache2/ports.conf'
sudo apache2ctl configtest
sudo service apache2 restart
```

### CSS/JS qui ne s’affichent pas

```bash
sudo bash -c 'cat > /etc/apache2/sites-available/glpi.conf <<EOF
<VirtualHost *:8080>
    DocumentRoot /var/www/html/glpi/public
    Alias /css_compiled /var/www/html/glpi/css_compiled
    Alias /js /var/www/html/glpi/js
    Alias /pics /var/www/html/glpi/pics
    <Directory /var/www/html/glpi>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF'
sudo service apache2 restart
```

-----

## Structure des fichiers importants

```
/workspaces/glpi/
├── .devcontainer/
│   ├── devcontainer.json   # Config du Codespace
│   ├── setup.sh            # Script d installation automatique
│   └── glpi_backup.sql     # Backup de la base de données
└── glpi-10.0.15.tgz        # Archive GLPI

/var/www/html/glpi/         # Fichiers GLPI (recréés à chaque démarrage)
/etc/apache2/               # Config Apache
```

-----

## Notes importantes

- Le Codespace s’éteint après 30 minutes d’inactivité
- Tout ce qui est dans /var/www/html/ est perdu à chaque redémarrage
- Seul le dossier /workspaces/glpi/ est persistant
- Toujours faire un backup avant d’éteindre le Codespace