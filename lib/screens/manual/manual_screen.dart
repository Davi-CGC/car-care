import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/layout.dart';

/// Modelo de item do FAQ.
class _FaqItem {
  final String category;
  final String question;
  final String answer;
  final IconData icon;

  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
    required this.icon,
  });
}

/// Central de Ajuda e Dúvidas Frequentes (FAQ).
/// Acessada pelo botão amarelo com ponto de interrogação no canto inferior esquerdo.
class ManualScreen extends StatefulWidget {
  const ManualScreen({super.key});

  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'Todas',
    'Veículos & Rodízio',
    'Combustível & Consumo',
    'Manutenções & Alertas',
    'Gastos & Relatórios',
    'Conta & Nuvem',
  ];

  static const List<_FaqItem> _faqList = [
    _FaqItem(
      category: 'Veículos & Rodízio',
      icon: Icons.directions_car,
      question: 'Como cadastrar meu primeiro carro ou moto?',
      answer:
          'Na aba "Veículos" ou no botão flutuante da tela inicial, toque em "Cadastrar Veículo". '
          'Escolha o tipo (Carro ou Moto), digite o nome e a placa. Você também pode tocar em '
          '"Buscar na Tabela FIPE" para preencher a marca, modelo e ano oficial automaticamente.',
    ),
    _FaqItem(
      category: 'Veículos & Rodízio',
      icon: Icons.calendar_month,
      question: 'Como o app avisa o dia do meu rodízio veicular?',
      answer:
          'O CarCare lê o último número da placa informada (padrão antigo ou Mercosul) e calcula o dia '
          'da restrição de trânsito (ex: finais 1 e 2 na segunda-feira, 3 e 4 na terça, etc.). '
          'Se hoje for o dia do rodízio do seu carro, um banner amarelo de alerta é exibido no topo da tela inicial. '
          'Motocicletas são identificadas automaticamente como isentas de rodízio.',
    ),
    _FaqItem(
      category: 'Combustível & Consumo',
      icon: Icons.speed,
      question: 'Como funciona o cálculo de quilometragem e consumo?',
      answer:
          'Ao cadastrar um abastecimento, o app puxa a quilometragem atual do veículo. '
          'Quando você digita a nova quilometragem e os litros abastecidos, o app calcula na hora a distância '
          'percorrida e o consumo do trecho (km/l ou km/m³). Ao salvar, o odômetro do veículo é atualizado '
          'automaticamente no banco.',
    ),
    _FaqItem(
      category: 'Combustível & Consumo',
      icon: Icons.local_gas_station,
      question: 'Posso abastecer com Etanol, Diesel ou GNV?',
      answer:
          'Sim! No formulário de abastecimento, selecione o tipo de combustível: Gasolina, Etanol, Diesel ou GNV. '
          'Ao escolher GNV, o campo de volume muda automaticamente para Metros Cúbicos (m³) e o consumo é '
          'calculado em km/m³.',
    ),
    _FaqItem(
      category: 'Combustível & Consumo',
      icon: Icons.thermostat,
      question: 'O que significa o Termômetro de Consumo?',
      answer:
          'O termômetro visual indica se o consumo está eficiente:\n'
          '• Verde (Muito Econômico): Alta autonomia por litro/m³.\n'
          '• Amarelo (Normal / Moderado): Consumo padrão esperado para o combustível.\n'
          '• Vermelho (Alto Consumo): Indica consumo elevado. Vale a pena verificar calibragem dos pneus, '
          'filtro de ar, velas e bicos injetores.',
    ),
    _FaqItem(
      category: 'Manutenções & Alertas',
      icon: Icons.edit_note,
      question: 'Como editar ou corrigir uma manutenção ou abastecimento?',
      answer:
          'Se você confirmou um registro e percebeu que errou algum valor ou quilometragem, basta ir até a aba '
          '"Manutenções" ou "Abastecimentos", tocar sobre o item desejado e selecionar a opção "Editar". '
          'Faça o ajuste necessário e salve.',
    ),
    _FaqItem(
      category: 'Manutenções & Alertas',
      icon: Icons.menu_book,
      question: 'O que é o Diário de Bordo (Log do Veículo)?',
      answer:
          'O Diário de Bordo é a linha do tempo completa do seu veículo. Nele você vê em ordem cronológica '
          'todas as manutenções realizadas, os abastecimentos com consumo registrado, total gasto e evolução '
          'do odômetro. Acesse tocando no veículo e selecionando "Diário de Bordo".',
    ),
    _FaqItem(
      category: 'Manutenções & Alertas',
      icon: Icons.notifications_active,
      question: 'Como funcionam os alertas de revisão preventiva?',
      answer:
          'Ao registrar uma manutenção (ex: troca de óleo), ative "Agendar próximo serviço" e defina o próximo km '
          'ou a próxima data. O aplicativo monitora a quilometragem do veículo e avisa na tela inicial quando '
          'o serviço estiver próximo (menos de 1.000 km ou 15 dias) ou atrasado.',
    ),
    _FaqItem(
      category: 'Gastos & Relatórios',
      icon: Icons.bar_chart,
      question: 'Como ver os gráficos de gastos por semana, mês e ano?',
      answer:
          'Na aba "Relatórios", você tem gráficos interativos em colunas com filtros de Semana, Mês e Ano, '
          'podendo comparar gastos em carros e motos. Ao tocar em qualquer coluna, o aplicativo abre o '
          'detalhamento exato de no que o dinheiro foi gasto (combustível, peças, revisões).',
    ),
    _FaqItem(
      category: 'Gastos & Relatórios',
      icon: Icons.request_quote,
      question: 'Como atualizar o valor do veículo pela Tabela FIPE?',
      answer:
          'Na aba de Veículos, toque sobre o seu carro ou moto e clique em "Consultar" no campo Tabela FIPE. '
          'O aplicativo consulta a API oficial da FIPE e atualiza o valor médio de mercado e o código de referência.',
    ),
    _FaqItem(
      category: 'Conta & Nuvem',
      icon: Icons.cloud_done,
      question: 'Meus dados ficam salvos se eu trocar de aparelho?',
      answer:
          'Sim! Todos os seus veículos, manutenções e abastecimentos são salvos na nuvem pelo Cloud Firestore. '
          'Basta fazer login com o mesmo e-mail e senha em qualquer celular ou navegador para acessar tudo.',
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

    final filtered = _faqList.where((item) {
      final matchesCategory = _selectedCategory == 'Todas' || item.category == _selectedCategory;
      final q = _searchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          item.question.toLowerCase().contains(q) ||
          item.answer.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dúvidas Frequentes (FAQ)'),
      ),
      body: ResponsiveCenter(
        child: ListView(
          padding: pagePadding(context),
          children: [
            // Cabeçalho acolhedor
            Card(
              elevation: 0,
              color: AppColors.goldenPollen.withValues(alpha: isDark ? 0.15 : 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.goldenPollen.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.goldenPollen.withValues(alpha: 0.25),
                      child: const Icon(Icons.help_outline, color: AppColors.goldenPollen, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Central de Dúvidas CarCare',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Encontre respostas rápidas para as dúvidas mais comuns sobre o uso do aplicativo.',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Barra de busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar dúvida (ex: rodízio, consumo, editar...)',
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
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 12),

            // Filtro por categorias
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: selected,
                      label: Text(cat),
                      selectedColor: AppColors.goldenPollen.withValues(alpha: 0.25),
                      checkmarkColor: AppColors.goldenPollen,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de perguntas e respostas
            if (filtered.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Nenhuma dúvida encontrada',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tente buscar por outro termo ou selecione a categoria "Todas".',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filtered.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.goldenPollen.withValues(alpha: 0.15),
                        child: Icon(item.icon, color: AppColors.goldenPollen, size: 22),
                      ),
                      title: Text(
                        item.question,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.category,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.answer,
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
