# Pterodactyl Full Auto Setup (Ubuntu 20.04)

## 1. Panel (Web Admin)
- Jalankan: `sudo bash setup_pterodactyl.sh`
- Ikuti instruksi di layar
- Setelah selesai, buat user admin:
  ```sh
  cd /var/www/pterodactyl
  php artisan p:user:make
  ```
- Edit file `.env` untuk email dan konfigurasi lain

## 2. SSL Panel (HTTPS)
- Pastikan domain panel sudah mengarah ke IP server
- Jalankan: `sudo bash setup_ssl_panel.sh panel.domainkamu.com`
- Panel akan bisa diakses via https://panel.domainkamu.com

## 3. Wings (Daemon/Node)
- Jalankan: `sudo bash setup_wings.sh`
- Setelah selesai, login ke panel, buat node, download `config.yml`
- Upload `config.yml` ke `/etc/pterodactyl/config.yml` di server daemon
- Jalankan: `sudo systemctl start wings`
- Cek log: `sudo journalctl -u wings -f`

## 4. SSL Wings (Daemon)
- Pastikan domain node sudah mengarah ke IP server
- Jalankan: `sudo bash setup_ssl_wings.sh node.domainkamu.com`
- SSL otomatis aktif untuk wings

## 5. Auto Renewal SSL
- Panel: Sudah otomatis via certbot.timer
- Wings: Tambahkan ke crontab (optional):
  ```sh
  0 3 * * * certbot renew --pre-hook "systemctl stop wings" --post-hook "systemctl start wings"
  ```

---

**Catatan:**
- Semua script harus dijalankan sebagai root/sudo
- Pastikan domain sudah mengarah ke server sebelum setup SSL
- Untuk panel dan wings di server berbeda, jalankan script sesuai kebutuhan
