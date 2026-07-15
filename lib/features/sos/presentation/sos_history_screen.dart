import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/sos_event_repository.dart';
import '../domain/sos_event_model.dart';
import 'package:shurokkha/core/localization/l10n/app_localizations.dart';

class SosHistoryScreen extends ConsumerWidget {
  const SosHistoryScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case SosEvent.kStatusActive:
        return Colors.green;
      case SosEvent.kStatusCancelled:
        return Colors.orange;
      case SosEvent.kStatusResolved:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(sosEventsStreamProvider);
    final l10n = AppLocalizations.of(context)!;
    final formatter = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sosHistory),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noEventsYet,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final statusText = event.status == SosEvent.kStatusActive
                  ? l10n.statusActive
                  : (event.status == SosEvent.kStatusCancelled
                      ? l10n.statusCancelled
                      : l10n.statusResolved);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(event.status).withOpacity(0.2),
                    child: Icon(Icons.warning, color: _getStatusColor(event.status)),
                  ),
                  title: Text(
                    l10n.eventStarted(formatter.format(event.startedAt)),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(event.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: _getStatusColor(event.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Notified: ${event.contactsNotified.length}'),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (event.endedAt != null) ...[
                            Text(
                              l10n.eventEnded(formatter.format(event.endedAt!)),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            'Contacts notified:\n${event.contactsNotified.join("\n")}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          if (event.audioUrl != null && event.audioUrl!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(event.audioUrl!);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  if (context.mounted) {
                                    _showSnackBar(context, 'Could not open audio file');
                                  }
                                }
                              },
                              icon: const Icon(Icons.audiotrack),
                              label: Text(l10n.audioRecording),
                            ),
                          ],
                          const SizedBox(height: 12),
                          // View last location of the event in maps
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(event.userId)
                                .collection('sos_events')
                                .doc(event.id)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final data = snapshot.data!.data() as Map<String, dynamic>?;
                                if (data != null && data['latitude'] != null && data['longitude'] != null) {
                                  final double lat = data['latitude'];
                                  final double lng = data['longitude'];
                                  return OutlinedButton.icon(
                                    onPressed: () async {
                                      final urlString = Platform.isAndroid
                                          ? 'geo:$lat,$lng?q=$lat,$lng'
                                          : 'https://maps.apple.com/?daddr=$lat,$lng';
                                      final uri = Uri.parse(urlString);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      } else {
                                        final fallback = Uri.parse('https://maps.google.com/maps?daddr=$lat,$lng');
                                        if (await canLaunchUrl(fallback)) {
                                          await launchUrl(fallback);
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.map),
                                    label: Text(l10n.viewOnMap),
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
