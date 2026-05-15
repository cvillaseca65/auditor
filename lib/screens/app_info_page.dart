import 'package:flutter/material.dart';

import '../core/theme/sim_theme.dart';

/// Descripción de SIM Auditor para usuarios nuevos.
class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1),
              SimTheme.primaryColor,
              Color(0xFF1A237E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Información',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 64,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'SIM Auditor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La extensión móvil de SIM Four para trabajar con su '
                      'organización desde el celular o el navegador, con las '
                      'mismas credenciales de simfour.com.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _InfoCard(
                      icon: Icons.home_rounded,
                      color: Color(0xFF42A5F5),
                      title: 'Inicio',
                      body:
                          'Resumen de pendientes personales y de la organización, '
                          'con acceso rápido a hallazgos.',
                    ),
                    _InfoCard(
                      icon: Icons.report_rounded,
                      color: Color(0xFFEF5350),
                      title: 'Hallazgos',
                      body:
                          'Consulta pendientes y cerrados, crea nuevos hallazgos '
                          'y continúa el flujo de trabajo en la etapa que le corresponda.',
                    ),
                    _InfoCard(
                      icon: Icons.description_rounded,
                      color: Color(0xFF66BB6A),
                      title: 'Documentos',
                      body:
                          'Busca documentos oficiales, lee su contenido y abre '
                          'archivos con las relaciones vinculadas en SIM.',
                    ),
                    _InfoCard(
                      icon: Icons.menu_book_rounded,
                      color: Color(0xFFFFB74D),
                      title: 'Norma',
                      body:
                          'Navega normativas, artículos y cumplimiento; edita '
                          'registros con el mismo formulario que en la web.',
                    ),
                    _InfoCard(
                      icon: Icons.people_rounded,
                      color: Color(0xFFAB47BC),
                      title: 'Usuarios',
                      body:
                          'Ficha de personas, competencias, desempeño y tareas '
                          'de su equipo.',
                    ),
                    _InfoCard(
                      icon: Icons.fact_check_rounded,
                      color: Color(0xFF26C6DA),
                      title: 'Auditoría',
                      body:
                          'Planes y líneas de auditoría asignados, alineados con '
                          'el módulo de auditorías de SIM.',
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Conexión segura con su cuenta SIM. Los datos '
                              'pertenecen a la organización activa que seleccione '
                              'al iniciar sesión.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: SimTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
