# Infrastructure - Shared Services

Serviços compartilhados para todas as aplicações.

## Serviços Incluídos

| Serviço | Porta Local | Container |
|---------|-------------|-----------|
| MySQL 8.0 | 3306 | infra_mysql |
| PostgreSQL 16 | 5432 | infra_postgres |
| Redis 7 | 6379 | infra_redis |

## Setup na VPS

### 1. Clone o repositório

```bash
cd /opt
git clone git@github.com:SEU_USER/infrastructure.git
cd infrastructure
```

### 2. Configure as variáveis de ambiente

```bash
cp .env.example .env
nano .env
```

Gere senhas seguras:
```bash
openssl rand -base64 32  # Para cada senha
```

### 3. (Opcional) Ajuste os scripts de init

Edite `init/mysql/01-mautic.sql` para definir a senha do usuário mautic:
```sql
CREATE USER IF NOT EXISTS 'mautic'@'%' IDENTIFIED BY 'SUA_SENHA_AQUI';
```

### 4. Suba os serviços

```bash
docker-compose up -d
```

### 5. Verifique se estão rodando

```bash
docker-compose ps
docker-compose logs -f
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
