import 'package:flutter/material.dart';

import '../models/registro_abastecimento.dart';
import '../models/veiculo.dart';
import '../utils/calculos.dart';
import '../utils/formatadores.dart';

/// Card de Rotina de Abastecimento fiel à referência visual do usuário em português.
class CartaoRotinaCombustivel extends StatelessWidget {
  final Veiculo veiculo;
  final List<RegistroAbastecimento> abastecimentos;

  const CartaoRotinaCombustivel({
    super.key,
    required this.veiculo,
    required this.abastecimentos,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final eEscuro = tema.brightness == Brightness.dark;

    final estatisticas = Calculos.rotinaCombustivel(veiculo, abastecimentos);

    const corLaranja = Color(0xFFF59E0B); // Amber / Laranja do design
    final fundoCard = eEscuro ? const Color(0xFF1E1E24) : Colors.white;
    final corBorda = eEscuro
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final usaModoEletrico = veiculo.eEletrico &&
        (abastecimentos.isEmpty || abastecimentos.any((a) => a.eEletrico));

    final rotuloDistancia = estatisticas.distanciaMediaEntreAbastecimentos > 0
        ? '${formatarNumero(estatisticas.distanciaMediaEntreAbastecimentos, 0)} km'
        : '-- km';

    final diasArredondados = estatisticas.frequenciaMediaDias.round();
    final rotuloFrequencia = diasArredondados > 0
        ? '$diasArredondados ${diasArredondados == 1 ? "Dia" : "Dias"}'
        : '-- Dias';

    final rotuloAutonomia = estatisticas.autonomiaEstimada > 0
        ? '${formatarNumero(estatisticas.autonomiaEstimada, 0)} km'
        : '-- km';

    final rotuloMensal = estatisticas.projecaoMensal > 0
        ? formatarMoeda(estatisticas.projecaoMensal)
        : r'R$ --';

    final valorProgresso = (estatisticas.porcentagemTanqueCheio / 100.0).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      color: fundoCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: corBorda),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com Ícone e Título adaptado para Combustão ou Elétrico
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: usaModoEletrico ? Colors.green[600] : corLaranja,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      usaModoEletrico ? Icons.ev_station : Icons.show_chart,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    usaModoEletrico
                        ? 'Rotina de recarga elétrica'
                        : (veiculo.eHibrido
                            ? 'Rotina de abastecimento & recarga'
                            : 'Rotina de abastecimento'),
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: usaModoEletrico ? Colors.green[600] : corLaranja,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Grade 2x2 com as métricas
            Row(
              children: [
                Expanded(
                  child: _ItemMetrica(
                    rotulo: usaModoEletrico ? 'Entre recargas' : 'Entre abastecimentos',
                    valor: rotuloDistancia,
                  ),
                ),
                Expanded(
                  child: _ItemMetrica(
                    rotulo: 'Frequência',
                    valor: rotuloFrequencia,
                    alinhamento: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _ItemMetrica(
                    rotulo: usaModoEletrico ? 'Autonomia (100% carga)' : 'Autonomia estimada',
                    valor: rotuloAutonomia,
                  ),
                ),
                Expanded(
                  child: _ItemMetrica(
                    rotulo: 'Projeção mensal',
                    valor: rotuloMensal,
                    alinhamento: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Rodapé com barra de progresso e texto explicativo
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: valorProgresso > 0 ? valorProgresso : 0.05,
                      minHeight: 10,
                      backgroundColor: eEscuro
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFF1F1F4),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usaModoEletrico ? Colors.green[600]! : corLaranja,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    estatisticas.totalAbastecimentos > 0
                        ? (usaModoEletrico
                            ? '${estatisticas.quantidadeTanqueCheio} de ${estatisticas.totalAbastecimentos} recargas até 100% (${formatarNumero(estatisticas.porcentagemTanqueCheio, 1)}%) — a eficiência (km/kWh) é medida de uma carga completa até a próxima.'
                            : '${estatisticas.quantidadeTanqueCheio} de ${estatisticas.totalAbastecimentos} abastecimentos com tanque cheio (${formatarNumero(estatisticas.porcentagemTanqueCheio, 1)}%) — a média é medida de um tanque cheio até o próximo.')
                        : (usaModoEletrico
                            ? 'Registre suas recargas em kWh para acompanhar a autonomia e projeção mensal.'
                            : 'Cadastre abastecimentos para acompanhar sua rotina e projeção mensal.'),
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: eEscuro ? Colors.grey[400] : const Color(0xFF6B7280),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemMetrica extends StatelessWidget {
  final String rotulo;
  final String valor;
  final CrossAxisAlignment alinhamento;

  const _ItemMetrica({
    required this.rotulo,
    required this.valor,
    this.alinhamento = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final eEscuro = tema.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: alinhamento,
      children: [
        Text(
          rotulo,
          style: tema.textTheme.bodySmall?.copyWith(
            color: eEscuro ? Colors.grey[400] : const Color(0xFF8E8E93),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: tema.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class FuelRoutineCard extends CartaoRotinaCombustivel {
  const FuelRoutineCard({
    super.key,
    required Veiculo vehicle,
    required List<RegistroAbastecimento> fuels,
  }) : super(veiculo: vehicle, abastecimentos: fuels);
}
