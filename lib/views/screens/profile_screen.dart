import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_data.dart';
import '../../models/app_models.dart';
import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../services/auth_service.dart';
import '../widgets/common.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider).loadPartnerProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final ratingText = app.partnerRating != null
        ? '${app.partnerRating!.toStringAsFixed(1)} ★'
        : '— ★';
    final partnerTier = (app.totalDeliveries ?? 0) >= 100 ? 'Gold partner' : 'Delivery partner';
    final vehicleLabel = [
      if ((app.vehicleNumber ?? '').trim().isNotEmpty) app.vehicleNumber!.trim(),
      if ((app.vehicleType ?? '').trim().isNotEmpty) app.vehicleType!.trim(),
    ].join(' · ');

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => app.loadPartnerProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: Responsive.screenPadding(context, horizontal: 20, vertical: 4).copyWith(bottom: Responsive.isTablet(context) ? 150 : 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    BackButtonChip(onTap: () => app.toHome()),
                    const SizedBox(width: 12),
                    Text('Profile', style: AppText.display(size: 20)),
                    const Spacer(),
                    if (app.partnerProfileLoading)
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
              if (app.partnerProfileError != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.plumTint, borderRadius: BorderRadius.circular(12)),
                  child: Text(app.partnerProfileError!, style: AppText.body(size: 12, color: AppColors.red)),
                ),
              ],
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accentLight, AppColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.16), border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2)), alignment: Alignment.center, child: Text(app.displayInitials(riderInitials), style: AppText.display(size: 20, color: Colors.white))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.displayName(riderName), style: AppText.display(size: 18, color: Colors.white)),
                          Padding(padding: const EdgeInsets.only(top: 2), child: Text('Rider ID · ${app.displayId(riderId)}', style: AppText.body(size: 12, color: Colors.white.withValues(alpha: 0.85)))),
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(9)),
                            child: Text('$ratingText · $partnerTier', style: AppText.body(size: 11, weight: FontWeight.w800, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _statCard('Vehicle', vehicleLabel.isNotEmpty ? vehicleLabel : '—', icon: Icons.moped_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Deliveries', '${app.totalDeliveries ?? 0}')),
                ],
              ),
              Padding(padding: const EdgeInsets.fromLTRB(4, 20, 4, 10), child: Text('ACCOUNT STATUS', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 1))),
              _accountStatusCard(app),
              Padding(padding: const EdgeInsets.fromLTRB(4, 20, 4, 10), child: Text('DOCUMENTS', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 1))),
              Column(children: verifiableDocuments.map((d) => _DocumentCard(doc: d)).toList()),
              Padding(padding: const EdgeInsets.fromLTRB(4, 20, 4, 10), child: Text('PREFERENCES', style: AppText.body(size: 12, weight: FontWeight.w700, color: AppColors.bodyGrey, letterSpacing: 1))),
              Container(
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: riderPrefDefs
                      .map((p) => GestureDetector(
                            onTap: () => app.togglePref(p.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
                              child: Row(
                                children: [
                                  Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.plumTint, borderRadius: BorderRadius.circular(11)), alignment: Alignment.center, child: Icon(p.icon, size: 18, color: AppColors.accent)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(p.label, style: AppText.body(size: 13, weight: FontWeight.w700))),
                                  ToggleSwitch(on: app.prefs[p.key] ?? false, onTap: () => app.togglePref(p.key)),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: app.toHelp,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.midGrey),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Help & support', style: AppText.body(size: 13.5, weight: FontWeight.w700))),
                      const Text('→', style: TextStyle(color: AppColors.lightGreyText)),
                    ],
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: GestureDetector(onTap: app.logout, child: Text('Log out', style: AppText.body(size: 13, weight: FontWeight.w800, color: AppColors.red))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, {IconData? icon}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.body(size: 11.5, weight: FontWeight.w600, color: AppColors.bodyGrey)),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: icon == null
                  ? Text(value, style: AppText.display(size: 15))
                  : Row(
                      children: [
                        Icon(icon, size: 15, color: AppColors.midGrey),
                        const SizedBox(width: 5),
                        Expanded(child: Text(value, style: AppText.display(size: 15), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
            ),
          ],
        ),
      );

  Widget _accountStatusCard(AppState app) {
    final active = app.accountStatus == AccountStatus.active;
    final rejected = app.accountStatus == AccountStatus.rejected;
    final colors = rejected ? [AppColors.red, AppColors.red] : active ? [AppColors.green, AppColors.green] : [AppColors.goldDeep, AppColors.goldDeep];
    final label = rejected ? '✕ REJECTED' : active ? '✓ ACTIVE' : '⏳ UNDER REVIEW';
    final title = rejected ? 'Application rejected' : active ? 'Account verified' : 'Verification pending';
    final sub = rejected
        ? 'One or more documents were rejected. Please re-submit.'
        : active
            ? 'All documents verified — you can go online.'
            : 'Documents below are loaded from your partner profile. An admin reviews after submission.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(color: colors.first, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppText.display(size: 15, color: Colors.white)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(20)), child: Text(label, style: AppText.body(size: 10, weight: FontWeight.w800, color: Colors.white))),
            ],
          ),
          Padding(padding: const EdgeInsets.only(top: 5), child: Text(sub, style: AppText.body(size: 11.5, color: Colors.white.withValues(alpha: 0.9)))),
        ],
      ),
    );
  }
}

