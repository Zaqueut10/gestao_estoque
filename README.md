# Gestão de Estoque e Vendas (Flutter + Firebase)

Aplicativo de gestão de estoque e vendas desenvolvido em **Flutter**, usando **Firebase Authentication** e **Cloud Firestore**.

---

## Requisitos

- Flutter SDK (versão estável)
- Projeto Firebase configurado com:
  - Authentication (Email/Senha)
  - Cloud Firestore

---

## Como rodar

1. Instalar dependências:

   ```bash
   flutter pub get
   ```

2. Rodar o app:

   ```bash
   flutter run
   ```

---

## Funcionalidades

- Login (Firebase Auth)
- Produtos (CRUD)
- Movimentações: entrada, saída, ajuste
- Vendas: registra venda, baixa estoque e salva em **vendas** + **movimentos**
- Relatório de vendas:
  - total do período
  - vendas por dia
  - produtos mais vendidos
- Estoque crítico

---

## Roteiro rápido de teste

1. Criar conta / Login
2. Cadastrar produto
3. Fazer entrada (+10)
4. Registrar venda (2 un)
5. Conferir estoque atualizado
6. Conferir movimentações (Venda em vermelho)
7. Abrir relatório de vendas