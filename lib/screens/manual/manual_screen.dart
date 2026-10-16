import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/layout.dart';

/// Tela do Manual de Dúvidas e Documentação Técnica acessível diretamente
/// pelo botão de interrogação amarelo na tela principal.
class ManualScreen extends StatefulWidget {
  const ManualScreen({super.key});

  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<_ManualTopic> _topics = [
    _ManualTopic(
      title: 'Apresentação do aplicativo',
      icon: Icons.info_outline,
      content:
          'O CarCare é um pequeno produto de software desenvolvido em Flutter e Dart '
          'para controle preventivo e gerenciamento completo de veículos (carros e motocicletas). '
          'Possui autenticação segura, banco em nuvem (Cloud Firestore), regras de acesso por usuário, '
          'integração em tempo real com a Tabela FIPE e alertas preditivos de manutenção.',
    ),
    _ManualTopic(
      title: 'Objetivo e público-alvo',
      icon: Icons.track_changes,
      content:
          'Objetivo: Eliminar o esquecimento de manutenções preventivas, monitorar o consumo real '
          'de combustível (km/l ou km/m³) e centralizar gastos veiculares.\n\n'
          'Público-alvo: Proprietários de carros e motos, motoristas de aplicativo, entregadores '
          'e qualquer pessoa que deseje manter seu veículo valorizado e seguro.',
    ),
    _ManualTopic(
      title: 'Tecnologias utilizadas',
      icon: Icons.devices,
      content:
          '• Flutter & Dart: Framework multiplataforma e linguagem de desenvolvimento.\n'
          '• Firebase Authentication: Login e cadastro seguro por e-mail e senha.\n'
          '• Cloud Firestore: Banco NoSQL em nuvem com sincronização em tempo real.\n'
          '• API Tabela FIPE (Parallelum): Consulta pública de marcas, modelos, anos e preços médios.\n'
          '• SharedPreferences: Persistência local do tema (claro/escuro).\n'
          '• HTML5 e CSS3: Manual técnico web disponível no diretório manual/.',
    ),
    _ManualTopic(
      title: 'Requisitos para executar o projeto',
      icon: Icons.checklist,
      content:
          '• Flutter SDK (versão 3.19 ou superior).\n'
          '• Git instalado no sistema.\n'
          '• Navegador Google Chrome, emulador Android ou dispositivo físico com depuração USB.\n'
          '• Node.js e Firebase CLI (opcional para redeploy de regras).',
    ),
    _ManualTopic(
      title: 'Passo a passo para instalação',
      icon: Icons.terminal,
      content:
          '1. Clone o repositório do projeto no computador:\n'
          '   git clone <URL_DO_GITHUB>\n'
          '2. Entre na pasta do projeto:\n'
          '   cd carcare\n'
          '3. Baixe as dependências do Flutter:\n'
          '   flutter pub get\n'
          '4. Execute o projeto no Chrome ou Android:\n'
          '   flutter run -d chrome\n'
          '   ou flutter run -d android',
    ),
    _ManualTopic(
      title: 'Estrutura de pastas',
      icon: Icons.folder_open,
      content:
          '• lib/: Código-fonte principal do aplicativo.\n'
          '  ├── models/: Modelos e entidades (Vehicle, Maintenance, FuelRecord, Fipe).\n'
          '  ├── repositories/: Acesso ao banco de dados Firestore (CRUD).\n'
          '  ├── screens/: Telas do app (AuthGate, Login, Cadastro, Home, Manual).\n'
          '  ├── services/: Autenticação Firebase e API pública da FIPE.\n'
          '  ├── theme/: Paleta de cores oficial (Amarelo Pólen, Obsidian, Gelo) e temas.\n'
          '  ├── utils/: Catálogos de serviços de carros e motos, cálculos e formatadores.\n'
          '  └── widgets/: Componentes reutilizáveis (cards, termômetro, botões, campos).\n'
          '• assets/: Logotipo e imagens oficiais.\n'
          '• manual/: Manual técnico web (index.html e style.css).\n'
          '• firestore.rules: Regras de segurança do Cloud Firestore.',
    ),
    _ManualTopic(
      title: 'Explicação das principais telas',
      icon: Icons.view_quilt,
      content:
          '1. Início (Visão Geral): Dashboard com total de veículos cadastrados, gastos do mês, '
          'resumo de alertas pendentes, termômetro de consumo e atalhos rápidos.\n'
          '2. Veículos: Listagem dos carros e motos com quilometragem, placa, valor FIPE e badges.\n'
          '3. Manutenções: Histórico filtrável por veículo com valores e projeção de próximos serviços.\n'
          '4. Abastecimentos: Registros de combustível com tipo (Gasolina, Etanol, Diesel, GNV), '
          'preço por litro e volume abastecido.',
    ),
    _ManualTopic(
      title: 'Explicação do login e cadastro',
      icon: Icons.lock_outline,
      content:
          '• Login: Validação imediata de e-mail e senha. Credenciais incorretas exibem mensagem '
          'amigável em português. Há também opção de recuperação de senha por e-mail.\n'
          '• Cadastro: Criação de conta solicitando Nome, E-mail, Senha e Confirmação. '
          'O perfil do usuário é criado no Firebase Auth e salvo em users/{uid} no Firestore.\n'
          '• AuthGate: Gerencia o fluxo sem necessidade de recarregar a tela.',
    ),
    _ManualTopic(
      title: 'Estrutura do banco de dados',
      icon: Icons.storage,
      content:
          'O Cloud Firestore é organizado em coleções com isolamento estrito por usuário:\n\n'
          '• users/{uid}: Perfil do motorista (name, email, createdAt).\n'
          '• users/{uid}/vehicles/{vehicleId}: Carros e motos cadastrados.\n'
          '• users/{uid}/maintenances/{maintenanceId}: Histórico de manutenções e alertas.\n'
          '• users/{uid}/fuel/{fuelId}: Registros de abastecimento (fuelType, litros, valor, km).',
    ),
    _ManualTopic(
      title: 'Como cadastrar, editar e excluir informações',
      icon: Icons.edit_note,
      content:
          '• Cadastrar: Toque no botão flutuante (+) na aba correspondente (Veículo, Manutenção ou Abastecimento).\n'
          '• Odômetro Automático: Ao registrar um abastecimento, a quilometragem atual do veículo '
          'é atualizada automaticamente se o valor for superior ao anterior!\n'
          '• Editar: Toque sobre o card do item para abrir a folha de detalhes e selecione "Editar".\n'
          '• Excluir: Abra os detalhes e toque em "Excluir". Ao excluir um veículo, suas manutenções '
          'e abastecimentos vinculados são removidos em cascata automaticamente.',
    ),
    _ManualTopic(
      title: 'Como alterar cores',
      icon: Icons.palette_outlined,
      content:
          'Todas as cores estão centralizadas no arquivo:\n'
          'lib/theme/app_colors.dart\n\n'
          'Para mudar a cor principal ou fundos, altere as constantes:\n'
          '• goldenPollen = Color(0xFFE8B004); (Amarelo Pólen de Ouro)\n'
          '• iceWhite = Color(0xFFF7F7F2); (Branco Gelo)\n'
          '• obsidian = Color(0xFF121214); (Obsidian Black Metallic)\n\n'
          'Todo o app reflete a alteração de cores automaticamente.',
    ),
    _ManualTopic(
      title: 'Como trocar o logo',
      icon: Icons.image_outlined,
      content:
          '1. Substitua o arquivo da imagem em:\n'
          '   assets/images/logo.png\n'
          '2. Copie também para manual/imagens/logo.png.\n'
          '3. No terminal, execute para atualizar os ícones em todas as plataformas:\n'
          '   flutter pub run flutter_launcher_icons',
    ),
    _ManualTopic(
      title: 'Como alterar o nome do aplicativo',
      icon: Icons.badge_outlined,
      content:
          '1. No Flutter: altere a constante appName em lib/utils/constants.dart.\n'
          '2. No Android: altere android:label="Nome" em android/app/src/main/AndroidManifest.xml.\n'
          '3. Na Web: altere a tag <title> e a meta tag apple-mobile-web-app-title em web/index.html.',
    ),
    _ManualTopic(
      title: 'Como adicionar ou alterar uma tela',
      icon: Icons.add_to_photos_outlined,
      content:
          '1. Crie o novo arquivo na pasta lib/screens/ (exemplo: minha_tela_screen.dart).\n'
          '2. Crie uma classe StatelessWidget ou StatefulWidget com Scaffold e AppBar.\n'
          '3. Use Navigator.push(context, MaterialPageRoute(builder: (_) => MinhaTelaScreen())) '
          'a partir de qualquer botão para abrir a tela.',
    ),
    _ManualTopic(
      title: 'Como adicionar ou alterar um campo do banco de dados',
      icon: Icons.data_object,
      content:
          '1. No modelo (ex: lib/models/vehicle.dart): adicione o novo atributo, inclua no construtor, '
          'no toMap() e no fromDoc().\n'
          '2. No formulário correspondente: crie o controlador (TextEditingController) e o campo '
          'AppTextField para entrada de dados.\n'
          '3. As regras do Firestore (firestore.rules) já estão configuradas para permitir escrita segura '
          'por usuário sem quebrar novas propriedades.',
    ),
    _ManualTopic(
      title: 'Como gerar uma nova versão do projeto',
      icon: Icons.build_circle_outlined,
      content:
          '1. Atualize a versão no arquivo pubspec.yaml (ex: version: 1.0.1+2).\n'
          '2. Para gerar a versão Web:\n'
          '   flutter build web --release\n'
          '3. Para gerar o APK do Android:\n'
          '   flutter build apk --release\n'
          '   (O arquivo ficará em build/app/outputs/flutter-apk/app-release.apk).\n'
          '4. Para Windows Desktop:\n'
          '   flutter build windows --release',
    ),
    _ManualTopic(
      title: 'Solução de problemas comuns',
      icon: Icons.help_outline,
      content:
          '• Erro de exclusão de arquivos no Windows (build/flutter_assets): Ocorre quando o OneDrive '
          'bloqueia pastas sincronizadas. Execute Stop-Process -Name dart -Force e remova a pasta build.\n'
          '• Modo Desenvolvedor do Windows: Ative em Configurações do Windows > Modo de desenvolvedor '
          'para permitir a criação de links simbólicos dos plugins.\n'
          '• Permission-denied no Firestore: Assegure-se de que o usuário está autenticado e que as regras '
          'foram publicadas via firebase deploy --only firestore:rules.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredTopics = _searchQuery.isEmpty
        ? _topics
        : _topics.where((t) {
            final q = _searchQuery.toLowerCase();
            return t.title.toLowerCase().contains(q) ||
                t.content.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual de Dúvidas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar dúvidas, telas, banco...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: pagePadding(context),
        children: [
          // Banner com identidade visual
          Card(
            color: AppColors.goldenPollen.withValues(alpha: isDark ? 0.2 : 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.goldenPollen, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const AppLogo(size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guia Técnico & Operacional',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Documentação completa do projeto CarCare para desenvolvimento, avaliação e manutenção.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (filteredTopics.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Nenhum tópico encontrado para "$_searchQuery".',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            ...filteredTopics.map((topic) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.goldenPollen.withValues(alpha: 0.2),
                    child: Icon(topic.icon, color: AppColors.goldenPollen),
                  ),
                  title: Text(
                    topic.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 4),
                    SelectableText(
                      topic.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ManualTopic {
  final String title;
  final IconData icon;
  final String content;

  const _ManualTopic({
    required this.title,
    required this.icon,
    required this.content,
  });
}
