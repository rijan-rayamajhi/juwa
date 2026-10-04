import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/wallet_service.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/juwa_popup.dart';

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: JuwaColors.panel,
      behavior: SnackBarBehavior.floating,
    ));
}

// ---------------- Get Coins / Daily Bonus ----------------
void showGetCoinsPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => JuwaPopup(
      title: 'Get Coins',
      child: AnimatedBuilder(
        animation: WalletService.instance,
        builder: (context, _) {
          final w = WalletService.instance;
          final ready = w.bonusReady;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/bonus.png', width: 110, height: 110),
              const SizedBox(height: 8),
              const Text('Daily Bonus',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                '+${formatCoins(WalletService.dailyCoinBonus)} coins  '
                '+${WalletService.dailyGemBonus} gems',
                style: const TextStyle(color: JuwaColors.gold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (ready)
                JuwaButton(
                  label: 'Claim',
                  onTap: () {
                    final r = w.claimDailyBonus();
                    Navigator.of(ctx).pop();
                    _snack(context,
                        'Claimed +${formatCoins(r.coins)} coins & +${r.gems} gems!');
                  },
                )
              else
                Column(
                  children: [
                    const JuwaButton(label: 'Claimed', onTap: null),
                    const SizedBox(height: 8),
                    Text(
                      'Next in ${w.bonusRemaining.inHours}h '
                      '${w.bonusRemaining.inMinutes % 60}m',
                      style: const TextStyle(color: JuwaColors.textDim),
                    ),
                  ],
                ),
              if (w.rescueReady) ...[
                const SizedBox(height: 12),
                JuwaButton(
                  label: 'Free Refill +${formatCoins(WalletService.rescueCoins)}',
                  onTap: () {
                    w.claimRescue();
                    _snack(context,
                        'Refilled +${formatCoins(WalletService.rescueCoins)} coins');
                  },
                ),
              ],
              const SizedBox(height: 16),
              const Text('Exchange Gems',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in const [10, 50])
                    JuwaButton(
                      label:
                          '$g gems → ${formatCoins(g * WalletService.coinsPerGem)}',
                      onTap: w.gems >= g
                          ? () {
                              w.exchangeGems(g);
                              _snack(context,
                                  '+${formatCoins(g * WalletService.coinsPerGem)} coins');
                            }
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Play games to level up and earn gifts in your mailbox',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: JuwaColors.textDim, fontSize: 12)),
            ],
          );
        },
      ),
    ),
  );
}

