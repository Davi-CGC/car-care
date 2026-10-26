import 'package:flutter/material.dart';

import '../theme/cores_app.dart';
import '../utils/dialogos.dart';

/// Bloco obrigatório de Termos e Condições para Tela de Cadastro e Login.
/// Se a pessoa não clicar no quadradinho, não cria a conta e não entra no app.
class BlocoTermosCondicoes extends StatelessWidget {
  final bool aceitou;
  final ValueChanged<bool> aoAlterar;
  final bool exibirErro;

  const BlocoTermosCondicoes({
    super.key,
    required this.aceitou,
    required this.aoAlterar,
    this.exibirErro = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final eEscuro = tema.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: exibirErro
            ? CoresApp.perigo.withValues(alpha: 0.08)
            : (eEscuro ? const Color(0xFF1E1E24) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: exibirErro
              ? CoresApp.perigo
              : (aceitou ? CoresApp.amareloPolen : Colors.grey.withValues(alpha: 0.3)),
          width: exibirErro ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => aoAlterar(!aceitou),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: aceitou,
                      activeColor: CoresApp.amareloPolen,
                      checkColor: CoresApp.obsidian,
                      onChanged: (val) => aoAlterar(val ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Eu li e aceito os ',
                              style: TextStyle(fontSize: 12.5),
                            ),
                            GestureDetector(
                              onTap: () => exibirModalTermosECondicoes(context),
                              child: const Text(
                                'Termos e Condições',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: CoresApp.amareloPolen,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text(
                              ' da nossa empresa.',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (exibirErro)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 6),
                    child: Text(
                      'É obrigatório aceitar os termos e condições para prosseguir.',
                      style: TextStyle(color: CoresApp.perigo, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
