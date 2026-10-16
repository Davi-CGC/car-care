#  CarCare — Controle de Manutenção Veicular

<p align="center">
  <img src="assets/images/logo.png" width="140" alt="CarCare Logo" style="border-radius: 24px;"/>
</p>

<p align="center">
  <strong>Seu veículo sempre em dia.</strong><br>
  Aplicativo completo em Flutter e Dart com autenticação, persistência em nuvem (Firebase), integração com a Tabela FIPE e alertas inteligentes de manutenção preventiva para carros e motocicletas.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.19%2B-02569B?logo=flutter" alt="Flutter Badge">
  <img src="https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart" alt="Dart Badge">
  <img src="https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?logo=firebase" alt="Firebase Badge">
  <img src="https://img.shields.io/badge/Plataforma-Android%20%7C%20Web%20%7C%20Windows-brightgreen" alt="Platform Badge">
  <img src="https://img.shields.io/badge/Projeto-AV1-E8B004" alt="AV1 Badge">
</p>

---

##  1. Descrição do Projeto

O **CarCare** foi desenvolvido como produto de software individual no modelo prático da disciplina (AV1). Trata-se de uma aplicação pensada para simplificar a vida de motoristas e motociclistas, eliminando surpresas desagradáveis causadas por falta de manutenção preventiva, descontrole de despesas com peças/serviços e falta de monitoramento do consumo de combustível.

O projeto possui identidade visual própria desenvolvida nos temas **Claro (Branco Gelo + Amarelo Pólen de Ouro)** e **Escuro (Obsidian Black Metallic + Amarelo Pólen de Ouro)**, com navegação intuitiva, componentes responsivos e documentação técnica completa em página web (`manual/index.html`).

---

##  2. Objetivo

- **Prevenção:** alertar o condutor quando prazos ou limites de quilometragem de itens vitais (óleo, freios, pneus, correias, transmissão) estiverem próximos ou vencidos.
- **Gestão Financeira:** registrar e somar todos os gastos com manutenções e combustível mensalmente.
- **Consumo Real:** calcular automaticamente o consumo médio em km/l a partir dos registros de abastecimento.
- **Valor de Mercado:** consultar a cotação oficial da Tabela FIPE em tempo real para qualquer veículo cadastrado.

---

## ⚡ 3. Principais Funcionalidades

###  Autenticação de Usuários
- Login com validação reativa e mensagens amigáveis em português.
- Cadastro completo de novos usuários (Nome, E-mail, Senha e Confirmação de senha).
- Recuperação de senha por e-mail via Firebase Authentication.
- Persistência de sessão automática (`AuthGate`).

###  Gestão de Veículos (CRUD Completo)
- Cadastro de carros e motocicletas com marca, modelo, ano, placa e quilometragem.
- Seleção de tipo de câmbio (Manual ou Automático) para carros.
- Atualização rápida de quilometragem diretamente no odômetro.
- Consulta e sincronização com a **Tabela FIPE** (marca, modelo, ano e valor venal).
- Exclusão com limpeza em cascata (remove manutenções e abastecimentos associados com `WriteBatch`).

### ️ Histórico e Catálogo Inteligente de Manutenções (CRUD)
- **Catálogo Especializado para Motocicletas:**
  - Óleo do motor e filtro, Sistema de freios, Pneus e rodas, Kit de transmissão, Sistema elétrico e bateria, Filtro de ar e velas de ignição, Revisões periódicas, Óleo das bengalas, Caixa de direção, Balança traseira, Líquido de arrefecimento, Radiador e mangueiras, Cabos de aço, Manetes e pedal de câmbio, Filtro de combustível, Limpeza do corpo de borboleta (TBI).
- **Catálogo Especializado para Carros:**
  - Tabela FIPE do veículo, Consumo médio de combustível, Troca de óleo por KM e por tempo, Revisão geral, Troca de pneus, Filtros de ar e combustível, Sistema de freios, Alinhamento e balanceamento, Fluidos e arrefecimento, Sistema elétrico, Suspensão e escapamento, Correia dentada e tensores, Velas e cabos de ignição, Sistema de transmissão, Embreagem (filtrada automaticamente apenas para carros manuais), Palhetas do limpador.
- **Alertas Preditivos:** cálculo automático do próximo serviço por KM ou data, categorizando em *Em dia*, *Em breve* ou *Atrasado*.

###  Controle de Abastecimento & Consumo Médio (CRUD)
- Registro de data, quilometragem, litros e valor total pago.
- Cálculo automático do preço pago por litro.
- Cálculo estatístico do consumo médio da frota (km/l).

###  Identidade Visual & Usabilidade
- Seletor de tema claro / escuro com persistência via `SharedPreferences`.
- Layout responsivo adaptado para celulares, tablets e navegadores web.
- Ícones personalizados gerados para Android, iOS, Web e Windows.

---

##  4. Tecnologias Utilizadas

- **Linguagem:** [Dart](https://dart.dev/)
- **Framework:** [Flutter](https://flutter.dev/) (Material 3)
- **Autenticação:** [Firebase Authentication](https://firebase.google.com/products/auth)
- **Banco de Dados:** [Cloud Firestore](https://firebase.google.com/products/firestore)
- **API Externa:** [API FIPE Pública](https://parallelum.com.br/fipe/api/v1)
- **Preferências Locais:** `shared_preferences`
- **Internacionalização:** `intl` e `flutter_localizations` (pt_BR)
- **Documentação Técnica:** HTML5 e CSS3 puro em `manual/index.html`

---

##  5. Como Instalar e Executar

### Pré-requisitos
- Flutter SDK instalado e adicionado ao PATH (`flutter --version`).
- Navegador Google Chrome ou dispositivo Android conectado.

### Passo a passo
1. Clone o repositório:
   ```bash
   git clone https://github.com/davicalanca/carcare.git
   cd carcare
   ```

2. Obtenha os pacotes do projeto:
   ```bash
   flutter pub get
   ```

3. Execute o aplicativo:
   - **No Navegador (Web):**
     ```bash
     flutter run -d chrome
     ```
   - **No Dispositivo Android:**
     ```bash
     flutter run -d android
     ```
   - **No Windows Desktop:**
     ```bash
     flutter run -d windows
     ```

---

## ️ 6. Informações sobre o Banco de Dados

O aplicativo utiliza o **Cloud Firestore** em modo isolado por usuário. O caminho raiz de dados de cada cliente autenticado é:

```
users/
  └── {uid}/
        ├── vehicles/
        │     └── {vehicleId}
        ├── maintenances/
        │     └── {maintenanceId}
        └── fuel/
              └── {fuelId}
```

### Regras de Segurança (`firestore.rules`)
As regras garantem que nenhum usuário tenha acesso de leitura ou escrita aos dados de outro condutor (`request.auth.uid == uid`), validando os tipos de cada campo na criação e na atualização.

---

##  7. Manual Técnico do Desenvolvedor

O projeto acompanha um manual técnico completo desenvolvido em **HTML e CSS** para consulta de arquitetura, guias de manutenção e solução de problemas:

- Abra o arquivo: `manual/index.html` no seu navegador.
- Estilos e diagramas: `manual/style.css`.
- Identidade visual: `manual/imagens/logo.png`.

---

##  8. Identificação do Desenvolvedor

- **Aluno / Desenvolvedor:** Davi Calanca
- **Contato:** davicalanca168@gmail.com
- **Projeto:** AV1 — Desenvolvimento de Aplicações Móveis com Flutter e Dart
- **2° info B:** 2026
