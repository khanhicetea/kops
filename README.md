# KOPS

## INIT

Clone

```bash
git clone https://github.com/khanhicetea/kops.git
```

Run init script

- Edit `USERNAME` and `GH_USERNAME` in `scripts/linode-stack.sh` using nano or vim
- Run it

```bash
cd kops
nano scripts/linode-stack.sh
bash scripts/linode-stack.sh
```

## SETUP LEMP

Run kickstart

```bash
bash lemp/kickstart.sh
exit
```

When being asked about MySQL Password , using default password is `passwd`

## USING LEMP (LINUX + NginX + MySQL + PHP)

### CREATE NEW VIRTUAL HOST

```bash
cd lemp
./create_site.sh [username] [domain] [email for letencrypt] [webroot?] [db_name]
```