// ---------------- Profile ----------------
void showProfilePopup(BuildContext context) {
  final w = WalletService.instance;
  final controller = TextEditingController(text: w.player.username);
  showDialog(
    context: context,
    builder: (ctx) => JuwaPopup(
      title: 'Profile',
      child: AnimatedBuilder(
        animation: w,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/avatar_default.png',
                width: 90, height: 90),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Player name',
                hintStyle: const TextStyle(color: JuwaColors.textDim),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: JuwaColors.goldDark)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: JuwaColors.goldDark)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Level ${w.level}',
                style: const TextStyle(
                    color: JuwaColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: w.xpIntoLevel / WalletService.xpToNext(w.level),
                minHeight: 8,
                backgroundColor: Colors.black45,
                color: JuwaColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
                '${formatCoins(w.xpIntoLevel)} / '
                '${formatCoins(WalletService.xpToNext(w.level))} XP',
                style:
                    const TextStyle(color: JuwaColors.textDim, fontSize: 12)),
            const SizedBox(height: 12),
            _statRow('Coins', formatCoins(w.coins)),
            _statRow('Gems', '${w.gems}'),
            _statRow('Total Won', formatCoins(w.player.totalWon)),
            _statRow('Games Played', '${w.player.gamesPlayed}'),
            _statRow('Biggest Win', formatCoins(w.player.biggestWin)),
            _statRow('Favorite Game', w.player.favoriteGame ?? '-'),
            const SizedBox(height: 16),
            JuwaButton(
              label: 'Save',
              onTap: () {
                w.setUsername(controller.text);
                Navigator.of(ctx).pop();
                _snack(context, 'Profile saved');
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _statRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: JuwaColors.textDim)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );

// ---------------- Mail ----------------
void showMailPopup(BuildContext context) {
  final w = WalletService.instance;
  showDialog(
    context: context,
    builder: (ctx) => JuwaPopup(
      title: 'Mailbox',
      child: AnimatedBuilder(
        animation: w,
        builder: (context, _) {
          if (w.mail.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mark_email_read,
                      color: JuwaColors.textDim, size: 48),
                  SizedBox(height: 12),
                  Text('No new messages',
                      style:
                          TextStyle(color: JuwaColors.textDim, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Level up to receive gifts',
                      style:
                          TextStyle(color: JuwaColors.textDim, fontSize: 12)),
                ],
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in w.mail) _mailRow(context, m),
              if (w.mail.length > 1) ...[
                const SizedBox(height: 12),
                JuwaButton(
                  label: 'Claim All',
                  onTap: () {
                    final (c, g) = w.claimAllMail();
                    _snack(context,
                        'Claimed +${formatCoins(c)} coins & +$g gems!');
                  },
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

Widget _mailRow(BuildContext context, MailItem m) => Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JuwaColors.goldDark),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: JuwaColors.gold, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(m.body,
                    style: const TextStyle(
                        color: JuwaColors.textDim, fontSize: 12)),
                Text(
                    '+${formatCoins(m.coins)} coins'
                    '${m.gems > 0 ? '  +${m.gems} gems' : ''}',
                    style:
                        const TextStyle(color: JuwaColors.gold, fontSize: 12)),
              ],
            ),
          ),
          JuwaButton(
            label: 'Claim',
            onTap: () {
              WalletService.instance.claimMail(m.id);
              _snack(context, 'Claimed ${m.title}!');
            },
          ),
        ],
      ),
    );

// ---------------- Settings ----------------
void showSettingsPopup(BuildContext context) {
  final s = SettingsService.instance;
  showDialog(
    context: context,
    builder: (ctx) => JuwaPopup(
      title: 'Settings',
      child: AnimatedBuilder(
        animation: s,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggle('Sound', s.sound, s.setSound),
            _toggle('Music', s.music, s.setMusic),
            _toggle('Vibration', s.haptics, s.setHaptics),
            const SizedBox(height: 16),
            JuwaButton(
              label: 'Reset Progress',
              onTap: () => _confirmReset(context, ctx),
            ),
            const SizedBox(height: 12),
            const Text('Juwa v1.0.0',
                style: TextStyle(color: JuwaColors.textDim, fontSize: 12)),
          ],
        ),
      ),
    ),
  );
}

Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        Switch(
          value: value,
          onChanged: (v) {
            AudioService.instance.play(GameSound.click);
            onChanged(v);
          },
          activeThumbColor: JuwaColors.gold,
        ),
      ],
    );

void _confirmReset(BuildContext context, BuildContext settingsCtx) {
  showDialog(
    context: context,
    builder: (ctx) => JuwaPopup(
      title: 'Reset?',
      maxWidth: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This erases your coins, gems and stats and starts over. '
            'This cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          JuwaButton(
            label: 'Yes, Reset',
            onTap: () async {
              final confirmNav = Navigator.of(ctx);
              final settingsNav = Navigator.of(settingsCtx);
              final messenger = ScaffoldMessenger.of(context);
              await WalletService.instance.resetProgress();
              confirmNav.pop();
              settingsNav.pop();
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                  content: Text('Progress reset'),
                  backgroundColor: JuwaColors.panel,
                  behavior: SnackBarBehavior.floating,
                ));
            },
          ),
        ],
      ),
    ),
  );
}
