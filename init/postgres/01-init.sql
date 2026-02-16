-- RAG-as-a-Service database
SELECT 'CREATE DATABASE ragaas'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ragaas')\gexec
