# Infrastructure - Shared Services

Serviços compartilhados para todas as aplicações.

## Serviços Incluídos

| Serviço | Porta Local | Container |
|---------|-------------|-----------|
| MySQL 8.0 | 3306 | infra_mysql |
| PostgreSQL 16 | 5432 | infra_postgres |
| Redis 7 | 6379 | infra_redis |

## Deploy Automático (CI/CD)

O deploy é feito automaticamente via GitHub Actions quando há push na branch `main`.

### Pré-requisitos na VPS

1. **Docker e Docker Compose instalados**
2. **GitHub Actions Runner configurado**

### GitHub Secrets

Os segredos são gerenciados via GitHub Secrets (Settings → Secrets and variables → Actions):

| Secret | Descrição |
|--------|-----------|
| `MYSQL_ROOT_PASSWORD` | Senha root do MySQL |
| `POSTGRES_USER` | Usuário do PostgreSQL |
| `POSTGRES_PASSWORD` | Senha do PostgreSQL |
| `REDIS_PASSWORD` | Senha do Redis |

### Self-Hosted Runner

O runner está instalado em `/home/deploy/actions-runner`.

**Verificar status:**
```bash
cd /home/deploy/actions-runner
./svc.sh status
```

**Iniciar o runner:**
```bash
# Como serviço (recomendado)
sudo ./svc.sh start

# Ou manualmente (para debug)
./run.sh
```

**Parar o runner:**
```bash
sudo ./svc.sh stop
```

**Ver logs do runner:**
```bash
journalctl -u actions.runner.pedro9bee-infrastructure.$(hostname) -f
```

### Fluxo de Deploy

1. Push para `main` dispara o workflow
2. Runner na VPS pega o job
3. Código é sincronizado para `/opt/infrastructure`
4. `.env` é gerado a partir dos GitHub Secrets
5. `docker-compose up -d` sobe os containers

## Setup Manual (primeira vez)

### 1. Instalar Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

### 2. Instalar GitHub Actions Runner

Siga as instruções em: Settings → Actions → Runners → New self-hosted runner

```bash
mkdir -p /home/deploy/actions-runner && cd /home/deploy/actions-runner
# Baixe e configure seguindo as instruções do GitHub
./config.sh --url https://github.com/pedro9bee/infrastructure --token YOUR_TOKEN
sudo ./svc.sh install
sudo ./svc.sh start
```

### 3. (Opcional) Scripts de init para bancos

Edite `init/mysql/01-mautic.sql` para criar usuários adicionais:
```sql
CREATE USER IF NOT EXISTS 'mautic'@'%' IDENTIFIED BY 'SUA_SENHA_AQUI';
```

## Conectando outras aplicações

Outras aplicações (como Mautic) se conectam via rede `infra_network`:

```yaml
# No docker-compose.yml da outra app
networks:
  infra_network:
    external: true
```

E usam o nome do container como host:
- MySQL: `infra_mysql:3306`
- Postgres: `infra_postgres:5432`
- Redis: `infra_redis:6379`

## Backup

### MySQL
```bash
docker exec infra_mysql mysqldump -u root -p'SENHA' --all-databases > backup.sql
```

### PostgreSQL
```bash
docker exec infra_postgres pg_dumpall -U postgres > backup.sql
```

### Redis
```bash
docker exec infra_redis redis-cli -a 'SENHA' BGSAVE
docker cp infra_redis:/data/dump.rdb ./redis-backup.rdb
```

## Comandos Úteis

```bash
# Logs de um serviço
docker-compose logs -f mysql

# Acessar MySQL
docker exec -it infra_mysql mysql -u root -p

# Acessar PostgreSQL
docker exec -it infra_postgres psql -U postgres

# Acessar Redis
docker exec -it infra_redis redis-cli -a 'SENHA'

# Restart de um serviço
docker-compose restart mysql

# Parar tudo
docker-compose down

# Parar e remover volumes (CUIDADO: apaga dados!)
docker-compose down -v
```
