import 'package:flutter/material.dart';

import '../../app/ledger_theme.dart';
import '../risk/risk_copy.dart';

class LedgerPanel extends StatelessWidget {
  const LedgerPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: LedgerColors.inkSoft,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LedgerColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LedgerColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: LedgerColors.inkSoft,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.items});

  final List<MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(child: MetricTile(item: items[index])),
          if (index != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class MetricItem {
  const MetricItem({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    this.accent = LedgerColors.primary,
    this.soft = LedgerColors.primarySoft,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color accent;
  final Color soft;
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.item});

  final MetricItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIcon(icon: item.icon, color: item.accent, softColor: item.soft),
            const SizedBox(height: 12),
            Text(
              item.value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              item.helper,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LedgerColors.inkSoft,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SoftIcon extends StatelessWidget {
  const SoftIcon({
    super.key,
    required this.icon,
    this.color = LedgerColors.primary,
    this.softColor = LedgerColors.primarySoft,
  });

  final IconData icon;
  final Color color;
  final Color softColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 21, color: color),
    );
  }
}

class LedgerListRow extends StatelessWidget {
  const LedgerListRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      style: const TextStyle(color: LedgerColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(flex: 0, child: trailing),
            ],
          ),
        ),
      ),
    );
  }
}

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.risk});

  final String? risk;

  @override
  Widget build(BuildContext context) {
    final colors = riskColors(risk);
    return StatusBadge(
      label: RiskCopy.label(risk),
      color: colors.$1,
      softColor: colors.$2,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.softColor,
  });

  final String label;
  final Color color;
  final Color softColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28, maxWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SoftIcon(
              icon: Icons.inbox_outlined,
              color: LedgerColors.inkSoft,
              softColor: LedgerColors.surfaceAlt,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: LedgerColors.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InlineMessage extends StatelessWidget {
  const InlineMessage({super.key, required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? LedgerColors.reviewSoft : LedgerColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? LedgerColors.review : LedgerColors.primary,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? LedgerColors.review : LedgerColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        LedgerPanel(
          title: 'Memuat data',
          subtitle: 'Menghubungkan aplikasi dengan server Posyandu.',
          accent: LedgerColors.primary,
          child: LinearProgressIndicator(),
        ),
      ],
    );
  }
}

(Color, Color) riskColors(String? risk) {
  return switch (risk) {
    'rendah' => (LedgerColors.primary, LedgerColors.primarySoft),
    'sedang' => (LedgerColors.attention, LedgerColors.attentionSoft),
    'tinggi' => (LedgerColors.review, LedgerColors.reviewSoft),
    'gagal' => (LedgerColors.inkSoft, LedgerColors.line),
    _ => (LedgerColors.bidanBlue, LedgerColors.primarySoft),
  };
}
