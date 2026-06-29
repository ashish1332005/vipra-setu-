// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../shared/app_widgets.dart';
import '../taker/taker_ui.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, required this.api, required this.user});

  final ApiClient api;
  final AppUser user;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _lat = TextEditingController(text: '25.3407');
  final _lng = TextEditingController(text: '74.6313');
  bool _sharing = true;
  bool _busy = false;
  String? _message;

  Future<void> _saveLocation() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.api.patch('/providers/me/location', {
        'lat': _lat.text.trim(),
        'lng': _lng.text.trim(),
        'accuracy': 30,
        'locationSharing': _sharing,
      });
      setState(() => _message = 'Location updated successfully.');
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = widget.user.role == 'service_provider';
    return TakerShellBackground(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          18,
          16,
          MediaQuery.paddingOf(context).bottom + 120,
        ),
        children: [
          const _TrackedServiceCard(),
          const SizedBox(height: 14),
          const _MapPreview(),
          const SizedBox(height: 14),
          const _ProfessionalCard(),
          const SizedBox(height: 14),
          const _ProgressCard(),
          const SizedBox(height: 14),
          const _SupportBanner(),
          if (isProvider) ...[
            const SizedBox(height: 14),
            _ProviderLocationCard(
              lat: _lat,
              lng: _lng,
              sharing: _sharing,
              busy: _busy,
              message: _message,
              onSharingChanged: (value) => setState(() => _sharing = value),
              onSave: _saveLocation,
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackedServiceCard extends StatelessWidget {
  const _TrackedServiceCard();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Flex(
        direction: narrow ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment:
            narrow ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              AppAssets.serviceAcRepair,
              width: narrow ? double.infinity : 108,
              height: narrow ? 150 : 94,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: narrow ? 0 : 16, height: narrow ? 12 : 0),
          const _TrackedServiceDetails(),
        ],
      ),
    );
  }
}

