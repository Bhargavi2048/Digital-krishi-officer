import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/farmer_alert.dart';
import '../../core/utils/url_launcher_helper.dart';
import '../../core/services/backend_api_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state_view.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  String _formatTime(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  IconData _getAlertIcon(String type) {
    switch (type.toLowerCase()) {
      case 'weather': return Icons.cloud;
      case 'disease': return Icons.biotech;
      case 'pest': return Icons.bug_report;
      case 'scheme': return Icons.account_balance;
      case 'irrigation': return Icons.water_drop;
      default: return Icons.notifications;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return Colors.red.shade700;
      case 'warning': return Colors.orange.shade800;
      default: return const Color(0xFF2E7D32);
    }
  }

  void _dispatchWhatsAppAlert(BuildContext context, FarmerAlert alert) async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final farmer = authProv.currentUser;
    final phone = farmer?.mobileNumber ?? '';
    final district = (farmer != null && farmer.district.isNotEmpty) ? farmer.district : 'Thanjavur';
    final crop = (farmer != null && farmer.mainCrop.isNotEmpty) ? farmer.mainCrop : 'Paddy (Rice)';

    final message = '🚨 *DIGITAL KRISHI OFFICER - EMERGENCY ALERT* 🚨\n\n'
        '⚠️ *${alert.title}*\n'
        '📌 *Category*: ${alert.type.toUpperCase()} [${alert.severity.toUpperCase()}]\n'
        '📍 *District*: $district\n'
        '🌾 *Target Crop*: $crop\n\n'
        '📋 *Agronomic Advisory*:\n${alert.description}\n\n'
        '🕒 *Dispatched*: ${_formatTime(alert.timestamp)}\n'
        '----------------------------------\n'
        'Digital Krishi Officer AI Advisory System';

    // 1. Dispatch via native WhatsApp messaging
    await UrlLauncherHelper.launchWhatsApp(context: context, phone: phone, message: message);

    // 2. Concurrently record dispatch in Java Spring Boot backend
    BackendApiService().dispatchCloudAlert(
      phone: phone.isNotEmpty ? phone : '9876543210',
      district: district,
      cropName: crop,
      alertType: alert.type.toUpperCase(),
      severity: alert.severity.toUpperCase(),
      channel: 'WHATSAPP',
      message: alert.description,
    ).catchError((_) => false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('WhatsApp Alert dispatched for $crop in $district!'),
          backgroundColor: const Color(0xFF25D366),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertProv = Provider.of<AlertProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: Text(context.tr('alertsTitle')),
        actions: [
          if (alertProv.alerts.isNotEmpty) ...[
            TextButton(
              onPressed: () => alertProv.markAllAsRead(),
              child: Text(
                context.tr('markAllRead'),
                style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All',
              onPressed: () => alertProv.clearAll(),
            ),
          ],
        ],
      ),
      body: alertProv.alerts.isEmpty
          ? EmptyStateView(
              icon: Icons.notifications_off_outlined,
              title: 'No Active Farm Alerts',
              message: context.tr('noAlerts'),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: alertProv.alerts.length + 1,
              itemBuilder: (context, idx) {
                if (idx == 0) {
                  // Broadcast dispatch info header
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cell_tower, color: Color(0xFF2E7D32), size: 24),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live WhatsApp Push Alert Dispatcher',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tap WhatsApp Alert on any notification below to broadcast severe weather & pest advisories to yourself, family, or farm workers.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final a = alertProv.alerts[idx - 1];
                final color = _getSeverityColor(a.severity);

                return Card(
                  elevation: a.isRead ? 0.3 : 1.5,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: a.isRead ? Colors.grey.shade200 : color.withOpacity(0.5),
                      width: a.isRead ? 1 : 1.5,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => alertProv.markAsRead(a.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(_getAlertIcon(a.type), size: 16, color: color),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    a.type.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  if (!a.isRead) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    _formatTime(a.timestamp),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                    onPressed: () => alertProv.deleteAlert(a.id),
                                    padding: const EdgeInsets.only(left: 6),
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            a.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: a.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: const Color(0xFF1B381F),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            a.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.chat, size: 16),
                                label: const Text('WhatsApp Alert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _dispatchWhatsAppAlert(context, a),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
