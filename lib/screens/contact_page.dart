import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/sim_theme.dart';
import '../util/launch_external_uri.dart';

/// Contacto SIM Four (datos de simfour.com).
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const _email = 'info@simfour.com';

  Future<void> _launch(BuildContext context, Uri uri) async {
    final ok = await launchExternalUri(uri);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el enlace: ${uri.scheme}'),
        ),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      queryParameters: const {'subject': 'Consulta SIM Four'},
    );
    final ok = await launchExternalUri(uri);
    if (!context.mounted) return;
    if (!ok) {
      await Clipboard.setData(const ClipboardData(text: _email));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se detectó un cliente de correo. '
            'Correo copiado al portapapeles: info@simfour.com',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacto'),
        backgroundColor: SimTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SimTheme.primaryColor,
                  SimTheme.primaryColor.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.headset_mic, color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text(
                  'Ventas, soporte y canal de denuncias',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Estamos para ayudarle con SIM Four',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ContactCard(
            icon: Icons.phone_in_talk,
            iconColor: Colors.green,
            title: 'Teléfono',
            subtitle: '+56 2 3384 9065',
            onTap: () => _launch(context, Uri.parse('tel:+56233849065')),
          ),
          _ContactCard(
            icon: Icons.mark_email_unread,
            iconColor: Colors.orange,
            title: 'Email',
            subtitle: _email,
            onTap: () => _launchEmail(context),
          ),
          _ContactCard(
            icon: Icons.location_city,
            iconColor: Colors.blue,
            title: 'Dirección',
            subtitle:
                'Cerro el Plomo 5931 of 1011, Las Condes, Santiago RM Chile',
            onTap: () => _launch(
              context,
              Uri.parse(
                'https://www.google.cl/maps/place/Cerro+El+Plomo+5931,+Las+Condes',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Redes sociales',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SocialButton(
                icon: Icons.chat,
                color: const Color(0xFF25D366),
                label: 'WhatsApp',
                onTap: () => _launch(
                  context,
                  Uri.parse(
                    'https://api.whatsapp.com/message/WB6ER4EVRV3FB1',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SocialButton(
                icon: Icons.work,
                color: const Color(0xFF0A66C2),
                label: 'LinkedIn',
                onTap: () => _launch(
                  context,
                  Uri.parse('https://www.linkedin.com/company/simfour/'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SocialButton(
                icon: Icons.play_circle_fill,
                color: Colors.red,
                label: 'YouTube',
                onTap: () => _launch(
                  context,
                  Uri.parse('https://www.youtube.com/@simfour'),
                ),
              ),
              const SizedBox(width: 8),
              _SocialButton(
                icon: Icons.camera_alt,
                color: const Color(0xFFE4405F),
                label: 'Instagram',
                onTap: () => _launch(
                  context,
                  Uri.parse('https://www.instagram.com/simfour.iso/'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
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