class _DocumentCard extends ConsumerStatefulWidget {
  final VerifiableDocument doc;
  const _DocumentCard({required this.doc});

  @override
  ConsumerState<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends ConsumerState<_DocumentCard> {
  late final TextEditingController _ctrl;

  static const _uploadTypeFor = {
    'license': 'DRIVING_LICENSE',
    'aadhar': 'AADHAAR',
    'pan': 'PAN',
    'bank': 'BANK',
    'address_proof': 'AADHAAR',
  };

  @override
  void initState() {
    super.initState();
    final app = ref.read(appControllerProvider);
    _ctrl = TextEditingController(text: app.documentNumbers[widget.doc.id] ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final value = ref.read(appControllerProvider).documentNumbers[widget.doc.id] ?? '';
    if (_ctrl.text != value) {
      _ctrl.text = value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final d = widget.doc;
    final status = app.documentStatus[d.id] ?? DocumentStatus.unverified;
    final uploaded = app.documentUploaded[d.id] ?? false;
    final apiNumber = app.documentNumbers[d.id] ?? '';
    if (_ctrl.text != apiNumber && (status == DocumentStatus.verified || status == DocumentStatus.pending || uploaded)) {
      _ctrl.text = apiNumber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.plumTint, borderRadius: BorderRadius.circular(11)), alignment: Alignment.center, child: Icon(d.icon, size: 18, color: AppColors.accent)),
              const SizedBox(width: 12),
              Expanded(child: Text(d.label, style: AppText.body(size: 13, weight: FontWeight.w700))),
              _statusPill(status),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.dividerBorder, width: 1.5), borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _ctrl,
                    enabled: status != DocumentStatus.verified && status != DocumentStatus.pending,
                    onChanged: (v) => app.setDocumentNumber(d.id, v),
                    style: AppText.body(size: 13, weight: FontWeight.w600),
                    decoration: InputDecoration(border: InputBorder.none, isDense: true, hintText: d.numberHint, hintStyle: AppText.body(size: 13, color: AppColors.lightGreyText)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _statusIcon(status),
            ],
          ),
          const SizedBox(height: 10),
          _uploadButton(app, d, uploaded, status),
        ],
      ),
    );
  }

  Widget _statusPill(DocumentStatus status) {
    final (text, fg, bg) = switch (status) {
      DocumentStatus.verified => ('Verified', AppColors.green, AppColors.greenPaleBg),
      DocumentStatus.pending => ('Pending review', AppColors.goldDeep, AppColors.goldTint),
      DocumentStatus.rejected => ('Rejected', AppColors.red, AppColors.plumTint),
      DocumentStatus.unverified => ('Not submitted', AppColors.bodyGrey, AppColors.plumTint),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: AppText.body(size: 10.5, weight: FontWeight.w800, color: fg)),
    );
  }

  Widget _statusIcon(DocumentStatus status) {
    if (status == DocumentStatus.verified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(color: AppColors.greenPaleBg, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.check_rounded, color: AppColors.green, size: 18),
      );
    }
    if (status == DocumentStatus.pending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(color: AppColors.goldTint, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.hourglass_top_rounded, color: AppColors.goldDeep, size: 18),
      );
    }
    if (status == DocumentStatus.rejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(color: AppColors.plumTint, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.close_rounded, color: AppColors.red, size: 18),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _uploadButton(AppState app, VerifiableDocument d, bool uploaded, DocumentStatus status) {
    if (uploaded || status == DocumentStatus.verified || status == DocumentStatus.pending) {
      return Row(
        children: [
          Icon(
            status == DocumentStatus.rejected ? Icons.error_outline : Icons.check_circle,
            size: 16,
            color: status == DocumentStatus.rejected ? AppColors.red : AppColors.green,
          ),
          const SizedBox(width: 6),
          Text(
            status == DocumentStatus.rejected ? 'Document rejected — re-upload required' : 'Document on file',
            style: AppText.body(size: 12, weight: FontWeight.w700, color: status == DocumentStatus.rejected ? AppColors.red : AppColors.green),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final accessToken = app.accessToken;
          if (accessToken == null || accessToken.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in before uploading documents')));
            return;
          }

          try {
            await AuthService().uploadSignupDocuments(
              accessToken: accessToken,
              partnerId: app.partnerId ?? '',
              documentType: _uploadTypeFor[d.id] ?? d.id.toUpperCase(),
              documentNumber: app.documentNumbers[d.id] ?? '',
              fileName: '${d.id}.jpg',
            );
            app.uploadDocument(d.id);
            await app.loadPartnerProfile();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
            );
          }
        },
        icon: const Icon(Icons.upload_file_rounded, size: 16, color: AppColors.accent),
        label: Text('Upload document photo', style: AppText.body(size: 13, weight: FontWeight.w700, color: AppColors.accent)),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11), side: const BorderSide(color: AppColors.dividerBorder, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}