class _TrackedServiceDetails extends StatelessWidget {
  const _TrackedServiceDetails();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AC Repair & Service',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text('Booking ID: #VS245678',
            style:
                TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.location_on_outlined, color: AppTheme.muted, size: 18),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                'Shastri Nagar, Bhilwara',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppTheme.muted, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        if (narrow) ...[
          const SizedBox(height: 12),
          const Row(
            children: [
              _SoftStatus(text: 'In Progress'),
              Spacer(),
              Text('Today, 10:00 AM',
                  style: TextStyle(
                      color: AppTheme.saffron, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ],
    );

    if (narrow) return content;

    return Expanded(
      child: Row(
        children: [
          Expanded(child: content),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SoftStatus(text: 'In Progress'),
              SizedBox(height: 18),
              Text('Appointment Time',
                  style: TextStyle(
                      color: AppTheme.muted, fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('Today, 10:00 AM',
                  style: TextStyle(
                      color: AppTheme.saffron, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return SizedBox(
      height: narrow ? 300 : 440,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(AppAssets.trackLive, fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: .14),
              ),
            ),
          ),
          Positioned(
              left: narrow ? 18 : 24,
              top: narrow ? 18 : 24,
              child: const _EtaBox()),
          Positioned(
            left: narrow ? 74 : 92,
            right: narrow ? 52 : 74,
            top: narrow ? 164 : 220,
            child: Container(height: narrow ? 4 : 6, color: AppTheme.saffron),
          ),
          Positioned(
              left: narrow ? 58 : 78,
              top: narrow ? 136 : 188,
              child: _ProviderMapPin(compact: narrow)),
          Positioned(
              right: narrow ? 28 : 46,
              top: narrow ? 82 : 126,
              child: _HomeMapPin(compact: narrow)),
          Positioned(
            left: narrow ? 164 : 210,
            top: narrow ? 106 : 142,
            child: const _MapLabel(title: 'Arriving in', value: '20 mins'),
          ),
        ],
      ),
    );
  }
}

class _EtaBox extends StatelessWidget {
  const _EtaBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          Text('ETA',
              style: TextStyle(
                  color: AppTheme.muted, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('20',
              style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 34,
                  fontWeight: FontWeight.w800)),
          Text('mins',
              style: TextStyle(
                  color: AppTheme.success, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ProviderMapPin extends StatelessWidget {
  const _ProviderMapPin({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
              color: AppTheme.saffron, shape: BoxShape.circle),
          child: CircleAvatar(
            radius: compact ? 25 : 38,
            backgroundImage: const AssetImage(AppAssets.providerElectrician),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: const Text('Suresh Verma\n4.9 ★',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.success)),
        ),
      ],
    );
  }
}

class _HomeMapPin extends StatelessWidget {
  const _HomeMapPin({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: compact ? 28 : 38,
      backgroundColor: const Color(0x662F80ED),
      child: CircleAvatar(
        radius: compact ? 19 : 26,
        backgroundColor: const Color(0xFF2F80ED),
        child: const Icon(Icons.home, color: Colors.white),
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.muted, fontWeight: FontWeight.w700)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.saffron, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Flex(
        direction: narrow ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment:
            narrow ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              AppAssets.providerElectrician,
              width: narrow ? double.infinity : 132,
              height: narrow ? 170 : 132,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: narrow ? 0 : 20, height: narrow ? 14 : 0),
          const _ProfessionalDetails(),
          SizedBox(width: narrow ? 0 : 16, height: narrow ? 12 : 0),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.call, color: AppTheme.saffron),
            label: Text(narrow ? 'Call Professional' : ''),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalDetails extends StatelessWidget {
  const _ProfessionalDetails();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    const content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Suresh Verma',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ),
            _RatingBadge(),
          ],
        ),
        SizedBox(height: 8),
        const Text('Electrician  •  8 Years Exp.',
            style:
                TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w800)),
        SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.verified, color: AppTheme.success, size: 18),
            SizedBox(width: 6),
            Expanded(
              child: Text('Verified Professional',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ],
    );
    if (narrow) return content;
    return const Expanded(child: content);
  }
}

/*

                Text('Electrician  •  8 Years Exp.',
                    style: TextStyle(
                        color: AppTheme.muted, fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.verified, color: AppTheme.success, size: 18),
                    SizedBox(width: 6),
                    Text('Verified Professional',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const OutlinedButton(
            onPressed: null,
            child: Icon(Icons.call, color: AppTheme.saffron),
          ),
        ],
      ),
    );
  }
}

*/

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Booking\nConfirmed', true),
      ('Professional\nAssigned', true),
      ('On The Way', true),
      ('Service\nIn Progress', false),
      ('Service\nCompleted', false),
    ];
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 22),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                    child: _StepBubble(
                        label: steps[i].$1,
                        done: steps[i].$2,
                        current: i == 2)),
                if (i != steps.length - 1)
                  Expanded(
                    child: Divider(
                      color: steps[i + 1].$2 ? AppTheme.success : AppTheme.line,
                      thickness: 3,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBubble extends StatelessWidget {
  const _StepBubble(
      {required this.label, required this.done, required this.current});

  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final color = current
        ? AppTheme.saffron
        : done
            ? AppTheme.success
            : AppTheme.muted;
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: current ? .18 : 1),
          child: Icon(done ? Icons.check_circle : Icons.work_outline,
              color: current ? color : Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.15),
        ),
      ],
    );
  }
}

class _SupportBanner extends StatelessWidget {
  const _SupportBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9D9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Icon(Icons.support_agent, color: AppTheme.saffron, size: 38),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need Help?',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Our support team is here to help you.',
                    style: TextStyle(color: AppTheme.muted)),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.headset_mic),
            label: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }
}

class _ProviderLocationCard extends StatelessWidget {
  const _ProviderLocationCard({
    required this.lat,
    required this.lng,
    required this.sharing,
    required this.busy,
    required this.onSharingChanged,
    required this.onSave,
    this.message,
  });

  final TextEditingController lat;
  final TextEditingController lng;
  final bool sharing;
  final bool busy;
  final String? message;
  final ValueChanged<bool> onSharingChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: sharing,
            onChanged: onSharingChanged,
            title: const Text('Share live location',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: lat,
                      decoration:
                          const InputDecoration(labelText: 'Latitude'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: lng,
                      decoration:
                          const InputDecoration(labelText: 'Longitude'))),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(message!, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: busy ? null : onSave,
            icon: const Icon(Icons.my_location),
            label: Text(busy ? 'Updating...' : 'Update location'),
          ),
        ],
      ),
    );
  }
}

class _SoftStatus extends StatelessWidget {
  const _SoftStatus({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8EF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text,
          style: const TextStyle(
              color: AppTheme.success, fontWeight: FontWeight.w800)),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('4.9 ★',
          style:
              TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800)),
    );
  }
}
