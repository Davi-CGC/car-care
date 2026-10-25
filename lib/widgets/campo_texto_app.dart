import 'package:flutter/material.dart';

/// Campo de texto padrão do app em português. Com [eSenha] mostra o botão de ver senha.
class CampoTextoApp extends StatefulWidget {
  final TextEditingController controlador;
  final String rotulo;
  final IconData? icone;
  final String? dica;
  final String? ajuda;
  final String? Function(String?)? validador;
  final TextInputType? tipoTeclado;
  final TextInputAction acaoTeclado;
  final bool eSenha;
  final int maxLinhas;
  final ValueChanged<String>? aoAlterar;
  final VoidCallback? aoSubmeter;
  final TextCapitalization capitalizacaoTexto;

  const CampoTextoApp({
    super.key,
    required this.controlador,
    required this.rotulo,
    this.icone,
    this.dica,
    this.ajuda,
    this.validador,
    this.tipoTeclado,
    this.acaoTeclado = TextInputAction.next,
    this.eSenha = false,
    this.maxLinhas = 1,
    this.aoAlterar,
    this.aoSubmeter,
    this.capitalizacaoTexto = TextCapitalization.none,
  });

  @override
  State<CampoTextoApp> createState() => _CampoTextoAppState();
}

class _CampoTextoAppState extends State<CampoTextoApp> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controlador,
      validator: widget.validador,
      keyboardType: widget.tipoTeclado,
      textInputAction: widget.acaoTeclado,
      obscureText: widget.eSenha && _oculto,
      maxLines: widget.eSenha ? 1 : widget.maxLinhas,
      onChanged: widget.aoAlterar,
      onFieldSubmitted: (_) => widget.aoSubmeter?.call(),
      textCapitalization: widget.capitalizacaoTexto,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.rotulo,
        hintText: widget.dica,
        helperText: widget.ajuda,
        helperMaxLines: 2,
        prefixIcon: widget.icone == null ? null : Icon(widget.icone),
        suffixIcon: widget.eSenha
            ? IconButton(
                tooltip: _oculto ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(_oculto ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _oculto = !_oculto),
              )
            : null,
      ),
    );
  }
}

/// Alias para manter compatibilidade
class AppTextField extends CampoTextoApp {
  const AppTextField({
    super.key,
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    String? helper,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    bool isPassword = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
    VoidCallback? onSubmitted,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) : super(
          controlador: controller,
          rotulo: label,
          icone: icon,
          dica: hint,
          ajuda: helper,
          validador: validator,
          tipoTeclado: keyboardType,
          acaoTeclado: textInputAction,
          eSenha: isPassword,
          maxLinhas: maxLines,
          aoAlterar: onChanged,
          aoSubmeter: onSubmitted,
          capitalizacaoTexto: textCapitalization,
        );
}
