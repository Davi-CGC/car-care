import 'package:flutter/material.dart';

import '../../theme/cores_app.dart';
import '../../widgets/layout.dart';

/// Modelo de item do FAQ em português.
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

/// Central de Ajuda e Dúvidas Frequentes (FAQ) em português.
/// Acessada pelo botão amarelo com ponto de interrogação no canto inferior esquerdo.
class TelaManual extends StatefulWidget {
  const TelaManual({super.key});

  @override
  State<TelaManual> createState() => _TelaManualState();
}

class _TelaManualState extends State<TelaManual> {
  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'Todas',
    'Veículos & Rodízio',
    'Combustível & Consumo',
    'Serviços & Postos',
    'Documentos & Pneus',
    'Manutenções & Alertas',
    'Gastos & Relatórios',
    'Conta & Nuvem',
  ];

  static const List<_FaqItem> _faqList = [
    // 1. Veículos & Rodízio
    _FaqItem(
      category: 'Veículos & Rodízio',
      icon: Icons.directions_car,
      question: 'Como cadastrar meu carro, moto ou caminhão?',
      answer:
          'Na aba "Veículos" ou no botão flutuante da tela inicial, toque em "Novo Veículo". '
          'Selecione se o veículo é um Carro, Moto ou Caminhão e escolha a Marca e o Modelo diretamente na lista pesquisável '
          '(ou usando os botões rápidos de marcas e modelos populares da marca selecionada). '
          'Você também pode tocar em "Consultar Tabela FIPE" no card do veículo para puxar automaticamente '
          'o ano oficial e o valor médio de mercado!',
    ),
    _FaqItem(
      category: 'Veículos & Rodízio',
      icon: Icons.bolt,
      question: 'Como funciona o suporte para Carros, Motos e Caminhões Elétricos ou Híbridos?',
      answer:
          'Ao cadastrar ou editar um veículo, você pode selecionar a motorização entre "Combustão", "Híbrido" ou "100% Elétrico ⚡" '
          '(além disso, ao escolher marcas/modelos conhecidos como BYD, Tesla, Voltz, Watts, GWM Haval ou VW e-Delivery, o app detecta a propulsão automaticamente!).\n'
          'Quando o veículo é 100% Elétrico, o app adapta tudo:\n'
          '• Recargas exclusivamente em Eletricidade (kWh) e eficiência medida em km/kWh (sem opções de Gasolina, Etanol ou GNV).\n'
          '• Capacidade da bateria em kWh e sugestões de Eletropostos (Tupinambá, Shell Recharge, Zletric, Wallbox).\n'
          '• Catálogo de manutenção exclusivo para veículos elétricos (bateria de alta tensão, arrefecimento do inversor, óleo do redutor EV, freios regenerativos), ocultando itens de motor a combustão (óleo de motor, velas, correia dentada, escapamento).\n'
          '• Isenção ambiental automática no Rodízio Municipal.',
    ),
    _FaqItem(
      category: 'Veículos & Rodízio',
      icon: Icons.calendar_month,
      question: 'Como o app avisa o dia do meu rodízio veicular?',
      answer:
          'O CarCare lê o último número da placa informada (padrão antigo ou Mercosul) e calcula o dia '
          'da restrição de trânsito (ex: finais 1 e 2 na segunda-feira, 3 e 4 na terça, etc.). '
          'Se hoje for o dia do rodízio do seu carro, um banner amarelo em destaque surge no topo da tela inicial. '
          'Motocicletas e veículos Elétricos/Híbridos são identificados automaticamente como isentos do rodízio municipal.',
    ),
    _FaqItem(
      category: 'Veículos & Rodízio',
      icon: Icons.local_shipping,
      question: 'Como funciona o rodízio para caminhões (ZMRC)?',
      answer:
          'Para caminhões, o aplicativo adota as regras oficiais da Zona de Máxima Restrição de Circulação (ZMRC). '
          'A restrição para caminhões vigora em dias úteis das 05h00 às 21h00 conforme o final da placa. '
          'O banner e o card do veículo alertam o motorista sobre esse horário estendido.',
    ),
    _FaqItem(
      category: 'Veículos & Rodízio',
      icon: Icons.request_quote,
      question: 'Como atualizar o valor do veículo pela Tabela FIPE?',
      answer:
          'Na aba de Veículos, toque sobre o seu carro, moto ou caminhão e clique em "Consultar" no campo Tabela FIPE. '
          'Selecione a Marca, Modelo e Ano. O aplicativo busca diretamente na API oficial da FIPE e atualiza o valor '
          'médio de mercado e o código de referência do veículo.',
    ),

    // 2. Combustível & Consumo
    _FaqItem(
      category: 'Combustível & Consumo',
      icon: Icons.speed,
      question: 'Como funciona o cálculo de quilometragem e consumo?',
      answer:
          'Ao cadastrar um abastecimento, o app exibe a quilometragem anterior registrada. '
          'Ao digitar o novo odômetro e os litros abastecidos, o app calcula na hora a distância percorrida e '
          'o rendimento do trecho (km/l ou km/m³). Ao salvar, a quilometragem do veículo no banco é atualizada '
          'automaticamente!',
    ),
    _FaqItem(
      category: 'Combustível & Consumo',
      icon: Icons.local_gas_station,
      question: 'Posso abastecer com Etanol, Diesel ou GNV?',
      answer:
          'Sim! O formulário de abastecimento permite escolher entre Gasolina, Etanol, Diesel e GNV. '
          'Ao selecionar GNV, o campo de volume muda automaticamente para Metros Cúbicos (m³) e o consumo é '
          'calculado em km/m³.',
    ),
    _FaqItem(
      category: 'Combustível & Consumo',
      icon: Icons.ev_station,
      question: 'Para que serve marcar a opção "Tanque cheio até o automático"?',
      answer:
          'Abastecer com "tanque cheio" é a forma padrão da engenharia automotiva para saber o consumo exato do motor. '
          'Quando você marca que o tanque foi completado, o app calcula a média exata de km/l entre dois tanques cheios. '
          'Se foi um abastecimento parcial (ex: colocou só R\$ 50), deixe a chave desmarcada para não distorcer sua média.',
    ),
    _FaqItem(
      category: 'Combustível & Consumo',
      icon: Icons.calculate,
      question: 'Como funciona a calculadora automática no abastecimento?',
      answer:
          'No formulário de abastecimento, os campos "Preço por Litro", "Volume (Litros)" e "Valor Total Pago" estão '
          'interligados em tempo real:\n'
          '• Digite o Preço/L e os Litros ➔ O Total Pago é calculado na hora.\n'
          '• Digite o Preço/L e o Total Pago ➔ A quantidade de Litros é calculada na hora.\n'
          '• Digite os Litros e o Total Pago ➔ O Preço por Litro é calculado na hora.',
    ),
    _FaqItem(
      category: 'Combustível & Consumo',
      icon: Icons.insights,
      question: 'O que é o card "Rotina de Abastecimento"?',
      answer:
          'É um painel estatístico inteligente na aba de Abastecimentos que analisa o seu padrão de uso:\n'
          '• Distância entre abastecimentos: quantos km você roda em média antes de parar no posto.\n'
          '• Frequência: a cada quantos dias você costuma abastecer.\n'
          '• Autonomia estimada: projeção de quantos km seu tanque cheio rende.\n'
          '• Projeção mensal: estimativa de quanto você gastará de combustível no mês.\n'
          '• Barra inferior: percentual de abastecimentos feitos com tanque completo.',
    ),
    _FaqItem(
      category: 'Combustível & Consumo',
      icon: Icons.thermostat,
      question: 'Onde fica e o que significa o Termômetro de Consumo?',
      answer:
          'Cada veículo possui seu próprio Termômetro de Consumo exclusivo dentro do "Diário de Bordo / Log do Veículo" '
          '(basta tocar no veículo e abrir o Diário de Bordo). Ele indica se o consumo médio daquele veículo está eficiente:\n'
          '• Verde (Muito Econômico): Alta autonomia por litro/m³.\n'
          '• Amarelo (Normal / Moderado): Consumo padrão esperado para o combustível e tipo de veículo.\n'
          '• Vermelho (Alto Consumo): Indica consumo elevado. Vale a pena verificar calibragem dos pneus, '
          'filtro de ar, velas e bicos injetores.',
    ),

    // 3. Serviços & Postos
    _FaqItem(
      category: 'Serviços & Postos',
      icon: Icons.explore,
      question: 'Como encontrar postos, mecânicos e borracharias próximos?',
      answer:
          'No topo do app (na barra superior), toque no ícone de Bússola. O painel "Radar de Serviços Próximos" '
          'permite encontrar com 1 toque no Google Maps: Postos de Combustível, Oficinas Mecânicas, Borracharias 24h, '
          'Autoelétricas, Lava-rápidos e Auto Socorro / Guincho na sua região atual.',
    ),
    _FaqItem(
      category: 'Serviços & Postos',
      icon: Icons.storefront,
      question: 'O que é o Histórico de Postos Frequentados?',
      answer:
          'Na aba "Abastecimentos", toque no botão "Histórico de Postos Frequentados". Nele você visualiza todos os '
          'postos onde já abasteceu, quantidade de visitas, total gasto em reais, volume em litros e os preços '
          'históricos que você pagou por Gasolina, Etanol, Diesel ou GNV, além de um botão para abrir rota no Google Maps!',
    ),

    // 4. Documentos & Pneus
    _FaqItem(
      category: 'Documentos & Pneus',
      icon: Icons.account_balance,
      question: 'Como funciona o controle e lembrete de IPVA?',
      answer:
          'Ao abrir os detalhes do veículo, toque em "Lembretes: IPVA, Licenciamento, Seguro & Pneus". '
          'O CarCare calcula o mês de vencimento oficial do IPVA pelo final da placa, estima o valor com base na alíquota '
          'do estado sobre a Tabela FIPE e permite marcar o imposto como Pendente, Pago ou Isento.',
    ),
    _FaqItem(
      category: 'Documentos & Pneus',
      icon: Icons.description,
      question: 'Como funciona o lembrete de Licenciamento Anual (Detran)?',
      answer:
          'O app acompanha o calendário oficial do Detran pelo dígito final da placa (de Julho a Dezembro). '
          'Ele avisa se o documento está regular, no mês de vencimento ou em atraso, com botão para confirmar o pagamento anual.',
    ),
    _FaqItem(
      category: 'Documentos & Pneus',
      icon: Icons.security,
      question: 'Como cadastrar o Seguro e acionar o Guincho 24h rapidamente?',
      answer:
          'No modal de Lembretes do veículo, você pode cadastrar a Seguradora, número da Apólice, data de renovação '
          'e o telefone de assistência 24h. Quando precisar de um guincho ou socorro, basta tocar no botão de chamada rápida '
          'para discar diretamente sem precisar procurar papelada.',
    ),
    _FaqItem(
      category: 'Documentos & Pneus',
      icon: Icons.tire_repair,
      question: 'Como funciona o controle de Rodízio de Pneus?',
      answer:
          'O rodízio de pneus prolonga a vida útil dos pneus e melhora a segurança. O CarCare monitora o intervalo '
          'padrão de 10.000 km, exibindo uma barra visual de desgaste e a quilometragem restante. '
          'Ao fazer o rodízio, basta tocar em "Registrar Rodízio Hoje" para atualizar o odômetro da troca.',
    ),

    // 5. Manutenções & Alertas
    _FaqItem(
      category: 'Manutenções & Alertas',
      icon: Icons.speed,
      question: 'Como funciona a visualização do odômetro anterior no cadastro?',
      answer:
          'Sempre que você for cadastrar uma nova manutenção ou abastecimento, o app mostra em destaque a última quilometragem '
          'registrada e calcula em tempo real quantos km você rodou desde a última vez, evitando que você digite quilometragens '
          'inferiores por engano.',
    ),
    _FaqItem(
      category: 'Manutenções & Alertas',
      icon: Icons.edit_note,
      question: 'Como editar ou corrigir uma manutenção ou abastecimento já salvo?',
      answer:
          'Se você confirmou um abastecimento ou manutenção e percebeu que digitou algo errado, basta tocar sobre o item na lista '
          'e clicar no botão "Editar". Altere os valores desejados e salve novamente sem perder o histórico.',
    ),
    _FaqItem(
      category: 'Manutenções & Alertas',
      icon: Icons.menu_book,
      question: 'O que é o Diário de Bordo (Log do Veículo)?',
      answer:
          'O Diário de Bordo é a linha do tempo completa do seu veículo. Nele você vê em ordem cronológica reversa todas as '
          'manutenções e abastecimentos, total gasto, evolução do odômetro e a média diária de km rodados.',
    ),
    _FaqItem(
      category: 'Manutenções & Alertas',
      icon: Icons.notifications_active,
      question: 'Como funcionam os alertas de revisão preventiva?',
      answer:
          'Ao registrar uma manutenção (ex: troca de óleo), ative "Agendar próximo serviço" e defina o próximo km ou data. '
          'O aplicativo monitora o avanço do odômetro e avisa na tela inicial quando o serviço estiver próximo ou atrasado.',
    ),

    // 6. Gastos & Relatórios
    _FaqItem(
      category: 'Gastos & Relatórios',
      icon: Icons.bar_chart,
      question: 'Como ver os gráficos de gastos por semana, mês e ano?',
      answer:
          'Na aba "Relatórios", você encontra gráficos de colunas com filtros por Semana, Mês ou Ano, podendo filtrar entre '
          'Carros, Motos e Caminhões. Ao tocar em qualquer coluna, o aplicativo abre o detalhamento exato com tudo o que '
          'foi gasto no período!',
    ),
    _FaqItem(
      category: 'Gastos & Relatórios',
      icon: Icons.timeline,
      question: 'O que é a Média Diária de Distância (km/dia)?',
      answer:
          'É um cálculo que divide os quilômetros rodados pela quantidade de dias entre os registros. '
          'Essa métrica ajuda a saber o ritmo real de uso do veículo para planejar despesas e próximas trocas de óleo.',
    ),

    // 7. Conta & Nuvem
    _FaqItem(
      category: 'Conta & Nuvem',
      icon: Icons.cloud_done,
      question: 'Meus dados ficam salvos se eu trocar de aparelho?',
      answer:
          'Sim! Todos os seus dados ficam salvos com segurança na nuvem pelo Google Cloud Firestore. '
          'Basta fazer login com o mesmo e-mail e senha em qualquer celular ou computador para acessar seus veículos.',
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

/// Alias para manter compatibilidade
typedef ManualScreen = TelaManual;
